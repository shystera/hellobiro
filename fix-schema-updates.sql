-- Fix for missing columns and Mux integration
-- Run this in your Supabase SQL Editor

-- Add missing estimated_duration column to courses table
ALTER TABLE courses ADD COLUMN IF NOT EXISTS estimated_duration INTEGER DEFAULT 0;

-- Add Mux-related columns to lessons table if they don't exist
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS mux_asset_id TEXT;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS mux_playback_id TEXT;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS video_url TEXT;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS upload_status TEXT DEFAULT 'pending';

-- Create enum for upload status if it doesn't exist
DO $$ BEGIN
    CREATE TYPE upload_status AS ENUM ('pending', 'uploading', 'processing', 'ready', 'error');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Update lessons table to use the enum
ALTER TABLE lessons ALTER COLUMN upload_status TYPE upload_status USING upload_status::upload_status;

-- Add video storage bucket policy if not exists
INSERT INTO storage.buckets (id, name, public) 
VALUES ('lesson-videos', 'lesson-videos', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for lesson videos
DO $$ BEGIN
    -- Policy for coaches to upload videos
    CREATE POLICY "Coaches can upload lesson videos" ON storage.objects
        FOR INSERT WITH CHECK (
            bucket_id = 'lesson-videos' AND
            auth.role() = 'authenticated'
        );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    -- Policy for coaches to view their videos
    CREATE POLICY "Coaches can view their lesson videos" ON storage.objects
        FOR SELECT USING (
            bucket_id = 'lesson-videos' AND
            auth.role() = 'authenticated'
        );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    -- Policy for coaches to update their videos
    CREATE POLICY "Coaches can update their lesson videos" ON storage.objects
        FOR UPDATE USING (
            bucket_id = 'lesson-videos' AND
            auth.role() = 'authenticated'
        );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    -- Policy for coaches to delete their videos
    CREATE POLICY "Coaches can delete their lesson videos" ON storage.objects
        FOR DELETE USING (
            bucket_id = 'lesson-videos' AND
            auth.role() = 'authenticated'
        );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;