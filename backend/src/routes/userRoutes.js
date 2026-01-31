const express = require('express');
const router = express.Router();
const { getAllUsers } = require('../controllers/userController');
const { protect, authorize } = require('../middleware/authMiddleware');

// @route   GET /api/users
// @desc    Get all users (admin and manager only)
router.get('/', protect, authorize('admin', 'manager'), getAllUsers);

module.exports = router;
