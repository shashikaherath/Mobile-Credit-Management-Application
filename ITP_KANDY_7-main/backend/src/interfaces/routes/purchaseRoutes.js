const express = require('express');

function createPurchaseRoutes(purchaseController) {
    const router = express.Router();
    router.get('/purchases', (req, res) => purchaseController.getAll(req, res));
    router.get('/purchases/:id', (req, res) => purchaseController.getById(req, res));
    router.post('/purchases', (req, res) => purchaseController.create(req, res));
    router.put('/purchases/:id/settle', (req, res) => purchaseController.settle(req, res));
    router.get('/purchases/supplier/:supplierId', (req, res) => purchaseController.getBySupplier(req, res));
    router.put('/purchases/:id', (req, res) => purchaseController.update(req, res));
    router.delete('/purchases/:id', (req, res) => purchaseController.delete(req, res));
    return router;
}

module.exports = createPurchaseRoutes;
