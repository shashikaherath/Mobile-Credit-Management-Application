/**
 * Infrastructure Layer: MongoDB Implementation of the Feedback Repository.
 * Collects and stores support requests and system testimonials for administrative review.
 */

const { v4: uuidv4 } = require('uuid'); // Utility for generating unique feedback submission IDs
const FeedbackModel = require('./models/Feedback'); // Database schema for user feedback
const Feedback = require('../domain/entities/Feedback'); // Domain entity for standardized feedback data
const IFeedbackRepository = require('../domain/repositories/IFeedbackRepository'); // Interface enforcement

class MongoFeedbackRepository extends IFeedbackRepository {
    constructor() {
        super();
        this.model = FeedbackModel; // Active Mongoose model instance
    }

    /**
     * Logic: Feedback Submission.
     * Persists a new support ticket or user message to the global collection.
     */
    async create(feedbackData) {
        const now = new Date().toISOString();
        
        // --- Logic: Data Packaging ---
        // Explicitly map incoming data to the schema structure.
        const data = {
            _id: feedbackData.id || uuidv4(), // Identity logic
            ownerId: feedbackData.ownerId, // Identifying key for the merchant who sent it
            ownerName: feedbackData.ownerName, // Human-readable name for admin view
            contactInfo: feedbackData.contactInfo, // Email or phone for follow-up
            claimedShopName: feedbackData.claimedShopName, // Business name provided at signup
            isVerified: feedbackData.isVerified, // Security state of the account
            category: feedbackData.category, // e.g., 'Account', 'Bug Report', 'General'
            message: feedbackData.message, // The core content of the feedback
            createdAt: now // Permanent audit timestamp
        };

        // Note: Using array syntax [] for creation to support session-like environments if expanded.
        const [doc] = await this.model.create([data]);
        return new Feedback({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    /**
     * Logic: Administrative Triage.
     * Fetches ALL feedback from ALL merchants, ordered newest first.
     * Note: This is a global view intended for ShopBook system administrators.
     */
    async getAll(limit = 100) {
        // Fetch records with a limit and .lean() optimization.
        // Sorting by newest-first so latest issues appear at the top.
        const docs = await this.model.find()
            .sort({ createdAt: -1 })
            .limit(limit)
            .lean();
        
        return docs.map(doc => {
            return new Feedback({ id: doc._id, ...doc }).toJSON();
        });
    }

    /**
     * Logic: Resolved Ticket Disposal.
     * Deletes a feedback record once it has been processed by support.
     */
    async delete(id) {
        const result = await this.model.deleteOne({ _id: id });
        return result.deletedCount > 0;
    }

    /**
     * Logic: Cascading account removal.
     */
    async deleteAllByOwner(ownerId, session = null) {
        return this.model.deleteMany({ ownerId }, { session });
    }
}

// Module Export: Data infrastructure implementation for the feedback subsystem.
module.exports = MongoFeedbackRepository;
