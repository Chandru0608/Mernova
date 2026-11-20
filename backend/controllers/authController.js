const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const User = require("../models/User");

const sign = user => jwt.sign({ id: user._id, role: user.role },
  process.env.JWT_SECRET || "dev-secret-change-me", { expiresIn: "7d" });

exports.register = async (req, res, next) => {
  try {
    const { name, email, password, phone } = req.body;
    if (!name || !email || !password) return res.status(400).json({ message: "Name, email and password are required" });
    if (password.length < 8) return res.status(400).json({ message: "Password must be at least 8 characters" });
    const normalizedEmail = email.toLowerCase().trim();
    if (await User.findOne({ email: normalizedEmail })) return res.status(409).json({ message: "Email already registered" });
    const user = await User.create({ name, email: normalizedEmail, password: await bcrypt.hash(password, 12), phone, role: "customer" });
    res.status(201).json({ message: "Registration successful", token: sign(user), user: { id: user._id, name: user.name, email: user.email, role: user.role } });
  } catch (e) { next(e); }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email: String(email || "").toLowerCase().trim() }).select("+password");
    if (!user || !await bcrypt.compare(password || "", user.password)) return res.status(401).json({ message: "Invalid email or password" });
    if (!user.isActive) return res.status(403).json({ message: "Account disabled" });
    res.json({ token: sign(user), user: { id: user._id, name: user.name, email: user.email, role: user.role } });
  } catch (e) { next(e); }
};

exports.me = (req, res) => res.json({ user: {
  id: req.user._id, name: req.user.name, email: req.user.email,
  role: req.user.role, phone: req.user.phone || "", addresses: req.user.addresses || []
} });

exports.updateProfile = async (req, res, next) => {
  try {
    const { name, phone, addresses } = req.body;
    if (name !== undefined) {
      if (!String(name).trim()) return res.status(400).json({ message: "Name cannot be empty" });
      req.user.name = String(name).trim().slice(0, 80);
    }
    if (phone !== undefined) req.user.phone = String(phone).trim().slice(0, 25);
    if (addresses !== undefined) {
      if (!Array.isArray(addresses) || addresses.length > 20) return res.status(400).json({ message: "Provide up to 20 saved addresses" });
      const cleaned = addresses.map((item, index) => ({
        label: String(item.label || "Home").trim().slice(0, 40),
        fullAddress: String(item.fullAddress || "").trim().slice(0, 400),
        isDefault: Boolean(item.isDefault) || (index === 0 && addresses.length === 1)
      }));
      if (cleaned.some(item => !item.fullAddress)) return res.status(400).json({ message: "Every saved address needs a full address" });
      const defaults = cleaned.filter(item => item.isDefault);
      if (defaults.length > 1) return res.status(400).json({ message: "Choose only one default address" });
      req.user.addresses = cleaned;
    }
    await req.user.save();
    res.json({ message: "Profile updated", user: {
      id: req.user._id, name: req.user.name, email: req.user.email,
      role: req.user.role, phone: req.user.phone || "", addresses: req.user.addresses || []
    }});
  } catch (e) { next(e); }
};
