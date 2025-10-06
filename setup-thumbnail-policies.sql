-- RLS Policies for thumbnails bucket
-- Only run this AFTER creating the thumbnails bucket
-- If you get permission errors, set up policies in the Supabase Dashboard instead

-- Allow only coaches to upload thumbnails
CREATE POLICY "coaches_can_upload_thumbnails" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'thumbnails' 
  AND auth.role() = 'authenticated'
  AND EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'coach'
  )
);

-- Allow public read access to thumbnails
CREATE POLICY "public_can_view_thumbnails" ON storage.objects
FOR SELECT USING (bucket_id = 'thumbnails');

-- Allow only coaches to update thumbnails
CREATE POLICY "coaches_can_update_thumbnails" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'thumbnails' 
  AND auth.role() = 'authenticated'
  AND EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'coach'
  )
);

-- Allow only coaches to delete thumbnails
CREATE POLICY "coaches_can_delete_thumbnails" ON storage.objects
FOR DELETE USING (
  bucket_id = 'thumbnails' 
  AND auth.role() = 'authenticated'
  AND EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'coach'
  )
);