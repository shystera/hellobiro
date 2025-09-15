# Quick Mux Setup for Course Creation

## 🚀 Quick Start (2 minutes)

### Step 1: Start Mux Proxy Server
```bash
# In your project directory, run:
node mux-proxy.js
```

You should see:
```
Mux proxy server running on http://localhost:3001
Mux credentials loaded: tokenId: d5268e9b..., tokenSecret: Loaded (71 chars)
```

### Step 2: Test Video Upload
1. Go to `create-course-step1.html`
2. Fill out course details → Continue
3. Add a module and lesson
4. Click "Upload Video" on any lesson
5. Select a video file (MP4, MOV, etc.)
6. Watch the upload progress!

## ✅ What You'll See

### During Upload:
- Progress bar showing upload percentage
- "Processing..." status after upload completes
- Real Mux asset ID in your database

### In Mux Dashboard:
- Go to https://dashboard.mux.com
- See your uploaded videos in "Assets"
- Real video processing and encoding

## 🔧 Troubleshooting

### "Bucket not found" Error
✅ **FIXED!** The course creation now uses Mux instead of Supabase Storage.

### "Failed to create Mux upload URL"
❌ **Solution**: Make sure `node mux-proxy.js` is running on port 3001

### Upload Stuck at 100%
⏳ **Normal**: Mux is processing your video. Wait 30-60 seconds.

### No Video in Mux Dashboard
🔍 **Check**: 
- Mux proxy server is running
- Upload completed successfully
- Wait a few minutes for processing

## 🎯 Production Ready

This setup gives you:
- ✅ Real Mux video uploads
- ✅ Asset ID tracking in database  
- ✅ Upload progress monitoring
- ✅ Processing status updates
- ✅ Ready for student video playback

## 📝 Database Schema

The system now saves:
- `mux_asset_id` - Real Mux asset ID
- `upload_status` - pending/processing/ready/error
- `duration` - Video length in seconds

Perfect for your investor demo! 🎬