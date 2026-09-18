/**
 * NŪR AL-QURAN - Progressive Web App Service Worker
 * Provides offline caching for static assets, styles, scripts, and verified Quran pages.
 */

const CACHE_NAME = 'nur-al-quran-v2.5.0';

const STATIC_ASSETS = [
  './',
  './index.html',
  './code.js',
  './style.css',
  './mushaf-15line.css',
  './mushaf-redesign.css',
  './audio-advanced.css',
  './ramadan.css',
  './faq.css',
  './manifest.json',
  './assets/icon-192.png',
  './assets/icon-512.png'
];

// Install Event - Precache App Shell
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[SW] Precaching Nūr Al-Quran core assets');
      return cache.addAll(STATIC_ASSETS);
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

  // Static Local Assets: Cache-first
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
    }).catch(() => {
      if (event.request.mode === 'navigate') {
        return caches.match('./index.html');
      }
    })
  );
});

