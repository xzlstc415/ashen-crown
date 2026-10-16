// Offline support: the game shell is cached, so it opens without a connection after the first visit.
const CACHE='ruinaccord-__VERSION__';
const SHELL=['./','index.html','manifest.webmanifest','icon.svg','icon-192.png','icon-512.png','icon-maskable.png','apple-touch-icon.png'];
self.addEventListener('install',e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(SHELL)).then(()=>self.skipWaiting()))});
self.addEventListener('activate',e=>{e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()))});
self.addEventListener('fetch',e=>{
  const r=e.request;if(r.method!=='GET')return;
  // Leave the match server and other third-party calls alone; only our files and web fonts are cached.
  const host=new URL(r.url).hostname;if(host!==location.hostname&&!/^fonts\.(googleapis|gstatic)\.com$/.test(host))return;
  // Pages: try the network first so updates arrive, fall back to the cached copy offline.
  // The test page under /beta/ is left to the network, so it never replaces the cached main page.
  if(new URL(r.url).pathname.includes('/beta/'))return;
  if(r.mode==='navigate'){e.respondWith(fetch(r).then(res=>{const cp=res.clone();caches.open(CACHE).then(c=>c.put('index.html',cp));return res}).catch(()=>caches.match('index.html')));return}
  // Everything else (icons, fonts): cache first, then network, keeping a copy.
  e.respondWith(caches.match(r).then(hit=>hit||fetch(r).then(res=>{if(res.ok||res.type==='opaque'){const cp=res.clone();caches.open(CACHE).then(c=>c.put(r,cp))}return res})));
});
