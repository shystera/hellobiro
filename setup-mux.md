# Mux Integration Setup Guide

## Quick Setup (Recommended)

### 1. Start the Proxy Server
```bash
# Install dependencies
npm install express cors node-fetch dotenv

# Start the proxy server
node mux-proxy.js
```

You should see:
```
Mux proxy server running on http://localhost:3001
Mux credentials loaded: tokenId: d5268e9b..., tokenSecret: Loaded (71 chars)
```

### 2. Test the Upload
1. Open `video-upload.html` or `course-editor.html`
2. Upload a video file
3. The upload will now go to real Mux servers!

## What Happens Now

### Real Mux Upload Process:
1. **Create Upload URL**: Calls Mux API to get signed upload URL
2. **Upload File**: Directly uploads your video file to Mux servers
3. **Get Asset ID**: Receives real Mux asset ID for the video
4. **Processing**: Mux processes/encodes your video
5. **Playback**: Video becomes available via Mux CDN

### Check Your Mux Dashboard:
- Go to https://dashboard.mux.com
- Login with your Mux account
- Navigate to "Assets" to see uploaded videos
- You'll see real assets with your uploaded videos!

## Troubleshooting

### CORS Issues (Browser Direct Upload)
If the proxy server isn't running, the browser will try direct API calls which will fail due to CORS. This is expected - always use the proxy server.

### Upload Failures
- Check that `mux-proxy.js` is running on port 3001
- Verify your Mux credentials are correct
- Check browser console for error messages

### File Size Limits
- Mux supports files up to 5GB
- Larger files may take longer to upload
- Upload progress is tracked in real-time

## Production Deployment

For production, you would:
1. Deploy the proxy server to your backend (Vercel, Heroku, etc.)
2. Update the frontend to call your production API endpoint
3. Store Mux credentials as environment variables
4. Add proper error handling and retry logic

## Verification

After uploading a video, you should see:
- Real Mux asset ID in the UI (not "demo-asset-...")
- Video appears in your Mux dashboard
- Processing status updates in real-time
- Actual video playback when ready

This gives you a fully functional Mux integration for your investor demo!