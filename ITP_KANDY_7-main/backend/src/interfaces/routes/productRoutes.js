// Uses Express Router to map URL paths to Controller functions
const express = require('express');

function createProductRoutes(productController) {
    const router = express.Router();

    // GET /api/dashboard -> getDashboard()
    router.get('/dashboard', (req, res) => productController.getDashboard(req, res));

    // GET /api/transactions -> getTransactions()
    router.get('/transactions', (req, res) => productController.getTransactions(req, res));


    // GET /api/products -> getAll()
    router.get('/products', (req, res) => productController.getAll(req, res));

    // GET /api/products/:id -> getById()
    router.get('/products/:id', (req, res) => productController.getById(req, res));

    // POST /api/products -> create()
    router.post('/products', (req, res) => productController.create(req, res));

    // PUT /api/products/:id -> update()
    router.put('/products/:id', (req, res) => productController.update(req, res));

    // DELETE /api/products/:id -> delete()
    router.delete('/products/:id', (req, res) => productController.delete(req, res));

    return router;
}

module.exports = createProductRoutes;
