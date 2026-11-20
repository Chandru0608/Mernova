const jwt = require("jsonwebtoken");
const User = require("../models/User");

async function protect(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;
    if (!token) return res.status(401).json({ message: "Authentication required" });
    const payload = jwt.verify(token, process.env.JWT_SECRET || "dev-secret-change-me");
    const user = await User.findById(payload.id);
    if (!user || !user.isActive) return res.status(401).json({ message: "Account unavailable" });
    req.user = user;
    next();
  } catch (_err) {
    return res.status(401).json({ message: "Invalid or expired token" });
  }
}
function allow(...roles) {
  return (req, res, next) => roles.includes(req.user.role)
    ? next() : res.status(403).json({ message: "You do not have permission" });
}
module.exports = { protect, allow };
