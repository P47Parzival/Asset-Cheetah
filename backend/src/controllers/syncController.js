const Asset = require('../models/Asset');
const Event = require('../models/Event');

// @desc    Ingest events from mobile devices
// @route   POST /api/sync/events
// @access  Private
const syncEvents = async (req, res) => {
    const { events } = req.body; // Expecting an array of events

    if (!events || !Array.isArray(events)) {
        return res.status(400).json({ message: 'Invalid data format' });
    }

    const results = {
        processed: 0,
        errors: 0,
    };

    for (const eventData of events) {
        try {
            // 1. Idempotency Check
            const existingEvent = await Event.findOne({ eventId: eventData.eventId });
            if (existingEvent) {
                continue; // Skip if already synced
            }

            // 2. Save Event to Log
            const newEvent = new Event({
                ...eventData,
                syncedAt: Date.now(),
            });
            await newEvent.save();

            // 3. Replay Event to update Asset State (Read Model)
            const asset = await Asset.findOne({ assetId: eventData.assetId });

            if (asset) {
                // Update asset based on action type
                switch (eventData.actionType) {
                    case 'SCAN':
                        // Scan updates lastScanned and location (from GPS)
                        break;
                    case 'STATUS_CHANGE':
                        if (eventData.payload && eventData.payload.status) {
                            asset.status = eventData.payload.status;
                        }
                        break;
                    case 'LOCATION_UPDATE':
                        if (eventData.payload && eventData.payload.location) {
                            asset.location = eventData.payload.location;
                        }
                        break;
                }

                // Update location from GPS if available in payload
                if (eventData.payload && eventData.payload.location) {
                    asset.location = eventData.payload.location;
                }

                // Store GPS coordinates in metadata if available
                if (eventData.payload && eventData.payload.gps) {
                    asset.metadata = asset.metadata || {};
                    asset.metadata.lastGps = eventData.payload.gps;
                }

                // Common updates
                asset.lastScannedAt = eventData.occurredAt;
                asset.lastScannedBy = eventData.userId;

                await asset.save();
            } else if (eventData.actionType === 'SCAN' || eventData.actionType === 'STATUS_CHANGE') {
                // Auto-create Asset if it doesn't exist (Self-Registration)
                const newAsset = new Asset({
                    assetId: eventData.assetId,
                    name: `Unknown Asset ${eventData.assetId}`, // Placeholder name
                    location: eventData.payload?.location || 'Unknown Location',
                    status: eventData.payload?.status || 'operational',
                    lastScannedAt: eventData.occurredAt,
                    lastScannedBy: eventData.userId,
                    metadata: eventData.payload?.gps ? { lastGps: eventData.payload.gps } : {}
                });
                await newAsset.save();
                console.log(`Auto-created asset: ${eventData.assetId} at ${eventData.payload?.location || 'unknown location'}`);
            }

            results.processed++;
        } catch (error) {
            console.error(`Error processing event ${eventData.eventId}:`, error);
            results.errors++;
        }
    }

    res.json({ message: 'Sync complete', results });
};

// @desc    Get assets changed since timestamp
// @route   GET /api/sync/assets
// @access  Private
const syncAssets = async (req, res) => {
    const { lastSync } = req.query;

    let query = {};

    if (lastSync) {
        const lastSyncDate = new Date(lastSync);
        if (!isNaN(lastSyncDate.getTime())) {
            query = { updatedAt: { $gt: lastSyncDate } };
        }
    }

    try {
        const assets = await Asset.find(query);
        res.json(assets);
    } catch (error) {
        res.status(500).json({ message: 'Server Error' });
    }
};

module.exports = { syncEvents, syncAssets };
