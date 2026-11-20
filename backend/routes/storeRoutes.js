const router = require("express").Router();
const c = require("../controllers/storeController");
const { protect, allow } = require("../middleware/auth");
router.get("/", c.list);
router.get("/my-stores", protect, c.mine);
router.post("/", protect, allow("store","admin"), c.create);
module.exports = router;
