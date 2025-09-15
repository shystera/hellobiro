# Full Mux + Supabase Integration Setup

This guide will help you set up the complete video upload and playback system with Mux hosting and Supabase storage.

## 🚀 Quick Start

### 1. Set up Supabase

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Once created, go to Settings → API
3. Copy your project URL and keys
4. Update your `.env` file:

```env
# Mux API Credentials (already set)
MUX_TOKEN_ID=3171e035-cc96-430d-bf4f-60e8f1da8de2
MUX_TOKEN_SECRET=Z2LXWsPVSl2MYIlg6od/jj+oGKf/IcKlQnfUyYlT38JLRMWlIL0xT1qIMt6Vxi5BHE4lG0nGPhx

# Supabase Credentials (replace with your actual values)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### 2. Create Database Schema

1. In your Supabase dashboard, go to SQL Editor
2. Copy and paste the contents of `supabase-schema.sql`
3. Run the query to create all tables and policies

### 3. Set up Mux Webhooks (Important!)

1. Go to [Mux Dashboard](https://dashboard.mux.com) → Settings → Webhooks
2. Add a new webhook with URL: `http://localhost:3001/api/mux/webhook`
3. Select these events:
   - `video.upload.asset_created`
   - `video.asset.ready`
   - `video.asset.errored`

**For production:** Use ngrok or deploy your backend and use the real URL.

### 4. Start the Application

```bash
# Install dependencies
npm install

# Start both frontend and backend
npm start
```

This will start:
- Frontend (Vite): http://localhost:5173
- Backend (Mux + Supabase): http://localhost:3001

## 🎬 How It Works

### Upload Flow
1. **User uploads video** → Frontend sends to backend
2. **Backend creates Supabase lesson** → Gets lesson ID
3. **Backend requests Mux upload URL** → Returns direct upload URL
4. **Frontend uploads to Mux** → Direct upload to Mux servers
5. **Mux processes video** → Sends webhook to backend
6. **Backend updates Supabase** → Stores playback ID and status

### Playback Flow
1. **Frontend requests lesson** → Gets lesson data from Supabase
2. **Lesson has playback ID** → Uses Mux player with playback ID
3. **Video plays** → Streams from Mux CDN globally

## 🧪 Testing

### Test Video Upload
1. Go to http://localhost:5173
2. Navigate to course creation
3. Add a module and lesson
4. Upload a video file
5. Check server logs for processing status

### Test Video Playback
1. Open `mux-video-player.html` in browser
2. Enter the playback ID from your uploaded video
3. Video should play using Mux player

### Check Database
1. Go to Supabase dashboard → Table Editor
2. Check `lessons` table for your uploaded videos
3. Look for `mux_playback_id` field

## 📋 Available Endpoints

### Backend API (http://localhost:3001)

- `POST /api/mux/upload-url` - Create upload URL & store in Supabase
- `POST /api/mux/webhook` - Handle Mux webhooks (auto-updates Supabase)
- `POST /api/courses` - Create course
- `POST /api/modules` - Create module  
- `POST /api/lessons` - Create lesson
- `GET /api/courses/:id` - Get course with modules/lessons
- `GET /api/lessons/:id` - Get lesson details
- `GET /api/health` - Health check

## 🔧 Troubleshooting

### "Connection Refused" Error
- Make sure backend is running: `npm run fullstack`
- Check if port 3001 is available

### Video Upload Fails
- Verify Mux credentials in `.env`
- Check server logs for Mux API errors
- Ensure CORS is properly configured

### Webhook Not Working
- For local development, use ngrok: `ngrok http 3001`
- Update Mux webhook URL to ngrok URL
- Check webhook events are selected correctly

### Video Won't Play
- Verify playback ID exists in Supabase `lessons` table
- Check Mux dashboard for asset status
- Ensure video processing completed successfully

## 🚀 Production Deployment

1. Deploy backend to Heroku/Railway/Vercel
2. Update Mux webhook URL to production URL
3. Update frontend API calls to production backend URL
4. Set environment variables in production

## 📊 Database Schema

The system creates these main tables:
- `profiles` - User profiles (extends Supabase auth)
- `courses` - Course information
- `modules` - Course modules
- `lessons` - Individual lessons with Mux video data
- `enrollments` - Student course enrollments
- `lesson_progress` - Student progress tracking

## 🎯 Next Steps

1. **Authentication**: Integrate with Supabase Auth
2. **Course Management**: Build full course CRUD
3. **Student Portal**: Create student dashboard
4. **Progress Tracking**: Implement video watch progress
5. **Payments**: Add Stripe integration
6. **Analytics**: Track video engagement with Mux Data