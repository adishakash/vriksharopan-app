const { body, validationResult } = require('express-validator');

/**
 * Extract validation errors from request and return 422 if any exist.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({
      success: false,
      message: 'Validation failed.',
      errors: errors.array().map((e) => ({ field: e.path, message: e.msg })),
    });
  }
  return next();
};

const registerRules = [
  body('name').trim().notEmpty().withMessage('Name is required.').isLength({ max: 150 }),
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required.'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters.')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain upper, lower case and a number.'),
  body('mobile').optional().isMobilePhone('en-IN').withMessage('Valid Indian mobile number required.'),
  body('role').optional().isIn(['customer', 'worker']).withMessage('Role must be customer or worker.'),
  body('pin_code').optional().isPostalCode('IN').withMessage('Valid PIN code required.'),
];

const loginRules = [
  body('email').isEmail().normalizeEmail().withMessage('Valid email is required.'),
  body('password').notEmpty().withMessage('Password is required.'),
];

const changePasswordRules = [
  body('currentPassword').notEmpty().withMessage('Current password is required.'),
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters.')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('New password must contain upper, lower case and a number.'),
];

module.exports = { validate, registerRules, loginRules, changePasswordRules };
