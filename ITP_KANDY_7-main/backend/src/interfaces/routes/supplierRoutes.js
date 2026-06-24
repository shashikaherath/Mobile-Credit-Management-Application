const express = require('express');

function createSupplierRoutes(supplierController) {
    const router = express.Router();
    router.get('/suppliers/summary', (req, res) => supplierController.getSummary(req, res));
    router.get('/suppliers', (req, res) => supplierController.getAll(req, res));
    router.get('/suppliers/:id', (req, res) => supplierController.getById(req, res));
    router.post('/suppliers', (req, res) => supplierController.create(req, res));
    router.put('/suppliers/:id', (req, res) => supplierController.update(req, res));
    router.delete('/suppliers/:id', (req, res) => supplierController.delete(req, res));
    return router;
}

module.exports = createSupplierRoutes;
