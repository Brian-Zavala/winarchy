// A theme, font or user.css change made while the menu or a bar panel was hidden (they
// hide instead of closing, see menu.js / panel.js): swap in fresh copies of the generated
// stylesheets on the next open - only when one changed, since fetching and re-parsing them
// on every open is time the window spends not showing. `winarchy apply` restarts Zebar for
// anything else.
const GENERATED = /(^|\/)(theme|font|user)\.css(\?|$)/;
const text = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.text() : '')).catch(() => null);
let seen = null;   // themeVersion + user.css when this page's sheets were last loaded

export async function restyle() {
  const [status, user] = await Promise.all([text('status.json'), text('user.css')]);
  if (status === null || user === null) return;
  let ver = '';
  try { ver = JSON.parse(status).themeVersion ?? ''; } catch {}
  const now = `${ver}\n${user}`;
  if (seen === null || now === seen) { seen = now; return; }   // the first open: just note it
  seen = now;
  const root = document.documentElement;
  const olds = [...document.querySelectorAll('link[rel="stylesheet"]')].filter(l => GENERATED.test(l.getAttribute('href')));
  root.style.transition = 'none';   // (the menu's palette morph is for previews)
  const news = await Promise.all(olds.map(old => new Promise(r => {
    const l = Object.assign(document.createElement('link'), { rel: 'stylesheet' });
    l.onload = l.onerror = () => r(l);
    l.href = `${old.getAttribute('href').replace(/\?.*$/, '')}?v=${Date.now()}`;
    old.after(l);
  })));
  // Swapped once loaded, so nothing shows unstyled; ids stay (display.js looks up #font).
  olds.forEach((old, i) => { const id = old.id; old.remove(); if (id) news[i].id = id; });
  getComputedStyle(root).getPropertyValue('--bg');   // settle before transitions are back
  root.style.transition = '';
}
