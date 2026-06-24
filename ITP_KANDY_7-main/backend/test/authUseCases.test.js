const bcrypt = require('bcryptjs');
const { 
    RegisterOwner, 
    LoginOwner, 
    GetOwnerProfile, 
    UpdateOwnerProfile, 
    ChangeOwnerPassword, 
    GetAllOwners, 
    CheckAvailability,
    ResetPassword,
    UpdateOwnerByAdmin
} = require('../src/usecases/authUseCases');

jest.mock('../src/services/otpStoreService', () => ({
    isVerified: jest.fn().mockReturnValue(true),
    consumeProof: jest.fn()
}));

describe('Auth Use Cases', () => {
    let mockOwnerRepository;
    const testOwnerData = {
        name: 'John Doe',
        shopName: 'Test Shop',
        phone: '0771234567',
        email: 'john@gmail.com',
        password: 'password123'
    };

    beforeEach(() => {
        mockOwnerRepository = {
            create: jest.fn().mockImplementation(data => Promise.resolve({ id: 'owner1', ...data })),
            findByEmail: jest.fn().mockResolvedValue(null),
            findByPhone: jest.fn().mockResolvedValue(null),
            getById: jest.fn().mockImplementation(id => Promise.resolve({ id, name: 'John Doe', shopName: 'Test Shop', phone: '+94771234567', email: 'john@gmail.com' })),
            getByIdWithPassword: jest.fn().mockImplementation(async id => {
                const hashed = await bcrypt.hash('password123', 10);
                return { id, name: 'John Doe', password: hashed };
            }),
            getAll: jest.fn().mockResolvedValue([{ id: 'o1', name: 'Owner 1' }, { id: 'o2', name: 'Owner 2' }]),
            update: jest.fn().mockImplementation((id, data) => Promise.resolve({ id, ...data })),
        };
    });

    // ========== RegisterOwner ==========
    describe('RegisterOwner', () => {
        let registerOwner;
        beforeEach(() => { registerOwner = new RegisterOwner(mockOwnerRepository); });

        test('should register a new owner with valid data', async () => {
            const result = await registerOwner.execute(testOwnerData);
            expect(result.owner).toHaveProperty('id', 'owner1');
            expect(result).toHaveProperty('token');
            expect(mockOwnerRepository.create).toHaveBeenCalledTimes(1);
            // Password should be hashed
            const callArgs = mockOwnerRepository.create.mock.calls[0][0];
            expect(callArgs.password).not.toBe(testOwnerData.password);
            // Phone should be normalized to +94 format
            expect(callArgs.phone).toBe('+94771234567');
            // Email should be lowercase
            expect(callArgs.email).toBe('john@gmail.com');
        });

        test('should register with non-77 Sri Lankan prefix (e.g., 074)', async () => {
            const result = await registerOwner.execute({ ...testOwnerData, phone: '0741234567' });
            expect(result.owner).toHaveProperty('id', 'owner1');
            const callArgs = mockOwnerRepository.create.mock.calls[0][0];
            expect(callArgs.phone).toBe('+94741234567');
        });

        test('should throw if name is missing', async () => {
            await expect(registerOwner.execute({ ...testOwnerData, name: '' }))
                .rejects.toThrow('Owner name is required');
        });

        test('should throw if shopName is missing', async () => {
            await expect(registerOwner.execute({ ...testOwnerData, shopName: '' }))
                .rejects.toThrow('Shop name is required');
        });

        test('should throw if phone is invalid', async () => {
            await expect(registerOwner.execute({ ...testOwnerData, phone: '12345' }))
                .rejects.toThrow('Valid Sri Lankan phone number is required (starts with 07 or +947)');
        });

        test('should throw if email is not @gmail.com', async () => {
            await expect(registerOwner.execute({ ...testOwnerData, email: 'john@yahoo.com' }))
                .rejects.toThrow('Email must end with @gmail.com');
        });

        test('should throw if password is < 8 characters', async () => {
            await expect(registerOwner.execute({ ...testOwnerData, password: 'short' }))
                .rejects.toThrow('Password must be at least 8 characters');
        });

        test('should throw if email already exists', async () => {
            mockOwnerRepository.findByEmail.mockResolvedValue({ id: 'existing' });
            await expect(registerOwner.execute(testOwnerData))
                .rejects.toThrow('An account with this email already exists');
        });

        test('should throw if phone already exists', async () => {
            mockOwnerRepository.findByPhone.mockResolvedValue({ id: 'existing' });
            await expect(registerOwner.execute(testOwnerData))
                .rejects.toThrow('An account with this phone number already exists');
        });

        test('should allow registration without email', async () => {
            const noEmail = { ...testOwnerData, email: '' };
            const result = await registerOwner.execute(noEmail);
            expect(result.owner).toHaveProperty('id', 'owner1');
            expect(mockOwnerRepository.create).toHaveBeenCalledTimes(1);
        });
    });

    // ========== LoginOwner ==========
    describe('LoginOwner', () => {
        let loginOwner;
        beforeEach(() => {
            loginOwner = new LoginOwner(mockOwnerRepository);
        });

        test('should login with valid email and password', async () => {
            const hashedPwd = await bcrypt.hash('password123', 10);
            mockOwnerRepository.findByEmail.mockResolvedValue({ id: 'o1', email: 'john@gmail.com', password: hashedPwd, name: 'John' });
            const result = await loginOwner.execute('john@gmail.com', 'password123');
            expect(result.owner).toHaveProperty('id', 'o1');
            expect(result).toHaveProperty('token');
            expect(result.owner).not.toHaveProperty('password');
        });

        test('should login with valid phone and password', async () => {
            const hashedPwd = await bcrypt.hash('password123', 10);
            mockOwnerRepository.findByPhone.mockResolvedValue({ id: 'o1', phone: '+94771234567', password: hashedPwd, name: 'John' });
            const result = await loginOwner.execute('0771234567', 'password123');
            expect(result.owner).toHaveProperty('id', 'o1');
            expect(result).toHaveProperty('token');
        });

        test('should throw for non-existent user', async () => {
            mockOwnerRepository.findByEmail.mockResolvedValue(null);
            await expect(loginOwner.execute('nobody@gmail.com', 'password123'))
                .rejects.toThrow('Invalid email/phone or password');
        });

        test('should throw for wrong password', async () => {
            const hashedPwd = await bcrypt.hash('password123', 10);
            mockOwnerRepository.findByEmail.mockResolvedValue({ id: 'o1', email: 'john@gmail.com', password: hashedPwd });
            await expect(loginOwner.execute('john@gmail.com', 'wrongpassword'))
                .rejects.toThrow('Invalid email/phone or password');
        });
    });

    // ========== GetOwnerProfile ==========
    describe('GetOwnerProfile', () => {
        test('should retrieve owner profile by ID', async () => {
            const getProfile = new GetOwnerProfile(mockOwnerRepository);
            const result = await getProfile.execute('owner1');
            expect(mockOwnerRepository.getById).toHaveBeenCalledWith('owner1');
            expect(result).toHaveProperty('name', 'John Doe');
        });
    });

    // ========== UpdateOwnerProfile ==========
    describe('UpdateOwnerProfile', () => {
        let updateProfile;
        beforeEach(() => { updateProfile = new UpdateOwnerProfile(mockOwnerRepository); });

        test('should update profile and hash password if provided', async () => {
            await updateProfile.execute('o1', { name: 'New Name', password: 'newpassword123' });
            const callArgs = mockOwnerRepository.update.mock.calls[0][1];
            expect(callArgs.name).toBe('New Name');
            expect(callArgs).toHaveProperty('password');
            const matches = await bcrypt.compare('newpassword123', callArgs.password);
            expect(matches).toBe(true);
        });

        test('should update profile without password if not provided', async () => {
            await updateProfile.execute('o1', { name: 'New Name' });
            const callArgs = mockOwnerRepository.update.mock.calls[0][1];
            expect(callArgs).not.toHaveProperty('password');
            expect(callArgs.name).toBe('New Name');
        });

        test('should normalize phone number on update', async () => {
            await updateProfile.execute('o1', { phone: '0771234567' });
            const callArgs = mockOwnerRepository.update.mock.calls[0][1];
            expect(callArgs.phone).toBe('+94771234567');
        });

        test('should throw for invalid phone on update', async () => {
            await expect(updateProfile.execute('o1', { phone: '12345' }))
                .rejects.toThrow('Valid Sri Lankan phone number is required (starts with 07 or +947)');
        });

        test('should throw if target phone is already taken by another user', async () => {
            mockOwnerRepository.findByPhone.mockResolvedValue({ id: 'other-user', phone: '+94770000000' });
            await expect(updateProfile.execute('o1', { phone: '0770000000' }))
                .rejects.toThrow('Another account already uses this phone number');
        });

        test('should throw if target email is already taken by another user', async () => {
            mockOwnerRepository.findByEmail.mockResolvedValue({ id: 'other-user', email: 'other@gmail.com' });
            await expect(updateProfile.execute('o1', { email: 'other@gmail.com' }))
                .rejects.toThrow('Another account already uses this email address');
        });

        test('should succeed if updated phone/email belongs to the same user', async () => {
            mockOwnerRepository.findByPhone.mockResolvedValue({ id: 'o1', phone: '+94771234567' });
            const result = await updateProfile.execute('o1', { phone: '0771234567' });
            expect(result.phone).toBe('+94771234567');
        });
    });

    // ========== ChangeOwnerPassword ==========
    describe('ChangeOwnerPassword', () => {
        let changePassword;
        beforeEach(() => { changePassword = new ChangeOwnerPassword(mockOwnerRepository); });

        test('should change password with correct old password', async () => {
            await changePassword.execute('o1', 'password123', 'newpassword456');
            expect(mockOwnerRepository.update).toHaveBeenCalledTimes(1);
            const newPwdHash = mockOwnerRepository.update.mock.calls[0][1].password;
            // Verify the new password was hashed
            const matches = await bcrypt.compare('newpassword456', newPwdHash);
            expect(matches).toBe(true);
        });

        test('should throw if old password does not match', async () => {
            await expect(changePassword.execute('o1', 'wrongoldpassword', 'newpassword456'))
                .rejects.toThrow('Current password does not match');
        });

        test('should throw if owner not found', async () => {
            mockOwnerRepository.getByIdWithPassword.mockResolvedValue(null);
            await expect(changePassword.execute('no-owner', 'any', 'any'))
                .rejects.toThrow('Owner not found');
        });
    });

    // ========== GetAllOwners ==========
    describe('GetAllOwners', () => {
        test('should retrieve all owners', async () => {
            const getAllOwners = new GetAllOwners(mockOwnerRepository);
            const result = await getAllOwners.execute();
            expect(result).toHaveLength(2);
            expect(mockOwnerRepository.getAll).toHaveBeenCalledTimes(1);
        });
    });

    // ========== CheckAvailability ==========
    describe('CheckAvailability', () => {
        let checkAvailability;
        beforeEach(() => { checkAvailability = new CheckAvailability(mockOwnerRepository); });

        test('should return available true if phone and email are free', async () => {
            const result = await checkAvailability.execute({ phone: '0779998887', email: 'free@gmail.com' });
            expect(result.available).toBe(true);
        });

        test('should return available false if phone is taken', async () => {
            mockOwnerRepository.findByPhone.mockResolvedValue({ id: 'existing' });
            const result = await checkAvailability.execute({ phone: '0771234567' });
            expect(result.available).toBe(false);
            expect(result.message).toContain('phone number already exists');
        });

        test('should return available false if email is taken', async () => {
            mockOwnerRepository.findByEmail.mockResolvedValue({ id: 'existing' });
            const result = await checkAvailability.execute({ email: 'taken@gmail.com' });
            expect(result.available).toBe(false);
            expect(result.message).toContain('email already exists');
        });

        test('should throw if both phone and email are missing', async () => {
            await expect(checkAvailability.execute({}))
                .rejects.toThrow('Phone or Email is required for check');
        });
    });

    // ========== ResetPassword ==========
    describe('ResetPassword', () => {
        let resetPassword;
        const otpStore = require('../src/services/otpStoreService');

        beforeEach(() => {
            resetPassword = new ResetPassword(mockOwnerRepository);
            otpStore.isVerified.mockReturnValue(true);
        });

        test('should reset password with valid identifier and OTP', async () => {
            mockOwnerRepository.findByEmail.mockResolvedValue({ id: 'o1', email: 'user@gmail.com' });
            
            await resetPassword.execute('user@gmail.com', 'newPassword123');
            
            expect(mockOwnerRepository.update).toHaveBeenCalledWith('o1', expect.objectContaining({
                password: expect.any(String)
            }));
            expect(otpStore.consumeProof).toHaveBeenCalledWith('user@gmail.com');
        });

        test('should throw error if identifier not verified by OTP', async () => {
            otpStore.isVerified.mockReturnValue(false);
            mockOwnerRepository.findByEmail.mockResolvedValue({ id: 'o1', email: 'user@gmail.com' });
            await expect(resetPassword.execute('user@gmail.com', 'newPassword123'))
                .rejects.toThrow('Verification required');
        });

        test('should handle user not found', async () => {
            mockOwnerRepository.findByEmail.mockResolvedValue(null);
            await expect(resetPassword.execute('unknown@gmail.com', 'newPassword123'))
                .rejects.toThrow('User not found');
        });
    });

    // ========== UpdateOwnerByAdmin ==========
    describe('UpdateOwnerByAdmin', () => {
        let updateByAdmin;
        beforeEach(() => {
            updateByAdmin = new UpdateOwnerByAdmin(mockOwnerRepository);
            mockOwnerRepository.getByIdWithPassword = jest.fn().mockResolvedValue({
                id: 'o1', name: 'John', status: 'approved', isSuspended: false
            });
        });

        test('should update basic profile data', async () => {
            await updateByAdmin.execute('o1', { name: 'New Name' });
            expect(mockOwnerRepository.update).toHaveBeenCalledWith('o1', expect.objectContaining({
                name: 'New Name'
            }));
        });

        test('should handle account suspension', async () => {
            await updateByAdmin.execute('o1', { status: 'suspended' });
            expect(mockOwnerRepository.update).toHaveBeenCalledWith('o1', expect.objectContaining({
                status: 'suspended',
                isSuspended: true
            }));
        });

        test('should allow admin to reset password', async () => {
            await updateByAdmin.execute('o1', { password: 'adminResetPassword123' });
            const callArgs = mockOwnerRepository.update.mock.calls[0][1];
            const matches = await bcrypt.compare('adminResetPassword123', callArgs.password);
            expect(matches).toBe(true);
        });
    });
});
