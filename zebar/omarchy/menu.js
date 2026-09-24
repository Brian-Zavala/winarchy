// Omarchy menu for Windows: menu tree (menu.json), background picker, theme picker and
// keybindings viewer, in one Zebar widget. menu.ahk writes route.json and opens it;
// every action is handed back to menu.ahk (whitelisted in zpack.json).
import * as zebar from './zebar.mjs';
// Machine paths, written by `omarchy-win apply`.
import { AHK, MENU } from './env.js';
const COLS = 4;

// Errors go to %TEMP%\omarchy-win.log (there is no console to look at).
const log = msg => zebar.shellExec(AHK, [MENU, 'log', String(msg).slice(0, 500)]).catch(() => {});
window.addEventListener('error', e => log(`error: ${e.message} @${e.lineno}`));
window.addEventListener('unhandledrejection', e => log(`rejection: ${e.reason?.stack ?? e.reason}`));

const $ = id => document.getElementById(id);
const get = (file, type = 'json') =>
  fetch(`./${file}?t=${Date.now()}`, { cache: 'no-store' })
    .then(r => (r.ok ? r[type]() : null))
    .catch(() => null);

const [start, menus] = await Promise.all([get('route.json'), get('menu.json')]);
let index = null;    // index.json: themes + background groups (pickers only)
let status = null;   // status.json: current theme + background
let keys = null;     // parsed keybindings.txt

const stack = [];
let route = null;
let items = [];      // what is currently shown (after filtering)
let sel = 0;
let tab = 0;
let groups = [];

// ---------------------------------------------------------------- lifecycle
let closing = false;
function close() {
  if (closing) return;
  closing = true;
  zebar.currentWidget().window.tauri.close();
}
function run(action) {
  // Fire the action, then close: menu.ahk waits for this window to go away before
  // sending keys so they land on the window underneath.
  zebar.shellExec(AHK, [MENU, ...action]).catch(e => console.error(e));
  setTimeout(close, 60);
}
// Clicking outside (focus moves to another window) closes, like Omarchy's menu.
setTimeout(() => window.addEventListener('blur', close), 400);
$('scrim').onclick = close;

// ---------------------------------------------------------------- routes
async function go(name, push = true) {
  if (push && route) stack.push(route);
  route = name;
  sel = 0;
  $('search').value = '';
  if (name === 'background' || name === 'theme') {
    [index, status] = await Promise.all([get('index.json'), get('status.json')]);
    if (name === 'background') setupGroups();
  } else if (name === 'keys' && !keys) {
    keys = parseKeys((await get('keybindings.txt', 'text')) ?? '');
  }
  render(true);
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

function currentItems() {
  const q = $('search').value.trim();
  if (route === 'keys') {
    return q ? keys.filter(k => !k.section && matches(`${k.keys} ${k.label}`, q)) : keys;
  }
  if (route === 'theme') {
    return (index?.themes ?? []).filter(t => matches(t.label, q)).map(t => ({
      label: t.label, thumb: t.thumb, current: t.name === status?.theme, action: ['theme-set', t.name],
    }));
  }
  if (route === 'background') {
    const pool = q ? groups.flatMap(g => g.items.map(i => ({ ...i, group: g.label }))) : (groups[tab]?.items ?? []);
    return pool.filter(i => matches(`${i.label} ${i.group ?? ''}`, q)).map(i => ({
      ...i, current: same(i.path, status?.background), action: ['bg-set', i.path],
    }));
  }
  const m = menus?.[route];
  return (m?.items ?? []).filter(i => matches(i.label, q));
}

// ---------------------------------------------------------------- rendering
function render(initial = false) {
  items = currentItems();
  const picker = isPicker();
  const card = $('card');
  card.className = picker ? 'grid' : route === 'keys' ? 'wide' : '';
  $('list').classList.toggle('hidden', picker);
  $('grid').classList.toggle('hidden', !picker);
  $('tabs').classList.toggle('hidden', route !== 'background' || !!$('search').value.trim());
  $('footer').classList.toggle('hidden', !picker);
  $('search').placeholder =
    route === 'background' ? 'Search backgrounds…' :
    route === 'theme' ? 'Search themes…' :
    route === 'keys' ? 'Search keybindings…' :
    `${menus?.[route]?.title ?? 'Go'}…`;

  if (initial && picker) sel = Math.max(0, items.findIndex(i => i.current));
  if (route === 'keys') sel = Math.max(sel, items.findIndex(i => !i.section));
  sel = Math.min(Math.max(sel, 0), Math.max(items.length - 1, 0));

  if (picker) renderGrid(); else renderList();
}

function renderList() {
  const list = $('list');
  if (!items.length) {
    list.replaceChildren(Object.assign(document.createElement('div'), { className: 'empty-note', textContent: 'No matches' }));
    return;
  }
  list.replaceChildren(...items.map((it, i) => {
    if (it.section) {
      return Object.assign(document.createElement('div'), { className: 'section', textContent: it.section });
    }
    const row = document.createElement('div');
    row.className = route === 'keys' ? 'row key-row' : 'row';
    if (route === 'keys') {
      row.append(span('keys', it.keys), span('label', it.label));
    } else {
      row.append(span('icon', it.icon ?? ''), span('label', it.label));
      if (it.route) row.append(span('hint', '\uf105'));
    }
    if (i === sel) row.classList.add('selected');
    row.onmousemove = () => { if (sel !== i) { sel = i; highlight(); } };
    row.onclick = () => { sel = i; activate(); };
    return row;
  }));
  highlight();
}

function renderGrid() {
  if (route === 'background') {
    $('tabs').replaceChildren(...groups.map((g, i) => {
      const t = span(i === tab ? 'tab active' : 'tab', `${g.label} ${g.items.length}`);
      t.onclick = () => { tab = i; sel = 0; render(true); $('search').focus(); };
      return t;
    }));
    $('tabs').querySelector('.active')?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
  }
  const grid = $('grid');
  if (!items.length) {
    const note = index ? 'No matches' : 'No backgrounds yet: run Update > Themes & Backgrounds';
    grid.replaceChildren(Object.assign(document.createElement('div'), { className: 'empty-note', textContent: note }));
  } else {
    grid.replaceChildren(...items.map((it, i) => {
      const tile = document.createElement('div');
      tile.className = 'tile';
      const img = document.createElement('img');
      img.loading = 'lazy';
      img.decoding = 'async';
      img.src = it.thumb ? `./${it.thumb}` : '';
      tile.append(img);
      const name = span('name', it.label);
      if (it.group) name.append(span('group', ` · ${it.group}`));
      tile.append(name);
      if (it.current) tile.append(span('badge', '\uf00c'));
      tile.onmousemove = () => { if (sel !== i) { sel = i; highlight(); } };
      tile.onclick = () => { sel = i; activate(); };
      return tile;
    }));
  }
  highlight();
}

function highlight() {
  const container = isPicker() ? $('grid') : $('list');
  const els = [...container.children].filter(e => e.classList.contains('row') || e.classList.contains('tile'));
  const selectable = isPicker() ? items : items.filter(i => !i.section);
  const idx = selectable.indexOf(items[sel]);
  els.forEach((el, i) => el.classList.toggle('selected', i === idx));
  els[idx]?.scrollIntoView({ block: 'nearest' });
  if (isPicker()) {
    const it = items[sel];
    const where = route === 'background' ? (it?.path ?? '') : (it ? `Theme: ${it.label}` : '');
    $('footer').textContent = `Enter apply · ${route === 'background' ? 'Tab group · ' : ''}Esc close   ${where}`;
  }
}

function span(cls, text) {
  const s = document.createElement('span');
  s.className = cls;
  s.textContent = text;
  return s;
}

// ---------------------------------------------------------------- input
function move(delta) {
  if (!items.length) return;
  let i = Math.min(Math.max(sel + delta, 0), items.length - 1);
  while (items[i]?.section) i += delta > 0 ? 1 : -1;   // skip keybinding section headers
  if (i < 0 || i >= items.length) return;
  sel = i;
  highlight();
}

function activate() {
  const it = items[sel];
  if (!it || it.section) return;
  if (route === 'keys') return close();
  if (it.back) return back();
  if (it.route) return go(it.route);
  if (it.action) run(it.action);
}

window.addEventListener('keydown', e => {
  const k = e.key;
  const ctrl = e.ctrlKey;
  const picker = isPicker();
  const empty = !$('search').value;
  if (k === 'Escape') { e.preventDefault(); return close(); }
  if (k === 'Enter') { e.preventDefault(); return activate(); }
  if (k === 'ArrowDown' || (ctrl && (k === 'j' || k === 'n'))) { e.preventDefault(); return move(picker ? COLS : 1); }
  if (k === 'ArrowUp' || (ctrl && (k === 'k' || k === 'p'))) { e.preventDefault(); return move(picker ? -COLS : -1); }
  if (picker && (k === 'ArrowRight' || (ctrl && k === 'l'))) { e.preventDefault(); return move(1); }
  if (picker && (k === 'ArrowLeft' || (ctrl && k === 'h'))) { e.preventDefault(); return move(-1); }
  if (k === 'PageDown') { e.preventDefault(); return move(picker ? COLS * 3 : 8); }
  if (k === 'PageUp') { e.preventDefault(); return move(picker ? -COLS * 3 : -8); }
  if (k === 'Tab') {
    e.preventDefault();
    if (route === 'background' && empty && groups.length) {
      tab = (tab + (e.shiftKey ? -1 : 1) + groups.length) % groups.length;
      sel = 0;
      return render(true);
    }
    return move(e.shiftKey ? -1 : 1);
  }
  if (!picker && k === 'ArrowRight' && empty && items[sel]?.route) { e.preventDefault(); return activate(); }
  if ((k === 'Backspace' || (!picker && k === 'ArrowLeft')) && empty) { e.preventDefault(); return back(); }
});

$('search').addEventListener('input', () => { sel = 0; render(); });
$('search').addEventListener('blur', () => setTimeout(() => !closing && $('search').focus(), 0));

await go(start?.route && (menus?.[start.route] || ['background', 'theme', 'keys'].includes(start.route)) ? start.route : 'root', false);
$('search').focus();
