const express = require('express');

function createSaleRoutes(saleController) {
    const router = express.Router();
    router.get('/sales', (req, res) => saleController.getAll(req, res));
    router.get('/sales/:id', (req, res) => saleController.getById(req, res));
    router.get('/sales/customer/:customerId', (req, res) => saleController.getByCustomer(req, res));
    router.post('/sales', (req, res) => saleController.create(req, res));
    router.put('/sales/:id', (req, res) => saleController.update(req, res));
    router.delete('/sales/:id', (req, res) => saleController.delete(req, res));
    return router;
}

module.exports = createSaleRoutes;
