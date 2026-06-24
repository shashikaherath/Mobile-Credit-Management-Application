const { GetAllCustomers, GetCustomerById, CreateCustomer, UpdateCustomer, DeleteCustomer } = require('../src/usecases/customerUseCases');

describe('Customer Use Cases', () => {
    let mockCustomerRepository;
    const ownerId = 'test-owner-123';

    beforeEach(() => {
        mockCustomerRepository = {
            getAll: jest.fn().mockResolvedValue([
                { id: 'c1', name: 'Customer A', totalOutstanding: 1000 },
                { id: 'c2', name: 'Customer B', totalOutstanding: 0 }
            ]),
            getById: jest.fn().mockImplementation(id => Promise.resolve({ id, name: 'Customer A', totalOutstanding: 1000 })),
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'new-c1', ...data })),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
            delete: jest.fn().mockResolvedValue(true),
            findByPhone: jest.fn().mockResolvedValue(null),
        };
    });

    describe('GetAllCustomers', () => {
        test('should return all customers', async () => {
            const useCase = new GetAllCustomers(mockCustomerRepository);
            const result = await useCase.execute(ownerId);
            expect(result).toHaveLength(2);
            expect(mockCustomerRepository.getAll).toHaveBeenCalledWith(ownerId, undefined, undefined);
        });
    });

    describe('GetCustomerById', () => {
        test('should return a customer by ID', async () => {
            const useCase = new GetCustomerById(mockCustomerRepository);
            const result = await useCase.execute('c1', ownerId);
            expect(result.name).toBe('Customer A');
        });
    });

    describe('CreateCustomer', () => {
        let createCustomer;
        beforeEach(() => { createCustomer = new CreateCustomer(mockCustomerRepository); });

        test('should create a customer with valid data', async () => {
            const data = { name: 'New Customer', phone: '0771234567' };
            const result = await createCustomer.execute(data, ownerId);
            expect(result).toHaveProperty('id', 'new-c1');
            expect(mockCustomerRepository.create).toHaveBeenCalledWith({ ...data, ownerId });
        });

        test('should throw if customer data is missing', async () => {
            await expect(createCustomer.execute(null, ownerId))
                .rejects.toThrow('Customer data and Owner ID are required');
        });

        test('should throw if ownerId is missing', async () => {
            await expect(createCustomer.execute({ name: 'X' }, null))
                .rejects.toThrow('Customer data and Owner ID are required');
        });

        test('should throw if phone number already exists', async () => {
            const data = { name: 'Duplicate', phone: '0771234567' };
            mockCustomerRepository.findByPhone.mockResolvedValue({ id: 'existing-c', ...data });
            
            await expect(createCustomer.execute(data, ownerId))
                .rejects.toThrow('A customer with this phone number already exists in your records');
            
            expect(mockCustomerRepository.findByPhone).toHaveBeenCalledWith(data.phone, ownerId);
        });
    });

    describe('UpdateCustomer', () => {
        let updateCustomer;
        beforeEach(() => { updateCustomer = new UpdateCustomer(mockCustomerRepository); });

        test('should update a customer', async () => {
            const result = await updateCustomer.execute('c1', { name: 'Updated' }, ownerId);
            expect(result.name).toBe('Updated');
        });

        test('should throw if ID is missing', async () => {
            await expect(updateCustomer.execute(null, { name: 'X' }, ownerId))
                .rejects.toThrow('Customer ID and Owner ID are required');
        });

        test('should throw if ownerId is missing', async () => {
            await expect(updateCustomer.execute('c1', { name: 'X' }, null))
                .rejects.toThrow('Customer ID and Owner ID are required');
        });
    });

    describe('DeleteCustomer', () => {
        test('should delete a customer', async () => {
            mockCustomerRepository.getById.mockResolvedValue({ id: 'c1', name: 'John', totalOutstanding: 0 });
            const useCase = new DeleteCustomer(mockCustomerRepository);
            const result = await useCase.execute('c1', ownerId);
            expect(result).toBe(true);
        });
    });
});
