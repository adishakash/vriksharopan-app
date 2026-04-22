const express = require('express');
const router = express.Router();
const treesController = require('./trees.controller');
const { authenticate, authorize } = require('../../middleware/authenticate');
const { treePhotoUploader } = require('../../middleware/upload');

// All routes require authentication
router.use(authenticate);

router.get('/', treesController.getTrees);
router.get('/map', treesController.getTreesForMap);
router.get('/:id', treesController.getTreeById);

// Worker routes
router.post('/:id/geo-tag', authorize('worker'), treesController.geoTagTree);
router.post('/:id/photos', authorize('worker'), treePhotoUploader.single('photo'), treesController.uploadPhoto);
router.post('/:id/maintenance', authorize('worker'), treesController.logMaintenance);

// Customer routes
router.post('/gift', authorize('customer'), treesController.giftTree);

// Admin routes
router.post('/:id/assign-worker', authorize('admin', 'superadmin'), treesController.assignWorker);

module.exports = router;
