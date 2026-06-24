/**
 * Domain Layer: Feedback Entity.
 * Represents a merchant's communication with the system administrators.
 * Encapsulates support requests, bug reports, and account recovery documentation.
 */
class Feedback {
  /**
   * Logic: Entity Initialization.
   * Maps heterogeneous support data into a structured business object for administrative review.
   */
  constructor({
    id, // Unique identity (UUID)
    ownerId, // Link to the merchant (if authenticated)
    ownerName, // Snapshot of the sender's name for administrative clarity
    category, // Logic: 'Feedback', 'Error', 'Improvement', 'Account Recovery'
    message, // The core content of the submission
    createdAt, // Audit: When the feedback was transmitted
    contactInfo, // Fallback communication channel for unauthenticated users
    claimedShopName, // Identity proof for manual account recovery requests
    isVerified, // Security: Whether the sender passed an OTP challenge
  }) {
    this.id = id;
    this.ownerId = ownerId;
    this.ownerName = ownerName || 'Unknown User'; // Privacy: Default if name is missing
    this.contactInfo = contactInfo || null;
    this.claimedShopName = claimedShopName || null;
    this.isVerified = isVerified ?? false; // Security: Guaranteed boolean state
    this.category = category;
    this.message = message;
    this.createdAt = createdAt || new Date().toISOString(); // Audit timeline
  }

  /**
   * Logic: Data Serialization.
   * Converts the entity into a JSON object for storage in MongoDB or display in the Admin Panel.
   */
  toJSON() {
    return {
      id: this.id,
      ownerId: this.ownerId,
      ownerName: this.ownerName,
      category: this.category,
      message: this.message,
      createdAt: this.createdAt,
      contactInfo: this.contactInfo,
      claimedShopName: this.claimedShopName,
      isVerified: this.isVerified,
    };
  }
}

// Module Export: Business logic representation of a support or feedback event.
module.exports = Feedback;
