-- ------------------------------------------------------------------------------------------
-- DATABASE SETUP
-- ------------------------------------------------------------------------------------------

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- ENUM TYPES
-- -----------------------------------------------------------------------------

CREATE TYPE user_role AS ENUM ('user', 'builder', 'admin');
CREATE TYPE build_status AS ENUM ('draft', 'published');
CREATE TYPE build_type AS ENUM ('personal', 'showcase');
CREATE TYPE availability_status AS ENUM ('available', 'sold_out', 'discontinued');
CREATE TYPE request_status AS ENUM ('open', 'claimed', 'in_progress', 'completed', 'cancelled');
CREATE TYPE offer_status AS ENUM ('pending', 'accepted', 'rejected');
CREATE TYPE application_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE application_type AS ENUM ('business', 'individual');
CREATE TYPE inquiry_status AS ENUM ('pending', 'responded', 'closed');

-- -----------------------------------------------------------------------------
-- TABLE CREATION
-- -----------------------------------------------------------------------------

-- ------------------------------------------------------------------------------------------
-- Table 1: users
-- Stores user accounts with authentication and profile information
-- ------------------------------------------------------------------------------------------
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name VARCHAR(100) NOT NULL,
  avatar_url TEXT,
  bio TEXT,
  role user_role NOT NULL DEFAULT 'user',
  is_banned BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ------------------------------------------------------------------------------------------
-- Table 2: builder_profiles
-- Extended profile information for verified builders
-- ------------------------------------------------------------------------------------------
CREATE TABLE builder_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  business_name VARCHAR(200) NOT NULL,
  registration_number VARCHAR(100),
  address TEXT,
  website TEXT,
  portfolio_url TEXT,
  years_of_experience INTEGER,
  specialization VARCHAR(255),
  avg_rating DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  completed_builds INTEGER NOT NULL DEFAULT 0,
  is_verified BOOLEAN NOT NULL DEFAULT true,
   created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ------------------------------------------------------------------------------------------
-- Table 3: builder_applications
-- Applications from users requesting builder status
-- ------------------------------------------------------------------------------------------
CREATE TABLE builder_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  business_name VARCHAR(200) NOT NULL,
  registration_number VARCHAR(100),
  address TEXT,
  website TEXT,
  portfolio_url TEXT,
  years_of_experience INTEGER,
  specialization VARCHAR(255),
  application_type application_type NOT NULL,
  status application_status NOT NULL DEFAULT 'pending',
  admin_notes TEXT,
  reviewed_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_builder_applications_user ON builder_applications(user_id);
CREATE INDEX idx_builder_applications_status ON builder_applications(status);

-- ------------------------------------------------------------------------------------------
-- Table 4: part_categories
-- Categories for PC parts (CPU, GPU, Motherboard, etc.)
-- ------------------------------------------------------------------------------------------
CREATE TABLE part_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  icon VARCHAR(50)
);

-- ------------------------------------------------------------------------------------------
-- Table 5: parts
-- Individual PC components with specifications stored as JSONB
-- ------------------------------------------------------------------------------------------
CREATE TABLE parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES part_categories(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  brand VARCHAR(100) NOT NULL,
  model VARCHAR(200) NOT NULL,
  specifications JSONB NOT NULL DEFAULT '{}', -- This was necessary cuz if we didn't use JSONB we would need like 12 more tables T_T
  price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parts_category ON parts(category_id);
CREATE INDEX idx_parts_active ON parts(is_active);

-- ------------------------------------------------------------------------------------------
-- Table 6: builds
-- User-created PC builds with parts, pricing, and social metrics
-- ------------------------------------------------------------------------------------------
CREATE TABLE builds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  purpose VARCHAR(100),
  total_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  status build_status NOT NULL DEFAULT 'draft',
  build_type build_type NOT NULL DEFAULT 'personal',
  availability_status availability_status,
  image_urls TEXT[],
  specs_summary TEXT,
  like_count INTEGER NOT NULL DEFAULT 0,
  rating_avg DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  rating_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_builds_creator ON builds(creator_id);
CREATE INDEX idx_builds_status ON builds(status);
CREATE INDEX idx_builds_type ON builds(build_type);

-- ------------------------------------------------------------------------------------------
-- Table 7: build_parts (junction/associative table)
-- Links builds to parts inside the build with respective quantities
-- ------------------------------------------------------------------------------------------
CREATE TABLE build_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  build_id UUID NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  part_id UUID NOT NULL REFERENCES parts(id),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  UNIQUE (build_id, part_id)
);

CREATE INDEX idx_build_parts_build ON build_parts(build_id);
CREATE INDEX idx_build_parts_part ON build_parts(part_id);

-- ------------------------------------------------------------------------------------------
-- Table 8: build_requests
-- Requests from users for builders to make/assemble their pc builds
-- ------------------------------------------------------------------------------------------
CREATE TABLE build_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  build_id UUID NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  budget DECIMAL(10,2),
  purpose VARCHAR(200),
  notes TEXT,
  preferred_builder_id UUID REFERENCES users(id),
  status request_status NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_build_requests_user ON build_requests(user_id);
CREATE INDEX idx_build_requests_status ON build_requests(status);
CREATE INDEX idx_build_requests_build ON build_requests(build_id);

-- ------------------------------------------------------------------------------------------
-- Table 9: builder_offers
-- Offers from builders to fulfill build requests
-- ------------------------------------------------------------------------------------------
CREATE TABLE builder_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES build_requests(id) ON DELETE CASCADE,
  builder_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  message TEXT NOT NULL,
  suggested_build_id UUID REFERENCES builds(id),
  contact_info TEXT NOT NULL,
  status offer_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (request_id, builder_id)
);

CREATE INDEX idx_builder_offers_request ON builder_offers(request_id);
CREATE INDEX idx_builder_offers_builder ON builder_offers(builder_id);

-- ------------------------------------------------------------------------------------------
-- Table 10: showcase_inquiries
-- Inquiries from users interested in showcased builds
-- ------------------------------------------------------------------------------------------
CREATE TABLE showcase_inquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  build_id UUID NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  builder_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  status inquiry_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_showcase_inquiries_builder ON showcase_inquiries(builder_id);
CREATE INDEX idx_showcase_inquiries_build ON showcase_inquiries(build_id);

-- ------------------------------------------------------------------------------------------
-- Table 11: ratings
-- User ratings and reviews for builds (1-5 stars)
-- ------------------------------------------------------------------------------------------
CREATE TABLE ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  build_id UUID NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  score INTEGER NOT NULL CHECK (score >= 1 AND score <= 5),
  review_text TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, build_id)
);

CREATE INDEX idx_ratings_build ON ratings(build_id);

-- ------------------------------------------------------------------------------------------
-- Table 12: comments
-- Threaded comments on builds
-- ------------------------------------------------------------------------------------------
CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  build_id UUID NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_comments_build ON comments(build_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);

-- ------------------------------------------------------------------------------------------
-- Table 13: likes
-- User likes on builds (one like per user, per build)
-- ------------------------------------------------------------------------------------------
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  build_id UUID NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, build_id)
);

CREATE INDEX idx_likes_build ON likes(build_id);

-- ------------------------------------------------------------------------------------------
-- Table 14: compatibility_rules
-- Rules for validating PC part compatibility
-- ------------------------------------------------------------------------------------------
CREATE TABLE compatibility_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_number INTEGER UNIQUE NOT NULL,
  name VARCHAR(200) NOT NULL,
  description TEXT,
  severity VARCHAR(10) NOT NULL CHECK (severity IN ('error', 'warning')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  rule_config JSONB NOT NULL,
  message_template TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- ------------------------------------------------------------------------------------------
-- AUTHENTICATION QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 1: Register new user
-- Creates a new user account with hashed password
INSERT INTO users (email, password_hash, display_name)
VALUES ($1, $2, $3)

-- Query 2: Login - find user by email
-- Retrieves user for authentication verification
SELECT * FROM users WHERE email = $1

-- Query 3: Get current authenticated user
-- Returns the currently logged-in user's full profile
SELECT * FROM users WHERE id = $1


-- ------------------------------------------------------------------------------------------
-- CATEGORY QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 4: Get all part categories
-- Returns list of all part categories ordered for display
SELECT * FROM part_categories ORDER BY category_name


-- ------------------------------------------------------------------------------------------
-- PARTS QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 5: Get active parts (with Mandatory category filter)
-- Used by part picker to show available components
SELECT p.*, pc.category_name
FROM parts p 
JOIN part_categories pc ON p.category_id = pc.id 
WHERE p.is_active = true
  AND p.category_id = $1  -- Mandatory filter
ORDER BY pc.category_name, p.name

-- Query 6: Get all parts including inactive (admin only)
-- Admin management view of all parts
SELECT p.*, pc.category_name
FROM parts p JOIN part_categories pc ON p.category_id = pc.id
ORDER BY pc.category_name, p.name

-- Query 7: Get single part by ID
-- Returns details for a specific part
SELECT p.*, pc.category_name
FROM parts p JOIN part_categories pc ON p.category_id = pc.id
WHERE p.id = $1

-- Query 8: Create new part (admin only)
-- Adds a new part to the catalog
INSERT INTO parts (category_id, name, brand, model, specifications, price, image_url, is_active, created_by)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)

-- Query 9: Update part (admin only)
-- Modifies an existing part's details
UPDATE parts SET category_id=$1, name=$2, brand=$3, model=$4, specifications=$5, price=$6, image_url=$7, is_active=$8
WHERE id = $9

-- Query 10: Delete part (admin only)
-- Removes a part from the catalog
DELETE FROM parts WHERE id = $1


-- ------------------------------------------------------------------------------------------
-- BUILDS QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 11: Get featured showcase builds (Homepage)
-- Purpose: Display top 3 featured showcase builds on the homepage hero section
-- Sorted by rating and likes to show best builds first
SELECT 
  b.id,
  b.title,
  b.total_price,
  b.rating_avg,
  b.rating_count,
  b.like_count,
  b.specs_summary,
  u.display_name as creator_display_name
FROM builds b
JOIN users u ON b.creator_id = u.id
WHERE b.status = 'published'
  AND b.build_type = 'showcase'
ORDER BY b.rating_avg DESC, b.like_count DESC
LIMIT 3;

-- Query 12: Get all showcase builds (Showcase Page)
-- Purpose: Browse all showcase builds with client-side availability filtering
SELECT 
  b.id,
  b.title,
  b.total_price,
  b.rating_avg,
  b.rating_count,
  b.like_count,
  b.specs_summary,
  b.availability_status,
  u.display_name as creator_display_name
FROM builds b
JOIN users u ON b.creator_id = u.id
WHERE b.status = 'published'
  AND b.build_type = 'showcase'
ORDER BY b.created_at DESC;

-- Query 13: Get user's published builds (Profile Page)
-- Purpose: Show user's published builds on their profile page, mostly to show to other people.
SELECT 
  b.id,
  b.title,
  b.total_price,
  b.purpose,
  b.rating_avg,
  b.rating_count,
  b.like_count,
  b.build_type
FROM builds b
WHERE b.creator_id = $1
  AND b.status = 'published'
ORDER BY b.created_at DESC;

-- Query 14: Get my builds (User's Dashboard)
-- Purpose: User views their own builds including drafts this is used in the my builds page
SELECT 
  b.id,
  b.title,
  b.total_price,
  b.purpose,
  b.status,
  b.build_type,
  b.created_at,
  b.rating_avg,
  b.like_count
FROM builds b
WHERE b.creator_id = $1
ORDER BY b.created_at DESC;

-- Query 15: Get builder's showcase builds (Builder Dashboard)
-- Purpose: Builder  see/manage their showcase builds
SELECT 
  b.id,
  b.title,
  b.total_price,
  b.availability_status,
  b.rating_avg,
  b.rating_count,
  b.like_count,
  b.created_at
FROM builds b
WHERE b.creator_id = $1
  AND b.build_type = 'showcase'
ORDER BY b.created_at DESC;

-- Query 16: Get single build by ID
-- Purpose: Returns full build details including the user's role to either display or hide the showcase toggle.
SELECT b.*, u.display_name as creator_display_name, u.role as creator_role
FROM builds b JOIN users u ON b.creator_id = u.id
WHERE b.id = $1;

-- Query 17: Get build parts with details
-- Purpose: Returns all parts in a build with full specifications to display on the build detail page.
SELECT bp.*, p.name as part_name, p.brand, p.model, p.specifications, p.price, p.image_url,
       pc.id as category_id, pc.category_name
FROM build_parts bp
JOIN parts p ON bp.part_id = p.id
JOIN part_categories pc ON p.category_id = pc.id
WHERE bp.build_id = $1
ORDER BY pc.category_name;

-- Query 18: Create new build
-- Purpose: Creates a new PC build
INSERT INTO builds (creator_id, title, description, purpose, total_price, status, build_type, availability_status, image_urls, specs_summary)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
RETURNING *;

-- Query 19: Add part to build
-- Purpose: Links a part to a build during creation (this is run along side the create/update a new pc build and doesn't run on its own)
INSERT INTO build_parts (build_id, part_id, quantity) VALUES ($1, $2, 1);

-- Query 20: Update build
-- Purpose: Edit build details or to toggle showcase status
UPDATE builds SET title=$1, description=$2, purpose=$3, total_price=$4, status=$5, build_type=$6, availability_status=$7, image_urls=$8, specs_summary=$9
WHERE id = $10 RETURNING *;

-- Query 21: Delete all parts from build (for rebuild)
-- Purpose: Used when updating build parts - clears existing before re-adding
DELETE FROM build_parts WHERE build_id = $1;

-- Query 22: Check build ownership
-- Purpose: Verifies user owns the build before edit/delete
SELECT * FROM builds WHERE id = $1;

-- Query 23: Delete build
-- Purpose: Removes a build and all associated parts (cascades into other tables)
DELETE FROM builds WHERE id = $1 RETURNING creator_id;


-- ------------------------------------------------------------------------------------------
-- RATINGS QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 24: Get ratings for a build
-- Purpose: Returns all ratings with reviewer names for build detail page
SELECT r.*, u.display_name as creator_display_name
FROM ratings r JOIN users u ON r.user_id = u.id
WHERE r.build_id = $1 ORDER BY r.created_at DESC;

-- Query 25: Get current user's rating for a build
-- Purpose: Checks if user has already rated this build (to show/hide rating form)
SELECT * FROM ratings WHERE user_id = $1 AND build_id = $2;

-- Query 26: Add rating to build
-- Purpose: Creates a new rating with optional review text
INSERT INTO ratings (user_id, build_id, score, review_text)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- Query 27: Calculate and update build rating stats
-- Purpose: Updates average rating and count on build after new rating
SELECT AVG(score)::DECIMAL(3,2) as avg, COUNT(*)::INTEGER as count FROM ratings WHERE build_id = $1;
UPDATE builds SET rating_avg = $2, rating_count = $3 WHERE id = $1;


-- ------------------------------------------------------------------------------------------
-- COMMENTS QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 28: Get comments for a build
-- Purpose: Returns threaded comments ordered chronologically
SELECT c.*, u.display_name as creator_display_name
FROM comments c JOIN users u ON c.user_id = u.id
WHERE c.build_id = $1 ORDER BY c.created_at ASC;

-- Query 29: Add comment to build
-- Purpose: Creates a new comment (can be a reply with parent_comment_id)
INSERT INTO comments (user_id, build_id, content, parent_comment_id)
VALUES ($1, $2, $3, $4)


-- ------------------------------------------------------------------------------------------
-- LIKES QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 31: Get likes for a build
-- Purpose: Returns all likes (used for count)
SELECT * FROM likes WHERE build_id = $1;

-- Query 32: Check if user liked a build
-- Purpose: Returns whether current user has liked this build
SELECT id FROM likes WHERE user_id = $1 AND build_id = $2;

-- Query 33: Toggle like - check existing
-- Purpose: Determines if user already liked to toggle state
SELECT id FROM likes WHERE user_id = $1 AND build_id = $2;

-- Query 34: Like a build
-- Purpose: Insert like and increment build's like_count
INSERT INTO likes (user_id, build_id) VALUES ($1, $2);
UPDATE builds SET like_count = like_count + 1 WHERE id = $1;

-- Query 35: Unlike a build
-- Purpose: Delete like and decrement build's like_count (used by builds.js route)
DELETE FROM likes WHERE id = $1;
UPDATE builds SET like_count = GREATEST(0, like_count - 1) WHERE id = $1;


-- ------------------------------------------------------------------------------------------
-- BUILD REQUESTS QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 37: Browse build requests (Request Board)
-- Purpose: Browse all build requests on the request board with optional status filter
SELECT 
  br.id,
  br.budget,
  br.purpose,
  br.notes,
  br.status,
  br.created_at,
  u.id as user_id,
  u.display_name as user_display_name,
  b.id as build_id,
  b.title as build_title,
  b.total_price as build_total_price,
  pb.id as preferred_builder_id,
  pb.display_name as preferred_builder_name
FROM build_requests br
JOIN users u ON br.user_id = u.id
JOIN builds b ON br.build_id = b.id
LEFT JOIN users pb ON br.preferred_builder_id = pb.id
WHERE br.status = $1 
ORDER BY br.created_at DESC;

-- Query 38: Check build's active request
-- Purpose: Check if a build already has an open or claimed request (prevent duplicates)
SELECT 
  br.id,
  br.status,
  br.user_id
FROM build_requests br
WHERE br.build_id = $1
  AND br.status IN ('open', 'claimed')
LIMIT 1;

-- Query 39: Get single request details
-- Purpose: Returns full build request info for request detail page 
SELECT br.*, u.display_name as user_display_name, u.email as user_email,
       b.title as build_title, b.total_price as build_total_price, b.description as build_description,
       pb.display_name as preferred_builder_name
FROM build_requests br
JOIN users u ON br.user_id = u.id
JOIN builds b ON br.build_id = b.id
LEFT JOIN users pb ON br.preferred_builder_id = pb.id
WHERE br.id = $1;

-- Query 40: Create build request
-- Purpose: Posts a new request to the request board
INSERT INTO build_requests (build_id, user_id, budget, purpose, notes, preferred_builder_id)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- Query 41: Update build request
-- Purpose: Edit request details or change status (complete/cancel)
SELECT * FROM build_requests WHERE id = $1;
UPDATE build_requests SET budget=$1, purpose=$2, notes=$3, status=$4, preferred_builder_id=$5
WHERE id = $6 RETURNING *;


-- ------------------------------------------------------------------------------------------
-- BUILDER OFFERS QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 42: Get offers for a request (Request Owner View)
-- Purpose: Show request owner all offers submitted to their build request to either accept or reject them.
SELECT 
  bo.id,
  bo.fee,
  bo.message,
  bo.contact_info,
  bo.status,
  bo.created_at,
  u.id as builder_id,
  u.display_name as builder_display_name,
  json_build_object(
    'years_of_experience', bp.years_of_experience,
    'completed_builds', bp.completed_builds,
    'avg_rating', bp.avg_rating
  ) as builder_profile
FROM builder_offers bo
JOIN users u ON bo.builder_id = u.id
LEFT JOIN builder_profiles bp ON bp.user_id = bo.builder_id
WHERE bo.request_id = $1
ORDER BY bo.created_at DESC;

-- Query 43: Get builder's own offers (Builder Dashboard)
-- Purpose: Show builder all offers they have submitted across all requests
SELECT 
  bo.id,
  bo.fee,
  bo.message,
  bo.status,
  bo.created_at,
  bo.request_id,
  b.id as build_id,
  b.title as build_title,
  br.status as request_status
FROM builder_offers bo
JOIN build_requests br ON bo.request_id = br.id
JOIN builds b ON br.build_id = b.id
WHERE bo.builder_id = $1
ORDER BY bo.created_at DESC;

-- Query 44: Create builder offer
-- Purpose: Builder submits an offer on a request
INSERT INTO builder_offers (request_id, builder_id, fee, message, suggested_build_id, contact_info)
VALUES ($1, $2, $3, $4, $5, $6)
RETURNING *;

-- Query 45: Accept offer (transaction)
-- Purpose: Requester accepts an offer, it then cascade to rejects all other offers, marks request as claimed
SELECT * FROM builder_offers WHERE id = $1;
SELECT * FROM build_requests WHERE id = $1;
UPDATE builder_offers SET status = 'accepted' WHERE id = $1;
UPDATE builder_offers SET status = 'rejected' WHERE request_id = $1 AND id != $2;
UPDATE build_requests SET status = 'claimed' WHERE id = $1;


-- ------------------------------------------------------------------------------------------
-- USERS QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 46: Get all users (admin only)
-- Purpose: Admin user management list
SELECT id, email, display_name, avatar_url, bio, role, is_banned, created_at 
FROM users 
ORDER BY created_at DESC;

-- Query 47: Get builders list
-- Purpose: Returns all users with builder or admin role for dropdowns
SELECT id, display_name, avatar_url, role FROM users WHERE role IN ('builder', 'admin') ORDER BY display_name;

-- Query 48: Get user by ID (public profile)
-- Purpose: Public profile view
SELECT id, email, display_name, avatar_url, bio, role, is_banned, created_at FROM users WHERE id = $1;

-- Query 49: Update user profile
-- Purpose: User edits their own profile
UPDATE users SET display_name = COALESCE($1, display_name), avatar_url = $2, bio = $3
WHERE id = $4
RETURNING id, email, display_name, avatar_url, bio, role, is_banned, created_at;

-- Query 50: Ban/unban user (admin only)
-- Purpose: Admin can ban problematic users
UPDATE users SET is_banned = $1 WHERE id = $2
RETURNING id, email, display_name, role, is_banned;

-- Query 51: Change user role (admin only)
-- Purpose: Admin can promote/demote users
UPDATE users SET role = $1 WHERE id = $2
RETURNING id, email, display_name, role, is_banned;

-- Query 52: Get builder profile
-- Purpose: Returns extended profile for builders
SELECT * FROM builder_profiles WHERE user_id = $1;

-- Query 53: Update builder profile
-- Purpose: Builder edits their business profile
UPDATE builder_profiles SET business_name=$1, registration_number=$2, address=$3, website=$4, portfolio_url=$5, years_of_experience=$6, specialization=$7
WHERE user_id = $8 RETURNING *;


-- ------------------------------------------------------------------------------------------
-- SHOWCASE INQUIRIES QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 54: Get builder's inquiries (Builder Dashboard)
-- Purpose: Builders see inquiries on their showcase builds
SELECT si.*, u.display_name as user_display_name, b.title as build_title
FROM showcase_inquiries si
JOIN users u ON si.user_id = u.id
JOIN builds b ON si.build_id = b.id
WHERE si.builder_id = $1
ORDER BY si.created_at DESC;

-- Query 55: Create showcase inquiry
-- Purpose: User sends inquiry about a showcase build
INSERT INTO showcase_inquiries (user_id, build_id, builder_id, message)
VALUES ($1, $2, $3, $4)
RETURNING *;


-- ------------------------------------------------------------------------------------------
-- BUILDER APPLICATIONS QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 56: Get applications by status (admin only)
-- Purpose: Admin reviews builder applications filtered by status
SELECT ba.*, u.display_name as user_display_name, u.email as user_email
FROM builder_applications ba
JOIN users u ON ba.user_id = u.id
WHERE ba.status = $1  -- 'pending', 'approved', or 'rejected'
ORDER BY ba.created_at DESC;

-- Query 57: Get my applications
-- Purpose: User checks status of their builder application
SELECT ba.*, u.display_name as user_display_name, u.email as user_email
FROM builder_applications ba
JOIN users u ON ba.user_id = u.id
WHERE ba.user_id = $1
ORDER BY ba.created_at DESC;

-- Query 58: Submit builder application
-- Purpose: User applies to become a verified builder
INSERT INTO builder_applications (user_id, business_name, registration_number, address, website, portfolio_url, years_of_experience, specialization, application_type)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
RETURNING *;

-- Query 59: Approve application (admin only) - transaction
-- Purpose: Admin approves application, creates builder profile, updates user role
-- Step 1: Update application status
UPDATE builder_applications SET status=$1, admin_notes=$2, reviewed_by=$3
WHERE id = $4 RETURNING *;
-- Step 2: Promote user to builder role
UPDATE users SET role = 'builder' WHERE id = $1;
-- Step 3: Create builder profile from application data
INSERT INTO builder_profiles (user_id, business_name, registration_number, address, website, portfolio_url, years_of_experience, specialization)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
ON CONFLICT (user_id) DO NOTHING;

-- Query 60: Reject application (admin only)
-- Purpose: Admin rejects a builder application
UPDATE builder_applications SET status='rejected', admin_notes=$1, reviewed_by=$2
WHERE id = $3 RETURNING *;


-- ------------------------------------------------------------------------------------------
-- COMPATIBILITY QUERIES
-- ------------------------------------------------------------------------------------------

-- Query 61: Get parts for compatibility check
-- Purpose: Retrieves parts selected by user with category info for rule evaluation
SELECT p.*, LOWER(REPLACE(pc.category_name, ' ', '-')) as category_slug
FROM parts p JOIN part_categories pc ON p.category_id = pc.id
WHERE p.id = ANY($1);

-- Query 62: Get active compatibility rules
-- Purpose: Returns all active rules for evaluation during build creation/edit
SELECT * FROM compatibility_rules WHERE is_active = true ORDER BY rule_number;

-- Query 63: Get all compatibility rules (admin only)
-- Purpose: Admin can view all rules including inactive
SELECT * FROM compatibility_rules ORDER BY rule_number;

-- Query 64: Update compatibility rule (admin only)
-- Purpose: Admin can toggle active, change severity, or update message
UPDATE compatibility_rules SET is_active = $1, severity = $2, rule_config = $3, message_template = $4
WHERE id = $5 RETURNING *;

-- Query 65: Create compatibility rule (admin only)
-- Purpose: Admin can create new compatibility rules
INSERT INTO compatibility_rules (rule_number, name, description, severity, rule_config, message_template, is_active)
VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING *;

-- Query 66: Delete compatibility rule (admin only)
-- Purpose: Admin can delete compatibility rules
DELETE FROM compatibility_rules WHERE id = $1;


-- ------------------------------------------------------------------------------------------
-- STATS QUERY
-- ------------------------------------------------------------------------------------------

-- Query 67: Get platform statistics (Homepage)
-- Purpose: Returns counts for homepage stats display
SELECT
  (SELECT COUNT(*) FROM builds WHERE status = 'published')::int as builds,
  (SELECT COUNT(*) FROM parts WHERE is_active = true)::int as parts,
  (SELECT COUNT(*) FROM users WHERE is_banned = false)::int as users,
  (SELECT COUNT(*) FROM build_requests)::int as requests;


-- -----------------------------------------------------------------------------
--  SEED DATA ( These were used to insert sample data into the database)
-- -----------------------------------------------------------------------------
-- ─── Users ────────────────────────────────────────────────────────

-- INSERT INTO users (id, email, password_hash, display_name, avatar_url, bio, role, is_banned) VALUES
--   ('a0000000-0000-0000-0000-000000000001', 'admin@buildboard.com', '$2b$10$placeholder_admin_hash_will_be_set_by_seed_script__', 'Admin', NULL, 'Platform administrator', 'admin', false),
--   ('a0000000-0000-0000-0000-000000000002', 'alice@example.com', '$2b$10$placeholder_user1_hash_will_be_set_by_seed_script__', 'Alice Chen', NULL, 'PC enthusiast and gamer', 'user', false),
--   ('a0000000-0000-0000-0000-000000000003', 'bob@example.com', '$2b$10$placeholder_user2_hash_will_be_set_by_seed_script__', 'Bob Martinez', NULL, 'Content creator looking for the perfect workstation', 'user', false),
--   ('a0000000-0000-0000-0000-000000000004', 'techpro@example.com', '$2b$10$placeholder_build1_hash_will_be_set_by_seed_script', 'TechPro Builds', NULL, 'Professional PC builder with 10+ years experience', 'builder', false),
--   ('a0000000-0000-0000-0000-000000000005', 'elite@example.com', '$2b$10$placeholder_build2_hash_will_be_set_by_seed_script', 'ElitePC Workshop', NULL, 'Custom gaming and workstation builds', 'builder', false);

-- -- ─── Builder Profiles ────────────────────────────────────────────

-- INSERT INTO builder_profiles (id, user_id, business_name, registration_number, address, website, portfolio_url, years_of_experience, specialization, avg_rating, completed_builds, is_verified) VALUES
--   ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000004', 'TechPro Builds', 'BIZ-2024-001', '123 Tech Street, San Jose, CA', 'https://techprobuilds.example.com', 'https://techprobuilds.example.com/portfolio', 10, 'Gaming PCs, Workstations', 4.50, 150, true),
--   ('b0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000005', 'ElitePC Workshop', 'BIZ-2024-002', '456 Builder Ave, Austin, TX', 'https://elitepc.example.com', NULL, 7, 'Custom Gaming, RGB Builds', 4.20, 85, true);

-- -- ─── Part Categories ─────────────────────────────────────────────

-- INSERT INTO part_categories (id, category_name, description, icon) VALUES
--   ('c0000000-0000-0000-0000-000000000001', 'CPU', 'Central Processing Unit', 'cpu'),
--   ('c0000000-0000-0000-0000-000000000002', 'GPU', 'Graphics Processing Unit', 'gpu'),
--   ('c0000000-0000-0000-0000-000000000003', 'Motherboard', 'Motherboard / Mainboard', 'motherboard'),
--   ('c0000000-0000-0000-0000-000000000004', 'RAM', 'Memory', 'ram'),
--   ('c0000000-0000-0000-0000-000000000005', 'Storage', 'SSD / HDD Storage', 'storage'),
--   ('c0000000-0000-0000-0000-000000000006', 'PSU', 'Power Supply Unit', 'psu'),
--   ('c0000000-0000-0000-0000-000000000007', 'Case', 'PC Case / Chassis', 'case'),
--   ('c0000000-0000-0000-0000-000000000008', 'Cooling', 'CPU Cooler', 'cooling');

-- -- ─── Parts ───────────────────────────────────────────────────────

-- -- CPU (5)
-- INSERT INTO parts (id, category_id, name, brand, model, specifications, price, is_active, created_by) VALUES
--   ('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'AMD Ryzen 7 7700X', 'AMD', 'Ryzen 7 7700X',
--    '{"socket":"AM5","cores":8,"threads":16,"base_clock_ghz":4.5,"boost_clock_ghz":5.4,"tdp_watts":105,"integrated_graphics":true}',
--    299.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'AMD Ryzen 5 7600X', 'AMD', 'Ryzen 5 7600X',
--    '{"socket":"AM5","cores":6,"threads":12,"base_clock_ghz":4.7,"boost_clock_ghz":5.3,"tdp_watts":105,"integrated_graphics":true}',
--    199.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', 'Intel Core i7-13700K', 'Intel', 'Core i7-13700K',
--    '{"socket":"LGA1700","cores":16,"threads":24,"base_clock_ghz":3.4,"boost_clock_ghz":5.4,"tdp_watts":125,"integrated_graphics":true}',
--    349.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000001', 'Intel Core i5-13600K', 'Intel', 'Core i5-13600K',
--    '{"socket":"LGA1700","cores":14,"threads":20,"base_clock_ghz":3.5,"boost_clock_ghz":5.1,"tdp_watts":125,"integrated_graphics":true}',
--    264.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000001', 'AMD Ryzen 9 7950X', 'AMD', 'Ryzen 9 7950X',
--    '{"socket":"AM5","cores":16,"threads":32,"base_clock_ghz":4.5,"boost_clock_ghz":5.7,"tdp_watts":170,"integrated_graphics":true}',
--    549.99, true, 'a0000000-0000-0000-0000-000000000001');

-- -- GPU (5)
-- INSERT INTO parts (id, category_id, name, brand, model, specifications, price, is_active, created_by) VALUES
--   ('d0000000-0000-0000-0000-000000000006', 'c0000000-0000-0000-0000-000000000002', 'NVIDIA GeForce RTX 4070', 'NVIDIA', 'RTX 4070',
--    '{"interface":"PCIe 4.0 x16","vram_gb":12,"vram_type":"GDDR6X","length_mm":244,"tdp_watts":200,"recommended_psu_watts":650,"slots_occupied":2.5}',
--    549.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000007', 'c0000000-0000-0000-0000-000000000002', 'NVIDIA GeForce RTX 4080', 'NVIDIA', 'RTX 4080',
--    '{"interface":"PCIe 4.0 x16","vram_gb":16,"vram_type":"GDDR6X","length_mm":304,"tdp_watts":320,"recommended_psu_watts":750,"slots_occupied":3}',
--    1099.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000008', 'c0000000-0000-0000-0000-000000000002', 'AMD Radeon RX 7900 XTX', 'AMD', 'RX 7900 XTX',
--    '{"interface":"PCIe 4.0 x16","vram_gb":24,"vram_type":"GDDR6","length_mm":287,"tdp_watts":355,"recommended_psu_watts":800,"slots_occupied":2.5}',
--    899.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000009', 'c0000000-0000-0000-0000-000000000002', 'NVIDIA GeForce RTX 4060', 'NVIDIA', 'RTX 4060',
--    '{"interface":"PCIe 4.0 x16","vram_gb":8,"vram_type":"GDDR6","length_mm":240,"tdp_watts":115,"recommended_psu_watts":550,"slots_occupied":2}',
--    299.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000010', 'c0000000-0000-0000-0000-000000000002', 'AMD Radeon RX 7800 XT', 'AMD', 'RX 7800 XT',
--    '{"interface":"PCIe 4.0 x16","vram_gb":16,"vram_type":"GDDR6","length_mm":267,"tdp_watts":263,"recommended_psu_watts":700,"slots_occupied":2.5}',
--    449.99, true, 'a0000000-0000-0000-0000-000000000001');

-- -- Motherboard (5)
-- INSERT INTO parts (id, category_id, name, brand, model, specifications, price, is_active, created_by) VALUES
--   ('d0000000-0000-0000-0000-000000000011', 'c0000000-0000-0000-0000-000000000003', 'MSI MAG B650 TOMAHAWK WiFi', 'MSI', 'MAG B650 TOMAHAWK WiFi',
--    '{"socket":"AM5","form_factor":"ATX","chipset":"B650","ram_type":"DDR5","ram_slots":4,"max_ram_gb":128,"m2_slots":2,"pcie_x16_slots":1}',
--    219.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000012', 'c0000000-0000-0000-0000-000000000003', 'Gigabyte X670E AORUS Master', 'Gigabyte', 'X670E AORUS Master',
--    '{"socket":"AM5","form_factor":"ATX","chipset":"X670E","ram_type":"DDR5","ram_slots":4,"max_ram_gb":128,"m2_slots":4,"pcie_x16_slots":2}',
--    399.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000013', 'c0000000-0000-0000-0000-000000000003', 'ASUS ROG Strix Z790-E', 'ASUS', 'ROG Strix Z790-E',
--    '{"socket":"LGA1700","form_factor":"ATX","chipset":"Z790","ram_type":"DDR5","ram_slots":4,"max_ram_gb":128,"m2_slots":5,"pcie_x16_slots":2}',
--    379.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000014', 'c0000000-0000-0000-0000-000000000003', 'MSI MAG B660M Mortar WiFi', 'MSI', 'MAG B660M Mortar WiFi',
--    '{"socket":"LGA1700","form_factor":"mATX","chipset":"B660","ram_type":"DDR5","ram_slots":2,"max_ram_gb":64,"m2_slots":2,"pcie_x16_slots":1}',
--    159.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000015', 'c0000000-0000-0000-0000-000000000003', 'ASUS ROG Strix B650E-I', 'ASUS', 'ROG Strix B650E-I',
--    '{"socket":"AM5","form_factor":"ITX","chipset":"B650E","ram_type":"DDR5","ram_slots":2,"max_ram_gb":64,"m2_slots":2,"pcie_x16_slots":1}',
--    299.99, true, 'a0000000-0000-0000-0000-000000000001');

-- -- RAM (4)
-- INSERT INTO parts (id, category_id, name, brand, model, specifications, price, is_active, created_by) VALUES
--   ('d0000000-0000-0000-0000-000000000016', 'c0000000-0000-0000-0000-000000000004', 'Corsair Vengeance DDR5-6000 32GB', 'Corsair', 'Vengeance DDR5-6000 32GB (2x16GB)',
--    '{"type":"DDR5","speed_mhz":6000,"capacity_gb":16,"modules":2,"total_capacity_gb":32,"cas_latency":30}',
--    109.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000017', 'c0000000-0000-0000-0000-000000000004', 'G.Skill Trident Z5 DDR5-6400 32GB', 'G.Skill', 'Trident Z5 DDR5-6400 32GB (2x16GB)',
--    '{"type":"DDR5","speed_mhz":6400,"capacity_gb":16,"modules":2,"total_capacity_gb":32,"cas_latency":32}',
--    134.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000018', 'c0000000-0000-0000-0000-000000000004', 'Corsair Vengeance DDR5-5600 64GB', 'Corsair', 'Vengeance DDR5-5600 64GB (2x32GB)',
--    '{"type":"DDR5","speed_mhz":5600,"capacity_gb":32,"modules":2,"total_capacity_gb":64,"cas_latency":36}',
--    189.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000019', 'c0000000-0000-0000-0000-000000000004', 'Kingston Fury Beast DDR5-5200 16GB', 'Kingston', 'Fury Beast DDR5-5200 16GB (2x8GB)',
--    '{"type":"DDR5","speed_mhz":5200,"capacity_gb":8,"modules":2,"total_capacity_gb":16,"cas_latency":40}',
--    54.99, true, 'a0000000-0000-0000-0000-000000000001');

-- -- Storage (4)
-- INSERT INTO parts (id, category_id, name, brand, model, specifications, price, is_active, created_by) VALUES
--   ('d0000000-0000-0000-0000-000000000020', 'c0000000-0000-0000-0000-000000000005', 'Samsung 990 Pro 1TB', 'Samsung', '990 Pro 1TB',
--    '{"type":"NVMe","interface":"M.2","capacity_gb":1000,"read_speed_mbps":7450,"write_speed_mbps":6900,"form_factor":"M.2 2280"}',
--    109.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000021', 'c0000000-0000-0000-0000-000000000005', 'WD Black SN850X 2TB', 'Western Digital', 'SN850X 2TB',
--    '{"type":"NVMe","interface":"M.2","capacity_gb":2000,"read_speed_mbps":7300,"write_speed_mbps":6600,"form_factor":"M.2 2280"}',
--    159.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000022', 'c0000000-0000-0000-0000-000000000005', 'Crucial P3 Plus 1TB', 'Crucial', 'P3 Plus 1TB',
--    '{"type":"NVMe","interface":"M.2","capacity_gb":1000,"read_speed_mbps":5000,"write_speed_mbps":4200,"form_factor":"M.2 2280"}',
--    59.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000023', 'c0000000-0000-0000-0000-000000000005', 'Samsung 870 EVO 1TB SATA', 'Samsung', '870 EVO 1TB',
--    '{"type":"SATA","interface":"2.5\"","capacity_gb":1000,"read_speed_mbps":560,"write_speed_mbps":530,"form_factor":"2.5\""}',
--    79.99, true, 'a0000000-0000-0000-0000-000000000001');

-- -- PSU (4)
-- INSERT INTO parts (id, category_id, name, brand, model, specifications, price, is_active, created_by) VALUES
--   ('d0000000-0000-0000-0000-000000000024', 'c0000000-0000-0000-0000-000000000006', 'Corsair RM850x', 'Corsair', 'RM850x',
--    '{"wattage":850,"efficiency_rating":"80+ Gold","modular":"Full","form_factor":"ATX"}',
--    139.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000025', 'c0000000-0000-0000-0000-000000000006', 'EVGA SuperNOVA 1000 G7', 'EVGA', 'SuperNOVA 1000 G7',
--    '{"wattage":1000,"efficiency_rating":"80+ Gold","modular":"Full","form_factor":"ATX"}',
--    179.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000026', 'c0000000-0000-0000-0000-000000000006', 'Seasonic Focus GX-750', 'Seasonic', 'Focus GX-750',
--    '{"wattage":750,"efficiency_rating":"80+ Gold","modular":"Full","form_factor":"ATX"}',
--    109.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000027', 'c0000000-0000-0000-0000-000000000006', 'Corsair SF750 Platinum', 'Corsair', 'SF750 Platinum',
--    '{"wattage":750,"efficiency_rating":"80+ Platinum","modular":"Full","form_factor":"SFX"}',
--    159.99, true, 'a0000000-0000-0000-0000-000000000001');

-- -- Case (4)
-- INSERT INTO parts (id, category_id, name, brand, model, specifications, price, is_active, created_by) VALUES
--   ('d0000000-0000-0000-0000-000000000028', 'c0000000-0000-0000-0000-000000000007', 'Corsair 4000D Airflow', 'Corsair', '4000D Airflow',
--    '{"form_factor":"ATX","supported_motherboards":["ATX","mATX","ITX"],"max_gpu_length_mm":360,"max_cooler_height_mm":170,"max_psu_length_mm":180,"drive_bays_3_5":2,"drive_bays_2_5":2,"included_fans":2,"radiator_support":["120mm","240mm","280mm","360mm"]}',
--    104.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000029', 'c0000000-0000-0000-0000-000000000007', 'Cooler Master NR200P', 'Cooler Master', 'NR200P',
--    '{"form_factor":"ITX","supported_motherboards":["ITX"],"max_gpu_length_mm":330,"max_cooler_height_mm":155,"max_psu_length_mm":130,"drive_bays_3_5":1,"drive_bays_2_5":3,"included_fans":2,"radiator_support":["120mm","240mm","280mm"]}',
--    99.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000030', 'c0000000-0000-0000-0000-000000000007', 'NZXT H7 Flow', 'NZXT', 'H7 Flow',
--    '{"form_factor":"ATX","supported_motherboards":["ATX","mATX","ITX"],"max_gpu_length_mm":400,"max_cooler_height_mm":185,"max_psu_length_mm":200,"drive_bays_3_5":2,"drive_bays_2_5":2,"included_fans":2,"radiator_support":["120mm","240mm","280mm","360mm"]}',
--    129.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000031', 'c0000000-0000-0000-0000-000000000007', 'Lian Li Lancool III', 'Lian Li', 'Lancool III',
--    '{"form_factor":"ATX","supported_motherboards":["ATX","mATX","ITX"],"max_gpu_length_mm":420,"max_cooler_height_mm":187,"max_psu_length_mm":210,"drive_bays_3_5":4,"drive_bays_2_5":6,"included_fans":3,"radiator_support":["120mm","240mm","280mm","360mm"]}',
--    149.99, true, 'a0000000-0000-0000-0000-000000000001');

-- -- Cooling (4)
-- INSERT INTO parts (id, category_id, name, brand, model, specifications, price, is_active, created_by) VALUES
--   ('d0000000-0000-0000-0000-000000000032', 'c0000000-0000-0000-0000-000000000008', 'DeepCool AK620', 'DeepCool', 'AK620',
--    '{"type":"Air","socket_compatibility":["AM5","AM4","LGA1700","LGA1200"],"radiator_size_mm":null,"height_mm":160,"fan_count":2,"tdp_rating_watts":260}',
--    64.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000033', 'c0000000-0000-0000-0000-000000000008', 'Noctua NH-D15', 'Noctua', 'NH-D15',
--    '{"type":"Air","socket_compatibility":["AM5","AM4","LGA1700","LGA1200"],"radiator_size_mm":null,"height_mm":165,"fan_count":2,"tdp_rating_watts":250}',
--    109.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000034', 'c0000000-0000-0000-0000-000000000008', 'NZXT Kraken X63', 'NZXT', 'Kraken X63',
--    '{"type":"AIO","socket_compatibility":["AM5","AM4","LGA1700","LGA1200"],"radiator_size_mm":280,"height_mm":null,"fan_count":2,"tdp_rating_watts":300}',
--    149.99, true, 'a0000000-0000-0000-0000-000000000001'),
--   ('d0000000-0000-0000-0000-000000000035', 'c0000000-0000-0000-0000-000000000008', 'Arctic Liquid Freezer II 360', 'Arctic', 'Liquid Freezer II 360',
--    '{"type":"AIO","socket_compatibility":["AM5","AM4","LGA1700","LGA1200"],"radiator_size_mm":360,"height_mm":null,"fan_count":3,"tdp_rating_watts":350}',
--    119.99, true, 'a0000000-0000-0000-0000-000000000001');

-- -- ─── Builds ──────────────────────────────────────────────────────

-- INSERT INTO builds (id, creator_id, title, description, purpose, total_price, status, build_type, availability_status, image_urls, specs_summary, like_count, rating_avg, rating_count) VALUES
--   ('e0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'Ultimate Gaming Rig', 'High-end gaming build for 1440p gaming at max settings', 'Gaming', 1649.93, 'published', 'personal', NULL, '{}', NULL, 3, 4.50, 2),
--   ('e0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000003', 'Content Creator Workstation', 'Powerful workstation for video editing and 3D rendering', 'Content Creation', 2519.93, 'published', 'personal', NULL, '{}', NULL, 1, 5.00, 1),
--   ('e0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000004', 'ProGamer Elite Build', 'Pre-built high-performance gaming PC ready to ship. Professionally assembled with cable management and stress testing included.', 'Gaming', 1899.93, 'published', 'showcase', 'available', '{}', 'Ryzen 9 7950X / RTX 4080 / 64GB DDR5 / 2TB NVMe', 5, 4.80, 3);

-- -- ─── Build Parts ─────────────────────────────────────────────────

-- -- Gaming build: R7 7700X + RTX 4070 + B650 Tomahawk + Corsair DDR5 32GB + Samsung 990 Pro + RM850x + 4000D + AK620
-- INSERT INTO build_parts (build_id, part_id, quantity) VALUES
--   ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 1),
--   ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000006', 1),
--   ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000011', 1),
--   ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000016', 1),
--   ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000020', 1),
--   ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000024', 1),
--   ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000028', 1),
--   ('e0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000032', 1);

-- -- Workstation: R9 7950X + RTX 4080 + X670E AORUS + DDR5 64GB + SN850X + EVGA 1000G + H7 Flow + Arctic 360
-- INSERT INTO build_parts (build_id, part_id, quantity) VALUES
--   ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000005', 1),
--   ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000007', 1),
--   ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000012', 1),
--   ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000018', 1),
--   ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000021', 1),
--   ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000025', 1),
--   ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000030', 1),
--   ('e0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000035', 1);

-- -- Showcase: R9 7950X + RTX 4080 + X670E AORUS + DDR5 64GB + SN850X + EVGA 1000G + Lancool III + Arctic 360
-- INSERT INTO build_parts (build_id, part_id, quantity) VALUES
--   ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000005', 1),
--   ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000007', 1),
--   ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000012', 1),
--   ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000018', 1),
--   ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000021', 1),
--   ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000025', 1),
--   ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000031', 1),
--   ('e0000000-0000-0000-0000-000000000003', 'd0000000-0000-0000-0000-000000000035', 1);

-- -- ─── Ratings ─────────────────────────────────────────────────────

-- INSERT INTO ratings (user_id, build_id, score, review_text) VALUES
--   ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', 5, 'Excellent build! Great part selection for gaming.'),
--   ('a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000001', 4, 'Solid choices. Would suggest a beefier cooler for the 7700X though.'),
--   ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002', 5, 'Perfect for content creation workflows!'),
--   ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000003', 5, 'TechPro delivers quality as always.'),
--   ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000003', 5, 'Amazing pre-built, incredible value.'),
--   ('a0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000003', 4, 'Nice build, would have gone with a bigger case though.');

-- -- ─── Comments ────────────────────────────────────────────────────

-- INSERT INTO comments (id, user_id, build_id, parent_comment_id, content) VALUES
--   ('f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001', NULL, 'What FPS are you getting in AAA titles at 1440p?'),
--   ('f0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000001', 'f0000000-0000-0000-0000-000000000001', 'Getting 100-140 FPS in most titles at max settings!'),
--   ('f0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000003', NULL, 'How long does shipping typically take?'),
--   ('f0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000003', 'f0000000-0000-0000-0000-000000000003', 'Usually 5-7 business days after order confirmation.');

-- -- ─── Likes ───────────────────────────────────────────────────────

-- INSERT INTO likes (user_id, build_id) VALUES
--   ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000001'),
--   ('a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000001'),
--   ('a0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000001'),
--   ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000002'),
--   ('a0000000-0000-0000-0000-000000000002', 'e0000000-0000-0000-0000-000000000003'),
--   ('a0000000-0000-0000-0000-000000000003', 'e0000000-0000-0000-0000-000000000003'),
--   ('a0000000-0000-0000-0000-000000000005', 'e0000000-0000-0000-0000-000000000003'),
--   ('a0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000003'),
--   ('a0000000-0000-0000-0000-000000000004', 'e0000000-0000-0000-0000-000000000003');

-- -- ─── Compatibility Rules ─────────────────────────────────────────

-- INSERT INTO compatibility_rules (rule_number, name, severity, rule_config, message_template) VALUES
--   (1, 'CPU-Motherboard Socket Match', 'error',
--    '{"type":"field_match","part_a":"cpu","part_b":"motherboard","field_a":"socket","field_b":"socket"}',
--    'CPU socket ({a}) does not match motherboard socket ({b})'),

--   (2, 'RAM-Motherboard Type Match', 'error',
--    '{"type":"field_match","part_a":"ram","part_b":"motherboard","field_a":"type","field_b":"ram_type"}',
--    'RAM type ({a}) does not match motherboard RAM type ({b})'),

--   (3, 'RAM Modules vs Motherboard Slots', 'error',
--    '{"type":"field_lte","part_a":"ram","part_b":"motherboard","field_a":"modules","field_b":"ram_slots"}',
--    'RAM modules ({a}) exceeds motherboard RAM slots ({b})'),

--   (4, 'RAM Capacity vs Motherboard Max', 'error',
--    '{"type":"field_lte","part_a":"ram","part_b":"motherboard","field_a":"total_capacity_gb","field_b":"max_ram_gb"}',
--    'RAM capacity ({a}GB) exceeds motherboard max ({b}GB)'),

--   (5, 'Motherboard Form Factor vs Case', 'error',
--    '{"type":"array_contains","part_a":"motherboard","part_b":"case","field_a":"form_factor","field_b":"supported_motherboards"}',
--    'Motherboard form factor ({a}) is not supported by case (supports: {b})'),

--   (6, 'GPU Length vs Case Max', 'error',
--    '{"type":"field_lte","part_a":"gpu","part_b":"case","field_a":"length_mm","field_b":"max_gpu_length_mm"}',
--    'GPU length ({a}mm) exceeds case max GPU length ({b}mm)'),

--   (7, 'Cooler Socket Compatibility', 'error',
--    '{"type":"array_contains","part_a":"cpu","part_b":"cooling","field_a":"socket","field_b":"socket_compatibility"}',
--    'Cooler does not support CPU socket ({a}). Supported: {b}'),

--   (8, 'Air Cooler Height vs Case Max', 'error',
--    '{"type":"field_lte","part_a":"cooling","part_b":"case","field_a":"height_mm","field_b":"max_cooler_height_mm","condition":{"part":"cooling","field":"type","equals":"Air"}}',
--    'Cooler height ({a}mm) exceeds case max cooler height ({b}mm)'),

--   (9, 'AIO Radiator vs Case Support', 'error',
--    '{"type":"array_contains_formatted","part_a":"cooling","part_b":"case","field_a":"radiator_size_mm","field_b":"radiator_support","format":"{value}mm","condition":{"part":"cooling","field":"type","equals":"AIO"}}',
--    'AIO radiator size ({a}) is not supported by case (supports: {b})'),

--   (10, 'PSU Wattage vs Total TDP', 'warning',
--    '{"type":"sum_gte","target_part":"psu","target_field":"wattage","sum_fields":[{"part":"cpu","field":"tdp_watts"},{"part":"gpu","field":"tdp_watts"}],"multiplier":1.2}',
--    'PSU wattage ({a}W) may be insufficient. Recommended: {b}W+ (total TDP x 1.2)'),

--   (11, 'PSU-Case Form Factor', 'warning',
--    '{"type":"pair_mismatch","part_a":"psu","part_b":"case","field_a":"form_factor","field_b":"form_factor","pairs":[{"a":"ATX","b":"ITX","msg":"ATX PSU may not fit in ITX case. Consider an SFX power supply."},{"a":"SFX","b":"ATX","msg":"SFX PSU in ATX case — make sure you have an SFX-to-ATX bracket."}]}',
--    'PSU/Case form factor mismatch'),

--   (12, 'M.2 Storage vs Motherboard Slots', 'error',
--    '{"type":"field_lte","part_a":"storage","part_b":"motherboard","field_a":"_m2_count","field_b":"m2_slots","condition":{"part":"storage","field":"interface","equals":"M.2"}}',
--    'M.2 storage count ({a}) exceeds motherboard M.2 slots ({b})');
