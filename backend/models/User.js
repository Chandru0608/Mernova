const mongoose = require("mongoose");
const addressSchema = new mongoose.Schema({
  label: { type: String, trim: true, maxlength: 40, default: "Home" },
  fullAddress: { type: String, trim: true, required: true, maxlength: 400 },
  isDefault: { type: Boolean, default: false },
  latitude: { type: Number, min: -90, max: 90 },
  longitude: { type: Number, min: -180, max: 180 },
  flatOrHouse: { type: String, trim: true, maxlength: 100 },
  landmark: { type: String, trim: true, maxlength: 160 },
  city: { type: String, trim: true, maxlength: 100 },
  postalCode: { type: String, trim: true, maxlength: 12 }
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
