# Build Me a PC — Backend API

A RESTful backend API for **Build Me a PC**, a platform connecting PC enthusiasts with verified builders. The platform features a logic-based compatibility engine for validated PC designs, build commissions, and a marketplace for pre-built PCs.

## Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)
- [Database](#database) 
  - [Database Schema](#database-schema)  $\space$   (ERD is here)
- [Authentication](#authentication)
- [User Roles & Permissions](#user-roles--permissions)
- [API Endpoints](#api-endpoints)
  - [Auth](#auth)
  - [Users](#users)
  - [Parts](#parts)
  - [Categories](#categories)
  - [Builds](#builds)
  - [Build Requests](#build-requests)
  - [Builder Offers](#builder-offers)
  - [Showcase Inquiries](#showcase-inquiries)
  - [Builder Applications](#builder-applications)
  - [Compatibility](#compatibility)
  - [Stats & Health](#stats--health)
- [Compatibility Engine](#compatibility-engine)
- [Database Schema](#database-schema)
- [Project Structure](#project-structure)
- [Error Handling](#error-handling)
- [Contributors](#contributors)
---

## Overview

**Build Me a PC** is a platform where:

- **Users** can browse pre-built PCs, create custom builds with real-time compatibility checks, post build requests for builders, and interact with builds via comments, likes, and ratings.
- **Builders** are verified experts who can post showcase pre-built PCs, respond to build requests with offers, and manage their builder profiles. Users can apply to become builders.
- **Admins** can manage PC parts, review builder applications, moderate users (ban/unban), manage compatibility rules, and perform all builder/user actions.

---

## Tech Stack

| Layer          | Technology                                    |
| -------------- | --------------------------------------------- |
| Runtime        | **Node.js** (ES Modules)                      |
| Framework      | **Express.js** v4                             |
| Database       | **PostgreSQL** (via `pg`)                     |
| Authentication | **JWT** (`jsonwebtoken`) + **bcrypt**         |
| CORS           | **cors**                                      |
| Environment    | **dotenv**                                    |
| Dev Tools      | **nodemon**                                   |

---

## Getting Started

### Prerequisites

- Node.js (v18+)
- PostgreSQL database

### Installation

```bash
# Clone the repository
git clone <repo-url>
cd dbs-db

# Install dependencies
npm install

# Set up environment variables
cp .env.example .env
# Edit .env with your database URL and JWT secret

# Start the development server
npm run dev
```

### Scripts

| Command          | Description                                         |
| ---------------- | --------------------------------------------------- |
| `npm start`      | Start the production server                         |
| `npm run dev`    | Start with nodemon (auto-reload on file changes)    |
| `npm run db:init`| Seed the database with schema and sample data       |
| `npm run db:reset`| Reset and re-seed the database                     |

> **Note:** The server auto-initializes the database on first startup if tables don't exist.

---

## Environment Variables

Create a `.env` file in the project root:

```env
DATABASE_URL=postgresql://user:password@localhost:5432/buildmeapc
JWT_SECRET=your_jwt_secret_here
PORT=3000
NODE_ENV=development
```

---

## Database

The API uses **PostgreSQL** with the `pg` library. Connection pooling is configured via `config/db.js`.

### Auto-Initialization

On server startup, the app checks if the `users` table exists. If not, it automatically runs the schema and seeds the database with sample data including:

- **5 users** — 1 admin, 2 regular users, 2 builders
- **35 PC parts** across 8 categories (CPU, GPU, Motherboard, RAM, Storage, PSU, Case, Cooling)
- **3 sample builds** — 2 personal builds, 1 builder showcase
- **12 compatibility rules** covering socket matching, form factor checks, wattage calculations, etc.
- Sample ratings, comments, and likes

### Default Seed Accounts

| Email                    | Password      | Role    |
| ------------------------ | ------------- | ------- |
| `admin@buildboard.com`  | `admin123`    | Admin   |
| `alice@example.com`     | `password123` | User    |
| `bob@example.com`       | `password123` | User    |
| `techpro@example.com`   | `password123` | Builder |
| `elite@example.com`     | `password123` | Builder |

---

## Authentication

Authentication uses **JWT Bearer tokens**. Tokens are issued on login/register and expire after **7 days**.

Include the token in the `Authorization` header:

```
Authorization: Bearer <token>
```

### Middleware

| Middleware       | Description                                                        |
| ---------------- | ------------------------------------------------------------------ |
| `authenticate`   | Requires a valid JWT; attaches `req.user` with `id`, `email`, `role` |
| `optionalAuth`   | Attaches user if token present, otherwise sets `req.user = null`   |
| `requireRole(...)` | Checks user role; admins inherit builder permissions             |

---

## User Roles & Permissions

| Action                           | User | Builder | Admin |
| -------------------------------- | :--: | :-----: | :---: |
| Register & sign in               |  ✅  |   ✅    |  ✅   |
| Browse pre-built PCs             |  ✅  |   ✅    |  ✅   |
| Create custom builds             |  ✅  |   ✅    |  ✅   |
| Comment, like & rate builds      |  ✅  |   ✅    |  ✅   |
| Post a build request             |  ✅  |   ✅    |  ✅   |
| Browse active build requests     |  ✅  |   ✅    |  ✅   |
| Respond to offers from builders  |  ✅  |   ✅    |  ✅   |
| Apply to become a builder        |  ✅  |   ✅    |  ✅   |
| Send showcase inquiries          |  ✅  |   ✅    |  ✅   |
| Reply to build requests with offer |    |   ✅    |  ✅   |
| Post showcase pre-built PCs      |    |   ✅    |  ✅   |
| Add / edit / remove PC parts     |    |         |  ✅   |
| Review builder applications      |    |         |  ✅   |
| Manage compatibility rules       |    |         |  ✅   |
| Moderate users (ban/unban)       |    |         |  ✅   |
| Change user roles                |    |         |  ✅   |
| View all users                   |    |         |  ✅   |

---

## API Endpoints

Base URL: `/api`

### Auth

| Method | Endpoint        | Auth     | Description                            |
| ------ | --------------- | -------- | -------------------------------------- |
| POST   | `/auth/register`| —        | Register a new user                    |
| POST   | `/auth/login`   | —        | Login and receive JWT token            |
| GET    | `/auth/me`      | Required | Get current authenticated user profile |

### Users

| Method | Endpoint                      | Auth     | Description                        |
| ------ | ----------------------------- | -------- | ---------------------------------- |
| GET    | `/users`                      | Admin    | List all users                     |
| GET    | `/users/builders`             | —        | List all builders                  |
| GET    | `/users/:id`                  | —        | Get user by ID                     |
| PUT    | `/users/:id`                  | Owner/Admin | Update user profile             |
| PUT    | `/users/:id/ban`              | Admin    | Ban or unban a user                |
| PUT    | `/users/:id/role`             | Admin    | Change a user's role               |
| GET    | `/users/:id/builder-profile`  | —        | Get builder profile                |
| PUT    | `/users/:id/builder-profile`  | Owner/Admin | Update builder profile          |

### Parts

| Method | Endpoint      | Auth  | Description                              |
| ------ | ------------- | ----- | ---------------------------------------- |
| GET    | `/parts`      | —     | List active parts (filter by `category_id`) |
| GET    | `/parts/all`  | Admin | List all parts (including inactive)      |
| GET    | `/parts/:id`  | —     | Get part by ID                           |
| POST   | `/parts`      | Admin | Create a new part                        |
| PUT    | `/parts/:id`  | Admin | Update a part                            |
| DELETE | `/parts/:id`  | Admin | Delete a part                            |

### Categories

| Method | Endpoint      | Auth | Description                |
| ------ | ------------- | ---- | -------------------------- |
| GET    | `/categories` | —    | List all part categories   |

**Part Categories:** CPU, GPU, Motherboard, RAM, Storage, PSU, Case, Cooling

### Builds

| Method | Endpoint                    | Auth     | Description                              |
| ------ | --------------------------- | -------- | ---------------------------------------- |
| GET    | `/builds`                   | —        | List builds (filter by `status`, `build_type`, `creator_id`) |
| GET    | `/builds/:id`               | —        | Get build by ID                          |
| GET    | `/builds/:id/parts`         | —        | Get all parts in a build (nested `part` & `category` objects) |
| POST   | `/builds`                   | Required | Create a build with compatibility check; requires `cpu`, `motherboard`, `ram`, `psu`, `case` (returns `{ build, warnings }`) |
| PUT    | `/builds/:id`               | Owner/Admin | Update a build (re-runs compatibility and required parts validation, returns `{ build, warnings }`) |
| DELETE | `/builds/:id`               | Owner/Admin | Delete a build                        |
| GET    | `/builds/:id/ratings`       | —        | Get all ratings for a build              |
| GET    | `/builds/:id/ratings/mine`  | Required | Get your rating for a build              |
| POST   | `/builds/:id/ratings`       | Required | Rate a build (1–5 score, updates `rating_avg`/`rating_count`) |
| GET    | `/builds/:id/comments`      | —        | Get all comments on a build              |
| POST   | `/builds/:id/comments`      | Required | Add a comment (supports threaded replies, returns `creator_display_name`) |
| GET    | `/builds/:id/likes`         | —        | Get all likes on a build                 |
| GET    | `/builds/:id/likes/check`   | Required | Check if you liked a build               |
| POST   | `/builds/:id/likes/toggle`  | Required | Toggle like on a build (updates `like_count`) |

> **Build Types:** `personal` (user-created) | `showcase` (builder pre-built)  
> **Build Statuses:** `draft` | `published`

### Build Requests

| Method | Endpoint         | Auth     | Description                                   |
| ------ | ---------------- | -------- | --------------------------------------------- |
| GET    | `/requests`      | —        | List requests (filter by `status`, `user_id`, `build_id`) |
| GET    | `/requests/:id`  | —        | Get request by ID                             |
| POST   | `/requests`      | Required | Create a build request (with `budget`, `purpose`, `notes`, `preferred_builder_id`) |
| PUT    | `/requests/:id`  | Owner/Admin | Update a build request                     |

> **Request Statuses:** `open` → `claimed` → `in_progress` → `completed` | `cancelled`

### Builder Offers

| Method | Endpoint               | Auth    | Description                                |
| ------ | ---------------------- | ------- | ------------------------------------------ |
| GET    | `/offers`              | Required | List offers with builder profile data (filter by `request_id`, `builder_id`) |
| POST   | `/offers`              | Builder | Submit an offer (`fee`, `message`, `contact_info`, optional `suggested_build_id`) |
| POST   | `/offers/:id/accept`   | Request Owner/Admin | Accept an offer (auto-rejects others, sets request to `claimed`) |

> **Offer Statuses:** `pending` → `accepted` | `rejected`

### Showcase Inquiries

| Method | Endpoint      | Auth     | Description                                    |
| ------ | ------------- | -------- | ---------------------------------------------- |
| GET    | `/inquiries`  | Required | List inquiries (filter by `build_id`, `builder_id`, `user_id`) |
| POST   | `/inquiries`  | Required | Send an inquiry about a showcase build         |

### Builder Applications

| Method | Endpoint                    | Auth     | Description                              |
| ------ | --------------------------- | -------- | ---------------------------------------- |
| GET    | `/applications`             | Admin    | List all applications (filter by `status`, `user_id`) |
| GET    | `/applications/mine`        | Required | Get your own applications                |
| POST   | `/applications`             | Required | Submit a builder application             |
| PUT    | `/applications/:id/review`  | Admin    | Approve or reject (sets `reviewed_by` to admin) |

> On approval, the user's role is upgraded to `builder` and a builder profile is created automatically (skipped if one already exists).

### Compatibility

| Method | Endpoint                | Auth  | Description                           |
| ------ | ----------------------- | ----- | ------------------------------------- |
| POST   | `/compatibility/check`  | —     | Run compatibility check on a parts map|
| GET    | `/compatibility/rules`  | Admin | List all compatibility rules          |
| POST   | `/compatibility/rules`  | Admin | Create a new compatibility rule       |
| PUT    | `/compatibility/rules/:id` | Admin | Update a compatibility rule        |
| DELETE | `/compatibility/rules/:id` | Admin | Delete a compatibility rule        |

### Stats & Health

| Method | Endpoint       | Auth | Description                              |
| ------ | -------------- | ---- | ---------------------------------------- |
| GET    | `/health`      | —    | Health check (`{ status: 'ok' }`)        |
| GET    | `/stats`       | —    | Platform stats (builds, parts, users, requests counts) |

---

## Compatibility Engine

The platform includes a **rule-based PC part compatibility engine** that validates builds in real-time. When creating or updating a build, parts are checked against active compatibility rules. **Errors** block the build from being saved, while **warnings** are returned alongside the build.

### Rule Types

| Rule Type                 | Description                                              | Example                                     |
| ------------------------- | -------------------------------------------------------- | ------------------------------------------- |
| `field_match`             | Two parts must share the same value for a given field    | CPU socket must match motherboard socket     |
| `field_lte`              | Part A's field must be ≤ Part B's field                  | RAM modules ≤ motherboard RAM slots          |
| `array_contains`          | Part A's value must exist in Part B's array              | Motherboard form factor in case's supported list |
| `array_contains_formatted`| Same as above, but formats the value before checking     | AIO radiator size in case's radiator support |
| `sum_gte`                | Target part's field must be ≥ sum of other fields × multiplier | PSU wattage ≥ (CPU TDP + GPU TDP) × 1.2  |
| `pair_mismatch`           | Detects specific problematic value pairings              | ATX PSU in ITX case                          |

### Built-in Rules (12 rules)

1. **CPU-Motherboard Socket Match** — error
2. **RAM-Motherboard Type Match** — error
3. **RAM Modules vs Motherboard Slots** — error
4. **RAM Capacity vs Motherboard Max** — error
5. **Motherboard Form Factor vs Case** — error
6. **GPU Length vs Case Max** — error
7. **Cooler Socket Compatibility** — error
8. **Air Cooler Height vs Case Max** — error
9. **AIO Radiator vs Case Support** — error
10. **PSU Wattage vs Total TDP** — warning
11. **PSU-Case Form Factor** — warning
12. **M.2 Storage vs Motherboard Slots** — error

Rules are stored in the database and can be toggled, updated, or extended by admins via the API.

---

## Database Schema

The schema uses `DROP SCHEMA public CASCADE; CREATE SCHEMA public;` for clean resets, then creates all types and 14 tables with UUID primary keys:

![ERD](readmeResources/BuildMeAPC_ERD_CrowsFoot_Model_transparent.png)

### Enum Types

| Enum                 | Values                                                 |
| -------------------- | ------------------------------------------------------ |
| `user_role`          | `user`, `builder`, `admin`                             |
| `build_status`       | `draft`, `published`                                   |
| `build_type`         | `personal`, `showcase`                                 |
| `availability_status`| `available`, `sold_out`, `discontinued`                |
| `request_status`     | `open`, `claimed`, `in_progress`, `completed`, `cancelled` |
| `offer_status`       | `pending`, `accepted`, `rejected`                      |
| `application_status` | `pending`, `approved`, `rejected`                      |
| `application_type`   | `business`, `individual`                               |
| `inquiry_status`     | `pending`, `responded`, `closed`                       |

---

## Project Structure

```
dbs-db/
├── server.js                  # Express app entry point, route mounting, startup
├── package.json               # Dependencies and scripts
├── config/
│   └── db.js                  # PostgreSQL connection pool
├── db/
│   ├── init.js                # Auto-initialization on startup
│   ├── schema.sql             # Full database schema (14 tables, triggers)
│   ├── seed.js                # Standalone seed script
│   └── seed.sql               # Seed data (users, parts, builds, rules)
├── middleware/
│   ├── auth.js                # JWT authentication & role-based authorization
│   └── errorHandler.js        # Global error handler (PostgreSQL error codes)
├── routes/
│   ├── auth.js                # Register, login, current user
│   ├── users.js               # User profiles, banning, role management
│   ├── parts.js               # CRUD for PC parts (admin-managed)
│   ├── categories.js          # Part categories listing
│   ├── builds.js              # Builds CRUD, ratings, comments, likes
│   ├── requests.js            # Build requests from users
│   ├── offers.js              # Builder offers on requests
│   ├── inquiries.js           # Showcase build inquiries
│   ├── applications.js        # Builder application submission & review
│   └── compatibility.js       # Compatibility check & rule management
└── utils/
    └── compatibility.js       # Rule evaluation engine (6 rule types)
```

---

## Error Handling

The global error handler catches all errors and returns consistent JSON responses:

| Scenario                 | Status | Response                              |
| ------------------------ | ------ | ------------------------------------- |
| Authentication required  | 401    | `{ error: "Authentication required" }`|
| Invalid/expired token    | 401    | `{ error: "Invalid or expired token" }`|
| Insufficient permissions | 403    | `{ error: "Insufficient permissions" }`|
| Banned account login     | 403    | `{ error: "This account has been banned" }` |
| Missing required parts   | 400    | `{ error: "Build must include all required parts", missing_parts: [...] }` |
| Compatibility errors     | 400    | `{ error: "Compatibility errors", issues: [...] }` |
| Resource not found       | 404    | `{ error: "<Resource> not found" }`   |
| Duplicate resource       | 409    | `{ error: "Resource already exists" }`|
| FK constraint violation  | 400    | `{ error: "Referenced resource not found" }`|
| Internal error           | 500    | `{ error: "Internal server error" }`  |

---

## Contributors

This is a university project for **CSX3006 Database Systems** course, developed by a team of 3 students:

### Team Members

| Name                   | Student ID | GitHub Username (Profile)                   |
|------------------------|------------|---------------------------------------------|
| Min Khaung Kyaw Swar   | 6712164    | [sasta-kro](github.com/sasta-kro)           |
| Sai Aike Shwe Tun Aung | 6712122    | [minkhaung-mkks](github.com/minkhaung-mkks) |
| Ekaterina Kazakova     | 6720065    | [Kari-Nami](github.com/Kari-Nami)           |

---

