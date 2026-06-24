const mongoose = require('mongoose');
const BackupDatabase = require('./src/usecases/BackupDatabase');
const fs = require('fs');

async function testBackup() {
    await mongoose.connect('mongodb://127.0.0.1:27017/shopbook');
    console.log('Connected to DB');

    const backup = new BackupDatabase();
    
    // Mock the Express response object
    const res = {
        headersSent: false,
        status: function(code) {
            console.log('Status set to:', code);
            return this;
        },
        json: function(data) {
            console.log('JSON sent:', data);
        },
        send: function(data) {
            console.log('Send called:', data);
        },
        end: function() {
            console.log('End called');
        },
        on: function(event, callback) {
            // Mock event listener
        },
        once: function(event, callback) {
            // Mock event listener
        },
        emit: function(event, ...args) {
            // Mock event emitter
        }
    };

    const outStream = fs.createWriteStream('test_backup.zip');
    
    // archiver pipe expects a Writable stream, so let's just pass outStream directly 
    // to see if the core logic works, BUT BackupDatabase uses res to set status.
    // Let's add Writable methods to res to make it act like a Writable stream that wraps outStream
    
    const mockRes = Object.assign(outStream, res);

    try {
        await backup.execute(mockRes);
        console.log('Execute finished');
    } catch (e) {
        console.error('Execute failed', e);
    }
    
    mongoose.connection.close();
}

testBackup();
