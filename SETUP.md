# Kohza Platform Setup Guide

## 🚀 Complete Setup Instructions

### Prerequisites
- Node.js (v16 or higher)
- Supabase account
- Mux account (optional for video features)

### 1. Database Setup

#### Step 1: Create Supabase Project
1. Go to https://supabase.com/dashboard
2. Create a new project
3. Wait for the project to be ready

#### Step 2: Run Database Schema
1. Go to "SQL Editor" in your Supabase dashboard
2. Click "New Query"
3. Copy the contents of `supabase-schema.sql`
4. Paste and click "Run"
5. Verify all tables are created successfully

#### Step 3: Get Your Credentials
1. Go to "Settings" → "API" in Supabase
2. Copy these values:
   - **Project URL**: `https://your-project.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
   - **service_role key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (keep secret!)

### 2. Environment Configuration

Update `.env.local` with your credentials:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
VITE_SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Mux Configuration (Optional)
VITE_MUX_TOKEN_ID=your-mux-token-id
VITE_MUX_TOKEN_SECRET=your-mux-token-secret
```

### 3. Install Dependencies

```bash
npm install
```

### 4. Start Development Server

```bash
npm run dev
```

### 5. Start Mux Proxy (Optional - for video uploads)

In a separate terminal:

```bash
node mux-proxy.js
```

## 🎯 How to Use the Platform

### For Coaches:

1. **Sign Up**: Go to `/signup.html` and create an account with role "coach"
2. **Login**: Use `/login.html` to access your dashboard
3. **Create Course**: Click "New Course" on your dashboard
4. **Add Modules**: Use the course editor to organize content
5. **Upload Videos**: Add lessons with Mux video integration
6. **Enroll Students**: Manually enroll students from your dashboard
7. **Publish Course**: Make your course available to students

### For Students:

1. **Get Enrolled**: Coach must enroll you in courses
2. **Login**: Access your student dashboard
3. **View Courses**: See all enrolled courses
4. **Watch Videos**: Secure Mux video playback with progress tracking
5. **Track Progress**: Automatic lesson completion tracking
6. **Community**: Participate in course discussions

## 🔧 Key Features Implemented

### ✅ Authentication System
- Supabase Auth integration
- Role-based access (coach/student)
- Automatic redirects based on role
- Session management

### ✅ Course Management
- Create/edit courses
- Module and lesson organization
- Course publishing workflow
- Enrollment management

### ✅ Video Integration
- Mux video upload and storage
- Secure video playback
- Progress tracking
- Content protection

### ✅ Database Integration
- Complete Supabase schema
- Row Level Security (RLS)
- Real-time data synchronization
- Progress tracking

### ✅ User Experience
- Responsive design
- Dark/light theme toggle
- Loading states and error handling
- Intuitive navigation

## 📊 Database Schema Overview

### Core Tables:
- **profiles**: User management with roles
- **courses**: Course information and metadata
- **modules**: Course structure organization
- **lessons**: Individual lessons with Mux integration
- **enrollments**: Student course access
- **lesson_progress**: Video watch tracking
- **discussions**: Community features

### Security:
- Row Level Security enabled
- Role-based data access
- Automatic profile creation
- Secure video access control

## 🔐 Security Features

### Content Protection:
- Mux signed URLs for video access
- Enrollment verification before video playback
- Progress tracking and analytics
- Anti-piracy measures

### Data Security:
- Supabase RLS policies
- Role-based access control
- Secure API endpoints
- Environment variable protection

## 🚀 Production Deployment

### Environment Variables:
Ensure all production environment variables are set:
- Supabase credentials
- Mux credentials (if using video features)
- Domain configuration

### Build Process:
```bash
npm run build
npm run preview
```

### Hosting:
- Deploy to Vercel, Netlify, or similar
- Configure environment variables
- Set up custom domain
- Enable HTTPS

## 📞 Support

For technical support or questions:
- Check the console for error messages
- Verify Supabase connection
- Ensure all environment variables are set
- Test with sample data first

## 🎉 You're Ready!

Your Kohza platform is now fully integrated with:
- ✅ Real user authentication
- ✅ Database-driven content
- ✅ Video upload and playback
- ✅ Progress tracking
- ✅ Role-based access control
- ✅ Production-ready security

Start by creating a coach account and building your first course!