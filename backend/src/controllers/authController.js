const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const User = require('../models/User');

const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const loginUser = async (req, res) => {
    const { username, password } = req.body;

    const user = await User.findOne({ username });

    if (user && (await user.matchPassword(password))) {
        res.json({
            _id: user._id,
            username: user.username,
            role: user.role,
            token: generateToken(user._id),
        });
    } else {
        console.log(`Login failed for user: ${username}`);
        if (user) {
            console.log('User found in DB');
            const isMatch = await user.matchPassword(password);
            console.log(`Password match result: ${isMatch}`);
        } else {
            console.log('User NOT found in DB');
        }
        res.status(401).json({ message: 'Invalid username or password' });
    }
};

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public (or Admin only in real app)
const registerUser = async (req, res) => {
    const { username, password, role } = req.body;

    const userExists = await User.findOne({ username });

    if (userExists) {
        res.status(400).json({ message: 'User already exists' });
        return;
    }

    const user = await User.create({
        username,
        password,
        role: role || 'operator',
    });

    if (user) {
        res.status(201).json({
            _id: user._id,
            username: user.username,
            role: user.role,
            token: generateToken(user._id),
        });
    } else {
        res.status(400).json({ message: 'Invalid user data' });
    }
};

module.exports = { loginUser, registerUser };
