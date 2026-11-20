const router = require("express").Router();
const controller = require("../controllers/authController");
const { protect, allow } = require("../middleware/auth");
router.post("/register", controller.register);
router.post("/login", controller.login);
router.get("/me", protect, controller.me);
router.patch("/profile", protect, allow("customer"), controller.updateProfile);
module.exports = router;
