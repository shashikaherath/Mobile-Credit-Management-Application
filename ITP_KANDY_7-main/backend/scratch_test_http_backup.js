const http = require('http');

async function run() {
  const loginData = JSON.stringify({ email: 'admin@gmail.com', password: 'admin1234' });

  const loginOptions = {
    hostname: '127.0.0.1',
    port: 3000,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': loginData.length
    }
  };

  const loginReq = http.request(loginOptions, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      console.log('Login Response:', res.statusCode);
      try {
        const body = JSON.parse(data);
        if (!body.data || !body.data.token) {
          console.error('No token in response', body);
          return;
        }
        
        console.log('Got token, testing backup endpoint...');
        
        const backupOptions = {
          hostname: '127.0.0.1',
          port: 3000,
          path: '/api/admin/backup',
          method: 'GET',
          headers: {
            'Authorization': 'Bearer ' + body.data.token
          }
        };

        const backupReq = http.request(backupOptions, (bRes) => {
          console.log('Backup Response:', bRes.statusCode);
          console.log('Backup Headers:', bRes.headers);
          
          let size = 0;
          bRes.on('data', chunk => size += chunk.length);
          bRes.on('end', () => {
            console.log('Backup download complete. Total bytes:', size);
          });
        });
        
        backupReq.on('error', (e) => console.error('Backup req error:', e));
        backupReq.end();
      } catch (e) {
        console.error('Parse error', e);
      }
    });
  });

  loginReq.on('error', (e) => console.error('Login req error:', e));
  loginReq.write(loginData);
  loginReq.end();
}

run();
