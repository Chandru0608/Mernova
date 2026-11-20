const router = require("express").Router();
const c = require("../controllers/productController");
const { protect, allow } = require("../middleware/auth");
router.get("/", c.list);
router.post("/", protect, allow("store","admin"), c.create);
router.patch("/:id", protect, allow("store","admin"), c.update);
router.delete("/:id", protect, allow("store","admin"), c.remove);
module.exports = router;
