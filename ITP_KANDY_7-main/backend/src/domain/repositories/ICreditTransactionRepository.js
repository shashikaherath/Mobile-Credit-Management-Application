class ICreditTransactionRepository {
    async getAll(ownerId, limit = null, lastId = null) { throw new Error('Not implemented'); }
    async getByCustomer(customerId, ownerId, limit = null, lastId = null) { throw new Error('Not implemented'); }
    async getById(id, ownerId, transaction = null) { throw new Error('Not implemented'); }
    async create(transactionData, transaction = null) { throw new Error('Not implemented'); }
    async update(id, transactionData, ownerId) { throw new Error('Not implemented'); }
    async delete(id, ownerId, transaction = null) { throw new Error('Not implemented'); }
    async deleteByTitle(ownerId, customerId, titlePattern, transaction = null) { throw new Error('Not implemented'); }
    async deleteAllByOwner(ownerId) { throw new Error('Not implemented'); }
}

module.exports = ICreditTransactionRepository;
