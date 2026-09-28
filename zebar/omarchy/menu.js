// Omarchy menu for Windows: menu tree (menu.json), background picker, theme picker and
// keybindings viewer, in one Zebar widget. menu.ahk writes route.json and opens it;
// every action is handed back to menu.ahk (whitelisted in zpack.json).
import * as zebar from './zebar.mjs';
// Machine paths + settings, written by `winarchy apply` (read as a namespace, so a
// setting an older env.js doesn't have yet is just undefined).
import * as env from './env.js';
const { AHK, MENU } = env;
import { calm, wait, swap, skipSwap, glide, pop, stagger } from './motion.js';
const COLS = 4;
// Palette vars registered in menu.css (@property), so a previewed theme animates in.
const MORPH = ['bg', 'bg-light', 'fg', 'fg-dim', 'accent', 'alert', 'muted', 'selection'];
const SWATCHES = ['bg', 'fg', 'accent', 'red', 'orange', 'yellow', 'green', 'cyan', 'blue', 'magenta'];

// Errors go to %TEMP%\winarchy.log (there is no console to look at).
const log = msg => zebar.shellExec(AHK, [MENU, 'log', String(msg).slice(0, 500)]).catch(() => {});
window.addEventListener('error', e => log(`error: ${e.message} @${e.lineno}`));
window.addEventListener('unhandledrejection', e => log(`rejection: ${e.reason?.stack ?? e.reason}`));

const $ = id => document.getElementById(id);
const get = (file, type = 'json') =>
  fetch(`./${file}?t=${Date.now()}`, { cache: 'no-store' })
    .then(r => (r.ok ? r[type]() : null))
    .catch(() => null);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls, textContent: text ?? '' });
const span = (cls, text) => el('span', cls, text);

// menu.ahk activates the window after it loads (or shows it again): start the open
// animation then.
const focused = () => new Promise(r => {
  if (document.hasFocus()) return r();
  window.addEventListener('focus', r, { once: true });
  setTimeout(r, 300);
});

let menus = null;    // menu.json
let index = null;    // index.json: themes + background groups (pickers only)
let status = null;   // status.json: current theme + background
let keys = null;     // parsed keybindings.txt
let fonts = null;    // fonts.json: installed monospace fonts (font route)
let apps = null;     // apps.json: what Windows lists in Start (apps route)
let catalog = null;  // catalog.json: what winarchy can install, and what is already there
let herdrKeys = null;// parsed herdr-keys.txt (Learn > Herdr)
let defaults = null; // defaults.json: the coding agents, and which one is the default
let flags = null;    // menu-flags.json: what this PC has, for rows with a "when" (Omarchy's
                     // `when` conditions: Hibernate, the laptop display and touchpad)

const stack = [];
let route = null;
let items = [];      // what is currently shown (after filtering)
let sel = 0;
let tab = 0;
let groups = [];
// The row/tile for each item index, filled in by the last render (null for a section
// heading). Holding an arrow key must not walk every node in a 200-app list per repeat.
let rowOf = [];
let selEl = null;

// ---------------------------------------------------------------- lifecycle
// The window outlives a close: it hides, and menu.ahk shows it again for the next open on
// this monitor (focus starts it over from route.json), which saves starting a webview.
let closing = false;
let busy = false;    // an apply animation is playing: ignore input
let idle = false;    // hidden, waiting to be shown again
let openedAt = Date.now();
const win = () => zebar.currentWidget().window.tauri;
// fade: how long body.closing takes in menu.css (the landing fades slower).
function close(delay = 0, fade = 120) {
  if (closing) return;
  closing = true;
  busy = true;
  skipSwap();
  setTimeout(() => {
    document.body.classList.add('closing');
    setTimeout(hide, calm.matches ? 0 : fade);
  }, delay);
}
async function hide() {
  try {
    await win().hide();
  } catch (e) {
    log(`menu: hide failed, closing instead: ${e}`);
    // Let this close through: the close-request handler below would cancel it otherwise.
    quitting = true;
    return Promise.resolve(win().close()).catch(() => {});
  }
  reset();
  idle = true;
}
// Back to the empty page menu.html starts with.
function reset() {
  document.body.className = '';
  stack.length = 0;
  route = null;
  items = [];
  sel = tab = 0;
  groups = [];
  index = status = keys = fonts = herdrKeys = defaults = flags = null;
  $('search').value = '';
  palette(null);
  $('card').className = '';
  for (const id of ['list', 'grid', 'tabs', 'stage', 'info', 'swatches']) $(id).replaceChildren();
  delete $('info').dataset.name;
  for (const c of layers) { c.getAnimations().forEach(a => a.cancel()); c.classList.remove('on'); }
  wanted = null;
  const land = el('img');
  land.id = 'land';
  $('land').replaceWith(land);
  mouse = '';
  // Nothing is on screen any more, so no row to highlight and no key still repeating.
  rowOf = [];
  selEl = null;
  fast = false;
  clearTimeout(fastIdle);
  cancelAnimationFrame(moveFrame);
  moveFrame = 0;
  clearTimeout(typing);
  typing = 0;
  closing = busy = false;
}
// A theme or font change while hidden: fresh copies of the generated stylesheets, swapped
// in once loaded, without the palette morph (that is for previews).
async function restyle() {
  const root = document.documentElement;
  const olds = [...document.querySelectorAll('link[rel="stylesheet"]')].filter(l => !/menu\.css/.test(l.getAttribute('href')));
  root.style.transition = 'none';
  await Promise.all(olds.map(old => new Promise(r => {
    const l = Object.assign(document.createElement('link'), { rel: 'stylesheet' });
    l.onload = l.onerror = r;
    l.href = `${old.getAttribute('href').replace(/\?.*$/, '')}?v=${Date.now()}`;
    old.after(l);
  })));
  olds.forEach(l => l.remove());
  getComputedStyle(root).getPropertyValue('--bg');   // settle before the morph is back
  root.style.transition = '';
}
async function open(again = false) {
  idle = false;
  openedAt = Date.now();
  if (again) Promise.resolve(win().show()).catch(() => {});   // keep Tauri's state in step with menu.ahk's WinShow
  let start;
  [start, menus] = await Promise.all([get('route.json'), get('menu.json'), again && restyle()]);
  // Generated routes aren't in menu.json, so they need naming here or `menu.ahk open <x>`
  // silently falls back to root.
  const generated = r => ['background', 'theme', 'keys', 'font', 'apps', 'herdr-keys', 'agent'].includes(r)
    || r === 'install' || r === 'remove' || r.startsWith('install-') || r.startsWith('remove-');
  await go(start?.route && (menus?.[start.route] || generated(start.route)) ? start.route : 'root', false);
  $('search').focus();
  await focused();
  requestAnimationFrame(() => document.body.classList.add('shown'));
}
window.addEventListener('focus', () => { if (idle) open(true); });
// menu.ahk's toggle (and anything else closing the window) fades and hides it instead.
let quitting = false;
Promise.resolve(win().onCloseRequested?.(e => { if (quitting) return; e.preventDefault(); if (!idle) close(); })).catch(() => {});
function run(action) {
  if (action[0] === 'bg-set') return land(items[sel]);
  // Fire the action, then close: menu.ahk waits for this window to go away before
  // sending keys so they land on the window underneath.
  zebar.shellExec(AHK, [MENU, ...action]).catch(e => console.error(e));
  if (action[0] === 'theme-set' && !calm.matches) {
    busy = true;
    document.body.classList.add('applying');
    return close(280);
  }
  close(40);
}

// ---- landing: one animation from the picker to the new desktop
// Enter on a wallpaper: the card drops away and the blurred backdrop stays. Omarchy's reveal
// band (lib/transition.ps1: slanted, from the middle, 420 ms in-out cubic) opens on it with
// the full-size picture, which menu.ahk copies into thumbs/_land. winarchy leaves this
// monitor out of its own reveal and writes status.json once the desktop has the wallpaper;
// then the overlay fades, and the desktop under it already matches.
const LAND_MS = 420;
const LAND_EASE = 'cubic-bezier(.65, 0, .35, 1)';
// Get-RevealBand in lib/transition.ps1, at progress p, in this window's CSS pixels.
function band(p) {
  const w = innerWidth, h = innerHeight;
  const top = w / 2 + 0.09 * h, bottom = w / 2 - 0.09 * h, s = (w / 2 + 0.09 * h + 4) * p;
  return `polygon(${top - s}px 0, ${top + s}px 0, ${bottom + s}px ${h}px, ${bottom - s}px ${h}px)`;
}
// The copy shows up once menu.ahk has run: poll it until it decodes (or give up).
async function fullSize(name, ms) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    const img = new Image();
    img.src = `./thumbs/_land/${name}`;
    try { await img.decode(); return img; } catch { await wait(60); }
  }
  return null;
}
// When to open the band (Unix ms): winarchy writes reveal.json once its own reveal on the
// other monitors is ready, so they all open together (lib/transition.ps1, Send-RevealStart).
// Newer than the pick = this pick's; nothing within 3 s: now.
async function revealStart(t0) {
  while (Date.now() - t0 < 3000) {
    const r = await get('reveal.json');
    if (r?.start >= t0) return r.start;
    await wait(25);
  }
  return Date.now();
}
async function land(it) {
  busy = true;
  const ext = (it.path.match(/\.\w+$/)?.[0] ?? '.jpg').toLowerCase();
  const name = `${Date.now()}${ext}`;
  zebar.shellExec(AHK, [MENU, 'bg-set', it.path, name]).catch(e => console.error(e));
  if (calm.matches || env.REVEAL === false) return close();   // backgroundTransition "none"
  const t0 = Date.now();
  const desktop = (async () => {
    let done = it.current;
    while (!done && Date.now() - t0 < 6000) {
      done = same((await get('status.json'))?.background, it.path);
      if (!done) await wait(80);
    }
    if (!it.current) await wait(200);       // Explorer repaints the desktop
  })();
  backdrop(it.thumb);                       // normally showing already
  document.body.classList.add('landing');   // card, scrim and tint go; the blur stays
  let img = await fullSize(name, 1500);
  if (!img) {
    log(`landing: thumbs/_land/${name} never loaded, using the thumbnail`);
    img = new Image();
    img.src = `./${it.thumb}`;
    await img.decode().catch(() => {});
  }
  img.id = 'land';
  $('land').replaceWith(img);
  await wait(Math.max(0, 180 - (Date.now() - t0)));   // overlap the card's exit
  const start = await revealStart(t0);
  log(`landing: band at ${start} (${start - t0} ms after the pick)`);
  await wait(start - Date.now());
  document.body.classList.add('revealing');
  // The sharp picture settles as the blur pushes back behind it.
  img.animate([{ clipPath: band(0) }, { clipPath: band(1) }], { duration: LAND_MS, easing: LAND_EASE, fill: 'both' });
  img.animate([{ scale: 1.04 }, { scale: 1 }], { duration: LAND_MS + 280, easing: 'cubic-bezier(.2, .7, .2, 1)', fill: 'both' });
  for (const c of layers) c.animate([{ scale: 1 }, { scale: 1.06 }], { duration: LAND_MS, easing: LAND_EASE, fill: 'both' });
  await Promise.all([wait(LAND_MS + 280), desktop]);
  close(0, 300);
}
// Clicking outside (focus moves to another window) closes, like Omarchy's menu.
window.addEventListener('blur', () => busy || idle || Date.now() - openedAt < 400 || close());
$('scrim').onclick = () => busy || close();

// ---------------------------------------------------------------- routes
async function load(name) {
  if (!flags) flags = (await get('menu-flags.json')) ?? {};
  if (name === 'background' || name === 'theme') {
    [index, status] = await Promise.all([get('index.json'), get('status.json')]);
  } else if (name === 'keys' && !keys) {
    keys = parseKeys((await get('keybindings.txt', 'text')) ?? '');
  } else if (name === 'font') {
    [fonts, status] = await Promise.all([get('fonts.json'), get('status.json')]);
  } else if (name === 'apps') {
    apps = await get('apps.json');
    // The list is only as current as the last apply, and installing something should show
    // up without one. Rebuilding it takes about a second, far too long to open the route
    // behind, so kick it off unawaited: this open uses the file on disk, the next one is
    // current. (First ever open has no file yet, and renderList says so.)
    zebar.shellExec(AHK, [MENU, 'apps-refresh']).catch(() => {});
  } else if (name === 'herdr-keys' && !herdrKeys) {
    herdrKeys = parseKeys((await get('herdr-keys.txt', 'text')) ?? '');
  } else if (name === 'agent') {
    defaults = await get('defaults.json');
  } else if (name === 'install' || name === 'remove' || name.startsWith('install-') || name.startsWith('remove-')) {
    // Same deal as apps: show the file on disk now, and rebuild behind us so the next
    // open knows about anything just installed or removed.
    catalog = await get('catalog.json');
    zebar.shellExec(AHK, [MENU, 'catalog-refresh']).catch(() => {});
  }
}

async function go(name, push = true) {
  await load(name);   // before the transition: rendering is frozen during its update
  const first = route === null;
  if (push && route) stack.push(route);
  const enter = () => {
    route = name;
    sel = 0;
    $('search').value = '';
    if (name === 'background') setupGroups();
    render(true);
  };
  if (first) enter(); else swap(enter, push ? 'forward' : 'back');
}

function back() {
  if (stack.length) go(stack.pop(), false);
  else close();
}

function isPicker() { return route === 'background' || route === 'theme'; }

// ---------------------------------------------------------------- filtering
function matches(text, q) {
  if (!q) return true;
  text = text.toLowerCase();
  let i = 0;
  for (const ch of q.toLowerCase().replace(/\s+/g, '')) {
    i = text.indexOf(ch, i);
    if (i < 0) return false;
    i++;
  }
  return true;
}

function parseKeys(txt) {
  const out = [];
  for (const line of txt.split(/\r?\n/)) {
    if (!line.trim() || /^=+$/.test(line.trim()) || /^OMARCHY-STYLE/.test(line)) continue;
    if (/^\S/.test(line)) { out.push({ section: line.trim() }); continue; }
    const [k, ...rest] = line.trim().split(/\s{2,}/);
    out.push({ keys: k, label: rest.join('  ') });
  }
  return out;
}

function setupGroups() {
  const cur = status?.theme;
  const all = index?.groups ?? [];
  groups = [
    ...all.filter(g => g.id === cur),
    ...all.filter(g => g.id !== cur && g.id !== 'mine'),
    ...all.filter(g => g.id === 'mine'),
  ];
  // Open on the tab holding the current background, if we know it.
  tab = Math.max(0, groups.findIndex(g => g.items.some(i => same(i.path, status?.background))));
}

const same = (a, b) => !!a && !!b && a.toLowerCase() === b.toLowerCase();
// Font families come in long and short spellings ("JetBrainsMono Nerd Font" = "JetBrainsMono NF").
const fontKey = name => (name ?? '').toLowerCase().replace(/ nerd font mono$/, ' nfm').replace(/ nerd font$/, ' nf');
// Both keybinding viewers: a two-column list of key + description, read from a text
// file rather than menu.json, and Enter just closes.
const isKeys = r => r === 'keys' || r === 'herdr-keys';

function currentItems() {
  const q = $('search').value.trim();
  if (isKeys(route)) {
    const rows = (route === 'keys' ? keys : herdrKeys) ?? [];
    return q ? rows.filter(k => !k.section && matches(`${k.keys} ${k.label}`, q)) : rows;
  }
  if (route === 'agent') {
    // Omarchy picks no agent for you, so nothing is ticked until one is chosen. One that
    // isn't installed still shows: picking it says how to install it.
    return (defaults?.agents ?? []).filter(a => matches(a.label, q)).map(a => ({
      label: a.installed ? a.label : `${a.label}  (not installed)`,
      icon: a.icon, current: a.current, action: ['default-agent', a.key],
    }));
  }
  if (route === 'theme') {
    return (index?.themes ?? []).filter(t => matches(t.label, q)).map(t => ({
      ...t, current: t.name === status?.theme, action: ['theme-set', t.name],
    }));
  }
  if (route === 'background') {
    const pool = q ? groups.flatMap(g => g.items.map(i => ({ ...i, group: g.label }))) : (groups[tab]?.items ?? []);
    return pool.filter(i => matches(`${i.label} ${i.group ?? ''}`, q)).map(i => ({
      ...i, current: same(i.path, status?.background), action: ['bg-set', i.path],
    }));
  }
  if (route === 'font') {
    // Installed monospace fonts (winarchy font-list), Nerd Fonts first.
    const list = (fonts?.fonts ?? []).filter(f => matches(f.name, q)).map(f => ({
      label: f.name, font: f.name, icon: f.nerd ? '' : '', current: fontKey(f.name) === fontKey(status?.font), action: ['font-set', f.name],
    }));
    const more = { label: 'Install a Nerd Font…', icon: '', route: 'font-install' };
    return matches(more.label, q) ? [...list, more] : list;
  }
  if (route === 'apps') {
    // Everything Windows lists in Start (winarchy apps -> apps.json). Store apps and
    // desktop programs both launch through shell:AppsFolder, so one action covers both.
    return (apps?.apps ?? []).filter(a => matches(a.name, q)).map(a => ({
      label: a.name, icon: a.store ? '' : '', action: ['run-app', a.id],
    }));
  }
  if (route === 'install' || route === 'remove') {
    // The catalog's groups (catalog.json). Remove only offers a group with something in it.
    const removing = route === 'remove';
    return (catalog?.groups ?? [])
      .filter(g => (removing ? g.items.some(i => i.installed) : true))
      .filter(g => matches(g.label, q))
      .map(g => ({ label: g.label, icon: g.icon, route: `${route}-${g.key}` }));
  }
  if (route.startsWith('install-') || route.startsWith('remove-')) {
    const removing = route.startsWith('remove-');
    const group = (catalog?.groups ?? []).find(g => g.key === route.slice(removing ? 7 : 8));
    // Remove lists only what is there; Install lists everything and marks what you have.
    const pool = (group?.items ?? []).filter(i => (removing ? i.installed : true));
    return pool.filter(i => matches(i.label, q)).map(i => ({
      label: i.label, icon: i.icon,
      // An installed row stays listed but goes dim with a check, so the Install list still
      // reads as a catalog of everything on offer rather than hiding what you installed
      // from it. Omarchy's menu makes the same call.
      current: !removing && i.installed, dim: !removing && i.installed,
      action: [removing ? 'remove-app' : 'install-app', i.key],
    }));
  }
  const m = menus?.[route];
  return (m?.items ?? []).filter(i => (!i.when || flags?.[i.when]) && matches(i.label, q));
}

// ---------------------------------------------------------------- rendering
// `entry`: the route (or background tab) was just opened, so select the current item,
// place highlights without gliding and play the entry cascade. Typing only re-filters.
function render(entry = false) {
  items = currentItems();
  const card = $('card');
  const q = !!$('search').value.trim();
  card.className = route === 'background' ? 'grid' : route === 'theme' ? 'flow' : isKeys(route) ? 'wide' : '';
  document.body.classList.toggle('walls', route === 'background');
  $('list').classList.toggle('hidden', isPicker());
  $('grid').classList.toggle('hidden', route !== 'background');
  $('carousel').classList.toggle('hidden', route !== 'theme');
  $('tabs').classList.toggle('hidden', route !== 'background' || q);
  $('footer').classList.toggle('hidden', !isPicker());
  $('search').placeholder =
    route === 'background' ? 'Search backgrounds…' :
    route === 'theme' ? 'Search themes…' :
    isKeys(route) ? 'Search keybindings…' :
    route === 'font' ? 'Search fonts…' :
    route === 'apps' ? 'Search apps…' :
    route.startsWith('install') ? 'Install…' :
    route.startsWith('remove') ? 'Remove…' :
    `${menus?.[route]?.title ?? 'Go'}…`;
  if (route !== 'theme') palette(null);

  if (entry && isPicker()) sel = Math.max(0, items.findIndex(i => i.current));
  if (isKeys(route)) sel = Math.max(sel, items.findIndex(i => !i.section));
  sel = Math.min(Math.max(sel, 0), Math.max(items.length - 1, 0));

  if (route === 'theme') renderCarousel(entry);
  else if (route === 'background') renderGrid(entry);
  else renderList(entry);
}

function renderList(entry) {
  const list = $('list');
  if (!items.length) {
    // The apps route builds its list in the background on first open, so an empty one
    // means "not written yet", not "nothing installed".
    const note = route === 'apps' && !apps ? 'Building the app list… open Apps again in a moment'
      : route.startsWith('install') && !catalog ? 'Building the catalog… open Install again in a moment'
      : route.startsWith('remove') && !catalog ? 'Building the catalog… open Remove again in a moment'
      : route.startsWith('remove') ? 'Nothing here to remove'
      // Both of these only exist once Herdr is installed (Install > Terminal > Herdr).
      : route === 'herdr-keys' ? 'No Herdr keybindings yet — install Herdr, then: winarchy herdr keys'
      : route === 'agent' && !defaults ? 'No agent list yet — run: winarchy apply'
      : 'No matches';
    rowOf = [];
    selEl = null;
    list.replaceChildren(el('div', 'empty-note', note));
    return;
  }
  const rows = items.map((it, i) => {
    if (it.section) return el('div', 'section', it.section);
    const row = el('div', (isKeys(route) ? 'row key-row' : it.font ? 'row font-row' : 'row') + (it.dim ? ' dim' : ''));
    if (isKeys(route)) {
      row.append(span('keys', it.keys), span('label', it.label));
    } else {
      const label = span('label', it.label);
      // Font picker: each font previews itself (quoted; Nerd Font icons keep their glyphs).
      if (it.font) label.style.fontFamily = `"${it.font.replace(/["\\]/g, '\\$&')}", var(--font), monospace`;
      const icon = span('icon', it.icon ?? '');
      // A glyph from Omarchy's own font (its logo), as Omarchy's menu marks with iconFont.
      if (it.iconFont) icon.style.fontFamily = `'${it.iconFont}'`;
      row.append(icon, label);
      if (it.route) row.append(span('hint', '\uf105'));
      else if (it.current) row.append(span('hint', '\uf00c'));
    }
    row.onmousemove = e => { if (moved(e) && sel !== i) { sel = i; highlight(); } };
    row.onclick = () => { sel = i; activate(); };
    return row;
  });
  rowOf = rows.map(r => (r.classList.contains('row') ? r : null));   // sections aren't selectable
  list.replaceChildren(el('div', 'glider'), ...rows);
  highlight(entry);
  if (entry) stagger(rows.slice(0, 14), [{ opacity: 0, translate: '-8px 0' }, { opacity: 1, translate: '0 0' }], 16);
}

// ---- background picker: tabs + grid, and the wallpaper behind it all
function renderTabs() {
  const accent = id => (index?.themes ?? []).find(t => t.name === id)?.palette?.accent;
  const ink = el('div', 'glider');
  ink.dataset.axis = 'x';
  $('tabs').replaceChildren(ink, ...groups.map((g, i) => {
    const t = el('span', i === tab ? 'tab active' : 'tab');
    const dot = span('dot');
    dot.style.background = accent(g.id) ?? 'var(--fg-dim)';
    t.append(dot, span('', g.label), span('count', g.items.length));
    t.onclick = () => { switchTab(i); $('search').focus(); };
    return t;
  }));
}

function switchTab(i) {
  const dir = Math.sign(i - tab) || 1;
  tab = i;
  sel = 0;
  $('grid').scrollTop = 0;
  render(true);
  pop($('grid'), [{ opacity: 0, translate: `${dir * 48}px 0` }, { opacity: 1, translate: '0 0' }], { duration: 320 });
}

function renderGrid(entry) {
  if (entry) renderTabs();
  const grid = $('grid');
  if (!items.length) {
    const note = index ? 'No matches' : 'No backgrounds yet: run Update > Themes & Backgrounds';
    rowOf = [];
    selEl = null;
    grid.replaceChildren(el('div', 'empty-note', note));
    return;
  }
  const tiles = items.map((it, i) => {
    const tile = el('div', 'tile');
    const shot = el('div', 'shot');
    const img = el('img');
    img.loading = 'lazy';
    img.decoding = 'async';
    img.src = it.thumb ? `./${it.thumb}` : '';
    shot.append(img);
    const name = span('name', it.label);
    if (it.group) name.append(span('group', ` · ${it.group}`));
    tile.append(shot, name);
    if (it.current) tile.append(span('badge', '\uf00c'));
    tile.onmousemove = e => { if (moved(e) && sel !== i) { sel = i; highlight(); } };
    tile.onclick = () => { sel = i; activate(); };
    return tile;
  });
  rowOf = tiles;
  grid.replaceChildren(el('div', 'glider'), ...tiles);
  highlight(entry);
  if (entry) stagger(tiles, [{ opacity: 0, translate: '0 18px' }, { opacity: 1, translate: '0 0' }], 22);
}

// Two tiny canvases take turns: the new wallpaper is drawn into the hidden one, then
// they crossfade. At most one swap per frame, however fast the selection moves.
const layers = [...document.querySelectorAll('#backdrop canvas')];
let front = 0;
let wanted = null;
function backdrop(thumb) {
  if (!thumb || thumb === wanted) return;
  wanted = thumb;
  const img = new Image();
  img.src = `./${thumb}`;
  img.decode().then(() => requestAnimationFrame(() => {
    if (wanted !== thumb) return;   // a newer pick won
    const c = layers[1 - front];
    c.width = 192;
    c.height = 108;
    const ctx = c.getContext('2d');
    ctx.filter = 'blur(3px)';
    // Cover-fit, a little oversized so the blur has no dark edges.
    const s = Math.max(c.width / img.width, c.height / img.height) * 1.1;
    ctx.drawImage(img, (c.width - img.width * s) / 2, (c.height - img.height * s) / 2, img.width * s, img.height * s);
    c.classList.add('on');
    layers[front].classList.remove('on');
    front = 1 - front;
  })).catch(() => {});
}

// ---- theme picker: cover flow, and the whole menu previews the highlighted theme
function renderCarousel(entry) {
  const stage = $('stage');
  if (entry) {
    stage.replaceChildren(...(index?.themes ?? []).map(t => {
      const cover = el('div', 'cover off');
      cover.dataset.name = t.name;
      if (t.thumb) {
        // 960px previews: loaded once a cover comes near the middle (placeCarousel).
        const img = el('img');
        img.decoding = 'async';
        img.dataset.src = `./${t.thumb}`;
        cover.append(img);
      } else {
        const blank = el('div', 'blank', t.label);
        blank.style.background = t.palette?.bg ?? '';
        blank.style.color = t.palette?.fg ?? '';
        cover.append(blank);
      }
      if (t.name === status?.theme) cover.append(span('badge', '\uf00c'));
      cover.onclick = () => {
        const i = items.findIndex(x => x.name === t.name);
        if (i === sel) activate();
        else if (i >= 0) { sel = i; highlight(); }
      };
      return cover;
    }));
    // Big, but leave room for the reflection and the name below.
    const r = stage.getBoundingClientRect();
    stage.style.setProperty('--cw', `${Math.round(Math.min(r.width * 0.5, (r.height - 24) / 1.3 * 16 / 9))}px`);
    // Fan out from the middle once the folded start has been painted.
    requestAnimationFrame(() => requestAnimationFrame(() => placeCarousel(true)));
    placeInfo();
    return;
  }
  placeCarousel();
}

function placeCarousel(entry = false) {
  const stage = $('stage');
  const cw = parseFloat(stage.style.getPropertyValue('--cw')) || 480;
  const pos = new Map(items.map((it, i) => [it.name, i - sel]));
  for (const cover of stage.children) {
    const d = pos.get(cover.dataset.name);
    const a = Math.abs(d ?? 99);
    cover.classList.toggle('center', d === 0);
    cover.classList.toggle('off', a > 3);
    cover.style.zIndex = String(50 - Math.min(a, 49));
    cover.style.opacity = a > 3 ? '0' : String([1, 0.8, 0.5, 0.22][a]);
    cover.style.transitionDelay = entry ? `${a * 55}ms` : '';
    if (d === undefined) continue;   // filtered out: fade where it stands
    // Shown, or next in line to be: load its preview.
    const img = a <= 4 && cover.querySelector('img[data-src]');
    if (img) { img.src = img.dataset.src; delete img.dataset.src; }
    const s = Math.sign(d);
    const x = a ? s * cw * (0.66 + (a - 1) * 0.27) : 0;
    const z = a ? -cw * (0.45 + (a - 1) * 0.15) : 0;
    cover.style.transform = `translateX(${x}px) translateZ(${z}px) rotateY(${-s * 52}deg)`;
  }
  placeInfo();
}

function placeInfo() {
  const it = items[sel];
  palette(it);
  const info = $('info');
  if (!it) {
    info.replaceChildren(span('chip', 'No matches'));
    $('swatches').replaceChildren();
    footer('Esc close', '');
    return;
  }
  if (info.dataset.name === it.name) return;
  info.dataset.name = it.name;
  info.replaceChildren(
    span('title', it.label),
    span('chip', it.mode === 'light' ? '\uf185 light' : '\uf186 dark'),
    ...(it.current ? [span('chip now', '\uf00c current')] : []),
  );
  pop(info, [{ opacity: 0, translate: '0 8px' }, { opacity: 1, translate: '0 0' }]);
  const chips = SWATCHES.filter(k => it.palette?.[k]).map(k => {
    const s = span('');
    s.style.background = it.palette[k];
    s.title = k;
    return s;
  });
  $('swatches').replaceChildren(...chips);
  stagger(chips, [{ opacity: 0, scale: 0.3 }, { opacity: 1, scale: 1 }], 24);
  footer('←/→ browse · Enter apply · Esc close', `${sel + 1} / ${items.length}`);
}

// Preview a theme by overriding theme.css's colors inline; @property + the :root
// transition in menu.css animate the change. The current theme (or none) clears them.
function palette(t) {
  const root = document.documentElement.style;
  const p = t && !t.current ? t.palette : null;
  for (const k of MORPH) {
    if (p?.[k]) root.setProperty(`--${k}`, p[k]);
    else root.removeProperty(`--${k}`);
  }
  $('card').style.colorScheme = p ? t.mode : '';
}

function footer(keysText, where) {
  const f = $('footer');
  f.querySelector('.keys').textContent = keysText;
  f.querySelector('.where').textContent = where;
}

// ---- selection
function highlight(instant = false) {
  if (route === 'theme') return placeCarousel();
  const container = route === 'background' ? $('grid') : $('list');
  // Only the two rows that changed, not every row in the list (a render leaves selEl
  // pointing at a detached node, and removing a class from one of those is harmless).
  const target = rowOf[sel] ?? null;
  if (selEl !== target) {
    selEl?.classList.remove('selected');
    target?.classList.add('selected');
    selEl = target;
  }
  const glider = container.querySelector(':scope > .glider');
  if (glider) glide(glider, target, instant);
  target?.scrollIntoView({ block: 'nearest', container: 'nearest', behavior: instant || calm.matches ? 'instant' : 'smooth' });
  if (route === 'background') {
    const it = items[sel];
    backdrop(it?.thumb);
    footer('Enter apply · Tab group · Esc close', it?.path ?? '');
    const tabs = $('tabs');
    const active = tabs.querySelector('.tab.active');
    glide(tabs.querySelector('.glider'), active, instant);
    active?.scrollIntoView({ block: 'nearest', inline: 'nearest', container: 'nearest' });
  }
}

// Content sliding under a still cursor fires mousemove too; only a real move selects.
let mouse = '';
function moved(e) {
  const at = `${e.screenX},${e.screenY}`;
  if (at === mouse) return false;
  mouse = at;
  return true;
}

// ---------------------------------------------------------------- input
// A held arrow key repeats at the OS rate, several times faster than the 260ms glide and
// the smooth scroll they each restart. Left animated, the list trails a dozen rows behind
// the selection and you can't see what you are on. So while a key is repeating the
// highlight and the scroll jump straight to the row, at most once per frame; `fast` clears
// shortly after the last repeat, and single presses animate as before.
let fast = false;
let fastIdle = 0;
let moveFrame = 0;
function holdRepeat() {
  if (!fast) {
    fast = true;
    document.body.classList.add('fast');   // menu.css: no row/icon transitions meanwhile
  }
  clearTimeout(fastIdle);
  fastIdle = setTimeout(() => {
    fast = false;
    document.body.classList.remove('fast');
    highlight();   // settle exactly on the row the last repeat landed on
  }, 90);
}

function move(delta) {
  if (!items.length) return;
  let i = Math.min(Math.max(sel + delta, 0), items.length - 1);
  while (items[i]?.section) i += delta > 0 ? 1 : -1;   // skip keybinding section headers
  if (i < 0 || i >= items.length || i === sel) return;
  sel = i;
  if (!fast) return highlight();
  if (moveFrame) return;   // several repeats in one frame: one DOM update for all of them
  moveFrame = requestAnimationFrame(() => {
    moveFrame = 0;
    highlight(true);
  });
}

function activate() {
  const it = items[sel];
  if (!it || it.section) return;
  if (it.dim) return;   // already installed: the row is a catalog entry, not an action
  if (isKeys(route)) return close();
  if (it.back) return back();
  if (it.route) return go(it.route);
  if (it.action) run(it.action);
}

window.addEventListener('keydown', e => {
  if (busy) return e.preventDefault();
  if (typing && e.key.length > 1) flushSearch();   // Enter/arrows act on what was typed
  if (e.repeat) holdRepeat();                      // held key: move instantly (see move())
  const k = e.key;
  const ctrl = e.ctrlKey;
  const flow = route === 'theme';
  const grid = route === 'background';
  const empty = !$('search').value;
  if (k === 'Escape') { e.preventDefault(); return close(); }
  if (k === 'Enter') { e.preventDefault(); return activate(); }
  if (k === 'ArrowDown' || (ctrl && (k === 'j' || k === 'n'))) { e.preventDefault(); return move(grid ? COLS : 1); }
  if (k === 'ArrowUp' || (ctrl && (k === 'k' || k === 'p'))) { e.preventDefault(); return move(grid ? -COLS : -1); }
  if ((flow || grid) && (k === 'ArrowRight' || (ctrl && k === 'l'))) { e.preventDefault(); return move(1); }
  if ((flow || grid) && (k === 'ArrowLeft' || (ctrl && k === 'h'))) { e.preventDefault(); return move(-1); }
  if (k === 'PageDown') { e.preventDefault(); return move(grid ? COLS * 3 : flow ? 5 : 8); }
  if (k === 'PageUp') { e.preventDefault(); return move(grid ? -COLS * 3 : flow ? -5 : -8); }
  if (k === 'Tab') {
    e.preventDefault();
    if (grid && empty && groups.length) return switchTab((tab + (e.shiftKey ? -1 : 1) + groups.length) % groups.length);
    return move(e.shiftKey ? -1 : 1);
  }
  if (!isPicker() && k === 'ArrowRight' && empty && items[sel]?.route) { e.preventDefault(); return activate(); }
  if ((k === 'Backspace' || (!isPicker() && k === 'ArrowLeft')) && empty) { e.preventDefault(); return back(); }
});

// The wheel spins the cover flow one theme per notch; touchpads send many small deltas,
// so they add up first (and at most one step per frame).
let wheel = 0;
let wheelIdle = 0;
let wheelFrame = false;
window.addEventListener('wheel', e => {
  if (route !== 'theme' || busy) return;
  e.preventDefault();
  const d = (e.deltaY || e.deltaX) * (e.deltaMode === 1 ? 40 : 1);
  if (Math.sign(d) !== Math.sign(wheel)) wheel = 0;
  wheel += d;
  clearTimeout(wheelIdle);
  wheelIdle = setTimeout(() => (wheel = 0), 150);
  if (wheelFrame || Math.abs(wheel) < 100) return;
  move(Math.sign(wheel));
  wheel = 0;
  wheelFrame = true;
  requestAnimationFrame(() => (wheelFrame = false));
}, { passive: false });

// Typing re-filters once the keys pause (a background search rebuilds every tile).
let typing = 0;
function flushSearch() {
  clearTimeout(typing);
  typing = 0;
  if (!busy) { sel = 0; render(); }
}
$('search').addEventListener('input', () => {
  clearTimeout(typing);
  typing = setTimeout(flushSearch, 50);
});
$('search').addEventListener('blur', () => setTimeout(() => !closing && $('search').focus(), 0));

await open();
