class ISupplierRepository {
    async getAll(ownerId, limit, lastId) { throw new Error('Not implemented'); }
    async getById(id) { throw new Error('Not implemented'); }
    async findByPhone(phone, ownerId) { throw new Error('Not implemented'); }
    async findByEmail(email, ownerId) { throw new Error('Not implemented'); }
    async create(supplierData) { throw new Error('Not implemented'); }
    async update(id, supplierData) { throw new Error('Not implemented'); }
    async delete(id) { throw new Error('Not implemented'); }
    async getTotalPayable(ownerId) { throw new Error('Not implemented'); }
    async countActive(ownerId) { throw new Error('Not implemented'); }
    async deleteAllByOwner(ownerId) { throw new Error('Not implemented'); }
}

module.exports = ISupplierRepository;
