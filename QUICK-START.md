# 🚀 Quick Start Guide

## 1. Install Dependencies
```bash
npm install
```

## 2. Set Up Environment Variables
Copy the example file and fill in your credentials:
```bash
cp .env.example .env
```

Edit `.env` with your actual credentials:
```
MUX_TOKEN_ID=your_mux_token_id_here
MUX_TOKEN_SECRET=your_mux_token_secret_here
VITE_SUPABASE_URL=your_supabase_url
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

## 3. Start Both Servers
```bash
npm start
```

This will start:
- Vite dev server on http://localhost:5173
- Mux proxy server on http://localhost:3001

## 4. Test the Application
1. Open http://localhost:5173
2. Sign up as a new user
3. Try creating a course with video upload

## 5. Test Mux Uploader (Optional)
Open `test-mux-uploader.html` to test the Mux integration directly:
1. Make sure your proxy server is running (`npm run mux-proxy`)
2. Open `test-mux-uploader.html` in your browser
3. Try uploading a video file

## Current Status
- ✅ Authentication system working
- ✅ Course creation flow implemented  
- ✅ Mux Uploader integration (no custom upload code needed!)
- ✅ Database schema updated

## 🎯 What You Get

### Demo Mode:
- ✅ Full course creation workflow
- ✅ Simulated video uploads
- ✅ Complete UI/UX testing
- ✅ Database integration
- ✅ Perfect for demos/development

### Real Mux Mode:
- ✅ Professional video hosting
- ✅ Global CDN delivery
- ✅ Automatic video encoding
- ✅ Real asset tracking
- ✅ Production-ready infrastructure

## 🔧 Troubleshooting

### "Connection Refused" Error
- **Demo Mode**: System automatically falls back to demo uploads
- **Real Mode**: Make sure `npm run mux-proxy` is running

### No Videos in Mux Dashboard
- Check your API keys are correct
- Verify proxy server is running
- Wait a few minutes for processing

## 📝 Next Steps

1. **Test the course creation flow** (works in demo mode)
2. **Add your Mux API keys** when ready for real uploads
3. **Deploy to production** with real video infrastructure

Your course creation system is ready to use! 🎬