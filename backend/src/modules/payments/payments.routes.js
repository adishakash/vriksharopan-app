const express = require('express');
const router = express.Router();
const paymentsController = require('./payments.controller');
const { authenticate, authorize } = require('../../middleware/authenticate');

// Customer routes
router.post('/create-subscription', authenticate, authorize('customer'), paymentsController.createSubscription);
router.get('/', authenticate, paymentsController.getPayments);

// Webhook - no auth, uses signature verification
router.post('/webhook', express.raw({ type: 'application/json' }), paymentsController.handleWebhook);

// Admin routes
router.post('/refund/:paymentId', authenticate, authorize('admin', 'superadmin'), paymentsController.refundPayment);

module.exports = router;
