// Backend API for Mux direct upload URLs
import express from 'express';
import cors from 'cors';
import fetch from 'node-fetch';
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// Supabase client
const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_KEY // Use service key for server-side operations
);

// Mux credentials
const MUX_TOKEN_ID = process.env.MUX_TOKEN_ID;
const MUX_TOKEN_SECRET = process.env.MUX_TOKEN_SECRET;

if (!MUX_TOKEN_ID || !MUX_TOKEN_SECRET) {
    console.error('Missing Mux credentials. Please set MUX_TOKEN_ID and MUX_TOKEN_SECRET');
    process.exit(1);
}

app.use(cors());
app.use(express.json());

// Create Mux direct upload URL
app.post('/api/mux/upload-url', async (req, res) => {
    try {
        const { lesson_id, cors_origin } = req.body;
        
        if (!lesson_id) {
            return res.status(400).json({ error: 'lesson_id is required' });
        }

        const auth = Buffer.from(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`).toString('base64');
        
        const response = await fetch('https://api.mux.com/video/v1/uploads', {
            method: 'POST',
            headers: {
                'Authorization': `Basic ${auth}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                new_asset_settings: {
                    playback_policy: ['public'], // Use public for easier testing, change to 'signed' for production
                    encoding_tier: 'baseline'
                },
                cors_origin: cors_origin || '*',
                // Add metadata to track which lesson this upload is for
                passthrough: lesson_id
            })
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Mux API error: ${errorData.error?.message || 'Unknown error'}`);
        }

        const uploadData = await response.json();
        
        // Update lesson with upload_id and set status to uploading
        const { error: updateError } = await supabase
            .from('lessons')
            .update({ 
                mux_upload_id: uploadData.data.id,
                upload_status: 'uploading'
            })
            .eq('id', lesson_id);

        if (updateError) {
            console.error('Failed to update lesson:', updateError);
        }

        res.json({
            upload_url: uploadData.data.url,
            upload_id: uploadData.data.id
        });

    } catch (error) {
        console.error('Failed to create upload URL:', error);
        res.status(500).json({ error: error.message });
    }
});

// Mux webhook handler
app.post('/api/mux/webhook', async (req, res) => {
    try {
        const { type, data } = req.body;
        
        console.log('Mux webhook received:', type, data);

        if (type === 'video.upload.asset_created') {
            // Upload completed and asset created
            const { id: upload_id, asset_id, passthrough } = data;
            const lesson_id = passthrough;

            if (lesson_id) {
                // Get asset details to get playback_id
                const auth = Buffer.from(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`).toString('base64');
                
                const assetResponse = await fetch(`https://api.mux.com/video/v1/assets/${asset_id}`, {
                    headers: {
                        'Authorization': `Basic ${auth}`,
                    }
                });

                if (assetResponse.ok) {
                    const assetData = await assetResponse.json();
                    const playback_id = assetData.data.playback_ids?.[0]?.id;
                    const duration = assetData.data.duration;

                    // Update lesson with asset details
                    const { error } = await supabase
                        .from('lessons')
                        .update({
                            mux_asset_id: asset_id,
                            mux_playback_id: playback_id,
                            duration: duration ? Math.round(duration) : null,
                            upload_status: 'ready'
                        })
                        .eq('id', lesson_id);

                    if (error) {
                        console.error('Failed to update lesson with asset details:', error);
                    } else {
                        console.log(`Lesson ${lesson_id} updated with playback_id: ${playback_id}`);
                    }
                }
            }
        } else if (type === 'video.upload.errored') {
            // Upload failed
            const { passthrough } = data;
            const lesson_id = passthrough;

            if (lesson_id) {
                await supabase
                    .from('lessons')
                    .update({ upload_status: 'error' })
                    .eq('id', lesson_id);
            }
        }

        res.json({ received: true });
    } catch (error) {
        console.error('Webhook error:', error);
        res.status(500).json({ error: error.message });
    }
});

// Create lesson endpoint
app.post('/api/lessons', async (req, res) => {
    try {
        const { module_id, title, description, order_index } = req.body;
        
        const { data, error } = await supabase
            .from('lessons')
            .insert({
                module_id,
                title,
                description,
                order_index: order_index || 0,
                upload_status: 'pending'
            })
            .select()
            .single();

        if (error) {
            throw error;
        }

        res.json(data);
    } catch (error) {
        console.error('Failed to create lesson:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get lessons for a module
app.get('/api/modules/:module_id/lessons', async (req, res) => {
    try {
        const { module_id } = req.params;
        
        const { data, error } = await supabase
            .from('lessons')
            .select('*')
            .eq('module_id', module_id)
            .order('order_index');

        if (error) {
            throw error;
        }

        res.json(data);
    } catch (error) {
        console.error('Failed to get lessons:', error);
        res.status(500).json({ error: error.message });
    }
});

app.listen(PORT, () => {
    console.log(`Mux Upload API running on port ${PORT}`);
    console.log('Endpoints:');
    console.log('  POST /api/mux/upload-url - Create direct upload URL');
    console.log('  POST /api/mux/webhook - Mux webhook handler');
    console.log('  POST /api/lessons - Create lesson');
    console.log('  GET /api/modules/:module_id/lessons - Get lessons');
});