-- Fix for enrollment function ambiguous column reference error
-- Run this in your Supabase SQL editor

-- Drop the existing function to recreate it properly
DROP FUNCTION IF EXISTS public.enroll_student_by_email(TEXT, UUID);
DROP FUNCTION IF EXISTS public.enroll_student_by_email;

-- Create a corrected function to safely enroll students
-- Parameters match the client-side call: student_email, course_id
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
    student_id_var UUID;
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
    student_id_var := (student_data->>'id')::UUID;
    
    -- Check if already enrolled (use explicit variable names to avoid ambiguity)
    IF EXISTS (
        SELECT 1 FROM enrollments e 
        WHERE e.student_id = student_id_var 
        AND e.course_id = enroll_student_by_email.course_id
    ) THEN
        RETURN json_build_object('error', 'Student is already enrolled in this course');
    END IF;
    
    -- Create enrollment (use the declared variables)
    INSERT INTO enrollments (student_id, course_id)
    VALUES (student_id_var, enroll_student_by_email.course_id)
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.enroll_student_by_email TO authenticated;

-- Also ensure the find_student_for_enrollment function exists
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.find_student_for_enrollment TO authenticated;

-- Verify the functions exist and show their signatures
SELECT 
    routine_name, 
    routine_type,
    specific_name,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('enroll_student_by_email', 'find_student_for_enrollment')
ORDER BY routine_name;

-- Show function parameters
SELECT 
    routine_name,
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_schema = 'public' 
AND routine_name IN ('enroll_student_by_email', 'find_student_for_enrollment')
ORDER BY routine_name, ordinal_position;

SELECT 'Enrollment function ambiguity fix applied successfully!' as result;