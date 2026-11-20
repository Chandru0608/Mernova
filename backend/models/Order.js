const mongoose = require("mongoose");
const orderSchema = new mongoose.Schema({
  customer: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  store: { type: mongoose.Schema.Types.ObjectId, ref: "Store", required: true },
  deliveryPartner: { type: mongoose.Schema.Types.ObjectId, ref: "User", default: null },
  items: [{
    product: { type: mongoose.Schema.Types.ObjectId, ref: "Product" },
    name: String, quantity: Number, unitPrice: Number
  }],
  subtotal: { type: Number, required: true },
  deliveryFee: { type: Number, default: 30 },
  total: { type: Number, required: true },
  address: { type: String, required: true },
  orderType: { type: String, enum: ["grocery", "food"], default: "grocery" },
  deliveryLocation: { latitude: Number, longitude: Number, updatedAt: Date },
  status: { type: String, enum: ["placed","accepted","preparing","ready","picked_up","on_the_way","delivered","cancelled"], default: "placed" }
}, { timestamps: true });
module.exports = mongoose.model("Order", orderSchema);
