const mongoose = require("mongoose");
const storeSchema = new mongoose.Schema({
  owner: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  name: { type: String, required: true, trim: true },
  type: { type: String, enum: ["grocery", "food", "both"], default: "grocery" },
  description: String,
  address: String,
  imageUrl: String,
  isOpen: { type: Boolean, default: true }
}, { timestamps: true });
module.exports = mongoose.model("Store", storeSchema);
