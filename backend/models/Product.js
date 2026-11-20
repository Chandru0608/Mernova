const mongoose = require("mongoose");
const productSchema = new mongoose.Schema({
  store: { type: mongoose.Schema.Types.ObjectId, ref: "Store", required: true },
  name: { type: String, required: true, trim: true },
  description: String,
  category: { type: String, default: "general" },
  type: { type: String, enum: ["grocery", "food"], default: "grocery" },
  price: { type: Number, required: true, min: 0 },
  imageUrl: String,
  stock: { type: Number, default: 0, min: 0 },
  isAvailable: { type: Boolean, default: true }
}, { timestamps: true });
module.exports = mongoose.model("Product", productSchema);
