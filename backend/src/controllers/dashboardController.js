const Asset = require('../models/Asset');
const Event = require('../models/Event');

// @desc    Get Dashboard Statistics
// @route   GET /api/dashboard/stats
// @access  Private
const getDashboardStats = async (req, res) => {
    try {
        const totalAssets = await Asset.countDocuments();
        const maintenanceAssets = await Asset.countDocuments({ status: 'maintenance' });
        const totalEvents = await Event.countDocuments();

        // Optional: Recent activity (last 5 events)
        const recentActivity = await Event.find()
            .sort({ occurredAt: -1 })
            .limit(5)
            .populate('userId', 'username');

        res.json({
            totalAssets,
            maintenanceAssets,
            totalEvents,
            recentActivity
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

module.exports = { getDashboardStats };
