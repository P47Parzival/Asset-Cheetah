const Asset = require('../models/Asset');
const Event = require('../models/Event');

// @desc    Get All Assets (Paginated)
// @route   GET /api/assets
// @access  Private
const getAssets = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const query = {};
        if (req.query.search) {
            query.$or = [
                { name: { $regex: req.query.search, $options: 'i' } },
                { assetId: { $regex: req.query.search, $options: 'i' } }
            ];
        }
        if (req.query.status) {
            query.status = req.query.status;
        }

        const assets = await Asset.find(query)
            .sort({ updatedAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await Asset.countDocuments(query);

        res.json({
            assets,
            page,
            pages: Math.ceil(total / limit),
            total
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Get Single Asset
// @route   GET /api/assets/:id
// @access  Private
const getAssetById = async (req, res) => {
    try {
        const asset = await Asset.findOne({ assetId: req.params.id });

        if (!asset) {
            return res.status(404).json({ message: 'Asset not found' });
        }

        res.json(asset);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Get Asset History (Events)
// @route   GET /api/assets/:id/events
// @access  Private
const getAssetEvents = async (req, res) => {
    try {
        const events = await Event.find({ assetId: req.params.id })
            .sort({ occurredAt: -1 })
            .populate('userId', 'username');

        res.json(events);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Create New Asset
// @route   POST /api/assets
// @access  Private (Manager/Admin)
const createAsset = async (req, res) => {
    try {
        const { name, location, status, assetId } = req.body;

        // If assetId is provided, check uniqueness
        if (assetId) {
            const existing = await Asset.findOne({ assetId });
            if (existing) {
                return res.status(400).json({ message: 'Asset ID already exists' });
            }
        }

        const newAsset = new Asset({
            // Use provided ID or generate a short random one if missing (e.g., AS-1234)
            assetId: assetId || `AS-${Math.floor(1000 + Math.random() * 9000)}-${Date.now().toString().slice(-4)}`,
            name,
            location: location || 'Warehouse',
            status: status || 'operational',
            lastScannedBy: req.user._id, // Created by
        });

        await newAsset.save();
        res.status(201).json(newAsset);
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

module.exports = { getAssets, getAssetById, getAssetEvents, createAsset };
