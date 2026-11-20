# QuickDeliver — MERN + Flutter MVP

A combined food/grocery delivery starter with:
- Express + MongoDB backend, JWT authentication and Socket.IO events
- React/Vite admin and store dashboard
- Flutter customer app
- Flutter delivery-partner app

This is a runnable **MVP starter**, not a production-hardened marketplace. Before production, add payment-provider integration, image storage, stronger validation/rate limits, privacy controls, audit logs, and deployment secrets.

## 1. Requirements
- Node.js 20+
- MongoDB local service or MongoDB Atlas
- Flutter stable + Android SDK
- Android phone and development computer on the same Wi-Fi for physical-device testing

## 2. Backend
```bash
cd backend
copy .env.example .env
npm install
npm run seed
npm run dev
```
On macOS/Linux use `cp .env.example .env`.

Default API: `http://localhost:5000/api`

Demo accounts (created by seed):
- Admin: `admin@quickdeliver.test` / `Admin123!`
- Store: `store@quickdeliver.test` / `Store123!`
- Delivery partner: `delivery@quickdeliver.test` / `Delivery123!`
- Customer: register through the customer app or `/api/auth/register`

Change all demo passwords before using this outside local development.

## 3. Admin dashboard
```bash
cd admin-web
npm install
copy .env.example .env
npm run dev
```
Open `http://localhost:5173` and sign in with the demo admin or store account.
Vite proxy forwards `/api` and `/socket.io` to the backend.

## 4. Flutter customer app
```bash
cd customer_app
flutter pub get
```
Edit `lib/config.dart`:
- Android emulator: `http://10.0.2.2:5000/api`
- Physical Android phone: `http://YOUR_PC_LAN_IP:5000/api`
  (Find it with `ipconfig`; allow Node.js through Windows Firewall on private networks.)

Then generate the platform scaffold and apply the manifest template:
```bash
flutter create .
```
Copy `android_manifest_template.xml` over `android/app/src/main/AndroidManifest.xml`, then run:
```bash
flutter run
```
For local HTTP development, the manifest template enables cleartext traffic. Use HTTPS in production.

## 5. Flutter delivery app
```bash
cd delivery_app
flutter pub get
```
Set the same API URL in `lib/config.dart`, run `flutter create .`, apply `android_manifest_template.xml` as described in `PLATFORM_SETUP.md`, then run `flutter run`.
Sign in with a delivery-partner account. Create one using the register endpoint with role `delivery` (for local testing only), or add one in MongoDB. The backend deliberately only permits public registration as `customer`; demo store and delivery accounts are created by the seed script.

## 6. Useful API endpoints
- `POST /api/auth/register` — customer registration
- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/products`
- `POST /api/products` — store/admin
- `GET /api/stores`
- `GET /api/orders/my`
- `POST /api/orders/checkout`
- `GET /api/orders/store`
- `GET /api/orders/delivery`
- `POST /api/orders/:id/claim` — delivery partner claims an unassigned ready order
- `PATCH /api/orders/:id/status` — authorized store/admin/delivery status update
- `POST /api/orders/:id/assign` — admin assigns delivery partner
- `GET /api/health`

Socket.IO event: `order:updated` (room `user:<userId>`).

## 7. Notes
- MongoDB must be running, or `MONGO_URI` must point to a reachable Atlas cluster.
- Product `store` and order `customer` references are MongoDB ObjectIds.
- The customer app uses a basic in-memory cart; it is cleared after successful checkout.
- Delivery location sharing is a UI/API foundation. Continuous GPS tracking is not included in this MVP.
