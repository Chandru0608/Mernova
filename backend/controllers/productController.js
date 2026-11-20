const Product = require("../models/Product");
const Store = require("../models/Store");

exports.list = async (req, res, next) => {
  try {
    const filter = { isAvailable: true };
    if (req.query.type && ["grocery","food"].includes(req.query.type)) filter.type = req.query.type;
    if (req.query.store) filter.store = req.query.store;
    const products = await Product.find(filter).populate("store", "name type").sort({ createdAt: -1 });
    res.json({ count: products.length, products });
  } catch (e) { next(e); }
};

exports.create = async (req, res, next) => {
  try {
    const { name, price, store, type, category, description, stock, imageUrl } = req.body;
    const storeDoc = req.user.role === "admin"
      ? await Store.findById(store)
      : await Store.findOne({ _id: store, owner: req.user._id });
    if (!storeDoc) return res.status(404).json({ message: "Store not found or not owned by you" });
    const product = await Product.create({ name, price: Number(price), store: storeDoc._id, type, category, description, stock: Number(stock || 0), imageUrl });
    res.status(201).json({ product });
  } catch (e) { next(e); }
};

exports.update = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id).populate("store");
    if (!product) return res.status(404).json({ message: "Product not found" });
    if (req.user.role !== "admin" && String(product.store.owner) !== String(req.user._id)) return res.status(403).json({ message: "Not your product" });
    Object.assign(product, req.body);
    await product.save();
    res.json({ product });
  } catch (e) { next(e); }
};

exports.remove = async (req, res, next) => {
  try {
    const product = await Product.findById(req.params.id).populate("store");
    if (!product) return res.status(404).json({ message: "Product not found" });
    if (req.user.role !== "admin" && String(product.store.owner) !== String(req.user._id)) return res.status(403).json({ message: "Not your product" });
    await product.deleteOne();
    res.json({ message: "Product deleted" });
  } catch (e) { next(e); }
};
