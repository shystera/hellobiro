-- Fix coach enrollment by creating a secure function to find student profiles
-- This addresses RLS policy issues when coaches try to enroll students

-- 1. Drop existing conflicting policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Coaches can view student profiles for enrollment" ON profiles;
DROP POLICY IF EXISTS "Coaches can search student profiles by email" ON profiles;

-- 2. Create a comprehensive policy that allows:
-- - Users to view their own profile
-- - Coaches to view student profiles for enrollment
DO $$ BEGIN
    CREATE POLICY "Profile access policy" ON profiles
        FOR SELECT USING (
            -- Users can view their own profile
            auth.uid() = id
            OR 
            -- Coaches can view student profiles
            (
                EXISTS (
                    SELECT 1 FROM profiles coach_profile 
                    WHERE coach_profile.id = auth.uid() 
                    AND coach_profile.role = 'coach'
                )
                AND role = 'student'
            )
        );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- 3. Create a secure function for coaches to find student profiles by email
CREATE OR REPLACE FUNCTION public.find_student_for_enrollment(
    student_email TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    coach_profile profiles;
    student_profile profiles;
    result JSON;
BEGIN
    -- Verify the caller is a coach
    SELECT * INTO coach_profile 
    FROM profiles 
    WHERE id = auth.uid() AND role = 'coach';
    
    IF coach_profile.id IS NULL THEN
        RETURN json_build_object('error', 'Unauthorized: Only coaches can search for students');
    END IF;
    
    -- Normalize email
    student_email := LOWER(TRIM(student_email));
    
    -- Find the student profile
    SELECT * INTO student_profile 
    FROM profiles 
    WHERE LOWER(TRIM(email)) = student_email AND role = 'student';
    
    IF student_profile.id IS NULL THEN
        RETURN json_build_object('error', 'No student account found');
    END IF;
    
    -- Return student profile data
    RETURN json_build_object(
        'id', student_profile.id,
        'email', student_profile.email,
        'full_name', student_profile.full_name,
        'role', student_profile.role,
        'created_at', student_profile.created_at
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', 'Database error: ' || SQLERRM);
END;
$$;

-- 4. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.find_student_for_enrollment TO authenticated;

-- 5. Create a function to safely enroll students
CREATE OR REPLACE FUNCTION public.enroll_student_by_email(
    student_email TEXT,
    course_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    student_data JSON;
    student_id UUID;
    enrollment_result enrollments;
    result JSON;
BEGIN
    -- Find the student using our secure function
    SELECT find_student_for_enrollment(student_email) INTO student_data;
    
    -- Check if student was found
    IF student_data->>'error' IS NOT NULL THEN
        RETURN student_data; -- Return the error from the function
    END IF;
    
    -- Extract student ID
    student_id := (student_data->>'id')::UUID;
    
    -- Check if already enrolled
    IF EXISTS (
        SELECT 1 FROM enrollments 
        WHERE student_id = (student_data->>'id')::UUID 
        AND course_id = enroll_student_by_email.course_id
    ) THEN
        RETURN json_build_object('error', 'Student is already enrolled in this course');
    END IF;
    
    -- Create enrollment
    INSERT INTO enrollments (student_id, course_id)
    VALUES (student_id, course_id)
    RETURNING * INTO enrollment_result;
    
    -- Return success result
    RETURN json_build_object(
        'success', true,
        'enrollment_id', enrollment_result.id,
        'student_id', enrollment_result.student_id,
        'course_id', enrollment_result.course_id,
        'enrolled_at', enrollment_result.enrolled_at,
        'student_info', student_data
    );
    
EXCEPTION
    WHEN unique_violation THEN
        RETURN json_build_object('error', 'Student is already enrolled in this course');
    WHEN OTHERS THEN
        RETURN json_build_object('error', 'Enrollment failed: ' || SQLERRM);
END;
$$;

-- 6. Grant execute permission
GRANT EXECUTE ON FUNCTION public.enroll_student_by_email TO authenticated;

-- 7. Verify policies are active
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'profiles' AND cmd = 'SELECT';

SELECT 'Coach enrollment policy fix completed! Coaches can now search and enroll students.' as result;