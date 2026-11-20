const Store = require("../models/Store");
exports.list = async (_req, res, next) => {
  try {
    const stores = await Store.find({ isOpen: true }).populate("owner", "name");
    res.json({ count: stores.length, stores });
  } catch (e) { next(e); }
};
exports.mine = async (req, res, next) => {
  try {
    const stores = req.user.role === "admin" ? await Store.find().populate("owner", "name email") : await Store.find({ owner: req.user._id });
    res.json({ count: stores.length, stores });
  } catch (e) { next(e); }
};
exports.create = async (req, res, next) => {
  try {
    const owner = req.user.role === "admin" && req.body.owner ? req.body.owner : req.user._id;
    const store = await Store.create({ ...req.body, owner });
    res.status(201).json({ store });
  } catch (e) { next(e); }
};
