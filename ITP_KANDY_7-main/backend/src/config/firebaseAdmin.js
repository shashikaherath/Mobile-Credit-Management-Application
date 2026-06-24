/**
 * Infrastructure Layer: Firebase Admin SDK Configuration.
 * Securely initializes the connection between the backend and Firebase Cloud services.
 * Primarily used for Firestore data persistence and potentially Firebase Auth migrations.
 */

const admin = require('firebase-admin'); // Core: Peer dependency for cloud interactions
const path = require('path');

// --- Logic: Secure Credential Loading ---
let serviceAccount;

if (process.env.FIREBASE_ADMIN_CONFIG) {
    try {
        // Strategy: Load from Environment Variable (Replit Secrets)
        // Benefit: Secure, cloud-native approach that avoids uploading physical JSON keys.
        serviceAccount = JSON.parse(process.env.FIREBASE_ADMIN_CONFIG);
    } catch (error) {
        console.error('❌ Failed to parse FIREBASE_ADMIN_CONFIG secret!');
        process.exit(1);
    }
} else {
    // Fallback: Load from local file system
    const serviceAccountPath = path.join(__dirname, '..', '..', 'serviceAccountKey.json');
    try {
        serviceAccount = require(serviceAccountPath);
    } catch (error) {
        // Fail-Fast: Provide actionable documentation in the console for the next developer.
        console.error('❌ Firebase service account key not found!');
        console.error(`   Expected at: ${serviceAccountPath} OR process.env.FIREBASE_ADMIN_CONFIG`);
        console.error('\n   --- TRANSPARENCY: FIX STEPS FOR TEAM ---');
        console.error('   1. Go to: Firebase Console → Project Settings → Service accounts');
        console.error('   2. Click "Generate new private key"');
        console.error('   3. Either save as "backend/serviceAccountKey.json" OR');
        console.error('   4. Add the JSON content to a Replit Secret named "FIREBASE_ADMIN_CONFIG"');
        console.error('   ----------------------------------------\n');
        
        // Critical: Exit if we have NO credentials to prevent unauthenticated operations.
        process.exit(1);
    }
}

/**
 * Logic: Initializing the Singleton Firebase Application.
 * Uses the loaded certificate to establish a secure gRPC channel to Firebase.
 */
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

/**
 * Infrastructure: Firestore Database Reference.
 * Provides a globally shared database instance for the repository layer.
 */
const db = admin.firestore();

// Policy: Ignore undefined properties during writes to prevent 'Document cannot be updated with null' errors.
db.settings({ ignoreUndefinedProperties: true });

// Audit: Log success for system monitoring.
console.log('✅ Firebase Admin SDK initialized successfully');

/**
 * Exports: Shared Cloud Infrastructure.
 * 'admin': Provides access to Auth, FCM, etc.
 * 'db': Standard Firestore instance for document-based storage.
 */
module.exports = { admin, db };
