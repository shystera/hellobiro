
import express from 'express';
import cors from 'cors';
import { createClient } from '@supabase/supabase-js';

const app = express();
const PORT = 3001;

// Enable CORS for your frontend
app.use(cors({
    origin: [
        'http://localhost:5173',
        'http://127.0.0.1:5173',
        'http://localhost:3000',
        'http://127.0.0.1:5500',
        'http://localhost:5500',
        'http://127.0.0.1:5501',
        'http://localhost:5501',
        'http://127.0.0.1:5502',
        'http://localhost:5502'
    ],
    credentials: true
}));

app.use(express.json());

// Mux API credentials
const MUX_TOKEN_ID = '3171e035-cc96-430d-bf4f-60e8f1da8de2';
const MUX_TOKEN_SECRET = 'Z2LXWsPVSl2MYIlg6od/jj+oGKf/IcKlQnfUyYlT38JLRMWlIL0xT1qIMt6Vxi5BHE4lG0nGPhx';

// Supabase client
const supabase = createClient(
    'https://zmqayrsopghnzrfuqybw.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InptcWF5cnNvcGdobnpyZnVxeWJ3Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NjIyMzc4OSwiZXhwIjoyMDcxNzk5Nzg5fQ.Af3ZFE6B8yIawDsHK7SL_IHyOuXXMTdGdHAbgnVPU1k'
);

// Create Mux direct upload URL and store in Supabase
app.post('/api/mux/upload-url', async (req, res) => {
    try {
        const { lesson_id, cors_origin } = req.body;

        // Step 1: Create Mux upload URL
        const auth = Buffer.from(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`).toString('base64');

        const muxResponse = await fetch('https://api.mux.com/video/v1/uploads', {
            method: 'POST',
            headers: {
                'Authorization': `Basic ${auth}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                cors_origin: cors_origin || 'http://localhost:5173',
                new_asset_settings: {
                    playback_policy: ['public'],
                    encoding_tier: 'baseline'
                }
            })
        });

        if (!muxResponse.ok) {
            const errorText = await muxResponse.text();
            throw new Error(`Mux API error: ${muxResponse.status} - ${errorText}`);
        }

        const muxData = await muxResponse.json();

        // Step 2: Store upload info in Supabase if lesson_id provided
        if (lesson_id) {
            const { error: updateError } = await supabase
                .from('lessons')
                .update({
                    mux_upload_id: muxData.data.id,
                    upload_status: 'uploading',
                    updated_at: new Date().toISOString()
                })
                .eq('id', lesson_id);

            if (updateError) {
                console.error('Failed to update lesson in Supabase:', updateError);
                // Don't fail the request, just log the error
            }
        }

        res.json(muxData.data);

    } catch (error) {
        console.error('Upload URL creation failed:', error);
        res.status(500).json({
            error: 'Failed to create upload URL',
            details: error.message
        });
    }
});

// Mux webhook handler - updates Supabase when video processing is complete
app.post('/api/mux/webhook', async (req, res) => {
    try {
        const { type, data } = req.body;

        console.log('Mux webhook received:', type, data?.id);

        if (type === 'video.upload.asset_created') {
            // Video upload completed, asset created
            const uploadId = data.upload_id;
            const assetId = data.id;

            // Find lesson by upload_id and update with asset info
            const { data: lessons, error: findError } = await supabase
                .from('lessons')
                .select('*')
                .eq('mux_upload_id', uploadId);

            if (findError) {
                console.error('Error finding lesson:', findError);
                return res.status(500).json({ error: 'Database error' });
            }

            if (lessons && lessons.length > 0) {
                const lesson = lessons[0];

                const { error: updateError } = await supabase
                    .from('lessons')
                    .update({
                        mux_asset_id: assetId,
                        upload_status: 'processing',
                        updated_at: new Date().toISOString()
                    })
                    .eq('id', lesson.id);

                if (updateError) {
                    console.error('Error updating lesson with asset ID:', updateError);
                }
            }
        }

        else if (type === 'video.asset.ready') {
            // Video processing completed
            const assetId = data.id;
            const playbackIds = data.playback_ids || [];
            const publicPlaybackId = playbackIds.find(p => p.policy === 'public')?.id;

            // Update lesson with playback ID
            const { error: updateError } = await supabase
                .from('lessons')
                .update({
                    mux_playback_id: publicPlaybackId,
                    upload_status: 'ready',
                    video_duration: data.duration || null,
                    updated_at: new Date().toISOString()
                })
                .eq('mux_asset_id', assetId);

            if (updateError) {
                console.error('Error updating lesson with playback ID:', updateError);
            } else {
                console.log(`✅ Video ready! Asset: ${assetId}, Playback ID: ${publicPlaybackId}`);
            }
        }

        else if (type === 'video.asset.errored') {
            // Video processing failed
            const assetId = data.id;

            const { error: updateError } = await supabase
                .from('lessons')
                .update({
                    upload_status: 'error',
                    updated_at: new Date().toISOString()
                })
                .eq('mux_asset_id', assetId);

            if (updateError) {
                console.error('Error updating lesson status to error:', updateError);
            }
        }

        res.json({ received: true });

    } catch (error) {
        console.error('Webhook processing error:', error);
        res.status(500).json({ error: 'Webhook processing failed' });
    }
});

// Create a new course
app.post('/api/courses', async (req, res) => {
    try {
        const { title, description, price, coach_id } = req.body;

        const { data, error } = await supabase
            .from('courses')
            .insert([{
                title,
                description,
                price,
                coach_id,
                status: 'draft',
                created_at: new Date().toISOString()
            }])
            .select()
            .single();

        if (error) throw error;

        res.json(data);
    } catch (error) {
        console.error('Error creating course:', error);
        res.status(500).json({ error: 'Failed to create course' });
    }
});

// Create a new module
app.post('/api/modules', async (req, res) => {
    try {
        const { course_id, title, description, order_index } = req.body;

        const { data, error } = await supabase
            .from('modules')
            .insert([{
                course_id,
                title,
                description,
                order_index: order_index || 0,
                created_at: new Date().toISOString()
            }])
            .select()
            .single();

        if (error) throw error;

        res.json(data);
    } catch (error) {
        console.error('Error creating module:', error);
        res.status(500).json({ error: 'Failed to create module' });
    }
});

// Create a new lesson
app.post('/api/lessons', async (req, res) => {
    try {
        const { module_id, title, description, order_index } = req.body;

        const { data, error } = await supabase
            .from('lessons')
            .insert([{
                module_id,
                title,
                description,
                order_index: order_index || 0,
                upload_status: 'pending',
                created_at: new Date().toISOString()
            }])
            .select()
            .single();

        if (error) throw error;

        res.json(data);
    } catch (error) {
        console.error('Error creating lesson:', error);
        res.status(500).json({ error: 'Failed to create lesson' });
    }
});

// Get lesson details including video info
app.get('/api/lessons/:id', async (req, res) => {
    try {
        const { id } = req.params;

        const { data, error } = await supabase
            .from('lessons')
            .select('*')
            .eq('id', id)
            .single();

        if (error) throw error;

        res.json(data);
    } catch (error) {
        console.error('Error fetching lesson:', error);
        res.status(500).json({ error: 'Failed to fetch lesson' });
    }
});

// Get course with modules and lessons
app.get('/api/courses/:id', async (req, res) => {
    try {
        const { id } = req.params;

        // Get course
        const { data: course, error: courseError } = await supabase
            .from('courses')
            .select('*')
            .eq('id', id)
            .single();

        if (courseError) throw courseError;

        // Get modules with lessons
        const { data: modules, error: modulesError } = await supabase
            .from('modules')
            .select(`
                *,
                lessons (*)
            `)
            .eq('course_id', id)
            .order('order_index');

        if (modulesError) throw modulesError;

        res.json({
            ...course,
            modules: modules || []
        });
    } catch (error) {
        console.error('Error fetching course:', error);
        res.status(500).json({ error: 'Failed to fetch course' });
    }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        message: 'Mux + Supabase server is running',
        timestamp: new Date().toISOString(),
        services: {
            mux: !!MUX_TOKEN_ID,
            supabase: true
        }
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Mux + Supabase server running on http://localhost:${PORT}`);
    console.log(`📹 Mux credentials loaded: tokenId: ${MUX_TOKEN_ID.substring(0, 8)}...`);
    console.log(`🗄️  Supabase connected`);
    console.log('📋 Available endpoints:');
    console.log('  POST /api/mux/upload-url - Create upload URL & store in Supabase');
    console.log('  POST /api/mux/webhook - Handle Mux webhooks');
    console.log('  POST /api/courses - Create course');
    console.log('  POST /api/modules - Create module');
    console.log('  POST /api/lessons - Create lesson');
    console.log('  GET  /api/courses/:id - Get course with modules/lessons');
    console.log('  GET  /api/lessons/:id - Get lesson details');
    console.log('  GET  /api/health - Health check');
});