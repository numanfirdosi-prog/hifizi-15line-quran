/**
 * NŪR AL-QURAN - Progressive Web App Service Worker
 * Provides offline caching for static assets, styles, scripts, and verified Quran pages.
 */

const CACHE_NAME = 'nur-al-quran-v3.3.0';

const STATIC_ASSETS = [
  '/',
  '/index.html',
  './',
  './index.html',
  './code.js',
  './prayer-engine.js',
  './assets/audio/azan.mp3',
  './assets/data/page_ayahs_15lines.js',
  './assets/data/page_ayahs_15lines.json',
  './style.css',
  './mushaf-15line.css',
  './mushaf-redesign.css',
  './audio-advanced.css',
  './ramadan.css',
  './faq.css',
  './manifest.json',
  './assets/icon-192.png',
  './assets/icon-512.png',
  './assets/apple-touch-icon.png',
  './assets/favicon.png',
  './favicon.ico',
  './assets/pages/1.webp',
  './assets/pages/2.webp',
  './assets/pages/3.webp',
  './assets/pages/4.webp'
];

// Install Event - Precache App Shell and Skip Waiting Immediately
self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then(async (cache) => {
      console.log('[SW] Precaching Nūr Al-Quran core assets');
      for (const asset of STATIC_ASSETS) {
        try {
          await cache.add(asset);
        } catch (err) {
          console.warn('[SW] Failed to precache:', asset, err);
        }
      }
    })
  );
});

// Activate Event - Clean Up ALL Legacy Caches and Claim Clients Immediately
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[SW] Removing legacy cache:', key);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch Event - Dynamic Network-First Strategy for Code, Cache-First for Heavy Media
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Audio files: Cache if requested, otherwise fetch
  if (url.pathname.endsWith('.mp3')) {
    event.respondWith(
      caches.match(event.request).then((cachedResponse) => {
        if (cachedResponse) return cachedResponse;
        return fetch(event.request).then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const copy = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
          }
          return networkResponse;
        }).catch(() => new Response('Audio offline', { status: 503 }));
      })
    );
    return;
  }

  // Al-Quran Cloud API Pages: Network-first with cache fallback for offline reading
  if (url.hostname.includes('alquran.cloud') || url.hostname.includes('islamic.network')) {
    event.respondWith(
      fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const copy = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
          }
          return networkResponse;
        })
        .catch(() => {
          return caches.match(event.request).then((cached) => {
            if (cached) return cached;
            return new Response(JSON.stringify({ code: 503, status: 'Offline', data: null }), {
              headers: { 'Content-Type': 'application/json' }
            });
          });
        })
    );
    return;
  }

  // Network-First for HTML, Scripts, Styles, and Manifest (ensures instant updates on mobile!)
  const isCodeOrDoc = event.request.mode === 'navigate' ||
                      url.pathname.endsWith('.js') ||
                      url.pathname.endsWith('.css') ||
                      url.pathname.endsWith('.json') ||
                      url.pathname.endsWith('.html');

  if (isCodeOrDoc) {
    event.respondWith(
      fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const copy = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
          }
          return networkResponse;
        })
        .catch(async () => {
          const cached = await caches.match(event.request);
          if (cached) return cached;
          if (event.request.mode === 'navigate') {
            const rootCached = (await caches.match('/')) || 
                               (await caches.match('/index.html')) || 
                               (await caches.match('./index.html'));
            if (rootCached) return rootCached;
          }
          return new Response('Offline resource not found', { status: 503, headers: { 'Content-Type': 'text/plain' } });
        })
    );
    return;
  }

  // Images & Static Local Assets: Cache-first with network fallback
  event.respondWith(
    caches.match(event.request).then((cached) => {
      if (cached) return cached;
      return fetch(event.request).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200) {
          const copy = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
        }
        return networkResponse;
      });
    }).catch(async () => {
      return new Response('Offline resource not found', { status: 503, headers: { 'Content-Type': 'text/plain' } });
    })
  );
});

