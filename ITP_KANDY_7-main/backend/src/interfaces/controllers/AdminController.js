// AdminController handles administrative tasks, such as managing the shop owners.
class AdminController {
    constructor({ getAllOwners, updateOwnerProfile, deleteOwner, getOwnerProfile, getSystemHealth, backupDatabase }) {
        this.getAllOwners = getAllOwners;
        this.updateOwnerProfile = updateOwnerProfile;
        this.deleteOwner = deleteOwner;
        this.getOwnerProfile = getOwnerProfile;
        this.getSystemHealth = getSystemHealth;
        this.backupDatabase = backupDatabase;
    }

    // Fetches real-time system health and database statistics.
    async getSystemHealthStats(req, res) {
        try {
            const health = await this.getSystemHealth.execute();
            res.json({ success: true, data: health });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Fetches a list of all shop owners registered in the system.
    async getOwners(req, res) {
        try {
            const owners = await this.getAllOwners.execute();
            
            // Security: Sanitize output to prevent password hash leakage
            const sanitizedOwners = owners.map(owner => {
                const { password: _password, ...safeOwner } = owner;
                return safeOwner;
            });

            res.json({ success: true, data: sanitizedOwners });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    async updateOwner(req, res) {
        try {
            const owner = await this.updateOwnerProfile.execute(req.params.id, req.body);
            if (!owner) {
                return res.status(404).json({ success: false, error: 'Owner not found' });
            }
            res.json({ success: true, data: owner });
        } catch (error) {
            const statusCode = error.message.includes('already uses') || error.message.includes('Invalid owner status')
                ? 400
                : 500;
            res.status(statusCode).json({ success: false, error: error.message });
        }
    }

    async suspendOwner(req, res) {
        try {
            // First, fetch the current owner to determine their suspension status.
            const existingOwner = await this.getOwnerProfile.execute(req.params.id);
            if (!existingOwner) {
                return res.status(404).json({ success: false, error: 'Owner not found' });
            }

            // Security: Prevent administrative operations on a System Administrator
            if (existingOwner.role === 'admin') {
                return res.status(403).json({ 
                    success: false, 
                    error: 'Administrative accounts cannot be suspended via owner management.' 
                });
            }

            // Determine the new toggle state. If they are currently suspended, we unsuspend them.
            const currentlySuspended = existingOwner.isSuspended || existingOwner.status === 'suspended';
            const willBeSuspended = !currentlySuspended;

            const owner = await this.updateOwnerProfile.execute(req.params.id, {
                status: willBeSuspended ? 'suspended' : 'approved',
                isSuspended: willBeSuspended,
            });

            res.json({ success: true, data: owner });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    async deleteOwnerRecord(req, res) {
        try {
            // Security Check: Verify target is not an admin before deletion
            const targetOwner = await this.getOwnerProfile.execute(req.params.id);
            if (targetOwner && targetOwner.role === 'admin') {
                return res.status(403).json({ 
                    success: false, 
                    error: 'Administrative accounts cannot be deleted.' 
                });
            }

            const deleted = await this.deleteOwner.execute(req.params.id);
            if (!deleted) {
                return res.status(404).json({ success: false, error: 'Owner not found' });
            }
            res.json({ success: true, message: 'Owner deleted successfully' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Generates and downloads a ZIP backup of the entire MongoDB database.
    async downloadBackup(req, res) {
        try {
            const dateStr = new Date().toISOString().split('T')[0];
            const fileName = `shopbook_backup_${dateStr}.zip`;

            // Set headers for file download
            res.setHeader('Content-Type', 'application/zip');
            res.setHeader('Content-Disposition', `attachment; filename=${fileName}`);

            // Execute backup use case, piping output directly to response
            await this.backupDatabase.execute(res);
        } catch (error) {
            console.error('[ADMIN] Backup failed:', error);
            // If headers were already sent (e.g., streaming started), we can't send a normal JSON error.
            if (!res.headersSent) {
                res.status(500).json({ success: false, error: 'Database backup failed: ' + error.message });
            }
        }
    }
}

module.exports = AdminController;
