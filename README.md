# Matjar E-commerce API

REST backend for an e-commerce store built with Node.js, Express 5 and PostgreSQL (via Prisma 7).

## Stack

- Node.js 24 (ESM) + Express 5
- PostgreSQL + Prisma 7 (`@prisma/adapter-pg`)
- JWT access (15m) + refresh (7d) tokens, bcrypt passwords
- Zod validation, helmet / CORS / rate-limit, multer uploads
- Swagger UI at `/api-docs`

## Prerequisites

- Node.js 20+ (24 recommended) and npm
- No local PostgreSQL install needed for development: the project uses
  `prisma dev`, a local PGlite-backed PostgreSQL server (small npm download).

## Quickstart

```bash
npm install

# Terminal 1 - start the local database (keep running)
npm run db:dev

# Terminal 2 - first time only: migrate + seed
npm run prisma:migrate
npm run prisma:seed

# Terminal 2 - start the API
npm run dev
```

- API: http://localhost:4000
- Docs: http://localhost:4000/api-docs
- Seed admin: `admin@matjar.local` / `Admin123!` (override in `.env`)

## Scripts

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

## Environment

See `.env.example`. Key variables:

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Main connection (local: `postgres://postgres:postgres@localhost:51214/...`) |
| `SHADOW_DATABASE_URL` | Shadow DB for migrations (`...@localhost:51215/...`) |
| `PORT` | API port (default 4000) |
| `JWT_ACCESS_SECRET` / `JWT_REFRESH_SECRET` | Signing secrets (min 32 chars in production) |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` / `ADMIN_NAME` | Seeded admin user |

## Endpoint overview

All routes are prefixed with `/api/v1`. Responses use `{ success, data }`
(or `{ success, data, pagination }`); errors use `{ success: false, error }`.

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

## Business rules worth knowing

- Register always creates `CUSTOMER`; only admins change roles (and never their own).
- Checkout runs in a transaction: stock check, order + item snapshots, stock
  decrement, cart clear. Empty cart, inactive or out-of-stock products fail with 400.
- Order flow: `PENDING -> PAID -> SHIPPED -> DELIVERED`, cancellable from
  `PENDING`/`PAID`. Cancelling restocks items and refunds paid orders.
- Deleting a product with order history soft-deactivates it instead.
- Reviews require a delivered purchase of that product, one per customer.
- Product images upload to `uploads/products/` (5MB max, images only).

## Troubleshooting

- `prisma dev` hangs on start: a stale lock from a killed process. Stop node
  processes, delete `server.json` and `server.lock*` under
  `%LocalAppData%\prisma-dev-nodejs\Data\matjar` (and `durable-streams\matjar`),
  then run `npm run db:dev` again.
- Moving to hosted Postgres later: only `DATABASE_URL` changes. The Prisma
  schema stays `provider = "postgresql"`, so migrations carry over.

