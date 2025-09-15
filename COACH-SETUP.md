# 🎯 Complete Coach Panel Setup Guide

This guide shows you how to set up the complete coach panel with Mux video integration and Supabase database.

## 🚀 Quick Start

### 1. Database Setup (Supabase)
Your database is already configured with the complete schema in `supabase-schema.sql`. This includes:

- ✅ User profiles with role-based access
- ✅ Course management (courses, modules, lessons)
- ✅ Mux integration fields (asset_id, playback_id)
- ✅ Student enrollments and progress tracking
- ✅ Row-level security policies

### 2. Mux Video Integration

#### Start the Proxy Server:
```bash
# Install dependencies
npm install express cors node-fetch dotenv

# Start the Mux proxy server
node mux-proxy.js
```

You should see:
```
Mux proxy server running on http://localhost:3001
Mux credentials loaded: tokenId: d5268e9b..., tokenSecret: Loaded (71 chars)
```

#### Test Video Upload:
1. Open `coach-demo.html` to see the complete flow
2. Login as a coach
3. Create a course
4. Add modules and upload videos
5. Videos will be processed by Mux and stored in Supabase

## 📋 Complete Feature List

### Coach Features:
- ✅ **Course Creation**: Create courses with title, description, pricing
- ✅ **Module Management**: Organize content into modules
- ✅ **Video Upload**: Upload videos to Mux with automatic processing
- ✅ **Student Management**: Enroll students and track progress
- ✅ **Course Publishing**: Publish/unpublish courses
- ✅ **Analytics**: View student progress and engagement

### Student Features:
- ✅ **Course Access**: View enrolled courses
- ✅ **Video Playback**: Secure Mux video streaming
- ✅ **Progress Tracking**: Automatic progress tracking
- ✅ **Course Navigation**: Browse modules and lessons
- ✅ **Completion Tracking**: Mark lessons as complete

### Technical Features:
- ✅ **Mux Integration**: Secure video upload and playback
- ✅ **Supabase Database**: Complete data management
- ✅ **Authentication**: Role-based access control
- ✅ **Real-time Updates**: Live progress tracking
- ✅ **Content Protection**: Secure video delivery

## 🎬 Demo Flow

### For Coaches:
1. **Login** → `login.html`
2. **Dashboard** → `coach-admin-panel.html`
3. **Create Course** → `create-course.html`
4. **Edit Course** → `course-editor.html`
5. **Upload Videos** → Integrated in course editor
6. **Manage Students** → Built into dashboard

### For Students:
1. **Login** → `login.html`
2. **Dashboard** → `student-panel.html`
3. **Browse Course** → `course-detail.html`
4. **Watch Videos** → `lesson-player-mux.html`
5. **Track Progress** → Automatic

## 🔧 Key Files

### Core Pages:
- `coach-admin-panel.html` - Main coach dashboard
- `course-editor.html` - Course building interface
- `lesson-player-mux.html` - Video player with Mux
- `student-panel.html` - Student dashboard
- `course-detail.html` - Course overview for students

### Backend Integration:
- `supabase-client.js` - Database functions
- `mux-proxy.js` - Mux API proxy server
- `supabase-schema.sql` - Complete database schema

### Demo:
- `coach-demo.html` - Complete feature overview

## 📊 Database Schema

### Core Tables:
```sql
profiles          -- User accounts (coach/student)
courses           -- Course information
modules           -- Course modules
lessons           -- Individual lessons with Mux data
enrollments       -- Student course enrollments
lesson_progress   -- Progress tracking
```

### Mux Integration Fields:
```sql
lessons.mux_asset_id      -- Mux asset identifier
lessons.mux_playback_id   -- Mux playback identifier
lessons.video_url         -- Mux streaming URL
lessons.status            -- draft/processing/published
```

## 🎯 Testing the Complete Flow

### 1. Coach Workflow:
```bash
# 1. Start Mux proxy
node mux-proxy.js

# 2. Open coach demo
open coach-demo.html

# 3. Login as coach
# 4. Create a course
# 5. Add modules
# 6. Upload a video (will go to real Mux!)
# 7. Enroll a student
```

### 2. Student Workflow:
```bash
# 1. Login as student
# 2. View enrolled courses
# 3. Click on course
# 4. Watch videos with progress tracking
```

## 🔐 Security Features

### Content Protection:
- ✅ Mux signed URLs for video security
- ✅ Row-level security in Supabase
- ✅ Role-based access control
- ✅ Enrollment verification for video access

### Data Security:
- ✅ User authentication required
- ✅ Course access restricted to enrolled students
- ✅ Coach can only manage their own courses
- ✅ Progress tracking per user

## 🚀 Production Deployment

### For Production:
1. **Deploy Mux Proxy**: Deploy `mux-proxy.js` to your backend
2. **Environment Variables**: Set Mux credentials securely
3. **Update Frontend**: Point to production API endpoints
4. **SSL/HTTPS**: Ensure secure connections
5. **CDN**: Consider CDN for static assets

### Scaling Considerations:
- Mux handles video scaling automatically
- Supabase scales with your user base
- Consider caching for course data
- Implement proper error handling

## 🎉 What You Get

This setup gives you a **complete course platform** with:

- 🎬 **Professional Video Hosting** (Mux)
- 🗄️ **Scalable Database** (Supabase)
- 👥 **User Management** (Authentication + Roles)
- 📊 **Progress Tracking** (Real-time)
- 🔒 **Content Security** (Protected videos)
- 📱 **Responsive Design** (Works on all devices)

Perfect for coaches, educators, and content creators who want to deliver premium video courses with professional-grade infrastructure!