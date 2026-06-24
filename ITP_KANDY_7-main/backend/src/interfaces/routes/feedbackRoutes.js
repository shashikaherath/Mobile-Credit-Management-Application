const express = require('express');

function createFeedbackRoutes(feedbackController, authMiddleware) {
    const router = express.Router();

    // --- Public Routes ---
    // POST /api/public/feedback -> submit()
    // This allows unauthenticated users to contact admin for account issues.
    router.post('/public/feedback', (req, res) => feedbackController.submit(req, res));


    // --- Private Routes (Protected) ---
    // POST /api/feedback -> submit()
    router.post('/feedback', authMiddleware, (req, res) => feedbackController.submit(req, res));

    // GET /api/admin/feedback -> getAll()
    router.get('/admin/feedback', authMiddleware, (req, res) => feedbackController.getAll(req, res));

    // DELETE /api/admin/feedback/:id -> delete()
    router.delete('/admin/feedback/:id', authMiddleware, (req, res) => feedbackController.delete(req, res));

    return router;
}

module.exports = createFeedbackRoutes;
