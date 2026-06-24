const express = require('express');

function createCustomerRoutes(customerController) {
    const router = express.Router();
    router.get('/customers', (req, res) => customerController.getAll(req, res));
    router.get('/customers/:id', (req, res) => customerController.getById(req, res));
    router.post('/customers', (req, res) => customerController.create(req, res));
    router.put('/customers/:id', (req, res) => customerController.update(req, res));
    router.delete('/customers/:id', (req, res) => customerController.delete(req, res));
    return router;
}

module.exports = createCustomerRoutes;
