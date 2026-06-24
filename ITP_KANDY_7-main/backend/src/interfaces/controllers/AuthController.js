// AuthController handles everything related to user accounts: signing up, logging in, and managing profiles.
class AuthController {
    constructor({ registerOwner, loginOwner, getOwnerProfile, updateOwnerProfile, changeOwnerPassword, resetPassword, checkAvailability, deleteOwner }) {
        this.registerOwner = registerOwner;
        this.loginOwner = loginOwner;
        this.getOwnerProfile = getOwnerProfile;
        this.updateOwnerProfile = updateOwnerProfile;
        this.changeOwnerPassword = changeOwnerPassword;
        this.resetPasswordUseCase = resetPassword;
        this.checkAvailabilityUseCase = checkAvailability;
        this.deleteOwner = deleteOwner;
    }

    // Registers a brand new shop owner account.
    async register(req, res) {
        try {
            const { name, shopName, phone, email, password } = req.body;
            if (!phone || !password) {
                return res.status(400).json({ success: false, error: 'Phone number and password are required' });
            }
            // Generate a default name from phone if not provided
            const ownerName = name || `Owner_${phone.replace(/[^0-9]/g, '').slice(-6)}`;
            const result = await this.registerOwner.execute({ name: ownerName, shopName: shopName || '', phone, email: email || '', password });
            
            // Response: Include the cryptographically signed session token.
            res.status(201).json({ 
                success: true, 
                data: { 
                    ...result.owner, 
                    token: result.token 
                } 
            });
        } catch (error) {
            let statusCode = 500;
            if (error.message.includes('already exists')) statusCode = 409;
            if (error.message.includes('verification required')) statusCode = 401;
            
            res.status(statusCode).json({ success: false, error: error.message });
        }
    }

    // Logs in an existing owner using their email or phone number.
    async login(req, res) {
        try {
            const { email, phone, password, identifier } = req.body;
            // Support login by email, phone, or a generic identifier field
            const loginId = identifier || email || phone;
            if (!loginId || !password) {
                return res.status(400).json({ success: false, error: 'Email/Phone and password are required' });
            }
            const result = await this.loginOwner.execute(loginId, password);
            
            // Response: Bundle the user profile with the access token.
            res.json({ 
                success: true, 
                data: { 
                    ...result.owner, 
                    token: result.token 
                } 
            });
        } catch (error) {
            res.status(401).json({ success: false, error: error.message });
        }
    }

    // Retrieves the personal profile details of a specific owner.
    async getProfile(req, res) {
        try {
            // Security: Only allow users to see their own profile
            if (req.params.id !== req.ownerId) {
                return res.status(403).json({ success: false, error: 'Unauthorized access to profile' });
            }
            const owner = await this.getOwnerProfile.execute(req.params.id);
            if (!owner) {
                return res.status(404).json({ success: false, error: 'Owner not found' });
            }
            res.json({ success: true, data: owner });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Updates the profile information for an owner (e.g., changing their name or shop name).
    async updateProfile(req, res) {
        try {
            // Security: Only allow users to update their own profile
            if (req.params.id !== req.ownerId) {
                return res.status(403).json({ success: false, error: 'Unauthorized access to profile' });
            }
            const owner = await this.updateOwnerProfile.execute(req.params.id, req.body);
            if (!owner) {
                return res.status(404).json({ success: false, error: 'Owner not found' });
            }
            res.json({ success: true, data: owner });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Allows an owner to securely change their account password.
    async changePassword(req, res) {
        try {
            // Security: Only allow users to change their own password
            if (req.params.id !== req.ownerId) {
                return res.status(403).json({ success: false, error: 'Unauthorized access' });
            }
            const { oldPassword, newPassword } = req.body;
            if (!oldPassword || !newPassword) {
                return res.status(400).json({ success: false, error: 'Old password and new password are required' });
            }
            const owner = await this.changeOwnerPassword.execute(req.params.id, oldPassword, newPassword);
            res.json({ success: true, message: 'Password changed successfully', data: owner });
        } catch (error) {
            const statusCode = error.message.includes('not match') ? 401 : 500;
            res.status(statusCode).json({ success: false, error: error.message });
        }
    }

    // Allows unauthenticated password reset for cases where users forgot their password.
    async resetPassword(req, res) {
        try {
            const { identifier, email, phone, newPassword } = req.body;
            const resetId = identifier || email || phone;
            if (!resetId || !newPassword) {
                return res.status(400).json({ success: false, error: 'Email/Phone and new password are required' });
            }
            const owner = await this.resetPasswordUseCase.execute(resetId, newPassword);
            res.json({ success: true, message: 'Password reset successfully', data: owner });
        } catch (error) {
            const statusCode = error.message.includes('not found') ? 404 : 400;
            res.status(statusCode).json({ success: false, error: error.message });
        }
    }

    // Checks if a phone number or email is already registered.
    async checkAvailability(req, res) {
        try {
            const { phone, email } = req.body;
            const result = await this.checkAvailabilityUseCase.execute({ phone, email });
            res.json({ success: true, ...result });
        } catch (error) {
            res.status(400).json({ success: false, error: error.message });
        }
    }

    // Permanently deletes an owner profile and all associated data.
    async deleteProfile(req, res) {
        try {
            // Security: Only allow users to delete their own profile
            if (req.params.id !== req.ownerId) {
                return res.status(403).json({ success: false, error: 'Unauthorized access' });
            }
            const success = await this.deleteOwner.execute(req.params.id);
            if (!success) {
                return res.status(404).json({ success: false, error: 'Account not found or already deleted' });
            }
            res.json({ success: true, message: 'Account and all associated data have been permanently deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = AuthController;
