class ISaleRepository {
    async getAll(ownerId, limit = null, lastId = null) { throw new Error('Not implemented'); }
    async getById(id, ownerId, transaction = null) { throw new Error('Not implemented'); }
    async getByCustomer(customerId, ownerId, limit = null, lastId = null) { throw new Error('Not implemented'); }
    async create(saleData, transaction = null) { throw new Error('Not implemented'); }
    async update(id, saleData, ownerId, transaction = null) { throw new Error('Not implemented'); }
    async delete(id, ownerId, transaction = null) { throw new Error('Not implemented'); }
    async getTodayTotal(ownerId, timezoneOffset = 0) { throw new Error('Not implemented'); }
    async getTotalRevenue(ownerId) { throw new Error('Not implemented'); }
    async getAllByDateRange(ownerId, startDate, endDate) { throw new Error('Not implemented'); }
    async deleteAllByOwner(ownerId) { throw new Error('Not implemented'); }
}

module.exports = ISaleRepository;
