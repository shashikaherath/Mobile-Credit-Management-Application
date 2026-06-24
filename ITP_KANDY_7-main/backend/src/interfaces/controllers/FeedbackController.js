class FeedbackController {
    constructor(useCases) {
        this.submitFeedback = useCases.submitFeedback;
        this.getAllFeedback = useCases.getAllFeedback;
        this.deleteFeedback = useCases.deleteFeedback;
    }

    async submit(req, res) {
        try {
            const feedback = await this.submitFeedback.execute(req.body, req.ownerId, req.ownerName);
            res.status(201).json({ success: true, data: feedback });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    async getAll(req, res) {
        try {
            const feedbacks = await this.getAllFeedback.execute();
            res.json({ success: true, data: feedbacks });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    async delete(req, res) {
        try {
            const deleted = await this.deleteFeedback.execute(req.params.id);
            if (!deleted) {
                return res.status(404).json({ success: false, error: 'Feedback not found' });
            }
            res.json({ success: true, message: 'Feedback deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = FeedbackController;
