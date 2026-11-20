require("dotenv").config();
const http = require("http");
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const { Server } = require("socket.io");

const authRoutes = require("./routes/authRoutes");
const productRoutes = require("./routes/productRoutes");
const storeRoutes = require("./routes/storeRoutes");
const orderRoutes = require("./routes/orderRoutes");

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: process.env.CLIENT_ORIGIN?.split(",") || "*", methods: ["GET", "POST", "PATCH"] }
});
app.set("io", io);
app.use(cors({ origin: true, credentials: true }));
app.use(express.json({ limit: "1mb" }));

app.get("/api/health", (_req, res) => res.json({ ok: true, service: "QuickDeliver API" }));
app.use("/api/auth", authRoutes);
app.use("/api/products", productRoutes);
app.use("/api/stores", storeRoutes);
app.use("/api/orders", orderRoutes);

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(err.status || 500).json({ message: err.message || "Server error" });
});

io.on("connection", socket => {
  socket.on("join:user", userId => {
    if (typeof userId === "string") socket.join(`user:${userId}`);
  });
});

const PORT = process.env.PORT || 5000;
mongoose.connect(process.env.MONGO_URI || "mongodb://127.0.0.1:27017/quickdeliver")
  .then(() => {
    console.log("MongoDB connected");
    server.listen(PORT, "0.0.0.0", () => console.log(`QuickDeliver API running on ${PORT}`));
  })
  .catch(err => {
    console.error("MongoDB connection failed:", err.message);
    process.exit(1);
  });
