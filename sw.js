const CACHE_NAME = 'bingo-liste-v3';

const CORE_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './vendor/xlsx.full.min.js',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/icon-512-maskable.png',
  './icons/icon-180.png',
  './icons/favicon-32.png',
  'https://cdn.jsdelivr.net/npm/html5-qrcode@2.3.8/html5-qrcode.min.js',
  'https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@2.47.0/tabler-icons.min.css'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => Promise.all(
      // cache: 'reload' umgeht den HTTP-Cache des Webspace, damit nach einem
      // Update wirklich die neuen Dateien im Offline-Cache landen.
      CORE_ASSETS.map((url) => cache.add(new Request(url, { cache: 'reload' })).catch(() => {}))
    ))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(
      keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
    ))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  event.respondWith(
    caches.match(req).then((cached) => {
      const networkFetch = fetch(req)
        .then((res) => {
          if (res && res.status === 200) {
            const copy = res.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(req, copy)).catch(() => {});
          }
          return res;
        })
        .catch(() => {
          if (cached) return cached;
          if (req.mode === 'navigate') return caches.match('./index.html');
          return undefined;
        });

      return cached || networkFetch;
    })
  );
});
