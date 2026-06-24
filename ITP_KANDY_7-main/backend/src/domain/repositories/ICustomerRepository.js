class ICustomerRepository {
    async getAll(ownerId, limit, lastId) { throw new Error('Not implemented'); }
    async getTotalOutstanding(ownerId) { throw new Error('Not implemented'); }
    async getById(id) { throw new Error('Not implemented'); }
    async findByPhone(phone, ownerId) { throw new Error('Not implemented'); }
    async create(customerData) { throw new Error('Not implemented'); }
    async update(id, customerData) { throw new Error('Not implemented'); }
    async delete(id) { throw new Error('Not implemented'); }
    async deleteAllByOwner(ownerId) { throw new Error('Not implemented'); }
}

module.exports = ICustomerRepository;
