// Interface for Feedback operations
class IFeedbackRepository {
    async create(feedbackData) {
        throw new Error('Method not implemented');
    }

    async getAll() {
        throw new Error('Method not implemented');
    }

    async delete(id) {
        throw new Error('Method not implemented');
    }

    async deleteAllByOwner(ownerId) {
        throw new Error('Method not implemented');
    }
}

module.exports = IFeedbackRepository;
