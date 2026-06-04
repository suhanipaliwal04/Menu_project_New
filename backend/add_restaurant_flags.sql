-- SQL Script to add Operational settings to Restaurants table

ALTER TABLE restaurants 
ADD COLUMN IF NOT EXISTS has_dine_in BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS has_takeaway BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS is_open_manually BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS opening_time TIME,
ADD COLUMN IF NOT EXISTS closing_time TIME;

-- You can run this directly in the Supabase SQL Editor.
