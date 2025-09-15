
// Simple Node.js proxy for Mux API calls
// Run with: node mux-proxy.js

import express from 'express';
import cors from 'cors';
import fetch from 'node-fetch';

const app = express();
const PORT = 3001;

// Enable CORS for your frontend
app.use(cors({
    origin: ['http://127.0.0.1:5500', 'http://localhost:5500', 'http://localhost:3000']
}));

app.use(express.json());

// Mux credentials from environment or hardcoded
const MUX_TOKEN_ID = '3171e035-cc96-430d-bf4f-60e8f1da8de2';
const MUX_TOKEN_SECRET = 'Z2LXWsPVSl2MYIlg6od/jj+oGKf/IcKlQnfUyYlT38JLRMWlIL0xT1qIMt6Vxi5BHE4lG0nGPhx';

console.log('Mux credentials loaded:', {
    tokenId: MUX_TOKEN_ID ? MUX_TOKEN_ID.substring(0, 8) + '...' : 'Not found',
    tokenSecret: MUX_TOKEN_SECRET ? 'Loaded (' + MUX_TOKEN_SECRET.length + ' chars)' : 'Not found'
});

// Create Mux upload URL
app.post('/api/mux/uploads', async (req, res) => {
    try {
        const auth = Buffer.from(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`).toString('base64');
        
        const response = await fetch('https://api.mux.com/video/v1/uploads', {
            method: 'POST',
            headers: {
                'Authorization': `Basic ${auth}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                new_asset_settings: {
                    playback_policy: ['signed'],
                    encoding_tier: 'baseline'
                },
                cors_origin: req.headers.origin || 'http://localhost:5500'
            })
        });

        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error('Mux upload creation failed:', error);
        res.status(500).json({ error: 'Failed to create upload URL' });
    }
});

// Get asset details
app.get('/api/mux/assets/:assetId', async (req, res) => {
    try {
        const auth = Buffer.from(`${MUX_TOKEN_ID}:${MUX_TOKEN_SECRET}`).toString('base64');
        
        const response = await fetch(`https://api.mux.com/video/v1/assets/${req.params.assetId}`, {
            headers: {
                'Authorization': `Basic ${auth}`,
            }
        });

        const data = await response.json();
        res.json(data);
    } catch (error) {
        console.error('Failed to get asset:', error);
        res.status(500).json({ error: 'Failed to get asset details' });
    }
});

app.listen(PORT, () => {
    console.log(`Mux proxy server running on http://localhost:${PORT}`);
    console.log('Make sure to install dependencies: npm install express cors node-fetch dotenv');
});
