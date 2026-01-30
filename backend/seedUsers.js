const mongoose = require('mongoose');
const dotenv = require('dotenv');
// Fix import path relative to root of backend if running from there, or file relative.
// Assuming running from backend/ 
const User = require('./src/models/User');
const bcrypt = require('bcryptjs');

dotenv.config();

const users = [
    {
        username: 'admin',
        password: 'password123',
        role: 'admin',
        email: 'admin@assetcheetah.com'
    },
    {
        username: 'manager',
        password: 'password123',
        role: 'manager',
        email: 'manager@assetcheetah.com'
    },
    {
        username: 'operator',
        password: 'password123',
        role: 'operator',
        email: 'operator@assetcheetah.com'
    },
    {
        username: 'test',
        password: 'test123',
        role: 'manager',
        email: 'test@assetcheetah.com'
    }
];

const seedUsers = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('MongoDB Connected');

        // Clear existing users
        await User.deleteMany({});
        console.log('Users Cleared');

        for (const user of users) {
            // CRITICAL FIX: Do NOT hash password here. 
            // The User model has a pre-save hook that hashes it.
            // If we hash here, it gets hashed TWICE (Double Hashed).
            await User.create({
                username: user.username,
                password: user.password,
                role: user.role
            });
        }

        console.log('Users Seeded Successfully (Single Hashed)');
        process.exit();
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
};

seedUsers();
