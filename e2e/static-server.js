// Minimal static server for the built site: directory indexes, and 404.html with
// a 404 status for unknown paths, like GitHub Pages. No dependencies.
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(process.argv[2] || '_site');
const port = Number(process.argv[3] || 4000);

const types = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.xml': 'application/xml',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.ttf': 'font/ttf',
};

function resolve(urlPath) {
  const target = path.join(root, path.normalize(decodeURIComponent(urlPath)));
  if (!target.startsWith(root)) return null;
  for (const candidate of [target, path.join(target, 'index.html'), `${target}.html`]) {
    if (fs.existsSync(candidate) && fs.statSync(candidate).isFile()) return candidate;
  }
  return null;
}

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, 'http://localhost');
    let file = resolve(pathname);
    let status = 200;
    if (!file) {
      file = path.join(root, '404.html');
      status = 404;
    }
    res.writeHead(status, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream' });
    fs.createReadStream(file).pipe(res);
  })
  .listen(port, '127.0.0.1', () => console.log(`Serving ${root} on http://127.0.0.1:${port}`));
