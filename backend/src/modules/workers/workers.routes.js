const express = require('express');
const router = express.Router();
const workersController = require('./workers.controller');
const { authenticate, authorize } = require('../../middleware/authenticate');

router.use(authenticate);
router.use(authorize('worker'));

router.get('/dashboard', workersController.getDashboard);
router.get('/orders', workersController.getOrders);
router.put('/orders/:orderId', workersController.updateOrderStatus);
router.get('/earnings', workersController.getEarnings);
router.post('/attendance/check-in', workersController.checkIn);
router.post('/attendance/check-out', workersController.checkOut);
router.post('/sync', workersController.syncOfflineData);

module.exports = router;
