/**
 * Service: OTP & Identity Verification Store.
 * Purpose: Provides a centralized, shared state for managing OTP codes and verification proofs.
 * Rationale: This is a singleton service that allows both the OTP Gateway and Auth Use Cases
 *   to securely verify that an identifier (Email/Phone) has successfully passed a multi-factor
 *   challenge before allowing sensitive operations (Registration/Reset).
 */

class OtpStoreService {
    constructor() {
        // Active OTP sessions (Identifier -> { pin, expiresAt })
        this.otpSessions = new Map();
        
        // Active "Verified Proofs" (Identifier -> { verifiedAt, expiresAt })
        // These are created once a PIN is correctly verified.
        this.verifiedIdentities = new Map();
        
        // Configuration: 10-minute validity for the "Proof of Verification"
        this.PROOF_TTL_MS = 10 * 60 * 1000; 
        
        // Logical Guard: Background Scavenger.
        // Runs every 10 minutes to prune expired memory objects to prevent leaks.
        setInterval(() => this.cleanup(), 10 * 60 * 1000).unref();
    }

    /**
     * Periodic Maintenance: Prunes expired sessions and proofs from memory.
     */
    cleanup() {
        const now = Date.now();
        let prunedSessions = 0;
        let prunedProofs = 0;

        // Prune PIN Sessions
        for (const [key, value] of this.otpSessions.entries()) {
            if (value.expiresAt < now) {
                this.otpSessions.delete(key);
                prunedSessions++;
            }
        }

        // Prune Verification Proofs
        for (const [key, value] of this.verifiedIdentities.entries()) {
            if (value.expiresAt < now) {
                this.verifiedIdentities.delete(key);
                prunedProofs++;
            }
        }

        if (prunedSessions > 0 || prunedProofs > 0) {
            console.log(`[MAINTENANCE] OTP Scavenger active: Pruned ${prunedSessions} sessions and ${prunedProofs} proofs.`);
        }
    }

    // --- PIN Management ---
    setPin(target, pin, expiresAt) {
        this.otpSessions.set(target, { 
            pin, 
            expiresAt, 
            attempts: 0, 
            lastRequestedAt: Date.now() 
        });
    }

    getPin(target) {
        return this.otpSessions.get(target);
    }

    incrementAttempts(target) {
        const session = this.otpSessions.get(target);
        if (session) {
            session.attempts += 1;
            return session.attempts;
        }
        return 0;
    }

    isThrottled(target) {
        const session = this.otpSessions.get(target);
        if (!session) return false;
        
        const COOLDOWN_MS = 60 * 1000; // 1-minute cooldown
        const timeSinceLastRequest = Date.now() - session.lastRequestedAt;
        return timeSinceLastRequest < COOLDOWN_MS;
    }

    deletePin(target) {
        this.otpSessions.delete(target);
    }

    // --- Proof Management ---
    /**
     * Records that an identity has been successfully verified.
     */
    markAsVerified(target) {
        const now = Date.now();
        this.verifiedIdentities.set(target, {
            verifiedAt: now,
            expiresAt: now + this.PROOF_TTL_MS
        });
        console.log(`[SECURITY] Identity marked as verified: ${target}. Expires in 10 minutes.`);
    }

    /**
     * Checks if an identity has a valid, unexpired verification proof.
     */
    isVerified(target) {
        const proof = this.verifiedIdentities.get(target);
        if (!proof) return false;

        if (Date.now() > proof.expiresAt) {
            this.verifiedIdentities.delete(target); // Cleanup expired proof
            return false;
        }

        return true;
    }

    /**
     * Revokes a verification proof (call this after 'consuming' the proof during registration).
     */
    consumeProof(target) {
        const wasVerified = this.isVerified(target);
        this.verifiedIdentities.delete(target);
        return wasVerified;
    }
}

// Singleton Instance
module.exports = new OtpStoreService();
