/**
 * Diagnostic Utility: Public IP Finder
 * This script helps developers identify their outbound IP address to whitelist it in MongoDB Atlas.
 */

const https = require('https');

console.log('🔍 Detecting your public IP address...');

https.get('https://api.ipify.org?format=json', (res) => {
    let data = '';
    res.on('data', (chunk) => { data += chunk; });
    res.on('end', () => {
        try {
            const ip = JSON.parse(data).ip;
            console.log('\n================================================');
            console.log(`🌐 YOUR PUBLIC IP: ${ip}`);
            console.log('================================================\n');
            console.log('✅ ACTION REQUIRED:');
            console.log('1. Log in to MongoDB Atlas.');
            console.log('2. Go to "Network Access" under "Security".');
            console.log('3. Click "Add IP Address".');
            console.log(`4. Paste ${ip} and click "Confirm".`);
            console.log('\nOnce whitelisted, wait ~1 minute and restart your server.\n');
        } catch (e) {
            console.error('❌ Failed to parse IP response:', e.message);
        }
    });
}).on('error', (err) => {
    console.error('❌ Network Error: Could not reach ipify.org.', err.message);
    console.log('Please check your internet connection or use "https://whatismyipaddress.com/" manually.');
});
