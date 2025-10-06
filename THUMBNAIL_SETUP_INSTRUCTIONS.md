# Thumbnail Bucket Setup Instructions

Since you're getting permission errors with SQL, follow these steps to set up the thumbnails bucket manually in the Supabase Dashboard:

## Step 1: Create the Bucket

1. Go to your Supabase Dashboard
2. Navigate to **Storage** in the left sidebar
3. Click **"New bucket"**
4. Fill in the details:
   - **Name**: `thumbnails`
   - **Public bucket**: ✅ **Yes** (checked)
   - **File size limit**: `5242880` (5MB)
   - **Allowed MIME types**: 
     ```
     image/jpeg
     image/png
     image/webp
     image/gif
     ```
5. Click **"Save"**

## Step 2: Set Up RLS Policies

1. Still in **Storage**, click on your new **thumbnails** bucket
2. Go to the **"Policies"** tab
3. Click **"New policy"** and create these 4 policies:

### Policy 1: Allow coaches to upload
- **Policy name**: `coaches_can_upload_thumbnails`
- **Allowed operation**: `INSERT`
- **Policy definition**:
  ```sql
  auth.role() = 'authenticated' AND EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'coach'
  )
  ```

### Policy 2: Allow everyone to view
- **Policy name**: `public_can_view_thumbnails`
- **Allowed operation**: `SELECT`
- **Policy definition**:
  ```sql
  true
  ```

### Policy 3: Allow coaches to update
- **Policy name**: `coaches_can_update_thumbnails`
- **Allowed operation**: `UPDATE`
- **Policy definition**:
  ```sql
  auth.role() = 'authenticated' AND EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'coach'
  )
  ```

### Policy 4: Allow coaches to delete
- **Policy name**: `coaches_can_delete_thumbnails`
- **Allowed operation**: `DELETE`
- **Policy definition**:
  ```sql
  auth.role() = 'authenticated' AND EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE profiles.id = auth.uid() 
    AND profiles.role = 'coach'
  )
  ```

## Step 3: Test the Setup

1. Open `test-thumbnail-upload.html` in your browser
2. Log in as a coach
3. Try uploading an image
4. Verify that students can view the uploaded thumbnails but cannot upload

## Alternative: Simple Setup (Less Secure)

If the above is too complex, you can create a simpler setup:

1. Create the bucket as **public** (step 1 above)
2. Don't add any custom policies - just use the default public access
3. Handle permissions in your JavaScript code only

This is less secure but easier to set up for development/testing.