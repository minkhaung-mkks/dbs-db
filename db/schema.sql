
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- Enable pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─── ENUM Types ────────────────────────────────────────────────────

CREATE TYPE user_role AS ENUM ('user', 'builder', 'admin');
CREATE TYPE build_status AS ENUM ('draft', 'published');
CREATE TYPE build_type AS ENUM ('personal', 'showcase');
CREATE TYPE availability_status AS ENUM ('available', 'sold_out', 'discontinued');
CREATE TYPE request_status AS ENUM ('open', 'claimed', 'in_progress', 'completed', 'cancelled');
CREATE TYPE offer_status AS ENUM ('pending', 'accepted', 'rejected');
CREATE TYPE application_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE application_type AS ENUM ('business', 'individual');
CREATE TYPE inquiry_status AS ENUM ('pending', 'accepted', 'declined');

-- ─── Tables ────────────────────────────────────────────────────────

-- 1. users
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

-- 2. builder_profiles
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

-- 3. builder_applications
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

-- 4. part_categories
CREATE TABLE part_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  icon VARCHAR(50)
);

-- 5. parts
CREATE TABLE parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id UUID NOT NULL REFERENCES part_categories(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  brand VARCHAR(100) NOT NULL,
  model VARCHAR(200) NOT NULL,
  specifications JSONB NOT NULL DEFAULT '{}',
  price DECIMAL(10,2) NOT NULL,
  image_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parts_category ON parts(category_id);
CREATE INDEX idx_parts_active ON parts(is_active);

-- 6. builds
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

-- 7. build_parts (junction table)
CREATE TABLE build_parts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  build_id UUID NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  part_id UUID NOT NULL REFERENCES parts(id),
  quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
  UNIQUE (build_id, part_id)
);

CREATE INDEX idx_build_parts_build ON build_parts(build_id);
CREATE INDEX idx_build_parts_part ON build_parts(part_id);

-- 8. build_requests
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

-- 9. builder_offers
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

-- 10. showcase_inquiries
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

-- 11. ratings
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

-- 12. comments
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

-- 13. likes
CREATE TABLE likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  build_id UUID NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, build_id)
);

CREATE INDEX idx_likes_build ON likes(build_id);

-- 14. compatibility_rules
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