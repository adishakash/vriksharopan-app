const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const { validate, registerRules, loginRules, changePasswordRules } = require('./auth.validator');
const { authenticate } = require('../../middleware/authenticate');

router.post('/register', registerRules, validate, authController.register);
router.post('/login', loginRules, validate, authController.login);
router.post('/admin/login', loginRules, validate, authController.adminLogin);
router.post('/refresh', authController.refreshTokens);
router.post('/logout', authController.logout);
router.post('/change-password', authenticate, changePasswordRules, validate, authController.changePassword);

module.exports = router;
