const dgram = require('dgram'); // Core Node.js module for UDP (User Datagram Protocol) networking
const os = require('os'); // Core module for interacting with the host operating system's interfaces

/**
 * Infrastructure Service: Auto-Discovery Heartbeat.
 * Broadcasts the server's local IP address across the Wi-Fi network.
 * This allows mobile devices to automatically handshake with the backend without manual IP entry.
 */
class DiscoveryService {
    constructor(port = 3000, broadcastPort = 5555) {
        this.port = port; // The target API port the mobile app should connect to
        this.broadcastPort = broadcastPort; // The standard UDP port for the discovery listener
        this.socket = dgram.createSocket('udp4'); // Create an IPv4 UDP socket
        this.interval = null; // Reference to the periodic broadcast timer
    }

    /**
     * Logic: Network Interface Probe.
     * Scans the machine's hardware to find the most likely "Local IP" reachable by a mobile device.
     */
    getLocalIp() {
        const interfaces = os.networkInterfaces(); // Fetch all physical and virtual network adapters
        let fallbackIp = '127.0.0.1'; // Default to localhost if no network is found

        for (const name of Object.keys(interfaces)) {
            // --- Strategy: Interface Filtering ---
            // Skip virtual adapters (Docker, VM, VirtualBox) which often have IPs 
            // that are NOT reachable by external mobile devices.
            const lowerName = name.toLowerCase();
            if (lowerName.includes('vbox') || lowerName.includes('vmware') || lowerName.includes('virtual') || lowerName.includes('pseudo')) {
                continue;
            }

            for (const iface of interfaces[name]) {
                // Focus: Only consider IPv4 addresses that are NOT internal (loopback).
                if (iface.family === 'IPv4' && !iface.internal) {
                    
                    // --- Strategy: Subnet Prioritization ---
                    // Prefer IPs on common private subnets used by home/office Wi-Fi.
                    // (192.168.x.x, 10.x.x.x, or 172.16-31.x.x)
                    if (iface.address.startsWith('192.168.') || iface.address.startsWith('10.')) {
                        return iface.address; // Return immediate match for standard Wi-Fi
                    }
                    
                    // Specific check for the Class B private range (172.16.x.x - 172.31.x.x).
                    const parts = iface.address.split('.');
                    if (parts[0] === '172') {
                        const second = parseInt(parts[1], 10);
                        if (second >= 16 && second <= 31) {
                            return iface.address;
                        }
                    }
                    fallbackIp = iface.address; // Use as fallback if it's the only non-internal IPv4
                }
            }
        }
        return fallbackIp; // Return best guess
    }

    /**
     * Logic: Starts the UDP transmission engine.
     * @param {number} apiPort - The port the main Express server is listening on.
     */
    start(apiPort) {
        if (apiPort) {
            this.port = apiPort; // Update the port to match the actual server configuration
        }
        // Handle unexpected socket crashes (e.g., port already in use).
        this.socket.on('error', (err) => {
            console.error(`[Discovery] Socket error:\n${err.stack}`);
            this.socket.close();
        });

        // Bind the socket to start the UDP lifecycle.
        this.socket.bind(() => {
            // Critical: Enable Broadcast mode so the packet reaches all devices on the subnet.
            this.socket.setBroadcast(true);
            console.log(`📡 [Discovery] Auto-discovery heartbeat started on UDP port ${this.broadcastPort}`);

            // Periodically shout the server's identity into the network.
            this.interval = setInterval(() => {
                const ip = this.getLocalIp();
                
                // Construct the "Heartbeat" payload.
                const message = JSON.stringify({
                    service: 'shopbook', // Signature for the mobile app to recognize us
                    ip: ip, // Our reachable address
                    port: this.port, // Logic: Tell the phone which port we are listening on
                    timestamp: Date.now() // For health tracking
                });

                // Send to the global broadcast address (255.255.255.255).
                this.socket.send(message, 0, message.length, this.broadcastPort, '255.255.255.255', (err) => {
                    if (err) console.error('[Discovery] Broadcast error:', err);
                });
            }, 2000); // Pulse every 2 seconds to minimize battery drain on phone listeners
        });
    }

    /**
     * Logic: Cleanup.
     * Shuts down the socket and clears timers upon server termination.
     */
    stop() {
        if (this.interval) {
            clearInterval(this.interval);
        }
        this.socket.close();
    }
}

// Module Export: Singleton instance shared across the main server entry point.
module.exports = new DiscoveryService();
