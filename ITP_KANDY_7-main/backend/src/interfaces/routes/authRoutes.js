const express = require('express');

function createAuthRoutes(authController, authMiddleware) {
    const router = express.Router();
    // Public routes
    router.post('/auth/register', (req, res) => authController.register(req, res));
    router.post('/auth/check-availability', (req, res) => authController.checkAvailability(req, res));
    router.post('/auth/login', (req, res) => authController.login(req, res));
    router.post('/auth/reset-password', (req, res) => authController.resetPassword(req, res));
    
    // Private routes (protected by authMiddleware)
    router.get('/auth/profile/:id', authMiddleware, (req, res) => authController.getProfile(req, res));
    router.put('/auth/profile/:id', authMiddleware, (req, res) => authController.updateProfile(req, res));
    router.delete('/auth/profile/:id', authMiddleware, (req, res) => authController.deleteProfile(req, res));
    router.put('/auth/change-password/:id', authMiddleware, (req, res) => authController.changePassword(req, res));
    
    return router;
}

module.exports = createAuthRoutes;
