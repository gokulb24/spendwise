const CACHE='fet-v4';
const ASSETS=[
  './','./index.html','./manifest.webmanifest','./firebase-config.js',
  './icons/icon-192.png','./icons/icon-512.png','./icons/icon-512-maskable.png',
  './icons/apple-touch-icon.png','./icons/favicon.png',
  'https://cdn.jsdelivr.net/npm/chart.js@4.5.0/dist/chart.umd.js',
  'https://cdn.jsdelivr.net/npm/jspdf@2.5.2/dist/jspdf.umd.min.js',
  'https://cdn.jsdelivr.net/npm/jspdf-autotable@3.8.4/dist/jspdf.plugin.autotable.min.js',
  'https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js',
  'https://www.gstatic.com/firebasejs/10.12.5/firebase-auth-compat.js',
  'https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore-compat.js'
];
self.addEventListener('install',e=>{
  e.waitUntil(caches.open(CACHE).then(c=>Promise.all(ASSETS.map(u=>c.add(u).catch(()=>{})))).then(()=>self.skipWaiting()));
});
self.addEventListener('activate',e=>{
  e.waitUntil(caches.keys().then(ks=>Promise.all(ks.filter(k=>k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim()));
});
// Hosts whose traffic must always go straight to the network (live sync/auth).
const BYPASS=[/firestore\.googleapis\.com/,/firebaseio\.com/,/identitytoolkit\.googleapis\.com/,/securetoken\.googleapis\.com/,/googleapis\.com\/google\.firestore/];
self.addEventListener('fetch',e=>{
  if(e.request.method!=='GET')return;              // Firebase writes (POST) untouched
  const url=e.request.url;
  if(BYPASS.some(re=>re.test(url)))return;         // never intercept live Firebase APIs
  e.respondWith(
    caches.match(e.request).then(hit=>hit||fetch(e.request).then(res=>{
      const copy=res.clone();
      caches.open(CACHE).then(c=>c.put(e.request,copy)).catch(()=>{});
      return res;
    }).catch(()=>e.request.mode==='navigate'?caches.match('./index.html'):Response.error()))
  );
});
