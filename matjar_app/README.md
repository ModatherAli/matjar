# Matjar Mobile App (Flutter)

The mobile client for the **Matjar** full-stack luxury e-commerce platform. Built with **Flutter 3**, **Riverpod 3**, and **GoRouter**, connecting to the Node.js / Express 5 / Prisma 7 backend.

> 📖 **Full System Documentation**: See the root [README.md](../README.md) for the complete full-stack architecture, system diagrams, REST API documentation, and administrative features.

---

## 📱 Features

- **Luxury Design System**: Editorial typography, custom warm color palette, micro-animations (`flutter_animate`), and skeleton loaders (`shimmer`).
- **Feature-First Architecture**: Clean separation into `core/` (network, models, router, theme, storage) and `features/` (`home`, `catalog`, `shop`, `auth`, `profile`, `admin`).
- **State Management**: Reactive and compile-time safe state management using **Riverpod 3**.
- **Resilient Networking**: **Dio** with interceptors for automatic JWT renewal and queue management upon token expiration.
- **Secure Persistence**: Tokens stored securely using **Flutter Secure Storage** (Keychain on iOS, Keystore on Android).
- **Admin Atelier**: Integrated mobile management dashboard for store administrators to manage products, categories, orders, and review live revenue metrics.

---

## 🚀 Running the App

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run the App

- **Android Emulator** *(automatically targets `http://10.0.2.2:4000`)*:
  ```bash
  flutter run
  ```

- **iOS Simulator / Web / Desktop**:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://localhost:4000
  ```

- **Physical Device** *(substitute with your host machine's local IP)*:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.X:4000
  ```

---

## 🧪 Testing & Linting

```bash
flutter analyze
flutter test
```
