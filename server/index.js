import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import multer from 'multer';
import Mux from '@mux/mux-node';
import { createClient } from '@supabase/supabase-js';

// Load environment variables
dotenv.config();

// Use PORT from environment or default to 3001
const PORT = process.env.PORT || 3001;
console.log(`🔧 Server starting on port ${PORT}`);

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Configure multer for file uploads
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024 * 1024 // 5GB limit
  }
});

// Initialize Mux (only if credentials are provided)
let mux = null;
if (process.env.MUX_TOKEN_ID && process.env.MUX_TOKEN_SECRET && 
    process.env.MUX_TOKEN_ID !== 'your_mux_token_id_here' && 
    process.env.MUX_TOKEN_SECRET !== 'your_mux_token_secret_here') {
  console.log('🔍 Mux Token ID:', process.env.MUX_TOKEN_ID ? process.env.MUX_TOKEN_ID.substring(0, 8) + '...' : 'undefined');
  console.log('🔍 Mux Secret length:', process.env.MUX_TOKEN_SECRET ? process.env.MUX_TOKEN_SECRET.length : 'undefined');
  
  mux = new Mux({
    tokenId: process.env.MUX_TOKEN_ID,
    tokenSecret: process.env.MUX_TOKEN_SECRET,
  });
  console.log('✅ Mux initialized with credentials');
} else {
  console.log('⚠️ Mux credentials not provided - video upload will be simulated');
}

// Initialize Supabase (using service role key for server-side operations)
const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

// Routes

// Health check
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Mux + Supabase server is running',
    timestamp: new Date().toISOString(),
    services: {
      mux: !!process.env.MUX_TOKEN_ID,
      supabase: !!process.env.VITE_SUPABASE_URL
    }
  });
});

// Create direct upload URL for Mux
app.post('/api/mux/upload-url', async (req, res) => {
  try {
    if (!mux) {
      // Simulate Mux upload URL for development when credentials are not available
      const simulatedUpload = {
        id: 'simulated_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9),
        url: 'https://httpbin.org/post' // This will accept any POST request for testing
      };
      
      console.log('⚠️ Simulating Mux upload URL (no credentials provided)');
      res.json({
        uploadId: simulatedUpload.id,
        url: simulatedUpload.url
      });
      return;
    }

    const { corsOrigin } = req.body;
    
    try {
      const upload = await mux.video.uploads.create({
        cors_origin: corsOrigin || 'http://localhost:5173',
        new_asset_settings: {
          playback_policy: ['public'],
          encoding_tier: 'baseline',
          max_resolution_tier: '1080p'
        }
      });

      res.json({
        uploadId: upload.id,
        url: upload.url
      });
    } catch (muxError) {
      console.error('Mux authentication failed, falling back to simulation mode:', muxError.message);
      
      // Fallback to simulation mode
      const simulatedUpload = {
        id: 'simulated_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9),
        url: 'https://httpbin.org/post'
      };
      
      res.json({
        uploadId: simulatedUpload.id,
        url: simulatedUpload.url
      });
    }
  } catch (error) {
    console.error('Error creating Mux upload URL:', error);
    res.status(500).json({ 
      error: 'Failed to create upload URL',
      details: error.message 
    });
  }
});

// Get upload status
app.get('/api/mux/upload/:uploadId', async (req, res) => {
  try {
    const { uploadId } = req.params;
    
    if (!mux || uploadId.startsWith('simulated_')) {
      // Simulate upload status for development
      res.json({
        status: 'asset_created',
        assetId: 'simulated_asset_' + uploadId.replace('simulated_', ''),
        error: null
      });
      return;
    }
    
    const upload = await mux.video.uploads.retrieve(uploadId);
    
    res.json({
      status: upload.status,
      assetId: upload.asset_id,
      error: upload.error
    });
  } catch (error) {
    console.error('Error getting upload status:', error);
    res.status(500).json({ 
      error: 'Failed to get upload status',
      details: error.message 
    });
  }
});

// Get asset details
app.get('/api/mux/asset/:assetId', async (req, res) => {
  try {
    const { assetId } = req.params;
    
    if (!mux || assetId.startsWith('simulated_asset_')) {
      // Simulate asset details for development
      res.json({
        id: assetId,
        status: 'ready',
        playback_ids: [{
          id: 'simulated_playback_' + assetId.replace('simulated_asset_', ''),
          policy: 'public'
        }],
        duration: 120, // 2 minutes default
        aspect_ratio: '16:9',
        created_at: new Date().toISOString()
      });
      return;
    }
    
    const asset = await mux.video.assets.retrieve(assetId);
    
    res.json({
      id: asset.id,
      status: asset.status,
      playback_ids: asset.playback_ids,
      duration: asset.duration,
      aspect_ratio: asset.aspect_ratio,
      created_at: asset.created_at
    });
  } catch (error) {
    console.error('Error getting asset details:', error);
    res.status(500).json({ 
      error: 'Failed to get asset details',
      details: error.message 
    });
  }
});

// Create lesson in Supabase
app.post('/api/lessons', async (req, res) => {
  try {
    const { 
      module_id, 
      title, 
      description, 
      order_index 
    } = req.body;

    const { data, error } = await supabase
      .from('lessons')
      .insert([{
        module_id,
        title,
        description,
        order_index
        // Note: removed 'status' field as it doesn't exist in the schema
        // The lessons table has 'upload_status' instead, which defaults to 'pending'
      }])
      .select()
      .single();

    if (error) {
      throw error;
    }

    res.json(data);
  } catch (error) {
    console.error('Error creating lesson:', error);
    res.status(500).json({ 
      error: 'Failed to create lesson',
      details: error.message 
    });
  }
});

// Update lesson in Supabase
app.patch('/api/lessons/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const { data, error } = await supabase
      .from('lessons')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      throw error;
    }

    res.json(data);
  } catch (error) {
    console.error('Error updating lesson:', error);
    res.status(500).json({ 
      error: 'Failed to update lesson',
      details: error.message 
    });
  }
});

// Save video metadata to Supabase
app.post('/api/videos', async (req, res) => {
  try {
    const { 
      title, 
      description, 
      mux_asset_id, 
      mux_playback_id, 
      course_id, 
      lesson_id,
      duration,
      user_id 
    } = req.body;

    const { data, error } = await supabase
      .from('videos')
      .insert([{
        title,
        description,
        mux_asset_id,
        mux_playback_id,
        course_id,
        lesson_id,
        duration,
        created_by: user_id,
        status: 'processing'
      }])
      .select()
      .single();

    if (error) {
      throw error;
    }

    res.json(data);
  } catch (error) {
    console.error('Error saving video metadata:', error);
    res.status(500).json({ 
      error: 'Failed to save video metadata',
      details: error.message 
    });
  }
});

// Update video status
app.patch('/api/videos/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const { data, error } = await supabase
      .from('videos')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (error) {
      throw error;
    }

    res.json(data);
  } catch (error) {
    console.error('Error updating video:', error);
    res.status(500).json({ 
      error: 'Failed to update video',
      details: error.message 
    });
  }
});

// Mux webhook handler
app.post('/api/mux/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  try {
    const event = JSON.parse(req.body);
    
    console.log('Mux webhook received:', event.type);
    
    if (event.type === 'video.asset.ready') {
      const assetId = event.data.id;
      
      // Update video status in Supabase
      const { error } = await supabase
        .from('videos')
        .update({ status: 'ready' })
        .eq('mux_asset_id', assetId);
        
      if (error) {
        console.error('Error updating video status:', error);
      }
    }
    
    res.status(200).send('OK');
  } catch (error) {
    console.error('Error processing webhook:', error);
    res.status(400).send('Bad Request');
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Server error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    details: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
  });
});

// Catch-all route for debugging
app.use('*', (req, res) => {
  console.log(`🔍 404 - Route not found: ${req.method} ${req.originalUrl}`);
  console.log(`📝 Available routes:`);
  console.log(`   GET  /api/health`);
  console.log(`   POST /api/mux/upload-url`);
  console.log(`   GET  /api/mux/upload/:uploadId`);
  console.log(`   GET  /api/mux/asset/:assetId`);
  console.log(`   POST /api/lessons`);
  console.log(`   PATCH /api/lessons/:id`);
  console.log(`   POST /api/videos`);
  console.log(`   PATCH /api/videos/:id`);
  console.log(`   POST /api/mux/webhook`);
  
  // Return a simple HTML page for debugging
  res.status(404).send(`
    <!DOCTYPE html>
    <html>
    <head>
        <title>404 - Route Not Found</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; }
            .error { color: #d32f2f; }
            .info { background: #f5f5f5; padding: 15px; border-radius: 5px; }
        </style>
    </head>
    <body>
        <h1 class="error">404 - Route Not Found</h1>
        <p>Requested: ${req.method} ${req.originalUrl}</p>
        <div class="info">
            <p>This is the Kohza backend server.</p>
            <p>Available API endpoints:</p>
            <ul>
                <li>GET /api/health - Server health check</li>
                <li>POST /api/mux/upload-url - Create Mux upload URL</li>
                <li>GET /api/mux/upload/:uploadId - Get upload status</li>
                <li>GET /api/mux/asset/:assetId - Get video asset details</li>
                <li>POST /api/lessons - Create lesson</li>
                <li>PATCH /api/lessons/:id - Update lesson</li>
                <li>POST /api/videos - Save video metadata</li>
                <li>PATCH /api/videos/:id - Update video status</li>
                <li>POST /api/mux/webhook - Mux webhook handler</li>
            </ul>
        </div>
    </body>
    </html>
  `);
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Mux + Supabase server running on port ${PORT}`);
  console.log(`📺 Mux configured: ${!!process.env.MUX_TOKEN_ID}`);
  console.log(`🗄️  Supabase configured: ${!!process.env.VITE_SUPABASE_URL}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/api/health`);
});