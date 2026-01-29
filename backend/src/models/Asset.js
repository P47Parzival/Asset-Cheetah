const mongoose = require('mongoose');

const assetSchema = new mongoose.Schema({
    assetId: {
        type: String,
        required: true,
        unique: true,
        index: true,
    },
    name: {
        type: String,
        required: true,
    },
    status: {
        type: String,
        enum: ['operational', 'maintenance', 'retired', 'in_transit'],
        default: 'operational',
    },
    location: {
        type: String,
        required: true,
    },
    lastScannedAt: {
        type: Date,
    },
    lastScannedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    metadata: {
        type: Map,
        of: String,
        default: {},
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
    updatedAt: {
        type: Date,
        default: Date.now,
    },
});

assetSchema.pre('save', function (next) {
    this.updatedAt = Date.now();
    next();
});

module.exports = mongoose.model('Asset', assetSchema);
