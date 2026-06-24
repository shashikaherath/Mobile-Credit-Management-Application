class IPurchaseRepository {
    async getAll(ownerId, limit, lastId) { throw new Error('Not implemented'); }
    async getById(id, ownerId, transaction) { throw new Error('Not implemented'); }
    async create(purchaseData, transaction) { throw new Error('Not implemented'); }
    async getBySupplier(supplierId, ownerId, limit, lastId) { throw new Error('Not implemented'); }
    async update(id, purchaseData, ownerId) { throw new Error('Not implemented'); }
    async delete(id, ownerId, transaction) { throw new Error('Not implemented'); }
    async getTotalPurchases(ownerId) { throw new Error('Not implemented'); }
    async getTotalPayable(ownerId) { throw new Error('Not implemented'); }
    async getAllByDateRange(ownerId, startDate, endDate) { throw new Error('Not implemented'); }
    async deleteAllByOwner(ownerId) { throw new Error('Not implemented'); }
}

module.exports = IPurchaseRepository;
