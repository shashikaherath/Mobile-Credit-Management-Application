/**
 * Infrastructure Layer: MongoDB Connection Configuration.
 * Handles the lifecycle of the database connection using Mongoose ODM.
 */

const mongoose = require('mongoose');
require('dotenv').config(); // Logic: Load environment secrets (MONGODB_URI) before initialization

/**
 * Logic: Database Bootstrapper.
 * Establishes a singleton connection to MongoDB Atlas or local instance.
 */
const connectDB = async () => {
    try {
        // Validation: Attempt to connect using the secure URI provided in the .env file.
        const conn = await mongoose.connect(process.env.MONGODB_URI, {
            // Stability: Max time to wait for a primary/secondary server selection before erroring.
            serverSelectionTimeoutMS: 5000, 
            // Performance: Max time a socket can stay idle before closing to prevent ghost connections.
            socketTimeoutMS: 45000,         
            // Network: Standardize on IPv4 to avoid DNS resolution lag on certain cloud providers.
            family: 4,                      
            // Reliability: Frequency of server availability pings to detect disconnections early.
            heartbeatFrequencyMS: 10000,    
        });
        
        // Audit: Positive confirmation of network handshake.
        console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        // Fail-Fast: Catch network/auth errors and terminate process to prevent corrupt app states.
        console.error(`❌ MongoDB Connection Error: ${error.message}`);
        
        // Diagnostic Support: Provide specific advice for common Atlas connection issues.
        if (error.message.includes('ETIMEDOUT') || error.message.includes('EADDRNOTAVAIL') || error.message.includes('selection timeout')) {
            console.error('💡 TIP: This usually means your IP address is not whitelisted in MongoDB Atlas.');
            console.error('👉 Run "node src/utils/checkIp.js" to find your public IP and add it to the Atlas Network Access list.');
        } else if (error.message.includes('Authentication failed')) {
            console.error('💡 TIP: Check your MONGODB_URI username and password in the .env file.');
        }

        process.exit(1); // Security: Critical failure exit code
    }
};

// Module Export: Connection handler for application entry points.
module.exports = connectDB;
