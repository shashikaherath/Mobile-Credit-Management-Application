const BASE_URL = 'http://localhost:3000';

async function verifyBackendAndMongo() {
    console.log('--- SYSTEM CONNECTIVITY VERIFICATION ---\n');

    try {
        // 1. Backend Connectivity
        console.log('[STEP 1] Checking API Gateway Health...');
        const healthCheck = await fetch(`${BASE_URL}/health`);
        const healthData = await healthCheck.json();
        if (healthCheck.ok && healthData.status === 'OK') {
            console.log('✅ BACKEND: Online and responding.');
        } else {
            console.error('❌ BACKEND: Health check failed.');
            return;
        }

        // 2. Authentication & JWT Engine
        console.log('[STEP 2] Verifying Authentication & Token Issuance...');
        const login = await fetch(`${BASE_URL}/api/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ identifier: 'admin@gmail.com', password: 'admin1234' })
        });
        const loginResult = await login.json();
        if (login.ok && loginResult.success && loginResult.data.token) {
            console.log('✅ AUTH: JWT token successfully issued.');
            const token = loginResult.data.token;

            // 3. MongoDB Connectivity (via Admin Stats)
            console.log('[STEP 3] Verifying MongoDB Connection & Data Retrieval...');
            const statsCheck = await fetch(`${BASE_URL}/api/admin/system-health`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const statsData = await statsCheck.json();
            if (statsCheck.ok && statsData.success) {
                console.log('✅ MONGODB: Connected and returning statistics.');
                console.log(`   - Storage Used: ${statsData.data.mongodb.storageUsed}`);
                console.log(`   - Collections: ${statsData.data.mongodb.collections}`);
                console.log(`   - Total Objects: ${statsData.data.mongodb.objects}`);
            } else {
                console.error('❌ MONGODB: Failed to retrieve system stats.', statsData);
            }
        } else {
            console.error('❌ AUTH: Admin login failed. Check credentials or JWT secret.');
        }

    } catch (e) {
        console.error('❌ FATAL ERROR DURING VERIFICATION:', e.message);
    }

    console.log('\n--- VERIFICATION COMPLETE ---');
}

verifyBackendAndMongo();
