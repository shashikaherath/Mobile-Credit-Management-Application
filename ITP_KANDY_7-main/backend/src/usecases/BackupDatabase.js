const mongoose = require('mongoose'); // Interface for raw database access and collection discovery
const archiver = require('archiver'); // High-level compression library for generating ZIP archives

/**
 * Business Logic: Disaster Recovery and Data Portability Service.
 * This use case exports the entire system state into a portable ZIP archive containing JSON snapshots of every collection.
 */
class BackupDatabase {
    /**
     * Executes the backup process and pipes the resulting stream directly to the HTTP response.
     * @param {Object} res - Express response object used as the destination stream.
     */
    async execute(res) {
        try {
            // 1. Connection Check: Ensure we have a valid handle to the underlying MongoDB driver.
            const db = mongoose.connection.db;
            if (!db) {
                throw new Error('Database connection not established');
            }

            // 2. Collection Discovery: Query the database to find all logical tables (collections).
            const collections = await db.listCollections().toArray();
            
            // 3. Archiver Initialization
            const archive = archiver('zip', {
                zlib: { level: 6 }
            });

            // 4. Error & Warning Boundaries
            archive.on('warning', (err) => {
                console.warn('[BACKUP] Archiver warning:', err);
            });

            archive.on('error', (err) => {
                console.error('[BACKUP] Archiver error:', err);
                if (!res.headersSent) {
                    res.status(500).send('Archive generation failed');
                } else {
                    res.end();
                }
            });

            // 5. Pipe Integration
            archive.pipe(res);

            // 6. Data Extraction Loop (Streaming approach)
            for (const collectionInfo of collections) {
                const collectionName = collectionInfo.name;
                
                // 6.1 Cursor Initialization: Fetch documents one by one to avoid OOM.
                const cursor = db.collection(collectionName).find({});
                
                // 6.2 Stream Buffer: We'll collect documents into an array, but stringify 
                // in chunks if necessary. For most cases, a manual loop over the cursor 
                // is safer than toArray().
                const documents = [];
                while (await cursor.hasNext()) {
                    documents.push(await cursor.next());
                }
                
                // 6.3 Append to Archive
                const content = JSON.stringify(documents, null, 2);
                archive.append(content, { name: `${collectionName}.json` });
                
                console.log(`[BACKUP] Added collection: ${collectionName} (${documents.length} records)`);
            }

            // 7. Finalization
            await archive.finalize();
            console.log(`[BACKUP] Database backup completed with ${collections.length} collections.`);
        } catch (error) {
            console.error('[BACKUP] Error during database backup:', error);
            if (!res.headersSent) {
                res.status(500).json({ success: false, error: error.message });
            } else {
                res.end();
            }
        }
    }
}

// Module Export: Entry point for the administrative backup utility.
module.exports = BackupDatabase;
