// Omarchy Quattro's Display panel (shell/plugins/panels/monitor) on Windows. menu.ahk opens
// it from the bar's display icon after writing display-anchor.json (the click's x and the
// monitor, n); the panel draws the last display.json at once and asks for a fresh one
// (lib/display.ahk: every monitor, its brightness, scale and scale steps).
//   j / k, arrows: section · h / l: adjust or pick · Enter: choose · Esc: close
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { panel } from './panel.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls ?? '', textContent: text ?? '' });
// Resolves once menu.ahk has finished (zebar waits for the process), so actions can queue.
const act = (...args) => zebar.shellExec(env.AHK, [env.MENU, ...args.map(String)]).catch(e => console.error(e));
const get = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).catch(() => null);

const GLYPH = { monitor: '\u{F0379}', monitors: '\u{F037A}', check: '\u{F012C}' };
// Quattro's text size notches (px); omarchy-display-text-size takes 9-20, 12 = default.
const TEXT_STOPS = [9, 10, 11, 12, 14, 16, 20];
// Quattro's scale presets are 1, 1.25, 1.6, 2, 3, 4. Windows only has its own steps, so
// these are the ones nearest them (plus whatever the monitor is on now).
const SCALE_PRESETS = [100, 125, 150, 175, 200, 250, 300, 400];

// Quattro's brightnessName: bands wide enough that a nudge keeps the name.
function mood(p) {
  p = Math.round(p);
  if (p >= 95) return 'Sun blast';
  if (p >= 80) return 'Solar flare';
  if (p >= 65) return 'Golden hour';
  if (p >= 45) return 'Even day';
  if (p >= 30) return 'Soft glow';
  if (p >= 20) return 'Lamp light';
  if (p >= 10) return 'Candlelit';
  return 'Night owl';
}
const scaleLabel = pct => `${+(pct / 100).toFixed(2)}x`;

// ---- state
let data = null;          // display.json
let brightness = -1;      // the focused monitor's, as last set here or read
let textPx = 12;
let textPending = -1;     // a stop index while a text size change is on its way
let cursorOn = false;
let section = 'brightness', index = -1;
let panelMon = null;      // the AHK monitor this window is for (display-anchor.json "n")

const monitors = () => data?.monitors ?? [];
const enabled = () => monitors().filter(m => m.enabled);
// This window's monitor: the window outlives a close and belongs to one monitor, while
// display.json may still be the one written for another monitor's panel.
const focused = () => monitors().find(m => m.n === panelMon && m.enabled)
  ?? monitors().find(m => m.focused && m.enabled) ?? enabled()[0] ?? null;
function scaleValues() {
  const m = focused();
  if (!m?.scales?.length) return [];
  return m.scales.filter(v => SCALE_PRESETS.includes(v) || v === m.scale);
}
function sections() {
  const list = [];
  if (brightness >= 0) list.push('brightness');
  list.push('textsize');
  if (scaleValues().length) list.push('scale');
  if (monitors().length > 1) list.push('monitors');
  return list;
}

// ---- sliders (Quattro's PanelSlider): drag, click, wheel; `moved` while dragging,
// `released` when let go.
function slider(node, { min, max, moved, released }) {
  let value = min;
  const set = v => {
    value = Math.max(min, Math.min(max, Math.round(v)));
    node.style.setProperty('--p', `${((value - min) / Math.max(1, max - min)) * 100}%`);
    node.setAttribute('aria-valuenow', String(value));
  };
  const at = e => {
    const r = node.getBoundingClientRect();
    return min + ((e.clientX - r.left) / r.width) * (max - min);
  };
  node.addEventListener('pointerdown', e => {
    if (e.button !== 0) return;
    node.setPointerCapture(e.pointerId);
    node.classList.add('dragging');
    set(at(e)); moved?.(value);
  });
  node.addEventListener('pointermove', e => {
    if (!node.classList.contains('dragging')) return;
    const before = value;
    set(at(e));
    if (value !== before) moved?.(value);
  });
  const end = e => {
    if (!node.classList.contains('dragging')) return;
    node.classList.remove('dragging');
    try { node.releasePointerCapture(e.pointerId); } catch {}
    released?.(value);
  };
  node.addEventListener('pointerup', end);
  node.addEventListener('pointercancel', end);
  node.addEventListener('wheel', e => {
    e.preventDefault();
    set(value + (e.deltaY < 0 ? 1 : -1) * (node.step ?? 1));
    moved?.(value); released?.(value);
  }, { passive: false });
  return { set, get value() { return value; }, get dragging() { return node.classList.contains('dragging'); } };
}

// Brightness: 1-100, 5 a wheel notch, applied 180 ms after the last move (Quattro's
// debounce). One set at a time: a DDC/CI write takes a moment, and writes that overlap
// can land out of order, so the newest waits for the one in flight.
let pending = null, busy = false, debounce = 0;
function applyBrightness(v) {
  pending = v;
  if (busy) return;
  const m = focused();
  if (!m) return;
  const next = pending;
  pending = null;
  busy = true;
  act('brightness', m.n, next).finally(() => {
    busy = false;
    if (pending !== null) applyBrightness(pending);
  });
}
const bright = slider($('brightness'), {
  min: 1, max: 100,
  moved: v => { brightness = v; renderBrightnessText(); clearTimeout(debounce); debounce = setTimeout(() => applyBrightness(v), 180); },
  released: v => { clearTimeout(debounce); brightness = v; renderBrightnessText(); applyBrightness(v); },
});
$('brightness').step = 5;

// Text size snaps to the notches and applies on release (the whole shell reflows).
const text = slider($('textsize'), {
  min: 0, max: TEXT_STOPS.length - 1,
  moved: i => { $('textValue').textContent = `${TEXT_STOPS[i]}px`; },
  released: i => setTextSize(i),
});
$('textsize').querySelector('.ticks').append(...TEXT_STOPS.map((_, i) => {
  const t = el('i');
  t.style.left = `${(i / (TEXT_STOPS.length - 1)) * 100}%`;
  return t;
}));
function nearestStop(px) {
  let best = 0;
  TEXT_STOPS.forEach((s, i) => { if (Math.abs(s - px) < Math.abs(TEXT_STOPS[best] - px)) best = i; });
  return best;
}
async function setTextSize(i) {
  if (TEXT_STOPS[i] === textPx && textPending < 0) return;
  textPending = i;
  renderText();
  await act('text-size', TEXT_STOPS[i]);
  // font.css now has the new size: reload it here (the bar and menu pick it up from
  // status.json's version bump).
  $('font').href = `./font.css?v=${Date.now()}`;
  setTimeout(() => { readTextSize(); textPending = -1; renderText(); place(); }, 150);
}
function readTextSize() {
  const v = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--text-size'));
  textPx = Number.isFinite(v) ? v : 12;
}

// ---- render
function renderBrightnessText() {
  const has = brightness >= 0;
  $('mood').textContent = has ? mood(brightness) : 'Fixed brightness';
  $('brightnessValue').textContent = has ? `${Math.round(brightness)}%` : '';
}

function renderText() {
  const i = textPending >= 0 ? textPending : nearestStop(textPx);
  if (!text.dragging) text.set(i);
  $('textValue').textContent = `${textPending >= 0 ? TEXT_STOPS[textPending] : textPx}px`;
  $('textsize').setAttribute('aria-valuetext', $('textValue').textContent);
}

function render() {
  const m = focused();
  $('heroGlyph').textContent = monitors().length > 1 ? GLYPH.monitors : GLYPH.monitor;

  $('brightnessBox').classList.toggle('hidden', brightness < 0);
  if (brightness >= 0 && !bright.dragging) bright.set(brightness);
  renderBrightnessText();
  renderText();

  // Scale: the steps Windows offers this monitor, nearest Quattro's presets.
  const values = scaleValues();
  $('scaleBox').classList.toggle('hidden', !values.length);
  $('scaleMonitor').textContent = enabled().length > 1 && m ? m.name : '';
  $('scales').replaceChildren(...values.map((v, i) => {
    const b = el('button', `pill${v === m.scale ? ' on' : ''}${v === m.recommended ? ' rec' : ''}`, scaleLabel(v));
    b.setAttribute('role', 'radio');
    b.setAttribute('aria-checked', String(v === m.scale));
    b.title = `${v}%${v === m.recommended ? ' (recommended)' : ''}`;
    b.onclick = () => setScale(v);
    b.onmouseenter = () => hover('scale', i);
    return b;
  }));

  // Displays, with more than one: click turns one on or off; the last one on stays on.
  const list = monitors();
  $('monitorsBox').classList.toggle('hidden', list.length < 2);
  const on = enabled().length;
  $('monitors').replaceChildren(...list.map((d, i) => {
    const row = el('button', `mon${d.enabled ? '' : ' off'}${d.enabled && on <= 1 ? ' locked' : ''}`);
    const name = el('span', 'name', d.name);
    if (d.focused) name.append(el('small', '', ' · focused'));
    row.append(el('span', 'glyph', GLYPH.monitor), name, el('span', 'check', d.enabled ? GLYPH.check : ''));
    row.title = d.enabled ? (on <= 1 ? 'The last display that is on stays on' : 'Click: turn this display off') : 'Click: turn this display on';
    row.onclick = () => toggleMonitor(d);
    row.onmouseenter = () => hover('monitors', i);
    return row;
  }));

  clampCursor();
  paintCursor();
  place();
}

async function setScale(v) {
  const m = focused();
  if (!m || v === m.scale) return;
  m.scale = v;
  render();
  await act('scale', m.n, v);
  refresh();
}

async function toggleMonitor(d) {
  if (d.enabled && enabled().length <= 1) return;
  await act('monitor', d.key, d.enabled ? 'off' : 'on');
  refresh();
}

// ---- keyboard cursor (Quattro's: sections top to bottom; the sliders are one row,
// the scale pills one row walked with h/l, the displays one row each)
function clampCursor() {
  const list = sections();
  if (!list.includes(section)) { section = list[0]; index = first(section); }
  if (section === 'scale') index = Math.max(0, Math.min(scaleValues().length - 1, index));
  if (section === 'monitors') index = Math.max(0, Math.min(monitors().length - 1, index));
}
const first = s => (s === 'brightness' || s === 'textsize' ? -1 : 0);
function move(dy) {
  const list = sections();
  const si = list.indexOf(section);
  if (section === 'monitors' && ((dy > 0 && index < monitors().length - 1) || (dy < 0 && index > 0))) { index += dy; return; }
  const next = list[si + dy];
  if (!next) return;
  section = next;
  index = next === 'monitors' && dy < 0 ? monitors().length - 1 : first(next);
}
function adjust(dx) {
  if (section === 'brightness' && brightness >= 0) {
    brightness = Math.max(1, Math.min(100, brightness + dx * 5));
    bright.set(brightness);
    renderBrightnessText();
    applyBrightness(brightness);
  } else if (section === 'textsize') {
    const i = Math.max(0, Math.min(TEXT_STOPS.length - 1, (textPending >= 0 ? textPending : nearestStop(textPx)) + dx));
    setTextSize(i);
  } else if (section === 'scale') {
    index = Math.max(0, Math.min(scaleValues().length - 1, index + dx));
  }
}
function activate() {
  if (section === 'scale') setScale(scaleValues()[index]);
  else if (section === 'monitors') toggleMonitor(monitors()[index]);
}
function hover(s, i) { section = s; index = i; cursorOn = true; paintCursor(); }
function paintCursor() {
  document.body.classList.toggle('cursor-on', cursorOn);
  for (const n of document.querySelectorAll('.has-cursor')) n.classList.remove('has-cursor');
  const target = section === 'brightness' ? $('brightness')
    : section === 'textsize' ? $('textsize')
    : section === 'scale' ? $('scales').children[index]
    : $('monitors').children[index];
  target?.classList.add('has-cursor');
  target?.scrollIntoView?.({ block: 'nearest' });
}
$('brightness').addEventListener('mouseenter', () => hover('brightness', -1));
$('textsize').addEventListener('mouseenter', () => hover('textsize', -1));

// ---- position: under the bar, centered on the icon, kept on the monitor
let anchorX = null;
function place() {
  const w = $('wrap').getBoundingClientRect().width;
  const x = anchorX ?? window.innerWidth / 2;
  document.documentElement.style.setProperty('--left', `${Math.max(12, Math.min(window.innerWidth - w - 12, x - w / 2))}px`);
}

// ---- data: re-read every 5 s while open (Quattro), without fighting a drag or a set
// that is still on its way.
async function load() {
  const next = await get('display.json');
  if (!next) return;
  data = next;
  const m = focused();
  if (!bright.dragging && !busy && pending === null) brightness = m ? m.brightness : -1;
  render();
}
async function refresh() {
  await act('display-state', panelMon ?? focused()?.n ?? '');
  await load();
}

// ---- lifecycle (panel.js: the window hides on close and is shown again next time)
const close = () => p.close();
window.addEventListener('keydown', e => {
  const k = e.key;
  if (k === 'Escape') return close();
  const dy = k === 'j' || k === 'ArrowDown' ? 1 : k === 'k' || k === 'ArrowUp' ? -1 : 0;
  const dx = k === 'l' || k === 'ArrowRight' ? 1 : k === 'h' || k === 'ArrowLeft' ? -1 : 0;
  if (!dy && !dx && k !== 'Enter' && k !== ' ') return;
  e.preventDefault();
  // The first key only shows where the cursor is (Quattro).
  if (!cursorOn) { cursorOn = true; paintCursor(); return; }
  if (dy) move(dy);
  else if (dx) adjust(dx);
  else activate();
  paintCursor();
});

const p = panel({
  name: 'display',
  async open({ anchor }) {
    anchorX = Number.isFinite(anchor.x) ? anchor.x : null;
    panelMon = Number.isInteger(anchor.n) ? anchor.n : null;
    cursorOn = false; textPending = -1; pending = null;
    data = (await get('display.json')) ?? data;     // the last state, drawn at once
    brightness = focused()?.brightness ?? -1;
    readTextSize();                                 // font.css may have changed while hidden
    section = brightness >= 0 ? 'brightness' : 'textsize';
    index = -1;
    render();
    refresh();                                      // this monitor's brightness now (DDC/CI)
  },
});
p.every(5000, refresh);
