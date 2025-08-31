const express = require('express');
const path = require('path');
const app = express();
const port = 3001;

// Serve static files
app.use(express.static('.'));

// Serve the auth test page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'auth-test.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Authentication test server running' });
});

app.listen(port, () => {
  console.log(`🚀 Authentication test server running at http://localhost:${port}`);
  console.log(`📋 Open http://localhost:${port} to test Microsoft Entra ID authentication`);
});
