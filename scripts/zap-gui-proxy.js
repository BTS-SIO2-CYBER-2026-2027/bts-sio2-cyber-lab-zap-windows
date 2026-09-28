// Relais local Webswing pour GitHub Codespaces.
// Webswing vérifie Host/Origin ; Codespaces termine HTTPS en amont.
const http = require('node:http');

const FRONT_PORT = 8091;
const BACK_PORT = 8093;
const BACK_HOST = `127.0.0.1:${BACK_PORT}`;
const codespace = process.env.CODESPACE_NAME;

function allowed(req) {
  const host = req.headers.host;
  const local = host === `127.0.0.1:${FRONT_PORT}` || host === `localhost:${FRONT_PORT}`;
  const remote = Boolean(codespace && host === `${codespace}-${FRONT_PORT}.app.github.dev`);
  if (!local && !remote) return false;
  if (!req.headers.origin) return true;
  return req.headers.origin === `${remote ? 'https' : 'http'}://${host}`;
}

function upstreamHeaders(req) {
  const headers = { ...req.headers, host: BACK_HOST };
  if (headers.origin) headers.origin = `http://${BACK_HOST}`;
  // Ne pas laisser les métadonnées du proxy Codespaces influencer Webswing.
  for (const key of Object.keys(headers)) {
    if (key.startsWith('x-forwarded-')) delete headers[key];
  }
  return headers;
}

function unavailable(res, err) {
  console.error(`[proxy] backend 8093 indisponible: ${err?.code || err?.message || err}`);
  if (res.headersSent) return res.end();
  // Une page transitoire qui se recharge évite de laisser l'élève bloqué
  // sur un ancien 502 si Webswing finit son démarrage quelques secondes après.
  res.writeHead(503, {
    'content-type': 'text/html; charset=utf-8',
    'cache-control': 'no-store, no-cache, must-revalidate',
    'retry-after': '2'
  });
  res.end(`<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="2">
<title>Démarrage de ZAP</title><style>body{font-family:system-ui;background:#111;color:#eee;padding:2rem}</style>
<h1>Démarrage de ZAP…</h1><p>Webswing n'est pas encore prêt. Nouvelle tentative automatique dans 2 secondes.</p>`);
}

const server = http.createServer((req, res) => {
  if (!allowed(req)) { res.writeHead(403); res.end('Hôte non autorisé'); return; }
  const upstream = http.request({
    host: '127.0.0.1', port: BACK_PORT, method: req.method,
    path: req.url, headers: upstreamHeaders(req)
  }, remote => {
    const headers = { ...remote.headers };
    if (headers.location?.startsWith(`http://${BACK_HOST}/`)) {
      headers.location = headers.location.slice(`http://${BACK_HOST}`.length);
    }
    headers['cache-control'] = headers['cache-control'] || 'no-store';
    res.writeHead(remote.statusCode, headers);
    remote.pipe(res);
  });
  upstream.setTimeout(15000, () => upstream.destroy(new Error('timeout backend')));
  upstream.on('error', err => unavailable(res, err));
  req.pipe(upstream);
});

server.on('upgrade', (req, socket, head) => {
  if (!allowed(req) || !req.url.startsWith('/zap/')) { socket.destroy(); return; }
  const upstream = http.request({
    host: '127.0.0.1', port: BACK_PORT, method: req.method,
    path: req.url, headers: upstreamHeaders(req)
  });
  upstream.on('upgrade', (remote, backend, backendHead) => {
    let response = `HTTP/${remote.httpVersion} ${remote.statusCode} ${remote.statusMessage}\r\n`;
    for (const [key, value] of Object.entries(remote.headers)) response += `${key}: ${value}\r\n`;
    socket.write(response + '\r\n');
    if (backendHead.length) socket.write(backendHead);
    if (head.length) backend.write(head);
    socket.pipe(backend).pipe(socket);
    socket.on('error', () => backend.destroy());
    backend.on('error', () => socket.destroy());
  });
  upstream.on('response', remote => {
    console.error(`[proxy] websocket refusé par backend: HTTP ${remote.statusCode}`);
    socket.write(`HTTP/1.1 ${remote.statusCode} ${remote.statusMessage}\r\nConnection: close\r\n\r\n`);
    socket.destroy(); remote.resume();
  });
  upstream.on('error', err => {
    console.error(`[proxy] websocket backend indisponible: ${err?.code || err?.message || err}`);
    socket.destroy();
  });
  upstream.end();
});

server.on('clientError', (err, socket) => {
  console.error(`[proxy] client error: ${err.message}`);
  if (!socket.destroyed) socket.destroy();
});

server.listen(FRONT_PORT, '127.0.0.1', () => {
  console.log(`Relais ZAP : 127.0.0.1:${FRONT_PORT} vers ${BACK_HOST}`);
});
