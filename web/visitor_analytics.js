/* First-party anonymous app-open analytics; never send URLs, accounts or content. */
(() => {
  if (location.hostname !== 'arivora.onrender.com' || navigator.doNotTrack === '1' || navigator.globalPrivacyControl === true) return;
  try {
    const key = 'arivora_visitor_v1';
    let visitor;
    try { visitor = JSON.parse(localStorage.getItem(key)); } catch (_) {}
    const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
    if (!visitor || !uuid.test(visitor.id) || !Number.isFinite(visitor.expires) || visitor.expires <= Date.now()) {
      visitor = {id: crypto.randomUUID(), expires: Date.now() + 90 * 86400000};
      localStorage.setItem(key, JSON.stringify(visitor));
    }
    let source = 'direct';
    if (document.referrer) {
      const host = new URL(document.referrer).hostname.toLowerCase();
      if (host !== location.hostname) {
        source = 'other';
        for (const [label, domains] of Object.entries({google:['google.com','google.co.in'], bing:['bing.com'], facebook:['facebook.com','fb.com'], instagram:['instagram.com'], whatsapp:['whatsapp.com','wa.me']})) {
          if (domains.some(domain => host === domain || host.endsWith('.' + domain))) source = label;
        }
      }
    }
    const body = JSON.stringify({event_id: crypto.randomUUID(), visitor_id: visitor.id, source});
    const send = () => fetch('https://akka-tutor-backend.onrender.com/analytics/visit', {
      method: 'POST', headers: {'Content-Type':'application/json'}, body,
      credentials: 'omit', keepalive: true, referrerPolicy: 'no-referrer',
    });
    // Retry with the SAME event ID, so a lost response cannot double-count.
    send().then(response => { if (response.status >= 500) setTimeout(() => send().catch(() => {}), 5000); })
      .catch(() => setTimeout(() => send().catch(() => {}), 5000));
  } catch (_) { /* Storage blocked or unavailable: leave the application unaffected. */ }
})();
