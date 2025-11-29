-- Find Me A Coffee - Database Schema
-- Run this in your Supabase SQL Editor

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLES
-- ============================================

-- Users (customers who collect stamps)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(15) UNIQUE NOT NULL,
  name VARCHAR(100),
  email VARCHAR(255),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cafe Owners (people who manage cafes)
CREATE TABLE cafe_owners (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(100),
  phone VARCHAR(15),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Cafes
CREATE TABLE cafes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id UUID REFERENCES cafe_owners(id) ON DELETE CASCADE,
  name VARCHAR(200) NOT NULL,
  address TEXT,
  city VARCHAR(100),
  latitude DECIMAL(10, 8),
  longitude DECIMAL(11, 8),
  logo_url TEXT,
  nfc_tag_id VARCHAR(100) UNIQUE,
  qr_code_url TEXT,
  stamps_required INT DEFAULT 10 CHECK (stamps_required > 0 AND stamps_required <= 20),
  reward_description TEXT DEFAULT 'Free coffee',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stamps (each stamp collected by a user at a cafe)
CREATE TABLE stamps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  cafe_id UUID REFERENCES cafes(id) ON DELETE CASCADE,
  stamped_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Redemptions (when user claims a reward)
CREATE TABLE redemptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  cafe_id UUID REFERENCES cafes(id) ON DELETE CASCADE,
  stamps_used INT NOT NULL,
  reward_description TEXT NOT NULL,
  redemption_code VARCHAR(20) UNIQUE NOT NULL,
  is_claimed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  claimed_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL
);

-- ============================================
-- INDEXES
-- ============================================

CREATE INDEX idx_stamps_user_cafe ON stamps(user_id, cafe_id);
CREATE INDEX idx_stamps_cafe ON stamps(cafe_id);
CREATE INDEX idx_stamps_stamped_at ON stamps(stamped_at);
CREATE INDEX idx_redemptions_user ON redemptions(user_id);
CREATE INDEX idx_redemptions_cafe ON redemptions(cafe_id);
CREATE INDEX idx_redemptions_code ON redemptions(redemption_code);
CREATE INDEX idx_cafes_location ON cafes(latitude, longitude);
CREATE INDEX idx_cafes_city ON cafes(city);
CREATE INDEX idx_cafes_nfc ON cafes(nfc_tag_id);
CREATE INDEX idx_cafes_active ON cafes(is_active);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Get stamp summary for a specific cafe and user
CREATE OR REPLACE FUNCTION get_stamp_summary_for_cafe(p_user_id UUID, p_cafe_id UUID)
RETURNS TABLE (
  cafe_id UUID,
  cafe_name VARCHAR,
  cafe_logo_url TEXT,
  stamp_count BIGINT,
  stamps_required INT,
  reward_description TEXT,
  last_stamped_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id AS cafe_id,
    c.name AS cafe_name,
    c.logo_url AS cafe_logo_url,
    COUNT(s.id) AS stamp_count,
    c.stamps_required,
    c.reward_description,
    MAX(s.stamped_at) AS last_stamped_at
  FROM cafes c
  LEFT JOIN stamps s ON s.cafe_id = c.id AND s.user_id = p_user_id
  WHERE c.id = p_cafe_id AND c.is_active = true
  GROUP BY c.id, c.name, c.logo_url, c.stamps_required, c.reward_description;
END;
$$ LANGUAGE plpgsql;

-- Get all stamp summaries for a user
CREATE OR REPLACE FUNCTION get_user_stamp_summaries(p_user_id UUID)
RETURNS TABLE (
  cafe_id UUID,
  cafe_name VARCHAR,
  cafe_logo_url TEXT,
  stamp_count BIGINT,
  stamps_required INT,
  reward_description TEXT,
  last_stamped_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id AS cafe_id,
    c.name AS cafe_name,
    c.logo_url AS cafe_logo_url,
    COUNT(s.id) AS stamp_count,
    c.stamps_required,
    c.reward_description,
    MAX(s.stamped_at) AS last_stamped_at
  FROM stamps s
  JOIN cafes c ON c.id = s.cafe_id
  WHERE s.user_id = p_user_id AND c.is_active = true
  GROUP BY c.id, c.name, c.logo_url, c.stamps_required, c.reward_description
  ORDER BY MAX(s.stamped_at) DESC;
END;
$$ LANGUAGE plpgsql;

-- Get nearby cafes using Haversine formula
CREATE OR REPLACE FUNCTION get_nearby_cafes(
  p_latitude DECIMAL,
  p_longitude DECIMAL,
  p_radius_km DECIMAL DEFAULT 5.0,
  p_limit INT DEFAULT 50
)
RETURNS TABLE (
  id UUID,
  name VARCHAR,
  address TEXT,
  city VARCHAR,
  latitude DECIMAL,
  longitude DECIMAL,
  logo_url TEXT,
  stamps_required INT,
  reward_description TEXT,
  distance_km DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    c.address,
    c.city,
    c.latitude,
    c.longitude,
    c.logo_url,
    c.stamps_required,
    c.reward_description,
    (
      6371 * acos(
        cos(radians(p_latitude)) * cos(radians(c.latitude)) *
        cos(radians(c.longitude) - radians(p_longitude)) +
        sin(radians(p_latitude)) * sin(radians(c.latitude))
      )
    )::DECIMAL AS distance_km
  FROM cafes c
  WHERE c.is_active = true
    AND c.latitude IS NOT NULL
    AND c.longitude IS NOT NULL
    AND (
      6371 * acos(
        cos(radians(p_latitude)) * cos(radians(c.latitude)) *
        cos(radians(c.longitude) - radians(p_longitude)) +
        sin(radians(p_latitude)) * sin(radians(c.latitude))
      )
    ) <= p_radius_km
  ORDER BY distance_km
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Get cafes where user has stamps
CREATE OR REPLACE FUNCTION get_cafes_with_user_stamps(p_user_id UUID)
RETURNS TABLE (
  id UUID,
  name VARCHAR,
  address TEXT,
  city VARCHAR,
  latitude DECIMAL,
  longitude DECIMAL,
  logo_url TEXT,
  stamps_required INT,
  reward_description TEXT,
  user_stamp_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    c.address,
    c.city,
    c.latitude,
    c.longitude,
    c.logo_url,
    c.stamps_required,
    c.reward_description,
    COUNT(s.id) AS user_stamp_count
  FROM cafes c
  JOIN stamps s ON s.cafe_id = c.id
  WHERE s.user_id = p_user_id AND c.is_active = true
  GROUP BY c.id
  ORDER BY MAX(s.stamped_at) DESC;
END;
$$ LANGUAGE plpgsql;

-- Get cafe stats for dashboard
CREATE OR REPLACE FUNCTION get_cafe_stats(p_cafe_id UUID)
RETURNS TABLE (
  total_stamps BIGINT,
  total_redemptions BIGINT,
  active_customers BIGINT,
  stamps_today BIGINT,
  stamps_this_week BIGINT,
  stamps_this_month BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM stamps WHERE cafe_id = p_cafe_id) AS total_stamps,
    (SELECT COUNT(*) FROM redemptions WHERE cafe_id = p_cafe_id AND is_claimed = true) AS total_redemptions,
    (SELECT COUNT(DISTINCT user_id) FROM stamps WHERE cafe_id = p_cafe_id AND stamped_at > NOW() - INTERVAL '30 days') AS active_customers,
    (SELECT COUNT(*) FROM stamps WHERE cafe_id = p_cafe_id AND stamped_at > NOW() - INTERVAL '1 day') AS stamps_today,
    (SELECT COUNT(*) FROM stamps WHERE cafe_id = p_cafe_id AND stamped_at > NOW() - INTERVAL '7 days') AS stamps_this_week,
    (SELECT COUNT(*) FROM stamps WHERE cafe_id = p_cafe_id AND stamped_at > NOW() - INTERVAL '30 days') AS stamps_this_month;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE cafe_owners ENABLE ROW LEVEL SECURITY;
ALTER TABLE cafes ENABLE ROW LEVEL SECURITY;
ALTER TABLE stamps ENABLE ROW LEVEL SECURITY;
ALTER TABLE redemptions ENABLE ROW LEVEL SECURITY;

-- Users can only read/update their own data
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Cafe owners can only manage their own data
CREATE POLICY "Cafe owners can view own data" ON cafe_owners
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Cafe owners can update own data" ON cafe_owners
  FOR UPDATE USING (auth.uid() = id);

-- Cafes - public read, owner write
CREATE POLICY "Anyone can view active cafes" ON cafes
  FOR SELECT USING (is_active = true);

CREATE POLICY "Owners can manage own cafes" ON cafes
  FOR ALL USING (owner_id = auth.uid());

-- Stamps - users can view own, insert own
CREATE POLICY "Users can view own stamps" ON stamps
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own stamps" ON stamps
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Cafe owners can view stamps for their cafes
CREATE POLICY "Cafe owners can view cafe stamps" ON stamps
  FOR SELECT USING (
    cafe_id IN (SELECT id FROM cafes WHERE owner_id = auth.uid())
  );

-- Redemptions - users can view/insert own
CREATE POLICY "Users can view own redemptions" ON redemptions
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own redemptions" ON redemptions
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Cafe owners can view/update redemptions for their cafes
CREATE POLICY "Cafe owners can view cafe redemptions" ON redemptions
  FOR SELECT USING (
    cafe_id IN (SELECT id FROM cafes WHERE owner_id = auth.uid())
  );

CREATE POLICY "Cafe owners can update cafe redemptions" ON redemptions
  FOR UPDATE USING (
    cafe_id IN (SELECT id FROM cafes WHERE owner_id = auth.uid())
  );

-- ============================================
-- SAMPLE DATA (for testing)
-- ============================================

-- Insert sample cafes in Delhi (run this only for testing)
/*
INSERT INTO cafe_owners (id, email, name, phone) VALUES
  ('00000000-0000-0000-0000-000000000001', 'demo@example.com', 'Demo Owner', '9876543210');

INSERT INTO cafes (owner_id, name, address, city, latitude, longitude, stamps_required, reward_description, nfc_tag_id) VALUES
  ('00000000-0000-0000-0000-000000000001', 'Blue Tokai Coffee', 'Hauz Khas Village, New Delhi', 'Delhi', 28.5494, 77.1957, 10, 'Free Americano', 'DEMO-001'),
  ('00000000-0000-0000-0000-000000000001', 'Third Wave Coffee', 'Shahpur Jat, New Delhi', 'Delhi', 28.5673, 77.2156, 8, 'Free Cold Brew', 'DEMO-002'),
  ('00000000-0000-0000-0000-000000000001', 'Cafe Dori', 'Champa Gali, New Delhi', 'Delhi', 28.5315, 77.1893, 10, 'Free Latte', 'DEMO-003'),
  ('00000000-0000-0000-0000-000000000001', 'Perch Wine & Coffee', 'Khan Market, New Delhi', 'Delhi', 28.6002, 77.2271, 12, 'Free Cappuccino', 'DEMO-004'),
  ('00000000-0000-0000-0000-000000000001', 'Sleepy Owl Coffee', 'Connaught Place, New Delhi', 'Delhi', 28.6315, 77.2167, 10, 'Free Cold Coffee', 'DEMO-005');
*/
