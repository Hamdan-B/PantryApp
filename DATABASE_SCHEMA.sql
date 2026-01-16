-- Pantry App Database Schema for Supabase
-- Run these SQL queries in your Supabase SQL editor

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies for users table
CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Pantry Items table
CREATE TABLE pantry_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  weight DECIMAL(10, 2) NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  unit TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX pantry_items_user_id_idx ON pantry_items(user_id);
CREATE INDEX pantry_items_category_idx ON pantry_items(category);

-- Enable RLS for pantry_items table
ALTER TABLE pantry_items ENABLE ROW LEVEL SECURITY;

-- Create policies for pantry_items table
CREATE POLICY "Users can view their own pantry items"
  ON pantry_items FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own pantry items"
  ON pantry_items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own pantry items"
  ON pantry_items FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own pantry items"
  ON pantry_items FOR DELETE
  USING (auth.uid() = user_id);

-- Planner table
CREATE TABLE planner (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  meal_type TEXT NOT NULL,
  dish_name TEXT NOT NULL,
  recipe_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX planner_user_id_idx ON planner(user_id);
CREATE INDEX planner_date_idx ON planner(date);

-- Enable RLS for planner table
ALTER TABLE planner ENABLE ROW LEVEL SECURITY;

-- Create policies for planner table
CREATE POLICY "Users can view their own planned meals"
  ON planner FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own planned meals"
  ON planner FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own planned meals"
  ON planner FOR DELETE
  USING (auth.uid() = user_id);

-- Usage Logs table
CREATE TABLE usage_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES pantry_items(id) ON DELETE CASCADE,
  item_name TEXT NOT NULL,
  category TEXT NOT NULL,
  weight_used DECIMAL(10, 2) NOT NULL,
  price_used DECIMAL(10, 2) NOT NULL,
  unit TEXT NOT NULL,
  used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX usage_logs_user_id_idx ON usage_logs(user_id);
CREATE INDEX usage_logs_used_at_idx ON usage_logs(used_at);
CREATE INDEX usage_logs_category_idx ON usage_logs(category);

-- Enable RLS for usage_logs table
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

-- Create policies for usage_logs table
CREATE POLICY "Users can view their own usage logs"
  ON usage_logs FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own usage logs"
  ON usage_logs FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create storage bucket for user avatars
-- Note: You'll need to do this in the Supabase console UI
-- Create bucket named: user-avatars
-- Set public access to ON

-- Set up bucket policies via SQL (optional)
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('user-avatars', 'user-avatars', true)
-- ON CONFLICT (id) DO NOTHING;

-- Auth trigger to create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
