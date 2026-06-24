const { isValidEmail, isValidPhone, isValidPassword, isValidPrice, isValidStock } = require('../src/utils/validationUtils');

describe('Validation Utilities', () => {
    describe('isValidEmail', () => {
        test('should return true for valid gmail', () => {
            expect(isValidEmail('test@gmail.com')).toBe(true);
            expect(isValidEmail('TEST@GMAIL.COM')).toBe(true);
        });

        test('should return false for non-gmail domain', () => {
            expect(isValidEmail('test@yahoo.com')).toBe(false);
        });

        test('should return true for empty or null (optional)', () => {
            expect(isValidEmail('')).toBe(true);
            expect(isValidEmail(null)).toBe(true);
        });
    });

    describe('isValidPhone', () => {
        test('should return true for valid Sri Lankan formats', () => {
            expect(isValidPhone('0771234567')).toBe(true);
            expect(isValidPhone('+94771234567')).toBe(true);
        });

        test('should return false for invalid lengths or formats', () => {
            expect(isValidPhone('077123456')).toBe(false);
            expect(isValidPhone('07712345678')).toBe(false);
            expect(isValidPhone('+9477123456')).toBe(false);
            expect(isValidPhone('abcdefghij')).toBe(false);
        });
    });

    describe('isValidPassword', () => {
        test('should return true for 8+ characters', () => {
            expect(isValidPassword('password123')).toBe(true);
        });

        test('should return false for < 8 characters', () => {
            expect(isValidPassword('pass')).toBe(false);
        });
    });

    describe('isValidPrice', () => {
        test('should return true for positive numbers', () => {
            expect(isValidPrice(10.5)).toBe(true);
            expect(isValidPrice("100")).toBe(true);
            expect(isValidPrice(1)).toBe(true);
        });

        test('should return false for zero or negative numbers', () => {
            expect(isValidPrice(0)).toBe(false);
            expect(isValidPrice(-1)).toBe(false);
            expect(isValidPrice("-10")).toBe(false);
        });

        test('should return false for non-numeric values', () => {
            expect(isValidPrice('abc')).toBe(false);
            expect(isValidPrice(null)).toBe(false);
        });
    });

    describe('isValidStock', () => {
        test('should return true for non-negative integers', () => {
            expect(isValidStock(0)).toBe(true);
            expect(isValidStock(10)).toBe(true);
            expect(isValidStock("50")).toBe(true);
        });

        test('should return false for negative or decimal numbers', () => {
            expect(isValidStock(-1)).toBe(false);
            expect(isValidStock(5.5)).toBe(false);
            expect(isValidStock("-10")).toBe(false);
        });

        test('should return false for non-numeric values', () => {
            expect(isValidStock('abc')).toBe(false);
            expect(isValidStock(null)).toBe(false);
        });
    });
});
