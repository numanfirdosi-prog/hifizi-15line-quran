/**
 * NŪR AL-QURAN - Progressive Web App Service Worker
 * Provides offline caching for static assets, styles, scripts, and verified Quran pages.
 */

const CACHE_NAME = 'nur-al-quran-v2.9.2';

const STATIC_ASSETS = [
  '/',
  '/index.html',
  './',
  './index.html',
  './code.js',
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
  './assets/pages/1.webp',
  './assets/pages/2.webp',
  './assets/pages/3.webp',
  './assets/pages/4.webp'
];

// Install Event - Precache App Shell
self.addEventListener('install', (event) => {
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
    }).then(() => self.skipWaiting())
  );
});

// Activate Event - Clean Up Outdated Caches
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

// Fetch Event - Dynamic Cache Strategy
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

  // Navigation requests (HTML document): Network-first with fallback to cached index
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          if (response && response.status === 200) {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
          }
          return response;
        })
        .catch(async () => {
          const cached = await caches.match(event.request);
          if (cached) return cached;
          const rootCached = (await caches.match('/')) || 
                             (await caches.match('/index.html')) || 
                             (await caches.match('./index.html'));
          if (rootCached) return rootCached;
          return new Response('Offline', { status: 503, headers: { 'Content-Type': 'text/plain' } });
        })
    );
    return;
  }

  // Static Local Assets: Cache-first with network fallback
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

