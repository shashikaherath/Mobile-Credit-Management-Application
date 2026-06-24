const mongoose = require('mongoose'); // Database driver used here for low-level administration commands

/**
 * Business Logic: Provides real-time observability into the backend infrastructure.
 * Monitors database growth, load patterns (reads/writes), and connectivity status.
 */
class GetSystemHealth {
    /**
     * Executes a deep-dive probe into the MongoDB server status.
     * Note: This requires administrative privileges on some environments.
     */
    async execute() {
        try {
            // 1. Connection Check: Ensure we have an active pipe to the database.
            const db = mongoose.connection.db;
            if (!db) {
                // Critical failure if the database is unreachable.
                return { status: 'ERROR', message: 'Database connection not established' };
            }

            // 2. Fetch Storage Statistics: Calculate physical disk usage and object counts.
            const stats = await db.stats();
            
            // 3. Operational Counters: Attempt to fetch real-time query/insert/update/delete metrics.
            // NOTE: On MongoDB Atlas Free Tier, the 'serverStatus' command is often restricted.
            // We implement a "Soft Failure" pattern here to avoid crashing the health page if permissions are missing.
            let opcounters = { query: 0, insert: 0, update: 0, delete: 0, getmore: 0 };
            try {
                const serverStatus = await db.admin().serverStatus();
                if (serverStatus && serverStatus.opcounters) {
                    opcounters = serverStatus.opcounters; // Success: Metrics captured from server RAM
                }
            } catch (adminError) {
                // Fallback: Notify logs that we are in a permission-restricted environment.
                console.warn('[HEALTH] Could not fetch serverStatus (likely permission restricted):', adminError.message);
                // System remains functional, but real-time R/W charts will be flat (0).
            }
            
            // --- Calculation Phase ---
            
            // 4. Unit Conversion: Transform bytes into human-readable MegaBytes.
            const storageMB = (stats.storageSize / (1024 * 1024)).toFixed(2);
            
            // 5. Load Aggregation: Group specialized MongoDB operations into standard "Reads" and "Writes".
            const reads = (opcounters.query || 0) + (opcounters.getmore || 0);
            const writes = (opcounters.insert || 0) + (opcounters.update || 0) + (opcounters.delete || 0);
 
            // --- Final Data Construction ---
            return {
                status: 'OK', // Primary system heartbeat
                mongodb: {
                    storageUsed: `${storageMB} MB`, // Physical footprint
                    reads: reads, // Cumulative read load since server start
                    writes: writes, // Cumulative write load since server start
                    collections: stats.collections, // Number of logical tables
                    objects: stats.objects, // Number of total records across all collections
                    isRestricted: opcounters.query === 0 && opcounters.insert === 0 // Flag for UI to show "Limited View"
                },
                timestamp: new Date().toISOString() // Snapshot time for sync verification
            };
        } catch (error) {
            // Global Error Boundary: Log the detailed stack for engineers.
            console.error('[HEALTH] Unexpected error fetching system health:', error);
            throw new Error(`Failed to fetch system health: ${error.message}`);
        }
    }
}

// Module Export: Entry point for the dev-ops dashboard.
module.exports = GetSystemHealth;
