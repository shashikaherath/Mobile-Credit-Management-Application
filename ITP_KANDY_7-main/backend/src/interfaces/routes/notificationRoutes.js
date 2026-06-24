const express = require('express');

function createNotificationRoutes(notificationController) {
    const router = express.Router();
    router.get('/notifications', (req, res) => notificationController.getAll(req, res));
    router.post('/notifications', (req, res) => notificationController.create(req, res));
    router.put('/notifications/:id/read', (req, res) => notificationController.markAsRead(req, res));
    router.put('/notifications/read-all', (req, res) => notificationController.markAllAsRead(req, res));
    router.delete('/notifications/:id', (req, res) => notificationController.delete(req, res));
    router.delete('/notifications', (req, res) => notificationController.deleteAll(req, res));
    return router;
}

module.exports = createNotificationRoutes;
