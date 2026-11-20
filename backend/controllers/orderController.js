const Order = require("../models/Order");
const Product = require("../models/Product");
const Store = require("../models/Store");

exports.checkout = async (req, res, next) => {
  try {
    const { items, address } = req.body;
    if (!Array.isArray(items) || !items.length || !address) return res.status(400).json({ message: "Cart items and delivery address are required" });
    const ids = items.map(x => x.productId);
    const products = await Product.find({ _id: { $in: ids }, isAvailable: true });
    if (products.length !== items.length) return res.status(400).json({ message: "One or more products are unavailable" });
    const storeIds = [...new Set(products.map(p => String(p.store)))];
    if (storeIds.length !== 1) return res.status(400).json({ message: "Please checkout one store at a time" });
    const normalized = items.map(item => {
      const p = products.find(x => String(x._id) === String(item.productId));
      const quantity = Math.max(1, Math.floor(Number(item.quantity || 1)));
      if (p.stock < quantity) throw Object.assign(new Error(`${p.name} has insufficient stock`), { status: 400 });
      return { product: p._id, name: p.name, quantity, unitPrice: p.price };
    });
    const subtotal = normalized.reduce((sum, x) => sum + x.unitPrice * x.quantity, 0);
    const store = await Store.findById(storeIds[0]);
    const order = await Order.create({
      customer: req.user._id, store: store._id, items: normalized,
      subtotal, deliveryFee: 30, total: subtotal + 30, address,
      orderType: products[0].type
    });
    for (const item of normalized) await Product.updateOne({ _id: item.product }, { $inc: { stock: -item.quantity } });
    res.status(201).json({ message: "Order placed successfully", order });
  } catch (e) { next(e); }
};

exports.myOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({ customer: req.user._id }).populate("store", "name").populate("deliveryPartner", "name phone").sort({ createdAt: -1 });
    res.json({ count: orders.length, orders });
  } catch (e) { next(e); }
};
exports.storeOrders = async (req, res, next) => {
  try {
    const stores = await Store.find(req.user.role === "admin" ? {} : { owner: req.user._id }).select("_id");
    const orders = await Order.find({ store: { $in: stores.map(s => s._id) } }).populate("customer", "name phone").populate("store", "name").sort({ createdAt: -1 });
    res.json({ count: orders.length, orders });
  } catch (e) { next(e); }
};
exports.deliveryOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({ $or: [{ deliveryPartner: req.user._id }, ...(req.user.isAvailable !== false ? [{ deliveryPartner: null, status: "ready" }] : [])] })
      .populate("customer", "name phone").populate("store", "name address").sort({ createdAt: -1 });
    res.json({ count: orders.length, orders });
  } catch (e) { next(e); }
};
exports.assign = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ message: "Order not found" });
    const User = require("../models/User");
    const partner = await User.findOne({ _id: req.body.deliveryPartnerId, role: "delivery", isActive: true });
    if (!partner) return res.status(404).json({ message: "Active delivery partner not found" });
    order.deliveryPartner = partner._id;
    await order.save();
    req.app.get("io").to(`user:${partner._id}`).emit("order:updated", order);
    res.json({ order });
  } catch (e) { next(e); }
};
exports.updateStatus = async (req, res, next) => {
  try {
    const allowed = ["accepted","preparing","ready","picked_up","on_the_way","delivered","cancelled"];
    if (!allowed.includes(req.body.status)) return res.status(400).json({ message: "Invalid status" });
    const order = await Order.findById(req.params.id).populate("store");
    if (!order) return res.status(404).json({ message: "Order not found" });
    const role = req.user.role;
    const ownsStore = role === "admin" || (role === "store" && String(order.store.owner) === String(req.user._id));
    const assignedPartner = role === "delivery" && String(order.deliveryPartner) === String(req.user._id);
    if (!ownsStore && !assignedPartner) return res.status(403).json({ message: "Not authorized for this order" });
    order.status = req.body.status;
    await order.save();
    const io = req.app.get("io");
    io.to(`user:${order.customer}`).emit("order:updated", order);
    if (order.deliveryPartner) io.to(`user:${order.deliveryPartner}`).emit("order:updated", order);
    res.json({ message: "Order status updated", order });
  } catch (e) { next(e); }
};


exports.claim = async (req, res, next) => {
  try {
    if (req.user.isAvailable === false) return res.status(403).json({ message: "Switch to Available before accepting a delivery" });
    const order = await Order.findOneAndUpdate(
      { _id: req.params.id, status: "ready", deliveryPartner: null },
      { $set: { deliveryPartner: req.user._id } },
      { new: true }
    );
    if (!order) return res.status(409).json({ message: "Order is no longer available to claim" });
    req.app.get("io").to(`user:${order.customer}`).emit("order:updated", order);
    res.json({ message: "Delivery accepted", order });
  } catch (e) { next(e); }
};

exports.updateDeliveryLocation = async (req, res, next) => {
  try {
    const latitude = Number(req.body.latitude);
    const longitude = Number(req.body.longitude);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude) || latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return res.status(400).json({ message: "Valid latitude and longitude are required" });
    }
    const order = await Order.findOne({ _id: req.params.id, deliveryPartner: req.user._id, status: { $in: ["picked_up", "on_the_way"] } });
    if (!order) return res.status(404).json({ message: "Active assigned delivery not found" });
    order.deliveryLocation = { latitude, longitude, updatedAt: new Date() };
    await order.save();
    req.app.get("io").to(`user:${order.customer}`).emit("order:location", {
      orderId: String(order._id), latitude, longitude, updatedAt: order.deliveryLocation.updatedAt
    });
    res.json({ message: "Delivery location updated", deliveryLocation: order.deliveryLocation });
  } catch (e) { next(e); }
};

exports.tracking = async (req, res, next) => {
  try {
    const order = await Order.findOne({ _id: req.params.id, customer: req.user._id })
      .select("status deliveryPartner deliveryLocation address")
      .populate("deliveryPartner", "name phone");
    if (!order) return res.status(404).json({ message: "Order not found" });
    res.json({ tracking: {
      orderId: order._id, status: order.status, address: order.address,
      deliveryPartner: order.deliveryPartner, location: order.deliveryLocation || null
    }});
  } catch (e) { next(e); }
};
