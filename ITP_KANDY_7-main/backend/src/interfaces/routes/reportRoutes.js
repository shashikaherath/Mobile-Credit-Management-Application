const express = require('express');

function createReportRoutes(reportController) {
    const router = express.Router();

    router.get('/reports', (req, res) => reportController.getReport(req, res));

    return router;
}

module.exports = createReportRoutes;
