const express = require('express');
const router = express.Router();
const { getAssets, getAssetById, getAssetEvents, createAsset } = require('../controllers/assetController');
const { protect } = require('../middleware/authMiddleware');

router.get('/', protect, getAssets);
router.get('/:id', protect, getAssetById);
router.post('/', protect, createAsset);
router.get('/:id/events', protect, getAssetEvents);

module.exports = router;
