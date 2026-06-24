const dgram = require('dgram');
const client = dgram.createSocket('udp4');

client.on('message', (msg, rinfo) => {
  console.log(`📡 [Research] Received broadcast from ${rinfo.address}:${rinfo.port}`);
  console.log(`📦 [Research] Payload: ${msg.toString()}`);
});

client.bind(5555, () => {
  console.log('🕵️ [Research] Listening for backend heartbeat on port 5555...');
});

// Auto-stop after 15 seconds
setTimeout(() => {
  console.log('⏰ [Research] Done.');
  client.close();
  process.exit(0);
}, 15000);
