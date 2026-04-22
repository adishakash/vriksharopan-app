const express = require('express');
const router = express.Router();
const adminController = require('./admin.controller');
const { authenticate, authorize } = require('../../middleware/authenticate');

router.use(authenticate);
router.use(authorize('admin', 'superadmin'));

// Dashboard
router.get('/dashboard', adminController.getDashboard);

// Customer management
router.get('/customers', adminController.getCustomers);
router.put('/customers/:id/status', adminController.updateCustomerStatus);

// Worker management
router.get('/workers', adminController.getWorkers);
router.put('/workers/:id/approve', adminController.approveWorker);

// Photo moderation
router.get('/photos/pending', adminController.getPendingPhotos);
router.put('/photos/:id/moderate', adminController.moderatePhoto);

// Notifications
router.post('/notifications/broadcast', adminController.sendBroadcast);

// Analytics
router.get('/analytics', adminController.getAnalytics);

module.exports = router;
