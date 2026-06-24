// CustomerController manages the profiles and contact information of the shop's customers.
class CustomerController {
    constructor({ getAllCustomers, getCustomerById, createCustomer, updateCustomer, deleteCustomer }) {
        this.getAllCustomers = getAllCustomers;
        this.getCustomerById = getCustomerById;
        this.createCustomer = createCustomer;
        this.updateCustomer = updateCustomer;
        this.deleteCustomer = deleteCustomer;
    }

    // Lists all customers registered in the shop's database.
    async getAll(req, res) {
        try {
            const { limit, lastId } = req.query;
            const customers = await this.getAllCustomers.execute(req.ownerId, limit, lastId);
            res.json({ success: true, data: customers });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Retrieves the details of a specific customer by their ID.
    async getById(req, res) {
        try {
            const customer = await this.getCustomerById.execute(req.params.id, req.ownerId);
            if (!customer) return res.status(404).json({ success: false, error: 'Customer not found' });
            res.json({ success: true, data: customer });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Adds a new customer profile to the system.
    async create(req, res) {
        try {
            const customer = await this.createCustomer.execute(req.body, req.ownerId);
            res.status(201).json({ success: true, data: customer });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Updates an existing customer's contact info or details.
    async update(req, res) {
        try {
            const customer = await this.updateCustomer.execute(req.params.id, req.body, req.ownerId);
            if (!customer) return res.status(404).json({ success: false, error: 'Customer not found' });
            res.json({ success: true, data: customer });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Removes a customer profile from the system.
    async delete(req, res) {
        try {
            const deleted = await this.deleteCustomer.execute(req.params.id, req.ownerId);
            if (!deleted) return res.status(404).json({ success: false, error: 'Customer not found' });
            res.json({ success: true, message: 'Customer deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = CustomerController;
