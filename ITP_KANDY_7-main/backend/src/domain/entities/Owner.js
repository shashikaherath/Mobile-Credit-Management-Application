/**
 * Domain Layer: Owner Entity.
 * Represents the primary merchant account and business identity in the system.
 * Encapsulates authentication credentials, business profile, and administrative status.
 */
class Owner {
    /**
     * Logic: Entity Initialization.
     * Maps merchant identity data into a structured business object for authentication and profile management.
     */
    constructor({ 
        id, // Unique identity (UUID)
        name, // Merchant's full legal name
        shopName, // The brand name of the business entity
        phone, // Primary identification and 2FA key
        email, // Optional digital communication channel
        password, // Security: Encrypted/Hashed password string (Only used in auth usecases)
        createdAt, // Audit: Initial registration timestamp
        updatedAt, // Audit: Last profile modification timestamp
        role, // Logic: 'owner' (standard merchant) or 'admin' (system superuser)
        status, // State: 'pending' (verification required), 'approved' (active access)
        isSuspended, // Administrative Lock: Prevents login if true
        profilePic // Visual asset reference for the identity
    }) {
        this.id = id;
        this.name = name || '';
        this.shopName = shopName || '';
        this.phone = phone || '';
        this.email = email || '';
        this.password = password || ''; // Persistence: Stays hashed in memory
        this.status = status || 'approved'; // Policy: Users stay approved unless manually flagged
        this.isSuspended = isSuspended ?? false; // Policy: Access is permitted by default
        this.createdAt = createdAt || new Date().toISOString();
        this.updatedAt = updatedAt || new Date().toISOString();
        this.role = role || 'owner'; // Role-Based Access Control: Defaults to standard merchant
        this.profilePic = profilePic || null;
    }

    /**
     * Logic: Data Serialization & Security.
     * Converts the entity into a JSON object for API transmission.
     * CRITICAL SECURITY: The 'password' field is EXPLICITLY OMITTED from serialization to prevent accidental leakage.
     */
    toJSON() {
        return {
            id: this.id,
            name: this.name,
            shopName: this.shopName,
            phone: this.phone,
            email: this.email,
            status: this.status,
            isSuspended: this.isSuspended,
            createdAt: this.createdAt,
            updatedAt: this.updatedAt,
            role: this.role,
            profilePic: this.profilePic
        };
    }
}

// Module Export: Global identity representation for the ShopBook business network.
module.exports = Owner;
