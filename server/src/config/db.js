const mongoose = require("mongoose");
const { MONGO_URI } = require("./env");

const connectDB = async () => {
  const attemptConnect = async () => {
    try {
      const conn = await mongoose.connect(MONGO_URI, {
        serverSelectionTimeoutMS: 10000,
      });
      console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
      console.error(`DB Connection Error: ${error.message}`);
      console.warn("Retrying MongoDB connection in 5 seconds...");
      setTimeout(attemptConnect, 5000);
    }
  };

  await attemptConnect();
};

module.exports = connectDB;
