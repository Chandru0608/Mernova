const mongoose = require("mongoose");
const addressSchema = new mongoose.Schema({
  label: { type: String, trim: true, maxlength: 40, default: "Home" },
  fullAddress: { type: String, trim: true, required: true, maxlength: 400 },
  isDefault: { type: Boolean, default: false }
}, { _id: true });

const userSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true, select: false },
  role: { type: String, enum: ["customer", "store", "delivery", "admin"], default: "customer" },
  phone: String,
  addresses: { type: [addressSchema], default: [] },
  isActive: { type: Boolean, default: true },
  isAvailable: { type: Boolean, default: true }
}, { timestamps: true });
module.exports = mongoose.model("User", userSchema);
