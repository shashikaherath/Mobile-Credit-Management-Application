/**
 * Infrastructure Layer: MongoDB Implementation of the Owner Repository.
 * Orchestrates identity management and profile persistence for shop merchants.
 */

const { v4: uuidv4 } = require('uuid'); // Utility for generating unique merchant identifiers
const OwnerModel = require('./models/Owner'); // Database schema for merchant identities
const Owner = require('../domain/entities/Owner'); // Domain entity for security logic standardization
const IOwnerRepository = require('../domain/repositories/IOwnerRepository'); // Interface enforcement

class MongoOwnerRepository extends IOwnerRepository {
    constructor() {
        super();
        this.model = OwnerModel; // Active Mongoose model instance
    }

    /**
     * Logic: Merchant Registration.
     * Persists a new shop owner profile to the system.
     */
    async create(ownerData) {
        const now = new Date().toISOString();
        
        // --- Logic: Identity Assignment ---
        const data = {
            ...ownerData,
            _id: ownerData.id || ownerData._id || uuidv4(), // Use provided ID or generate fresh UUID
            createdAt: now, // Audit: Genesis timestamp
            updatedAt: now // Initial update matches creation
        };
        delete data.id; // Correct to internal MongoDB structure

        // Note: Using array syntax [] for creation to support potential transaction integration.
        const [doc] = await this.model.create([data]);
        const owner = new Owner(doc.toJSON());
        return owner.toJSON();
    }

    /**
     * Logic: Authentication Discovery.
     * Finds a merchant by their unique email address.
     */
    async findByEmail(email) {
        // Optimization: Lean results as this is typically used for authentication logic.
        const doc = await this.model.findOne({ email }).lean();
        if (!doc) return null;
        return { ...doc, id: doc._id }; // Return plain JSON
    }

    /**
     * Logic: Multi-Channel Identity Lookup.
     * Finds a merchant by their verified phone number.
     */
    async findByPhone(phone) {
        const doc = await this.model.findOne({ phone }).lean();
        if (!doc) return null;
        return { ...doc, id: doc._id };
    }

    /**
     * Logic: Profile Retrieval.
     * Fetches public-facing profile info based on the internal primary key.
     */
    async getById(id) {
        const doc = await this.model.findById(id).lean();
        if (!doc) return null;
        const owner = new Owner({ ...doc, id: doc._id });
        return owner.toJSON();
    }

    /**
     * Logic: Security-Critical Retrieval.
     * Fetches the full owner profile including the hashed password (used only during login checks).
     */
    async getByIdWithPassword(id) {
        const doc = await this.model.findById(id).lean();
        if (!doc) return null;
        // Return as an entity instance to allow internal hashing comparisons.
        return new Owner({ ...doc, id: doc._id }); 
    }

    /**
     * Logic: Administrative Directory.
     * Fetches ALL registered merchants for the master Admin Panel.
     */
    async getAll(limit = 100) {
        const docs = await this.model.find({}).limit(limit).lean();
        return docs.map(doc => new Owner({ ...doc, id: doc._id }).toJSON());
    }

    /**
     * Logic: Profile Correction & State Updates (e.g., Suspension).
     */
    async update(id, ownerData) {
        const updateData = {
            ...ownerData,
            updatedAt: new Date().toISOString() // Audit: Refresh modified timestamp
        };
        delete updateData.id; // Security: Immutable identity

        // Find and update in a single atomic database pass.
        const doc = await this.model.findByIdAndUpdate(
            id,
            { $set: updateData },
            { new: true } // Return the fresh post-update document
        );

        if (!doc) return null;
        const owner = new Owner(doc.toJSON());
        return owner.toJSON();
    }

    /**
     * Logic: Global Merchant Revocation.
     * Used for GDPR-compliant account deletion or administrative removal.
     */
    async delete(id, session = null) {
        const result = await this.model.deleteOne({ _id: id }).session(session);
        return result.deletedCount > 0;
    }
}

// Module Export: Data infrastructure implementation for the identity management system.
module.exports = MongoOwnerRepository;
