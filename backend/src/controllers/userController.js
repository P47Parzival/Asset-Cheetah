const User = require('../models/User');

// @desc    Get current logged in user
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res) => {
    res.json({
        _id: req.user._id,
        username: req.user.username,
        role: req.user.role,
    });
};

// @desc    Get all users
// @route   GET /api/users
// @access  Private (Admin, Manager only)
const getAllUsers = async (req, res) => {
    try {
        const users = await User.find({}).select('-password');
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};

module.exports = { getMe, getAllUsers };
