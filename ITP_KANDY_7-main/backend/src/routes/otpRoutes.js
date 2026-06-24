const express = require('express');
const router = express.Router();
const OtpController = require('../interfaces/controllers/OtpController');

/**
 * Registry: Security & Verification Endpoints.
 */

// Route: Initiate verification (Email or Mocked SMS)
router.post('/request', (req, res) => OtpController.requestOtp(req, res));

// Route: Validate current PIN
router.post('/verify', (req, res) => OtpController.verifyOtp(req, res));

module.exports = router;
