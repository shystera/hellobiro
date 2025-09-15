# Direct Upload Setup Guide

This implementation provides a clean, straightforward course creation flow with direct Mux uploads.

## Architecture Overview

```
Frontend → Backend API → Mux API (get upload URL)
Frontend → Mux (direct upload)
Mux → Backend (webhook) → Supabase (update lesson)
```

## Setup Steps

### 1. Database Setup

Run the schema:
```sql
-- Run supabase-lessons-schema.sql in your Supabase SQL editor
```

### 2. Environment Variables

Copy and configure:
```bash
cp .env.example .env
```

Fill in your credentials:
- `MUX_TOKEN_ID` and `MUX_TOKEN_SECRET` from Mux dashboard
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` for frontend
- `SUPABASE_SERVICE_KEY` for backend operations

### 3. Mux Webhook Setup

1. Go to Mux Dashboard → Settings → Webhooks
2. Add webhook URL: `https://your-domain.com/api/mux/webhook`
3. Select events:
   - `video.upload.asset_created`
   - `video.upload.errored`

For local development, use ngrok:
```bash
ngrok http 3001
# Use the ngrok URL: https://abc123.ngrok.io/api/mux/webhook
```

### 4. Start the Application

```bash
npm install
npm start
```

This starts:
- Frontend on http://localhost:5173
- Backend API on http://localhost:3001

## How It Works

### Course Creation Flow

1. **Create Lesson**: Frontend creates lesson record in Supabase
2. **Get Upload URL**: Backend requests signed upload URL from Mux
3. **Direct Upload**: Frontend uploads video directly to Mux
4. **Webhook Processing**: Mux notifies backend when video is ready
5. **Update Database**: Backend updates lesson with playback_id

### Student Viewing Flow

1. **Load Course**: Fetch course modules and lessons from Supabase
2. **Render Player**: Use Mux Player with stored playback_id
3. **Seamless Playback**: Global CDN delivery with adaptive streaming

## API Endpoints

### Backend API (`mux-upload-api.js`)

- `POST /api/mux/upload-url` - Get direct upload URL
- `POST /api/mux/webhook` - Handle Mux webhooks
- `POST /api/lessons` - Create lesson
- `GET /api/modules/:id/lessons` - Get lessons for module

### Database Schema

```sql
lessons (
  id UUID PRIMARY KEY,
  module_id UUID REFERENCES modules(id),
  title TEXT NOT NULL,
  description TEXT,
  mux_asset_id TEXT,
  mux_playback_id TEXT,
  mux_upload_id TEXT,
  upload_status TEXT DEFAULT 'pending',
  duration INTEGER,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
)
```

## Testing

### 1. Test Direct Upload
```bash
# Open test-mux-uploader.html
# Upload a video file
# Check Mux dashboard for asset
```

### 2. Test Course Creation
```bash
# Open create-course-step1.html
# Create course with modules and lessons
# Upload videos for lessons
# Check Supabase for lesson records
```

### 3. Test Student View
```bash
# Open lesson-viewer.html?course_id=YOUR_COURSE_ID
# Should show lessons list and video player
```

## Production Considerations

1. **Security**: Change playback_policy to 'signed' for protected content
2. **Webhooks**: Use HTTPS endpoint with proper authentication
3. **Error Handling**: Implement retry logic for failed uploads
4. **Progress Tracking**: Add real-time upload progress updates
5. **File Validation**: Validate file types and sizes before upload

## Troubleshooting

### Upload Fails
- Check Mux credentials in .env
- Verify CORS origin in upload URL request
- Check browser network tab for errors

### Webhook Not Working
- Verify webhook URL is accessible
- Check Mux dashboard webhook logs
- Ensure proper event types are selected

### Video Not Playing
- Check if lesson has mux_playback_id
- Verify upload_status is 'ready'
- Check Mux Player console errors

## Benefits of This Approach

✅ **Direct Upload**: No proxy, faster uploads
✅ **Scalable**: Mux handles all video processing
✅ **Secure**: Signed URLs prevent unauthorized uploads
✅ **Real-time**: Webhooks update status immediately
✅ **Simple**: Clean separation of concerns
✅ **Production Ready**: Built for scale with proper error handling