# Kohza Learning Platform

A modern learning management system built with Vite, Supabase, and Mux.

## Quick Setup

### 1. Environment Variables
Copy `.env.example` to `.env` and fill in your credentials:

```bash
cp .env.example .env
```

You need to add:
- **Supabase Service Role Key**: Get from [Supabase Dashboard](https://app.supabase.com) → Settings → API
- **Mux Credentials**: Get from [Mux Dashboard](https://dashboard.mux.com) → Settings → Access Tokens

### 2. Install Dependencies
```bash
npm install
```

### 3. Run Fullstack Development Server
```bash
npm run fullstack
```

This starts:
- Frontend (Vite): http://localhost:5173
- Backend (Express): http://localhost:3001

## Features

### Video Upload & Management
- Secure video uploads to Mux
- DRM protection and global CDN
- Automatic transcoding and thumbnail generation
- Video analytics and playback tracking

### User Management
- Student and coach roles
- Supabase authentication
- Profile management
- Course enrollment system

### Course Creation
- Multi-step course builder
- Module and lesson organization
- Video lesson integration
- Student progress tracking

## API Endpoints

### Backend Server (Port 3001)
- `GET /api/health` - Server health check
- `POST /api/mux/upload-url` - Create Mux upload URL
- `GET /api/mux/upload/:uploadId` - Get upload status
- `GET /api/mux/asset/:assetId` - Get video asset details
- `POST /api/lessons` - Create lesson
- `PATCH /api/lessons/:id` - Update lesson
- `POST /api/videos` - Save video metadata
- `PATCH /api/videos/:id` - Update video status

## Troubleshooting

### Video Upload Error
If you see an error about backend server not running, ensure:

1. Environment variables are set correctly
2. Backend server is running and accessible
3. Mux credentials are valid
4. Supabase connection is working

### Check Server Status
Visit your backend server's health endpoint to verify it's running properly.