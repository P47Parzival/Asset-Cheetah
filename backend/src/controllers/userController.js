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

module.exports = { getMe };
