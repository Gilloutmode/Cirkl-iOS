-- ============================================
-- CIRKL iOS - Supabase Database Schema
-- Version: 1.0
-- Date: 2026-01-11
-- ============================================

-- Enable UUID extension (usually already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- Stores user profile information
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    auth_id TEXT UNIQUE NOT NULL,  -- Links to Supabase Auth
    email TEXT NOT NULL,
    name TEXT NOT NULL DEFAULT 'User',
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster auth lookups
CREATE INDEX IF NOT EXISTS idx_users_auth_id ON users(auth_id);

-- ============================================
-- USER PREFERENCES TABLE
-- Stores user settings and preferences
-- ============================================
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    morning_brief_time TEXT DEFAULT '07:30',
    morning_brief_enabled BOOLEAN DEFAULT true,
    language TEXT DEFAULT 'en',
    notifications_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- One preference set per user
    UNIQUE(user_id)
);

-- Index for faster user lookups
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Ensures users can only access their own data
-- ============================================

-- Enable RLS on both tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid()::text = auth_id);

CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid()::text = auth_id);

CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid()::text = auth_id);

-- User preferences policies
CREATE POLICY "Users can view own preferences"
    ON user_preferences FOR SELECT
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()::text));

CREATE POLICY "Users can update own preferences"
    ON user_preferences FOR UPDATE
    USING (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()::text));

CREATE POLICY "Users can insert own preferences"
    ON user_preferences FOR INSERT
    WITH CHECK (user_id IN (SELECT id FROM users WHERE auth_id = auth.uid()::text));

-- ============================================
-- AUTOMATIC UPDATED_AT TRIGGER
-- Automatically updates updated_at column
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to users table
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to user_preferences table
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;
CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUTURE TABLES (commented for now)
-- ============================================

-- OAuth Tokens (for LinkedIn integration)
-- CREATE TABLE IF NOT EXISTS oauth_tokens (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     provider TEXT NOT NULL,  -- 'linkedin', 'google', etc.
--     access_token TEXT NOT NULL,
--     refresh_token TEXT,
--     expires_at TIMESTAMPTZ,
--     created_at TIMESTAMPTZ DEFAULT NOW(),
--     updated_at TIMESTAMPTZ DEFAULT NOW(),
--     UNIQUE(user_id, provider)
-- );

-- Device Tokens (for push notifications)
-- CREATE TABLE IF NOT EXISTS device_tokens (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--     token TEXT NOT NULL,
--     platform TEXT NOT NULL DEFAULT 'ios',
--     is_active BOOLEAN DEFAULT true,
--     created_at TIMESTAMPTZ DEFAULT NOW(),
--     UNIQUE(user_id, token)
-- );

-- ============================================
-- VERIFICATION
-- ============================================
-- Run these queries to verify the schema:

-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users';
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'user_preferences';
