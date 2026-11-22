const mongoose = require("mongoose");
const productSchema = new mongoose.Schema({
  store: { type: mongoose.Schema.Types.ObjectId, ref: "Store", required: true },
  name: { type: String, required: true, trim: true },
  description: String,
  category: { type: String, default: "general" },
  type: { type: String, enum: ["grocery", "food"], default: "grocery" },
  price: { type: Number, required: true, min: 0 },
  imageUrl: String,
  unit: { type: String, default: "each", trim: true },
  mrp: { type: Number, min: 0 },
  tags: { type: [String], default: [] },
  stock: { type: Number, default: 0, min: 0 },
  isAvailable: { type: Boolean, default: true }
}, { timestamps: true });
module.exports = mongoose.model("Product", productSchema);
