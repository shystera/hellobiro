-- Create a server function to handle profile creation
-- Run this in your Supabase SQL editor

CREATE OR REPLACE FUNCTION create_user_profile(
    user_id UUID,
    user_email TEXT,
    user_name TEXT DEFAULT NULL,
    user_role TEXT DEFAULT 'student'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSON;
BEGIN
    -- Insert the profile
    INSERT INTO profiles (id, email, full_name, role)
    VALUES (user_id, user_email, COALESCE(user_name, split_part(user_email, '@', 1)), user_role)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, profiles.full_name),
        role = EXCLUDED.role,
        updated_at = NOW();
    
    -- Return the created profile
    SELECT json_build_object(
        'id', id,
        'email', email,
        'full_name', full_name,
        'role', role,
        'created_at', created_at
    ) INTO result
    FROM profiles
    WHERE id = user_id;
    
    RETURN result;
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object('error', SQLERRM);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_user_profile TO authenticated;

SELECT 'Profile creation function created successfully!' as result;