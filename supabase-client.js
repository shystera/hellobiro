// Supabase configuration - using CDN version
const supabaseUrl = 'https://zmqayrsopghnzrfuqybw.supabase.co'
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptcWF5cnNvcGdobnpyZnVxeWJ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyMjM3ODksImV4cCI6MjA3MTc5OTc4OX0.sPrgn7n3MmkfouzKtH6q3XC3J4GfIbGl3j4AeIna24w'

// Create Supabase client using the global supabase object from CDN
// Check if window.supabase is available
if (!window.supabase) {
  console.error('Supabase library not loaded. Make sure to include the CDN script.');
  throw new Error('Supabase library not available');
}

export const supabase = window.supabase.createClient(supabaseUrl, supabaseAnonKey)

// Auth helpers
export const auth = {
  // Sign up new user - manual profile creation
  async signUp(email, password, userData = {}) {
    try {
      console.log('🔐 Starting signup process for:', email);
      
      // Step 1: Create the auth user
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: window.location.origin
        }
      })

      if (error) {
        console.error('🔐 Auth signup error:', error);
        throw error;
      }

      console.log('🔐 Auth user created:', data.user?.email);
      return { data, error: null }

    } catch (error) {
      console.error('Signup error:', error);
      return { data: null, error }
    }
  },

  // Sign in user
  async signIn(email, password) {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    })

    console.log('🔐 signInWithPassword response:', { data, error }); // Add debug logging

    return { data, error }
  },

  // Sign out user
  async signOut() {
    const { error } = await supabase.auth.signOut()
    return { error }
  },

  // Get current user
  async getCurrentUser() {
    const { data: { user }, error } = await supabase.auth.getUser()
    return { user, error }
  },

  // Get user profile with role
  async getUserProfile(userId) {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single()
    return { data, error }
  },

  // Listen to auth changes
  onAuthStateChange(callback) {
    return supabase.auth.onAuthStateChange(callback)
  }
}

// Database helpers
export const db = {
  // Courses
  async getCoursesByCoach(coachId) {
    const { data, error } = await supabase
      .from('courses')
      .select(`
        *,
        modules (
          id,
          title,
          lessons (
            id,
            title,
            mux_playback_id
          )
        )
      `)
      .eq('coach_id', coachId)
      .order('created_at', { ascending: false })
    return { data, error }
  },

  async getEnrolledCourses(studentId) {
    const { data, error } = await supabase
      .from('enrollments')
      .select(`
        *,
        courses (
          *,
          profiles!courses_coach_id_fkey (
            full_name,
            avatar_url
          ),
          modules (
            id,
            title,
            order_index,
            lessons (
              id,
              title,
              video_duration,
              upload_status,
              order_index
            )
          )
        )
      `)
      .eq('student_id', studentId)
    return { data, error }
  },

  async createCourse(courseData) {
    const { data, error } = await supabase
      .from('courses')
      .insert([courseData])
      .select()
      .single()
    return { data, error }
  },

  async updateCourse(courseId, updates) {
    const { data, error } = await supabase
      .from('courses')
      .update(updates)
      .eq('id', courseId)
      .select()
      .single()
    return { data, error }
  },

  // Modules
  async createModule(moduleData) {
    const { data, error } = await supabase
      .from('modules')
      .insert([moduleData])
      .select()
      .single()
    return { data, error }
  },

  async getModulesByCourse(courseId) {
    const { data, error } = await supabase
      .from('modules')
      .select(`
        *,
        lessons (
          id,
          title,
          mux_playback_id
        )
      `)
      .eq('course_id', courseId)
      .order('created_at', { ascending: true })
    return { data, error }
  },

  // Lessons
  async createLesson(lessonData) {
    const { data, error } = await supabase
      .from('lessons')
      .insert([lessonData])
      .select()
      .single()
    return { data, error }
  },

  async updateLesson(lessonId, updates) {
    const { data, error } = await supabase
      .from('lessons')
      .update(updates)
      .eq('id', lessonId)
      .select()
      .single()
    return { data, error }
  },

  async getLesson(lessonId) {
    const { data, error } = await supabase
      .from('lessons')
      .select('*')
      .eq('id', lessonId)
      .single()
    return { data, error }
  },

  // Progress tracking
  async updateLessonProgress(studentId, lessonId, progressData) {
    const { data, error } = await supabase
      .from('lesson_progress')
      .upsert({
        student_id: studentId,
        lesson_id: lessonId,
        ...progressData
      })
      .select()
      .single()
    return { data, error }
  },

  async getLessonProgress(studentId, lessonId) {
    const { data, error } = await supabase
      .from('lesson_progress')
      .select('*')
      .eq('student_id', studentId)
      .eq('lesson_id', lessonId)
      .single()
    return { data, error }
  },

  // Enrollments
  async enrollStudent(studentId, courseId) {
    const { data, error } = await supabase
      .from('enrollments')
      .insert([{
        student_id: studentId,
        course_id: courseId
      }])
      .select()
      .single()
    return { data, error }
  },

  async checkEnrollment(studentId, courseId) {
    const { data, error } = await supabase
      .from('enrollments')
      .select('*')
      .eq('student_id', studentId)
      .eq('course_id', courseId)
      .single()
    return { data, error }
  },

  async getStudentsByCourse(courseId) {
    const { data, error } = await supabase
      .from('enrollments')
      .select(`
        *,
        profiles!enrollments_student_id_fkey (
          id,
          full_name,
          email,
          avatar_url
        )
      `)
      .eq('course_id', courseId)
    return { data, error }
  },

  // Get full course with modules and lessons
  async getCourseWithContent(courseId) {
    const { data, error } = await supabase
      .from('courses')
      .select(`
        *,
        profiles!courses_coach_id_fkey (
          full_name,
          avatar_url
        ),
        modules (
          id,
          title,
          description,
          lessons (
            id,
            title,
            description,
            duration,
            mux_asset_id,
            mux_playback_id
          )
        )
      `)
      .eq('id', courseId)
      .single()
    return { data, error }
  }
}

// Mux integration helpers (client-side only)
export const mux = {
  // Create local video reference (no external API needed)
  async createUploadUrl() {
    try {
      // Generate a local upload reference
      const uploadId = 'local_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);

      const data = {
        id: uploadId,
        url: null, // No external URL needed for client-side
        status: 'ready'
      };

      return { data, error: null };
    } catch (error) {
      console.error('Local upload reference creation failed:', error);
      return { data: null, error };
    }
  },

  // Get asset details (client-side simulation)
  async getAsset(assetId) {
    try {
      // Simulate asset details for client-side usage
      const data = {
        id: assetId,
        status: 'ready',
        playback_ids: [{
          id: 'local_playback_' + assetId,
          policy: 'public'
        }],
        duration: 0, // Would need to be calculated from actual video
        created_at: new Date().toISOString()
      };

      return { data, error: null };
    } catch (error) {
      console.error('Failed to get local asset:', error);
      return { data: null, error };
    }
  },

  // Upload video file to Mux
  async uploadVideo(file, onProgress = null) {
    try {
      // Step 1: Create upload URL
      const { data: uploadData, error: uploadError } = await this.createUploadUrl();
      if (uploadError) throw uploadError;

      const { url: uploadUrl, id: uploadId } = uploadData.data;

      // Step 2: Upload file to Mux
      const formData = new FormData();
      formData.append('file', file);

      const uploadResponse = await fetch(uploadUrl, {
        method: 'PUT',
        body: file,
        headers: {
          'Content-Type': file.type,
        }
      });

      if (!uploadResponse.ok) {
        throw new Error('Failed to upload video to Mux');
      }

      // Step 3: Poll for asset creation
      let asset = null;
      let attempts = 0;
      const maxAttempts = 30; // 5 minutes max

      while (!asset && attempts < maxAttempts) {
        await new Promise(resolve => setTimeout(resolve, 10000)); // Wait 10 seconds

        try {
          const { data: assetData } = await this.getAsset(uploadData.data.new_asset_settings.asset_id || uploadId);
          if (assetData && assetData.data && assetData.data.status === 'ready') {
            asset = assetData.data;
            break;
          }
        } catch (e) {
          // Asset might not be created yet, continue polling
        }

        attempts++;
        if (onProgress) {
          onProgress({ stage: 'processing', attempts, maxAttempts });
        }
      }

      if (!asset) {
        throw new Error('Video processing timed out');
      }

      return {
        data: {
          assetId: asset.id,
          playbackId: asset.playback_ids?.[0]?.id,
          duration: asset.duration,
          status: asset.status
        },
        error: null
      };

    } catch (error) {
      console.error('Video upload failed:', error);
      return { data: null, error };
    }
  }
}

// Utility functions
export const utils = {
  // Redirect based on user role
  async redirectBasedOnRole() {
    try {
      const { user, profile } = await this.checkAuth();
      
      if (!user || !profile) {
        window.location.href = 'role.html';
        return;
      }

      // Redirect based on role
      if (profile.role === 'coach') {
        window.location.href = 'coach-admin-panel.html';
      } else if (profile.role === 'student') {
        window.location.href = 'student-panel.html';
      } else {
        window.location.href = 'role.html';
      }
    } catch (error) {
      console.error('Error in redirectBasedOnRole:', error);
      window.location.href = 'role.html';
    }
  },

  // Check if user is authenticated and has role
  async requireAuth(requiredRole = null, skipRedirect = false) {
    try {
      const { user, error: userError } = await auth.getCurrentUser();
      
      if (userError || !user) {
        if (!skipRedirect) {
          window.location.href = 'login.html';
        }
        return { user: null, profile: null };
      }

      const { data: profile, error: profileError } = await auth.getUserProfile(user.id);
      
      if (profileError || !profile) {
        if (!skipRedirect) {
          window.location.href = 'role.html';
        }
        return { user, profile: null };
      }

      // Check role requirement
      if (requiredRole && profile.role !== requiredRole) {
        if (!skipRedirect) {
          window.location.href = profile.role === 'coach' ? 'coach-admin-panel.html' : 'student-panel.html';
        }
        return { user, profile, hasRequiredRole: false };
      }

      return { user, profile, hasRequiredRole: true };
    } catch (error) {
      console.error('Error in requireAuth:', error);
      if (!skipRedirect) {
        window.location.href = 'login.html';
      }
      return { user: null, profile: null };
    }
  },

  // Check authentication without redirecting
  async checkAuth() {
    return await utils.requireAuth(null, true)
  },

  // Format duration from seconds to readable format
  formatDuration(seconds) {
    if (!seconds) return '0:00'
    const minutes = Math.floor(seconds / 60)
    const remainingSeconds = seconds % 60
    return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`
  },

  // Generate thumbnail URL (placeholder for now)
  generateThumbnail(title) {
    return `https://via.placeholder.com/400x225/6366f1/ffffff?text=${encodeURIComponent(title)}`
  }
}
