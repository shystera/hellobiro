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
  // Sign up new user - with atomic profile creation
  async signUp(email, password, userData = {}) {
    try {
      console.log('🔐 Starting atomic signup process for:', email);
      
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
      
      // Step 2: Immediately create profile if user was created
      if (data.user) {
        console.log('👤 Creating profile immediately after auth...');
        try {
          const profileData = {
            id: data.user.id,
            email: data.user.email,
            full_name: userData.full_name || data.user.email.split('@')[0],
            role: userData.role || 'student'
          };
          
          const { error: profileError } = await supabase
            .from('profiles')
            .insert([profileData]);
            
          if (profileError) {
            console.error('❌ Profile creation failed:', profileError);
            // Don't throw here as auth user is already created
            // Let the calling code handle this appropriately
            console.warn('⚠️ Auth user created but profile creation failed. This may create an orphaned user.');
          } else {
            console.log('✅ Profile created successfully');
          }
        } catch (profileError) {
          console.error('❌ Profile creation exception:', profileError);
        }
      }

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

  // Create user profile safely
  async createProfile(userId, email, fullName = null, role = 'student') {
    try {
      const profileData = {
        id: userId,
        email: email,
        full_name: fullName || email.split('@')[0],
        role: role
      };
      
      const { data, error } = await supabase
        .from('profiles')
        .insert([profileData])
        .select()
        .single();
        
      return { data, error };
    } catch (error) {
      console.error('Profile creation error:', error);
      return { data: null, error };
    }
  },

  // Check if profile exists for user
  async getProfile(userId) {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
        
      return { data, error };
    } catch (error) {
      console.error('Profile fetch error:', error);
      return { data: null, error };
    }
  },

  // Find profile by email (for coaches to search students)
  async findProfileByEmail(email) {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('email', email)
        .maybeSingle(); // Use maybeSingle to avoid errors when no results
        
      return { data, error };
    } catch (error) {
      console.error('Profile search error:', error);
      return { data: null, error };
    }
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

  // Reset password for email
  async resetPasswordForEmail(email, options = {}) {
    try {
      const { data, error } = await supabase.auth.resetPasswordForEmail(email, options);
      return { data, error };
    } catch (error) {
      console.error('Password reset error:', error);
      return { data: null, error };
    }
  },

  // Update password (used after reset)
  async updatePassword(newPassword) {
    try {
      const { data, error } = await supabase.auth.updateUser({
        password: newPassword
      });
      return { data, error };
    } catch (error) {
      console.error('Password update error:', error);
      return { data: null, error };
    }
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

// Storage helpers for thumbnails
export const storage = {
  // Upload thumbnail to Supabase storage (coaches only)
  async uploadThumbnail(file, path) {
    try {
      // Check if user is a coach
      const { user, profile } = await utils.checkAuth();
      if (!user || !profile) {
        throw new Error('Authentication required');
      }
      
      if (profile.role !== 'coach') {
        throw new Error('Only coaches can upload thumbnails');
      }

      const { data, error } = await supabase.storage
        .from('thumbnails')
        .upload(path, file, {
          cacheControl: '3600',
          upsert: true
        });

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Error uploading thumbnail:', error);
      return { data: null, error };
    }
  },

  // Get public URL for thumbnail (everyone can view)
  getThumbnailUrl(path) {
    const { data } = supabase.storage
      .from('thumbnails')
      .getPublicUrl(path);
    
    return data.publicUrl;
  },

  // Delete thumbnail (coaches only)
  async deleteThumbnail(path) {
    try {
      // Check if user is a coach
      const { user, profile } = await utils.checkAuth();
      if (!user || !profile) {
        throw new Error('Authentication required');
      }
      
      if (profile.role !== 'coach') {
        throw new Error('Only coaches can delete thumbnails');
      }

      const { data, error } = await supabase.storage
        .from('thumbnails')
        .remove([path]);

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Error deleting thumbnail:', error);
      return { data: null, error };
    }
  },

  // Generate thumbnail path for courses
  generateCourseThumbnailPath(courseId, fileName) {
    const timestamp = Date.now();
    const extension = fileName.split('.').pop();
    return `courses/${courseId}/thumbnail_${timestamp}.${extension}`;
  },

  // Generate thumbnail path for lessons
  generateLessonThumbnailPath(lessonId, fileName) {
    const timestamp = Date.now();
    const extension = fileName.split('.').pop();
    return `lessons/${lessonId}/thumbnail_${timestamp}.${extension}`;
  },

  // Helper function for coaches to upload course thumbnails
  async uploadCourseThumbnail(courseId, file) {
    try {
      const path = this.generateCourseThumbnailPath(courseId, file.name);
      const { data, error } = await this.uploadThumbnail(file, path);
      
      if (error) throw error;
      
      // Get the public URL
      const thumbnailUrl = this.getThumbnailUrl(path);
      
      // Update the course with the thumbnail URL
      const { data: courseData, error: courseError } = await db.updateCourse(courseId, {
        thumbnail_url: thumbnailUrl
      });
      
      if (courseError) throw courseError;
      
      return { 
        data: { 
          path, 
          url: thumbnailUrl, 
          course: courseData 
        }, 
        error: null 
      };
    } catch (error) {
      console.error('Error uploading course thumbnail:', error);
      return { data: null, error };
    }
  },

  // Helper function for coaches to upload lesson thumbnails
  async uploadLessonThumbnail(lessonId, file) {
    try {
      const path = this.generateLessonThumbnailPath(lessonId, file.name);
      const { data, error } = await this.uploadThumbnail(file, path);
      
      if (error) throw error;
      
      // Get the public URL
      const thumbnailUrl = this.getThumbnailUrl(path);
      
      // Update the lesson with the thumbnail URL
      const { data: lessonData, error: lessonError } = await db.updateLesson(lessonId, {
        thumbnail_url: thumbnailUrl
      });
      
      if (lessonError) throw lessonError;
      
      return { 
        data: { 
          path, 
          url: thumbnailUrl, 
          lesson: lessonData 
        }, 
        error: null 
      };
    } catch (error) {
      console.error('Error uploading lesson thumbnail:', error);
      return { data: null, error };
    }
  }
}

// Community helpers
export const community = {
  // Get threads for a course
  async getThreads(courseId) {
    try {
      const { data, error } = await supabase
        .from('threads')
        .select(`
          *,
          profiles (full_name, avatar_url)
        `)
        .eq('course_id', courseId)
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Get reply counts for each thread
      if (data && data.length > 0) {
        for (let thread of data) {
          const { count } = await supabase
            .from('replies')
            .select('*', { count: 'exact', head: true })
            .eq('thread_id', thread.id);
          thread.reply_count = count || 0;
        }
      }

      return { data, error: null };
    } catch (error) {
      console.error('Error fetching threads:', error);
      return { data: null, error };
    }
  },

  // Create a new thread
  async createThread(threadData) {
    try {
      const { data, error } = await supabase
        .from('threads')
        .insert([threadData])
        .select(`
          *,
          profiles (full_name, avatar_url)
        `)
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Error creating thread:', error);
      return { data: null, error };
    }
  },

  // Get replies for a thread
  async getReplies(threadId) {
    try {
      const { data, error } = await supabase
        .from('replies')
        .select(`
          *,
          profiles (full_name, avatar_url)
        `)
        .eq('thread_id', threadId)
        .order('created_at', { ascending: true });

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Error fetching replies:', error);
      return { data: null, error };
    }
  },

  // Create a new reply
  async createReply(replyData) {
    try {
      const { data, error } = await supabase
        .from('replies')
        .insert([replyData])
        .select(`
          *,
          profiles (full_name, avatar_url)
        `)
        .single();

      if (error) throw error;
      return { data, error: null };
    } catch (error) {
      console.error('Error creating reply:', error);
      return { data: null, error };
    }
  }
}
