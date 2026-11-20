require("dotenv").config();
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");
const User = require("./models/User");
const Store = require("./models/Store");
const Product = require("./models/Product");

async function run() {
  await mongoose.connect(process.env.MONGO_URI || "mongodb://127.0.0.1:27017/quickdeliver");
  const password = await bcrypt.hash("Admin123!", 12);
  const admin = await User.findOneAndUpdate(
    { email: "admin@quickdeliver.test" },
    { name: "QuickDeliver Admin", email: "admin@quickdeliver.test", password, role: "admin" },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
  const storePassword = await bcrypt.hash("Store123!", 12);
  const owner = await User.findOneAndUpdate(
    { email: "store@quickdeliver.test" },
    { name: "Fresh Mart Owner", email: "store@quickdeliver.test", password: storePassword, role: "store" },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
  const deliveryPassword = await bcrypt.hash("Delivery123!", 12);
  await User.findOneAndUpdate(
    { email: "delivery@quickdeliver.test" },
    { name: "Demo Delivery Partner", email: "delivery@quickdeliver.test", password: deliveryPassword, role: "delivery" },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
  let store = await Store.findOne({ name: "Fresh Mart" });
  if (!store) store = await Store.create({ owner: owner._id, name: "Fresh Mart", type: "both", address: "Demo address, update before use" });
  const samples = [
    ["Fresh Apples","grocery","Fruits",80,100],
    ["Milk 1L","grocery","Dairy",60,80],
    ["Vegetable Sandwich","food","Snacks",120,40],
    ["Veg Pizza","food","Meals",220,25]
  ];
  for (const [name,type,category,price,stock] of samples) {
    await Product.updateOne({ store: store._id, name }, { $setOnInsert: { store: store._id, name, type, category, price, stock, isAvailable: true } }, { upsert: true });
  }
  console.log("Seed complete.");
  console.log("Admin:", admin.email, "/ Admin123!");
  console.log("Store:", owner.email, "/ Store123!");
  console.log("Delivery:", "delivery@quickdeliver.test", "/ Delivery123!");
  await mongoose.disconnect();
}
run().catch(e => { console.error(e); process.exit(1); });
