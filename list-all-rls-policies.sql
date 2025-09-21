-- List all RLS policies in the database
-- This query will show comprehensive information about every RLS policy

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
ORDER BY schemaname, tablename, policyname;

-- Alternative detailed view with more information
SELECT 
    n.nspname AS schema_name,
    c.relname AS table_name,
    pol.polname AS policy_name,
    CASE pol.polpermissive
        WHEN true THEN 'PERMISSIVE'
        WHEN false THEN 'RESTRICTIVE'
    END AS policy_type,
    CASE pol.polcmd
        WHEN 'r' THEN 'SELECT'
        WHEN 'a' THEN 'INSERT'
        WHEN 'w' THEN 'UPDATE'
        WHEN 'd' THEN 'DELETE'
        WHEN '*' THEN 'ALL'
    END AS command,
    CASE 
        WHEN pol.polroles = '{0}' THEN 'PUBLIC'
        ELSE array_to_string(
            ARRAY(
                SELECT rolname 
                FROM pg_roles 
                WHERE oid = ANY(pol.polroles)
            ), 
            ', '
        )
    END AS applies_to_roles,
    pg_get_expr(pol.polqual, pol.polrelid) AS using_expression,
    pg_get_expr(pol.polwithcheck, pol.polrelid) AS with_check_expression
FROM pg_policy pol
JOIN pg_class c ON c.oid = pol.polrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
ORDER BY n.nspname, c.relname, pol.polname;

-- Check which tables have RLS enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables 
WHERE rowsecurity = true
ORDER BY schemaname, tablename;

-- Summary count of policies per table
SELECT 
    schemaname,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
GROUP BY schemaname, tablename
ORDER BY policy_count DESC, schemaname, tablename;