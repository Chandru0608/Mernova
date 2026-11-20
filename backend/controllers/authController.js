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

exports.me = (req, res) => res.json({ user: { id: req.user._id, name: req.user.name, email: req.user.email, role: req.user.role } });
