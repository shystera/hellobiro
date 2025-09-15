
import express from 'express';
import cors from 'cors';

const app = express();
const PORT = 3001;

// Enable CORS for your frontend
app.use(cors({
    origin: ['http://localhost:5173', 'http://127.0.0.1:5173', 'http://localhost:3000'],
    credentials: true
}));

app.use(express.json());

// Mux API credentials from environment
const MUX_TOKEN_ID = '3171e035-cc96-430d-bf4f-60e8f1da8de2';
const MUX_TOKEN_SECRET = 'Z2LXWsPVSl2MYIlg6od/jj+oGKf/IcKlQnfUyYlT38JLRMWlIL0xT1qIMt6Vxi5BHE4lG0nGPhx';

// Create Mux direct upload URL
app.post('/api/mux/upload-url', async (req, res) => {
    try {
        const { cors_origin } = req.body;
        
        const auth = Buffer.from(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`).toString('base64');
        
        const response = await fetch('https://api.mux.com/video/v1/uploads', {
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

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`Mux API error: ${response.status} - ${errorText}`);
        }

        const data = await response.json();
        res.json(data);

    } catch (error) {
        console.error('Mux upload URL creation failed:', error);
        res.status(500).json({ 
            error: 'Failed to create upload URL',
            details: error.message 
        });
    }
});

// Get Mux asset details
app.get('/api/mux/asset/:assetId', async (req, res) => {
    try {
        const { assetId } = req.params;
        
        const auth = Buffer.from(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`).toString('base64');
        
        const response = await fetch(`https://api.mux.com/video/v1/assets/${assetId}`, {
            headers: {
                'Authorization': `Basic ${auth}`,
            }
        });

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`Mux API error: ${response.status} - ${errorText}`);
        }

        const data = await response.json();
        res.json(data);

    } catch (error) {
        console.error('Failed to get Mux asset:', error);
        res.status(500).json({ 
            error: 'Failed to get asset details',
            details: error.message 
        });
    }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        message: 'Mux minimal server is running',
        timestamp: new Date().toISOString()
    });
});

app.listen(PORT, () => {
    console.log(`🚀 Mux minimal server running on http://localhost:${PORT}`);
    console.log(`📹 Mux credentials loaded: tokenId: ${MUX_TOKEN_ID.substring(0, 8)}...`);
    console.log('📋 Available endpoints:');
    console.log('  POST /api/mux/upload-url - Create direct upload URL');
    console.log('  GET  /api/mux/asset/:id - Get asset details');
    console.log('  GET  /api/health - Health check');
});
