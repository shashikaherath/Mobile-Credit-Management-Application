/**
 * Business Logic: Manages the bidirectional communication between shop owners and system administrators.
 * Handles support requests, bug reports, and account recovery escalations.
 */

/**
 * Logic: Processes a new feedback submission or support ticket.
 * Includes automated escalation for critical categories.
 */
class SubmitFeedback {
    constructor(feedbackRepository, notificationRepository) {
        this.feedbackRepository = feedbackRepository; // Storage for feedback records
        this.notificationRepository = notificationRepository; // Interface for alerting admins
    }

    async execute(feedbackData, ownerId, ownerName) {
        // --- Input Validation Phase ---
        if (!feedbackData.message || feedbackData.message.trim() === '') {
            throw new Error('Feedback message is required');
        }
        if (!feedbackData.category) {
            throw new Error('Feedback category is required');
        }

        // 1. Persistence: Save the feedback entry for administrative audit.
        const feedback = await this.feedbackRepository.create({
            ...feedbackData,
            ownerId, // Linked user (if authenticated)
            ownerName // Human-readable name for the admin panel
        });

        // --- Escalation Phase ---
        // If the request is sensitive (Account Recovery) or urgent (Emergency), or from an unauthenticated user,
        // we proactively notify the master administrator to ensure a fast response time.
        if (!ownerId || feedbackData.category === 'Account Recovery' || feedbackData.category === 'Emergency/Support') {
            try {
                const adminId = 'admin_master_001'; // Static identifier for the system-level administrator
                const verificationStatus = feedbackData.isVerified ? ' (Verified Owner)' : ' (Unverified)';
                
                // Create a global notification for the admin dashboard.
                await this.notificationRepository.create({
                    ownerId: adminId,
                    type: 'alert', // Distinguished from standard 'info' notifications
                    title: 'New Support Request',
                    message: `New ${feedbackData.category} request from ${feedbackData.contactInfo || ownerName || 'Guest'}${verificationStatus}.`
                });
            } catch (notifyError) {
                // Non-blocking failure: Log error but return the feedback result so the user isn't stuck.
                console.error('[NOTIFY] Failed to alert admin of support request:', notifyError);
            }
        }

        return feedback;
    }
}

/**
 * Logic: Retrieves the global pool of feedback for administrative review.
 */
class GetAllFeedback {
    constructor(feedbackRepository) {
        this.feedbackRepository = feedbackRepository;
    }

    /**
     * Executes retrieval of all messages across all users.
     */
    async execute() {
        return this.feedbackRepository.getAll();
    }
}

/**
 * Logic: Safely removes an addressed or resolved feedback ticket.
 */
class DeleteFeedback {
    constructor(feedbackRepository) {
        this.feedbackRepository = feedbackRepository;
    }

    async execute(id) {
        return this.feedbackRepository.delete(id);
    }
}

// Module Exports: Exposes the feedback management suite.
module.exports = {
    SubmitFeedback,
    GetAllFeedback,
    DeleteFeedback
};
