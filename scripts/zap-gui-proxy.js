// Relais local Webswing : l'instance distante vérifie que Origin correspond à Host.
// GitHub Codespaces termine HTTPS en amont et transmet son origine externe.
const http = require('node:http');

const FRONT_PORT = 8091;
const BACK_PORT = 8093;
const BACK_HOST = `127.0.0.1:${BACK_PORT}`;
const codespace = process.env.CODESPACE_NAME;

function allowed(req) {
  const host = req.headers.host;
  const local = host === `127.0.0.1:${FRONT_PORT}` || host === `localhost:${FRONT_PORT}`;
  const remote = codespace && host === `${codespace}-${FRONT_PORT}.app.github.dev`;
  if (!local && !remote) return false;
  if (!req.headers.origin) return true;
  return req.headers.origin === `${remote ? 'https' : 'http'}://${host}`;
}

function upstreamHeaders(req) {
  const headers = { ...req.headers, host: BACK_HOST };
  if (headers.origin) headers.origin = `http://${BACK_HOST}`;
  delete headers['x-forwarded-host'];
  delete headers['x-forwarded-proto'];
  return headers;
}

const server = http.createServer((req, res) => {
  if (!allowed(req)) { res.writeHead(403); res.end('Hôte non autorisé'); return; }
  const upstream = http.request({ host: '127.0.0.1', port: BACK_PORT,
    method: req.method, path: req.url, headers: upstreamHeaders(req) }, remote => {
    const headers = { ...remote.headers };
    if (headers.location?.startsWith(`http://${BACK_HOST}/`)) {
      headers.location = headers.location.slice(`http://${BACK_HOST}`.length);
    }
    res.writeHead(remote.statusCode, headers);
    remote.pipe(res);
  });
  upstream.on('error', () => { if (!res.headersSent) res.writeHead(502); res.end('ZAP indisponible'); });
  req.pipe(upstream);
});

server.on('upgrade', (req, socket, head) => {
  if (!allowed(req) || !req.url.startsWith('/zap/')) { socket.destroy(); return; }
  const upstream = http.request({ host: '127.0.0.1', port: BACK_PORT,
    method: req.method, path: req.url, headers: upstreamHeaders(req) });
  upstream.on('upgrade', (remote, backend, backendHead) => {
    let response = `HTTP/${remote.httpVersion} ${remote.statusCode} ${remote.statusMessage}\r\n`;
    for (const [key, value] of Object.entries(remote.headers)) {
      response += `${key}: ${value}\r\n`;
    }
    socket.write(response + '\r\n');
    if (backendHead.length) socket.write(backendHead);
    if (head.length) backend.write(head);
    socket.pipe(backend).pipe(socket);
    socket.on('error', () => backend.destroy());
    backend.on('error', () => socket.destroy());
  });
  upstream.on('response', remote => {
    socket.write(`HTTP/1.1 ${remote.statusCode} ${remote.statusMessage}\r\nConnection: close\r\n\r\n`);
    socket.destroy(); remote.resume();
  });
  upstream.on('error', () => socket.destroy());
  upstream.end();
});

server.listen(FRONT_PORT, '127.0.0.1', () => {
  console.log(`Relais ZAP : 127.0.0.1:${FRONT_PORT} vers ${BACK_HOST}`);
});
