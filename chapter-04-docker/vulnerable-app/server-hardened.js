const http = require('http');

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }));
  } else {
    res.writeHead(200);
    res.end('Workstream API v1');
  }
});

server.listen(3000, () => {
  console.log('Server running on port 3000');
});
