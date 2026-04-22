const express = require('express');
const router = express.Router();
const customersController = require('./customers.controller');
const { authenticate, authorize } = require('../../middleware/authenticate');

router.use(authenticate);
router.use(authorize('customer'));

router.get('/dashboard', customersController.getDashboard);
router.put('/profile', customersController.updateProfile);
router.get('/referrals', customersController.getReferrals);
router.put('/fcm-token', customersController.updateFcmToken);

module.exports = router;
