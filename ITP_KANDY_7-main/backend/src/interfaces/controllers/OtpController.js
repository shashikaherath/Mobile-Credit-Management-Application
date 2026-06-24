const { RequestOtp, VerifyOtp } = require('../../usecases/otpUseCases');

// Shared State: Centralized registry for active verification sessions.
// Note: In a production cluster, this should be moved to Redis or MongoDB.
class OtpController {
    constructor() {
        this.requestOtpUseCase = new RequestOtp();
        this.verifyOtpUseCase = new VerifyOtp();
    }

    /**
     * POST /api/otp/request
     * Triggers the generation and dispatch of a verification pin.
     */
    async requestOtp(req, res) {
        try {
            const { target, method } = req.body;
            
            if (!target || !method) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Target identifier and delivery method are required.' 
                });
            }

            const result = await this.requestOtpUseCase.execute({ target, method });
            return res.status(200).json(result);
        } catch (error) {
            console.error('❌ [OtpController] Request Error:', error.message);
            
            // Logic: Distinguish between client errors (throttling) and server faults.
            let statusCode = 500;
            if (error.message.includes('wait') || error.message.includes('required')) {
                statusCode = 400; // Client-side logic error or throttling
            }

            return res.status(statusCode).json({ 
                success: false, 
                error: error.message || 'Internal server error during OTP request.' 
            });
        }
    }

    /**
     * POST /api/otp/verify
     * Validates a user-provided pin against an active session.
     */
    async verifyOtp(req, res) {
        try {
            const { target, pin } = req.body;

            if (!target || !pin) {
                return res.status(400).json({ 
                    success: false, 
                    message: 'Identifier and PIN code are required.' 
                });
            }

            const result = await this.verifyOtpUseCase.execute({ target, pin });
            return res.status(200).json(result);
        } catch (error) {
            console.error('❌ [OtpController] Verification Error:', error.message);
            
            // Logic: Align with standard HTTP patterns.
            let statusCode = 401; // Default to Unauthorized
            if (error.message.includes('No active')) statusCode = 404;
            if (error.message.includes('Too many')) statusCode = 403; // Forbidden (locked out)

            return res.status(statusCode).json({ 
                success: false, 
                error: error.message || 'Verification failed.' 
            });
        }
    }
}

module.exports = new OtpController();
