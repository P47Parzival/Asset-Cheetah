const express = require('express');
const router = express.Router();
const { getAssets, getAssetById, getAssetEvents, createAsset } = require('../controllers/assetController');
const { protect, authorize } = require('../middleware/authMiddleware');

router.get('/', protect, getAssets);
router.get('/:id', protect, getAssetById);
router.post('/', protect, authorize('manager', 'admin'), createAsset); // RBAC: Only managers and admins can create assets
router.get('/:id/events', protect, getAssetEvents);

module.exports = router;
