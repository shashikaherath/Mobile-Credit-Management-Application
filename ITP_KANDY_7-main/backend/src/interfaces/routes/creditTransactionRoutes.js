const express = require('express');

function createCreditTransactionRoutes(creditTransactionController) {
    const router = express.Router();
    router.get('/credit-transactions', (req, res) => creditTransactionController.getAll(req, res));
    router.get('/credit-transactions/customer/:customerId', (req, res) => creditTransactionController.getByCustomer(req, res));
    router.post('/credit-transactions', (req, res) => creditTransactionController.create(req, res));
    router.put('/credit-transactions/:id', (req, res) => creditTransactionController.update(req, res));
    router.delete('/credit-transactions/:id', (req, res) => creditTransactionController.delete(req, res));
    return router;
}

module.exports = createCreditTransactionRoutes;
