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
    ["Alphonso Mangoes", "grocery", "Fruits", 149, 80, "Fresh seasonal mangoes", "kg", "https://images.unsplash.com/photo-1553279768-865429fa0078?w=600"],
    ["Banana Robusta", "grocery", "Fruits", 55, 100, "Naturally sweet bananas", "dozen", "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=600"],
    ["Red Apples", "grocery", "Fruits", 120, 90, "Crisp premium apples", "kg", "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600"],
    ["Fresh Oranges", "grocery", "Fruits", 85, 75, "Juicy oranges", "kg", "https://images.unsplash.com/photo-1547514701-42782101795e?w=600"],
    ["Tomatoes", "grocery", "Vegetables", 35, 120, "Farm fresh tomatoes", "kg", "https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=600"],
    ["Potatoes", "grocery", "Vegetables", 32, 150, "Everyday fresh potatoes", "kg", "https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=600"],
    ["Onions", "grocery", "Vegetables", 40, 140, "Fresh red onions", "kg", "https://images.unsplash.com/photo-1508747703725-719777637510?w=600"],
    ["Green Capsicum", "grocery", "Vegetables", 65, 60, "Crisp green bell peppers", "500 g", "https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=600"],
    ["Spinach", "grocery", "Vegetables", 30, 55, "Fresh leafy spinach", "bunch", "https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=600"],
    ["Full Cream Milk", "grocery", "Dairy", 34, 100, "Pasteurised fresh milk", "500 ml", "https://images.unsplash.com/photo-1563636619-e9143da7973b?w=600"],
    ["Farm Fresh Eggs", "grocery", "Dairy", 78, 80, "Farm eggs", "6 pack", "https://images.unsplash.com/photo-1506976785307-8732e854ad03?w=600"],
    ["Paneer", "grocery", "Dairy", 95, 45, "Soft fresh paneer", "200 g", "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=600"],
    ["Greek Yogurt", "grocery", "Dairy", 65, 50, "Creamy plain yogurt", "400 g", "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600"],
    ["Whole Wheat Bread", "grocery", "Bakery", 45, 70, "Soft whole wheat loaf", "400 g", "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600"],
    ["Brown Rice", "grocery", "Staples", 95, 90, "Everyday brown rice", "1 kg", "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=600"],
    ["Toor Dal", "grocery", "Staples", 115, 80, "Cleaned split pigeon peas", "1 kg", "https://images.unsplash.com/photo-1515543904379-3d757afe72e4?w=600"],
    ["Masala Dosa", "food", "Breakfast", 90, 35, "Crispy dosa with potato masala", "plate", "https://images.unsplash.com/photo-1668236543090-82eba5ee5976?w=600"],
    ["Idli Sambar", "food", "Breakfast", 65, 40, "Steamed idlis with sambar", "plate", "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?w=600"],
    ["Veg Sandwich", "food", "Snacks", 110, 35, "Toasted garden vegetable sandwich", "piece", "https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=600"],
    ["Margherita Pizza", "food", "Meals", 199, 25, "Classic cheese and tomato pizza", "medium", "https://images.unsplash.com/photo-1579751626657-72bc17010498?w=600"],
    ["Veg Burger", "food", "Snacks", 99, 30, "Crispy veggie patty burger", "piece", "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600"],
    ["Paneer Wrap", "food", "Meals", 135, 25, "Spiced paneer in a soft wrap", "piece", "https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=600"],
    ["Fresh Lime Soda", "food", "Beverages", 55, 45, "Refreshing lime soda", "300 ml", "https://images.unsplash.com/photo-1513558161293-caad1deea5b4?w=600"],
    ["Chocolate Brownie", "food", "Desserts", 75, 30, "Rich chocolate brownie", "piece", "https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600"]
  ];
  for (const [name,type,category,price,stock,description,unit,imageUrl] of samples) {
    await Product.updateOne(
      { store: store._id, name },
      { $set: { description, unit, imageUrl, isAvailable: true }, $setOnInsert: { store: store._id, name, type, category, price, stock } },
      { upsert: true }
    );
  }
  console.log("Seed complete.");
  console.log("Admin:", admin.email, "/ Admin123!");
  console.log("Store:", owner.email, "/ Store123!");
  console.log("Delivery:", "delivery@quickdeliver.test", "/ Delivery123!");
  await mongoose.disconnect();
}
run().catch(e => { console.error(e); process.exit(1); });
