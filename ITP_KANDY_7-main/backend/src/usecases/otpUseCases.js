const nodemailer = require('nodemailer');
const otpStoreService = require('../services/otpStoreService');
const { normalizeEmail, normalizePhone } = require('./authUseCases');

/**
 * Normalization Helper: Selects the correct standardizer based on identifier type.
 */
function normalizeIdentifier(identifier) {
    if (!identifier) return identifier;
    return identifier.includes('@') ? normalizeEmail(identifier) : normalizePhone(identifier);
}

/**
 * Logic: Dual-Mode OTP Provisioner.
 * Rationale: Manages the lifecycle of security pins, offering both real email 
 *   delivery and a developer-safe "terminal mockup" for phone verification.
 */
class RequestOtp {
    async execute({ target, method }) {
        // --- Phase 1: Identity Normalization ---
        // Rationale: Ensures consistency between request, verification, and auth flows.
        const normalizedTarget = normalizeIdentifier(target);

        // --- Phase 1.1: Throttling Protection ---
        if (otpStoreService.isThrottled(normalizedTarget)) {
            throw new Error('Please wait 60 seconds before requesting a new code.');
        }

        // Step 1: Generate a secure 6-digit pin.
        const pin = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minute TTL

        // Step 2: Persist the pin in the registry.
        otpStoreService.setPin(normalizedTarget, pin, expiresAt);

        // Step 3: Delivery Orchestration.
        if (method === 'email') {
            await this._sendEmail(normalizedTarget, pin);
        } else if (method === 'phone') {
            await this._logToTerminal(normalizedTarget, pin);
        } else {
            throw new Error('Invalid verification method');
        }

        return { success: true, message: `OTP sent via ${method}` };
    }

    /**
     * Internal: Real-world Email Dispatcher.
     * Strategy: Uses Ethereal Mail for zero-setup testing, or Gmail for production.
     */
    async _sendEmail(email, pin) {
        let transporter;

        // Strategy: Use Gmail/SMTP if configured in .env, otherwise fallback to Ethereal Testing.
        if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
            transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: {
                    user: process.env.EMAIL_USER,
                    pass: process.env.EMAIL_PASS,
                },
            });
        } else {
            // Development Fallback: Ethereal Mail (No account required).
            console.log('\x1b[33m%s\x1b[0m', '⚠️ [OTP] EMAIL_USER/.PASS not set. Using Ethereal Mail for testing...');
            const testAccount = await nodemailer.createTestAccount();
            transporter = nodemailer.createTransport({
                host: "smtp.ethereal.email",
                port: 587,
                secure: false, 
                auth: {
                    user: testAccount.user,
                    pass: testAccount.pass,
                },
            });
        }

        const info = await transporter.sendMail({
            from: `"ShopBook Support" <${process.env.EMAIL_USER}>`,
            to: email,
            subject: "ShopBook - Your Verification Code",
            // Priority headers to signal transactional nature
            headers: {
                "X-Priority": "1 (Highest)",
                "X-MSMail-Priority": "High",
                "Importance": "High",
                "X-Auto-Response-Suppress": "All",
                "X-Entity-Ref-ID": `otp-${Date.now()}`
            },
            text: `Your ShopBook verification code is: ${pin}. It expires in 5 minutes.`,
            html: `
                <div style="max-width: 500px; margin: 0 auto; font-family: 'Segoe UI', Arial, sans-serif;">
                    <!-- HEADER: Dark gradient -->
                    <div style="background: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
                         padding: 30px 20px; border-radius: 16px 16px 0 0; text-align: center;">
                        <!-- Brand name -->
                        <div style="margin-top: 12px; font-size: 22px; font-weight: 700;
                             letter-spacing: 1.5px;">
                            <span style="color: #ffffff;">Shop</span><span style="color: #00B894;">Book</span>
                        </div>
                        <div style="color: #a0aec0; font-size: 11px; margin-top: 4px;
                             letter-spacing: 2px; text-transform: uppercase;">
                            Grocery Store
                        </div>
                    </div>

                    <!-- BODY: Light card -->
                    <div style="background: #ffffff; padding: 30px 25px; text-align: center;">
                        <h2 style="color: #2D3436; margin: 0 0 8px 0; font-size: 20px;">
                            Verify Your Identity
                        </h2>
                        <p style="color: #636E72; font-size: 14px; margin: 0 0 24px 0;">
                            Enter the following code to continue:
                        </p>

                        <!-- OTP Code Box -->
                        <div style="background: linear-gradient(135deg, #f8f9fa, #e9ecef);
                             border: 2px solid #00B894; border-radius: 12px;
                             padding: 18px; margin: 0 auto 24px; max-width: 280px;">
                            <div style="font-size: 36px; font-weight: 800; color: #00B894;
                                 letter-spacing: 8px; font-family: 'Courier New', monospace;">
                                ${pin}
                            </div>
                        </div>

                        <p style="color: #b2bec3; font-size: 12px; margin: 0;">
                            This code expires in <strong>5 minutes</strong>. 
                            If you didn't request this, you can safely ignore this email.
                        </p>
                    </div>

                    <!-- FOOTER: Dark section -->
                    <div style="background: #1a1a2e; padding: 16px 20px;
                         border-radius: 0 0 16px 16px; text-align: center;">
                        <p style="color: #636e72; font-size: 10px; margin: 0;">
                            Ref: ${Date.now().toString().slice(-6)} • ${new Date().toLocaleTimeString()}
                        </p>
                        <p style="color: #4a5568; font-size: 10px; margin: 4px 0 0 0;">
                            © ${new Date().getFullYear()} ShopBook — All rights reserved
                        </p>
                    </div>
                </div>
            `
        });

        // Diagnostic: Log the preview URL for free testing accounts.
        if (!process.env.EMAIL_USER) {
            console.log('\x1b[36m%s\x1b[0m', '📩 [OTP] Email Preview Link: ' + nodemailer.getTestMessageUrl(info));
        }
        console.log('\x1b[36m%s\x1b[0m', '🆔 [OTP] Message-ID: ' + info.messageId);
    }

    /**
     * Internal: Developer Mockup Dispatcher.
     * Rationale: Prints the code to the terminal, allowing immediate verification without carrier costs.
     */
    async _logToTerminal(phone, pin) {
        console.log('\n----------------------------------------');
        console.log('\x1b[32m%s\x1b[0m', '📱 [OTP MOCKUP]');
        console.log(`Target Number: ${phone}`);
        console.log('\x1b[1m\x1b[32m%s\x1b[0m', `VERIFICATION CODE: ${pin}`);
        console.log('----------------------------------------\n');
    }
}

/**
 * Logic: Identity Authenticator.
 * Rationale: Compares the user-provided pin against the registered session.
 */
class VerifyOtp {
    async execute({ target, pin }) {
        const normalizedTarget = normalizeIdentifier(target);
        const record = otpStoreService.getPin(normalizedTarget);

        if (!record) {
            throw new Error('No active verification session found');
        }

        if (Date.now() > record.expiresAt) {
            otpStoreService.deletePin(normalizedTarget);
            throw new Error('Verification code has expired');
        }

        if (record.pin !== pin) {
            const attempts = otpStoreService.incrementAttempts(normalizedTarget);
            const MAX_ATTEMPTS = 5;
            
            if (attempts >= MAX_ATTEMPTS) {
                otpStoreService.deletePin(normalizedTarget);
                throw new Error('Too many invalid attempts. This verification code has been deactivated for security. Please request a new one.');
            }
            
            throw new Error(`Invalid verification code. ${MAX_ATTEMPTS - attempts} attempts remaining.`);
        }

        // Action: Mark this identity as verified in the shared store.
        // This proof allows the Auth Use Cases to proceed with registration or reset.
        otpStoreService.markAsVerified(normalizedTarget);
        
        // Action: Cleanup the PIN record on success to prevent reuse.
        otpStoreService.deletePin(normalizedTarget);
        
        return { success: true, message: 'Identity verified successfully' };
    }
}

module.exports = { RequestOtp, VerifyOtp };
