const express = require('express');

function createAdminRoutes(adminController) {
    const router = express.Router();
    router.get('/admin/owners', (req, res) => adminController.getOwners(req, res));
    router.get('/admin/system-health', (req, res) => adminController.getSystemHealthStats(req, res));
    router.put('/admin/owners/:id', (req, res) => adminController.updateOwner(req, res));
    router.patch('/admin/owners/:id/suspend', (req, res) => adminController.suspendOwner(req, res));
    router.delete('/admin/owners/:id', (req, res) => adminController.deleteOwnerRecord(req, res));
    router.get('/admin/backup', (req, res) => adminController.downloadBackup(req, res));
    return router;
}

module.exports = createAdminRoutes;
