# Troubleshooting Guide - Authentication & Role Issues

## Issues Fixed

### ✅ 1. Auto-redirect to Coach Panel Issue
**Problem**: When going to role selection page, users were automatically redirected to coach admin panel without selecting a role.

**Solution**: Updated `role.html` to only redirect users who already have a profile with a role, not auto-redirect without user interaction.

### ✅ 2. Role Selection Ignored Issue  
**Problem**: Even when selecting "student" role, users were redirected to coach admin panel.

**Solution**: Fixed the profile creation logic in `login.html` to properly use the selected role from localStorage.

### ✅ 3. Email Not Loading in Coach Panel
**Problem**: User email and profile information wasn't displaying in the coach admin panel.

**Solution**: Updated authentication flow in `coach-admin-panel.html` to use synchronous authentication check and properly set user variables.

### ✅ 4. Courses Not Loading
**Problem**: Courses weren't loading in the coach admin panel.

**Solution**: Fixed authentication flow to ensure user is properly authenticated before attempting to load courses.

## Database Setup Required

### ⚠️ Important: Run Database Schema Fix

Your database might be missing the `published` column that the application expects. Run this SQL in your Supabase SQL editor:

```sql
-- Add published column to courses table if it doesn't exist
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='courses' AND column_name='published') THEN
        ALTER TABLE courses ADD COLUMN published BOOLEAN DEFAULT false;
    END IF;
END $$;

-- Update existing records
UPDATE courses SET published = false WHERE published IS NULL;
```

Or run the complete fix script: `fix-database-schema.sql`

## Testing the Fixes

### Test Flow 1: New User Registration
1. Go to `role.html`
2. Select "Coach" or "Student"
3. Go through login/signup process
4. Verify you're redirected to the correct dashboard

### Test Flow 2: Existing User Login
1. Go to `role.html`
2. If already logged in, should auto-redirect to appropriate dashboard
3. If not logged in, select role and login
4. Verify correct redirection

### Test Flow 3: Role Switching
1. Login as a coach
2. Logout using the logout button
3. Go to role selection
4. Select student role
5. Login with different credentials
6. Verify you go to student panel

## Debug Tools

### 1. Use the Test Auth Flow Page
Navigate to `test-auth-flow.html` to debug authentication issues:
- Check current user status
- Test profile retrieval
- Test role-based authentication
- Clear storage if needed

### 2. Browser Console Debugging
Open browser console (F12) and look for:
- `🎭` Role selection logs
- `🔐` Login logs  
- `✅` Success logs
- `❌` Error logs

### 3. Check Local Storage
In browser console, run:
```javascript
// Check what's stored
console.log('Selected Role:', localStorage.getItem('selectedRole'));
console.log('All localStorage:', {...localStorage});

// Clear if needed
localStorage.clear();
```

## Common Issues & Solutions

### Issue: "User not authenticated" in Coach Panel
**Solution**: 
1. Clear browser storage: `localStorage.clear(); sessionStorage.clear();`
2. Go to role selection page
3. Select role and login again

### Issue: Courses not loading
**Solutions**:
1. Check if database has `published` column (run schema fix)
2. Verify user has coach role in database
3. Check browser console for specific errors

### Issue: Stuck in redirect loop
**Solution**:
1. Clear all browser storage
2. Go directly to `role.html`
3. Use "Force Logout" button if available

### Issue: Profile creation fails
**Solution**:
1. Check if profiles table exists in database
2. Verify RLS policies allow profile creation
3. Check browser console for specific error messages

## Verification Checklist

After applying fixes, verify:

- [ ] Role selection page doesn't auto-redirect unless user has existing profile
- [ ] Selecting "student" role redirects to student panel after login
- [ ] Selecting "coach" role redirects to coach admin panel after login  
- [ ] User email displays correctly in dashboard header
- [ ] Courses load properly in coach admin panel (even if empty)
- [ ] Logout button works correctly
- [ ] Database has required `published` column

## Need More Help?

If issues persist:

1. Check the browser console for specific error messages
2. Use the `test-auth-flow.html` page to debug authentication
3. Verify database schema using `fix-database-schema.sql`
4. Check Supabase dashboard for RLS policy issues