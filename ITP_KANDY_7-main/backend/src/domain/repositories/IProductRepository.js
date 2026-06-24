/**
 * Interface for Product Repository.
 * This file defines the "contract" for what a Product Repository should do.
 * Any concrete implementation (like FirestoreProductRepository) MUST
 * provide actual logic for all of these functions.
 * By using this interface, the rest of the app doesn't need to know *how*
 * data is stored, just that these functions exist.
 */
class IProductRepository {
    async getAll() { throw new Error('Not implemented'); }
    async getById(id) { throw new Error('Not implemented'); }
    async create(product) { throw new Error('Not implemented'); }
    async update(id, productData) { throw new Error('Not implemented'); }
    async delete(id) { throw new Error('Not implemented'); }
    async deleteAllByOwner(ownerId) { throw new Error('Not implemented'); }
}

module.exports = IProductRepository;
