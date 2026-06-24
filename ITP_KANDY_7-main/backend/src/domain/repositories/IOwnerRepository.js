class IOwnerRepository {
    async create(ownerData) { throw new Error('Not implemented'); }
    async findByEmail(email) { throw new Error('Not implemented'); }
    async getById(id) { throw new Error('Not implemented'); }
    async update(id, ownerData) { throw new Error('Not implemented'); }
    async delete(id) { throw new Error('Not implemented'); }
}

module.exports = IOwnerRepository;
