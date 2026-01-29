const express = require('express');
const dotenv = require('dotenv');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const connectDB = require('./config/db');

dotenv.config();

connectDB();

const app = express();

app.use(express.json());
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));

const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Asset Cheetah Backend API is running...');
});

app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/sync', require('./routes/syncRoutes'));

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
