const express = require('express');
const router = express.Router();
const { syncEvents, syncAssets } = require('../controllers/syncController');
const { protect } = require('../middleware/authMiddleware');

router.post('/events', protect, syncEvents);
router.get('/assets', protect, syncAssets);

module.exports = router;
