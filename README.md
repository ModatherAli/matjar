# Matjar E-commerce API
# Matjar (متجر) — Full-Stack E-Commerce Platform

REST backend for an e-commerce store built with Node.js, Express 5 and PostgreSQL (via Prisma 7).
<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Node.js-24_ESM-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/Express-5.x-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express" />
  <img src="https://img.shields.io/badge/PostgreSQL-PGlite%20%2F%20v16-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL" />
  <img src="https://img.shields.io/badge/Prisma-7.x-2D3748?style=for-the-badge&logo=prisma&logoColor=white" alt="Prisma" />
  <img src="https://img.shields.io/badge/Riverpod-3.x-blueviolet?style=for-the-badge" alt="Riverpod" />
  <img src="https://img.shields.io/badge/Swagger-OpenAPI%203.0-85EA2D?style=for-the-badge&logo=swagger&logoColor=black" alt="Swagger" />
</p>

## Stack
---

- Node.js 24 (ESM) + Express 5
- PostgreSQL + Prisma 7 (`@prisma/adapter-pg`)
- JWT access (15m) + refresh (7d) tokens, bcrypt passwords
- Zod validation, helmet / CORS / rate-limit, multer uploads
- Swagger UI at `/api-docs`
## 🌟 Executive Summary

## Prerequisites
**Matjar** (*Arabic for "The Store"*) is an end-to-end, production-ready luxury e-commerce ecosystem. It couples a cross-platform mobile application built with **Flutter 3** and **Riverpod** with an enterprise-grade RESTful API powered by **Node.js (ESM)**, **Express 5**, and **Prisma 7 on PostgreSQL**.

- Node.js 20+ (24 recommended) and npm
- No local PostgreSQL install needed for development: the project uses
  `prisma dev`, a local PGlite-backed PostgreSQL server (small npm download).
Engineered with high standards for software craftsmanship, Matjar showcases clean domain-driven architecture, resilient mobile networking with automated JWT lifecycle management, ACID-compliant transactional checkout, strict order lifecycle state machines, and real-time operational analytics for store administrators.

## Quickstart
---

```bash
npm install
## 📱 Mobile Experience Showcase

# Terminal 1 - start the local database (keep running)
npm run db:dev
<div align="center">

# Terminal 2 - first time only: migrate + seed
npm run prisma:migrate
npm run prisma:seed
| **Customer Storefront** | **Auth & Identity** | **Admin Atelier Dashboard** |
| :---: | :---: | :---: |
| <img src="screenshots/home.png" width="280" alt="Customer Storefront" /> | <img src="screenshots/login.png" width="280" alt="Authentication Screen" /> | <img src="screenshots/admin_dashbord.png" width="280" alt="Admin Dashboard" /> |
| *Editorial luxury feed, category navigation, curated arrivals* | *Dual-token JWT auth, validation feedback, secure storage* | *Real-time revenue, order status breakdowns & inventory operations* |

# Terminal 2 - start the API
npm run dev
</div>

---

## 🏗️ System Architecture

Matjar follows a decoupled, layered architectural pattern across both client and server to guarantee testability, maintainability, and scalability.

```mermaid
flowchart TB
    subgraph Client["Flutter Mobile Client (matjar_app)"]
        UI["UI Layer (Screens, Custom Design System, Shimmers)"]
        State["State Layer (Riverpod Providers & Notifiers)"]
        Nav["Router (GoRouter with RBAC Redirect Guards)"]
        Net["Network Layer (Dio + Auto-Refresh JWT Interceptor)"]
        Store["Secure Persistence (Flutter Secure Storage)"]

        UI --> State
        State --> Nav
        State --> Net
        Net <--> Store
    end

    subgraph Gateway["API Gateway & Security Layer"]
        Rate["Express Rate Limiter"]
        Sec["Helmet & CORS Policy"]
        Logger["Morgan HTTP Logger"]
    end

    subgraph Backend["Express 5 REST API (src/)"]
        Router["Modular Domain Routers (/api/v1/*)"]
        Val["Zod Schema Validation Middleware"]
        AuthM["JWT Auth & Role Guards (RBAC)"]
        Ctrl["Controller Layer (HTTP Serialization)"]
        Svc["Service Layer (Business Rules & Transactions)"]

        Router --> Val --> AuthM --> Ctrl --> Svc
    end

    subgraph Persistence["Data & Infrastructure Layer"]
        ORM["Prisma ORM 7 (@prisma/adapter-pg)"]
        DB[(PostgreSQL Database)]
        Static["Static File Server (/uploads)"]
        Swagger["OpenAPI / Swagger Documentation (/api-docs)"]

        Svc --> ORM
        ORM <--> DB
    end

    Net <==>|"REST / JSON over HTTPS"| Gateway
    Gateway --> Backend
    Backend -.-> Static
    Backend -.-> Swagger
```

- API: http://localhost:4000
- Docs: http://localhost:4000/api-docs
- Seed admin: `admin@matjar.local` / `Admin123!` (override in `.env`)
---

## Scripts
## ✨ Key Engineering Highlights

| Script | Purpose |
|---|---|
| `npm run dev` | API with watch mode |
| `npm start` | API (production) |
| `npm run db:dev` | Local Postgres (PGlite) named instance `matjar` |
| `npm run db:ls` / `db:stop` | List / stop local database servers |
| `npm run prisma:migrate` | `prisma migrate dev` |
| `npm run prisma:seed` | Seed admin + sample catalog |
| `npm run prisma:generate` | Regenerate Prisma Client |
| `npm run db:push` | Push schema without a migration (dev only) |
### 1. Robust Transactional Integrity & Inventory Allocation
- **Atomic Checkout (`prisma.$transaction`)**: Orders cannot enter an inconsistent state. When a customer initiates checkout, the backend runs a serialized database transaction that:
  1. Validates address ownership and active cart items.
  2. Verifies stock availability and active status for every product.
  3. Creates immutable order records snapshotting product titles and prices at the moment of purchase.
  4. Atomically decrements warehouse inventory (`decrement: item.quantity`).
  5. Clears the customer's cart.
- **Auto-Restocking Lifecycle**: Cancelling a pending or paid order automatically increments stock levels back to the catalog and adjusts refund statuses.
- **Safe Soft Deactivations**: Products associated with past order histories are prevented from hard deletion; instead, they transition into soft-deactivated states to preserve financial auditing records.

## Environment
### 2. Dual-Persona Experience
- **Customer Storefront**:
  - Editorial curation with smooth animations and skeleton shimmering.
  - Multi-attribute catalog filtering (search query, category hierarchy, price range, sorting).
  - Multi-address management with default flag selection.
  - Verified Purchase Reviews: Customers can only review products they have purchased and received (`DELIVERED` status).
- **Admin Atelier**:
  - High-level KPI metrics: gross revenue, total orders, product catalog count, and registered users.
  - Real-time order fulfillment pipeline (`PENDING` ➔ `PAID` ➔ `SHIPPED` ➔ `DELIVERED`).
  - Full product inventory management with multi-image uploads via `multer`.
  - User role assignment and account deactivation controls.

See `.env.example`. Key variables:
### 3. Dual-Token JWT Auth with Silent Refresh
- **Access Tokens (15m)** and **Refresh Tokens (7d)** signed via cryptographically secure secrets.
- **Dio Interceptor Queue**: The Flutter client intercepts `401 Unauthorized` responses, buffers pending requests, exchanges the refresh token seamlessly in the background, and retries the original request with zero disruption to the user experience.
- Passwords hashed using industry-standard **bcrypt** with salted work factors.

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Main connection (local: `postgres://postgres:postgres@localhost:51214/...`) |
| `SHADOW_DATABASE_URL` | Shadow DB for migrations (`...@localhost:51215/...`) |
| `PORT` | API port (default 4000) |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | Signing secrets (min 32 chars in production) |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_NAME` | Seeded admin user |
### 4. Zero-Friction Local Developer Environment
- Embeds Prisma 7 local database engine (`prisma dev` backed by **PGlite**), eliminating the requirement of running a local PostgreSQL daemon or Docker container during development.
- Single command bootstrapper (`npm run dev:all`) that automatically starts the local database, monitors port readiness, and spawns the Express API with file-watch mode.

## Endpoint overview
---

All routes are prefixed with `/api/v1`. Responses use `{ success, data }`
(or `{ success, data, pagination }`); errors use `{ success: false, error }`.
## 🛠️ Technology Stack Matrix

| Area | Endpoints |
|---|---|
| Auth | `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, `POST /auth/logout` |
| Users | `GET/PUT /users/me`, `PUT /users/me/password` |
| Admin users | `GET /admin/users`, `GET /admin/users/:id`, `PATCH /admin/users/:id/role`, `PATCH /admin/users/:id/status` |
| Categories | `GET /categories`, `GET /categories/:slug` |
| Admin categories | `POST/GET /admin/categories`, `GET/PUT/DELETE /admin/categories/:id` |
| Products | `GET /products?search&category&minPrice&maxPrice&sort&page&limit`, `GET /products/:slug` |
| Admin products | `POST/GET /admin/products`, `GET/PUT/DELETE /admin/products/:id`, `POST /admin/products/:id/images`, `DELETE /admin/products/:id/images/:imageId` |
| Addresses | `GET/POST /addresses`, `GET/PUT/DELETE /addresses/:id` |
| Cart | `GET /cart`, `POST /cart/items`, `PATCH/DELETE /cart/items/:id`, `DELETE /cart` |
| Orders | `POST /orders/checkout`, `GET /orders`, `GET /orders/:id`, `POST /orders/:id/cancel` |
| Admin orders | `GET /admin/orders`, `GET /admin/orders/:id`, `PATCH /admin/orders/:id/status` |
| Reviews | `GET /products/:id/reviews`, `POST/PUT/DELETE /products/:id/reviews` |
| Admin | `GET /admin/dashboard` |
| Domain | Technology | Rationale & Responsibility |
| :--- | :--- | :--- |
| **Mobile Client** | **Flutter 3.x & Dart** | Cross-platform native compilation (Android, iOS, Web) with 60+ FPS performance. |
| **State Management** | **Flutter Riverpod 3** | Compile-time safe, reactive dependency injection and decoupled business logic. |
| **Mobile Routing** | **GoRouter** | Declarative deep linking with asynchronous authentication and role guards. |
| **Mobile HTTP** | **Dio 5** | Interceptor-driven networking, automatic token refresh, structured error mapping. |
| **Secure Storage** | **flutter_secure_storage** | Hardware-backed Keychain (iOS) and Keystore / EncryptedSharedPreferences (Android). |
| **Backend Runtime** | **Node.js 24 (ESM)** | Modern ECMAScript modules, top-level `await`, native performance. |
| **Web Framework** | **Express 5.x** | Modern routing, improved promise-based error handling, high throughput. |
| **ORM & Database** | **Prisma 7 + PostgreSQL** | Strict relational schema, automated migrations, type-safe queries via `@prisma/adapter-pg`. |
| **Data Validation** | **Zod 4** | Strict request schema parsing, sanitization, and structured validation errors. |
| **API Documentation** | **Swagger UI / OpenAPI 3** | Self-documenting interactive API playground accessible at `/api-docs`. |
| **Security & Headers** | **Helmet, CORS, Rate-Limit** | Protection against brute-force attacks, XSS, MIME sniffing, and clickjacking. |

## Business rules worth knowing
---

- Register always creates `CUSTOMER`; only admins change roles (and never their own).
- Checkout runs in a transaction: stock check, order + item snapshots, stock
  decrement, cart clear. Empty cart, inactive or out-of-stock products fail with 400.
- Order flow: `PENDING -> PAID -> SHIPPED -> DELIVERED`, cancellable from
  `PENDING`/`PAID`. Cancelling restocks items and refunds paid orders.
- Deleting a product with order history soft-deactivates it instead.
- Reviews require a delivered purchase of that product, one per customer.
- Product images upload to `uploads/products/` (5MB max, images only).
## 🗄️ Database Entity Relationship Model

## Troubleshooting
The database schema is designed with strict relational constraints, foreign keys, and indexes for performant querying:

- `prisma dev` hangs on start: a stale lock from a killed process. Stop node
  processes, delete `server.json` and `server.lock*` under
  `%LocalAppData%\prisma-dev-nodejs\Data\matjar` (and `durable-streams\matjar`),
  then run `npm run db:dev` again.
- Moving to hosted Postgres later: only `DATABASE_URL` changes. The Prisma
  schema stays `provider = "postgresql"`, so migrations carry over.
```mermaid
erDiagram
    User ||--o{ Address : "registers"
    User ||--o| Cart : "owns"
    User ||--o{ Order : "places"
    User ||--o{ Review : "writes"
    
    Category ||--o{ Category : "parent/child"
    Category ||--o{ Product : "classifies"
    
    Product ||--o{ ProductImage : "contains"
    Product ||--o{ CartItem : "referenced in"
    Product ||--o{ OrderItem : "snapshotted in"
    Product ||--o{ Review : "receives"
    
    Cart ||--o{ CartItem : "contains"
    Order ||--o{ OrderItem : "contains"

    User {
        string id PK
        string email UK
        string passwordHash
        Role role "CUSTOMER | ADMIN"
        string name
        boolean isActive
    }

    Product {
        string id PK
        string title
        string slug UK
        decimal price
        decimal compareAtPrice
        string sku UK
        int stockQty
        boolean isActive
    }

    Order {
        string id PK
        string userId FK
        OrderStatus status "PENDING | PAID | SHIPPED | DELIVERED | CANCELLED"
        PaymentStatus paymentStatus "UNPAID | PAID | REFUNDED"
        decimal subtotal
        decimal total
        json shippingAddress
    }

    OrderItem {
        string id PK
        string orderId FK
        string productId FK
        string titleSnapshot
        decimal priceAtPurchase
        int quantity
    }
```

---

## 📡 REST API Reference

All endpoints are versioned under `/api/v1`. Responses adhere to a standardized contract:
- **Success**: `{ "success": true, "data": { ... }, "pagination": { ... } }`
- **Error**: `{ "success": false, "error": { "code": "STATUS_CODE", "message": "Details" } }`

| Module | Method | Endpoint | Access Level | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Auth** | `POST` | `/api/v1/auth/register` | Public | Register new customer account |
| | `POST` | `/api/v1/auth/login` | Public | Authenticate and obtain access + refresh tokens |
| | `POST` | `/api/v1/auth/refresh` | Public | Refresh expired access token |
| | `POST` | `/api/v1/auth/logout` | Authenticated | Invalidate active session |
| **Users** | `GET` | `/api/v1/users/me` | Authenticated | Retrieve current user profile |
| | `PUT` | `/api/v1/users/me` | Authenticated | Update profile details |
| | `PUT` | `/api/v1/users/me/password` | Authenticated | Change user password |
| **Products** | `GET` | `/api/v1/products` | Public | Paginated product listing with filters and sorting |
| | `GET` | `/api/v1/products/:slug` | Public | Product details by slug |
| | `GET` | `/api/v1/products/:id/reviews` | Public | Product customer reviews |
| | `POST` | `/api/v1/products/:id/reviews` | Customer | Submit verified purchase review |
| **Cart** | `GET` | `/api/v1/cart` | Customer | Fetch current shopping cart |
| | `POST` | `/api/v1/cart/items` | Customer | Add product to cart |
| | `PATCH` | `/api/v1/cart/items/:id` | Customer | Update cart item quantity |
| | `DELETE` | `/api/v1/cart/items/:id` | Customer | Remove item from cart |
| | `DELETE` | `/api/v1/cart` | Customer | Clear cart |
| **Checkout** | `POST` | `/api/v1/orders/checkout` | Customer | Atomic checkout with inventory reservation |
| | `GET` | `/api/v1/orders` | Customer | List customer order history |
| | `GET` | `/api/v1/orders/:id` | Customer | Get order details |
| | `POST` | `/api/v1/orders/:id/cancel` | Customer | Cancel order and restock items |
| **Addresses** | `GET` / `POST` | `/api/v1/addresses` | Customer | List or create shipping addresses |
| | `PUT` / `DELETE`| `/api/v1/addresses/:id` | Customer | Update or delete address |
| **Admin** | `GET` | `/api/v1/admin/dashboard` | Admin | Real-time sales, order counts, and user metrics |
| | `GET` / `POST` | `/api/v1/admin/products` | Admin | List or create catalog items |
| | `PUT` / `DELETE`| `/api/v1/admin/products/:id`| Admin | Update or soft-delete product |
| | `POST` | `/api/v1/admin/products/:id/images` | Admin | Upload product media (Multer) |
| | `GET` | `/api/v1/admin/orders` | Admin | View all system orders across users |
| | `PATCH` | `/api/v1/admin/orders/:id/status` | Admin | Progress order through state machine |
| | `GET` / `PATCH`| `/api/v1/admin/users` | Admin | Manage user roles and activation states |

> 📖 **Interactive Documentation**: When running the server, explore the complete Swagger UI documentation at `http://localhost:4000/api-docs` or import `matjar.postman_collection.json`.

---

## 🚀 Quickstart Guide

### Prerequisites
- **Node.js**: v20+ (v24 recommended) & npm
- **Flutter SDK**: v3.12+ and Dart
- **Android Studio** (for Android Emulator) or **Xcode** (for iOS Simulator on macOS)

---

### 1. Backend Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/<your-username>/matjar.git
   cd matjar
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Configure environment variables**:
   ```bash
   cp .env.example .env
   ```
   *(The default `.env.example` comes pre-configured with local PGlite database ports and dev secrets).*

4. **One-Command Bootstrapper**:
   ```bash
   npm run dev:all
   ```
   *This starts the embedded local PostgreSQL engine, initializes the database connection, runs migrations, and launches the Express server with live reload.*

   *Alternatively, run step-by-step:*
   ```bash
   # Terminal 1: Start local database
   npm run db:dev

   # Terminal 2: Run migrations & seed data
   npm run prisma:migrate
   npm run prisma:seed

   # Terminal 2: Start API in watch mode
   npm run dev
   ```

5. **Verify Backend Status**:
   - **Health Endpoint**: `http://localhost:4000/health`
   - **Swagger API Docs**: `http://localhost:4000/api-docs`
   - **Default Seeded Admin**: `admin@matjar.local` / `Admin123!`

---

### 2. Mobile App Setup (Flutter)

1. **Navigate to the app directory**:
   ```bash
   cd matjar_app
   ```

2. **Install Flutter packages**:
   ```bash
   flutter pub get
   ```

3. **Run on Target Device**:

   - **Android Emulator** *(defaults to `10.0.2.2:4000` automatically)*:
     ```bash
     flutter run
     ```

   - **iOS Simulator / Web / Desktop**:
     ```bash
     flutter run --dart-define=API_BASE_URL=http://localhost:4000
     ```

   - **Physical Device** *(replace with your local machine's LAN IP)*:
     ```bash
     flutter run --dart-define=API_BASE_URL=http://192.168.1.X:4000
     ```

---

## 📂 Repository Structure

```plaintext
matjar/
├── .env.example                    # Environment template
├── matjar.postman_collection.json  # Postman API Collection
├── package.json                    # Backend scripts & dependencies
├── prisma/
│   ├── schema.prisma               # Prisma 7 schema & relational definitions
│   └── seed.js                     # Initial seed (Admin + luxury catalog dataset)
├── screenshots/                    # App UI captures used across documentation
│   ├── home.png
│   ├── login.png
│   └── admin_dashbord.png
├── scripts/
│   └── dev.js                      # Automated zero-config DB + API orchestrator
├── src/                            # Backend Application Source
│   ├── app.js                      # Express configuration & middleware pipeline
│   ├── server.js                   # HTTP server entrypoint
│   ├── config/                     # Environment configuration loader
│   ├── docs/                       # Swagger / OpenAPI specification
│   ├── lib/                        # Prisma client instance & helpers
│   ├── middlewares/                # Auth, RBAC, error handlers, rate-limiters
│   ├── modules/                    # Domain-Driven Modules
│   │   ├── addresses/              # Shipping address operations
│   │   ├── admin/                  # Admin KPIs & store analytics
│   │   ├── auth/                   # Registration, login, JWT refresh
│   │   ├── cart/                   # Cart item state & manipulation
│   │   ├── categories/             # Catalog taxonomy
│   │   ├── orders/                 # Checkout transactions & state machine
│   │   ├── products/               # Product catalog & Multer image uploads
│   │   ├── reviews/                # Verified review submission & scoring
│   │   └── users/                  # User profile & administration
│   └── utils/                      # ApiError, pagination, response formatters
└── matjar_app/                     # Cross-Platform Flutter Mobile Client
    ├── pubspec.yaml                # Flutter dependencies & assets
    └── lib/
        ├── main.dart               # App initialization
        ├── core/                   # Shared Infrastructure
        │   ├── config.dart         # Dynamic API endpoint resolution
        │   ├── models.dart         # Immutable data models & serializers
        │   ├── network.dart        # Dio HTTP client & token refresh interceptor
        │   ├── router.dart         # GoRouter definitions with auth guards
        │   ├── storage.dart        # Secure token storage wrapper
        │   ├── theme.dart          # Luxury color palette & typography
        │   └── widgets.dart        # Reusable buttons, inputs, loading skeletons
        └── features/               # Feature-First Architecture
            ├── admin/              # Atelier dashboard, product & order management
            ├── auth/               # Sign in, registration, session management
            ├── catalog/            # Search, filter chips, product details
            ├── home/               # Hero banner, category carousels, curated arrivals
            ├── profile/            # Order history, addresses, settings
            └── shop/               # Cart, multi-step checkout, order confirmation
```

---

## 🔒 Security & Quality Standards

- **Principle of Least Privilege**: Customer accounts cannot elevate roles; role changes and user suspensions are restricted exclusively to administrators.
- **Defensive Input Validation**: Strict validation via **Zod** on incoming payloads ensures bad or malicious data never reaches controllers or database transactions.
- **SQL Injection Immunity**: All database interactions are prepared and parametrized through Prisma ORM.
- **Protection Against Bruteforce & Denial of Service**: Authentication endpoints are rate-limited (`express-rate-limit`), with HTTP headers hardened via `helmet`.
- **Client-Side Storage**: Sensitive JWT credentials are encrypted using platform keystores via `flutter_secure_storage`.

---

## 🔮 Roadmap

- [ ] **Payment Gateway Integration**: Stripe & Apple Pay / Google Pay webhooks.
- [ ] **Push Notifications**: Firebase Cloud Messaging (FCM) for live order status updates.
- [ ] **Real-Time Analytics**: WebSockets / Server-Sent Events (SSE) for live admin dashboard counters.
- [ ] **Full-Text Search Engine**: Algolia or PostgreSQL Full-Text Search for fuzzy matching.

---

## 👨‍💻 Author & Contact

Crafted with passion for clean code and modern full-stack mobile architecture.

- **Portfolio**: [Portfolio](https://modather.pages.dev/)
- **GitHub**: [@ModatherAli](https://github.com/ModatherAli/)
- **LinkedIn**: [LinkedIn Profile](https://www.linkedin.com/in/modatherali/)
- **Email**: `modather0ali@gmail.com`

