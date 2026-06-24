/**
 * Backend Utility: Global Validation Suite.
 * Enforces business-critical data integrity constraints for the ShopBook ecosystem.
 */

/**
 * Logic: Email Integrity.
 * ShopBook currently enforces a Gmail-only policy for merchant accounts for standardized recovery.
 */
const isValidEmail = (email) => {
    if (!email) return true; // Stability: Allow empty if field is optional in specific contexts.
    return email.toLowerCase().endsWith('@gmail.com'); // Constraint: Domain restriction.
};

/**
 * Logic: Contact Channel Verification.
 * Enforces strict formatting for Sri Lankan mobile numbers (Local & International formats).
 */
const isValidPhone = (phone) => {
    if (!phone) return false; // Constraint: Phone is a mandatory identity key.
    const trimmed = phone.trim();
    
    // Pattern A: Standard local 10-digit (e.g., 0771234567, 0741234567)
    // Pattern B: International format with +94 prefix (e.g., +94771234567, +94741234567)
    return /^07[0-9]{8}$/.test(trimmed) || /^\+947[0-9]{8}$/.test(trimmed);
};

/**
 * Logic: Security Baseline.
 * Enforces a minimum entropy standard for merchant passwords.
 */
const isValidPassword = (password) => {
    return password && password.length >= 8; // Constraint: 8-character minimum.
};

/**
 * Logic: Financial Precision.
 * Ensures the provided price is a positive numeric value to prevent accounting errors.
 */
const isValidPrice = (price) => {
    const val = parseFloat(price);
    // Stability: Use isNaN check and ensure it's strictly greater than zero.
    return !isNaN(val) && val > 0;
};

/**
 * Logic: Inventory Accuracy.
 * Ensures stock levels are valid non-negative integers for discrete unit tracking.
 */
const isValidStock = (stock) => {
    // Initial null/undefined check for required inventory fields.
    if (stock === null || stock === undefined || stock === '') return false;
    const val = Number(stock);
    
    // Integers are required for discrete units (e.g., 1 box, 2 items, NOT 1.5).
    return Number.isInteger(val) && val >= 0;
};

// Module Export: Validation logic shared across usecases and infrastructure.
module.exports = {
    isValidEmail,
    isValidPhone,
    isValidPassword,
    isValidPrice,
    isValidStock
};
