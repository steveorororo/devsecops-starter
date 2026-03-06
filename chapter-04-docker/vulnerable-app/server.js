const http = require('http');
const fs = require('fs');

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200);
    res.end(JSON.stringify({
      status: 'ok',
      environment: process.env.NODE_ENV,
      dbHost: process.env.DATABASE_HOST,
      dbPassword: process.env.DATABASE_PASSWORD,
      awsKey: process.env.AWS_ACCESS_KEY_ID
    }));
  } else {
    res.writeHead(200);
    res.end('Workstream API v1');
  }
});

server.listen(3000, () => {
  console.log('Server running on port 3000');
});
