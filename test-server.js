const express = require('express');
const path = require('path');

const app = express();
const port = 3000;

// Serve static files
app.use(express.static('.'));

// Main test page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'auth-test.html'));
});

// Auth callback (redirect after login)
app.get('/auth/callback', (req, res) => {
    res.send(`
        <html>
        <head>
            <title>Authentication Callback</title>
            <script src="https://alcdn.msauth.net/lib/1.4.4/js/msal-browser.min.js"></script>
        </head>
        <body>
            <h1>Authentication Callback</h1>
            <p>Processing authentication...</p>
            <script>
                // Handle the redirect response
                const msalInstance = new msal.PublicClientApplication({
                    auth: {
                        clientId: 'be183263-80c3-4191-bc84-2ee3c618cbcd',
                        authority: 'https://login.microsoftonline.com/common',
                        redirectUri: window.location.origin + '/auth/callback'
                    }
                });

                msalInstance.initialize().then(() => {
                    msalInstance.handleRedirectPromise().then((response) => {
                        if (response) {
                            console.log('Redirect response:', response);
                            // Redirect back to main page
                            window.location.href = '/';
                        }
                    }).catch((error) => {
                        console.error('Redirect error:', error);
                    });
                });
            </script>
        </body>
        </html>
    `);
});

app.listen(port, () => {
    console.log(`Authentication test server running at http://localhost:${port}`);
    console.log('Open your browser to test Microsoft Entra ID authentication');
});
