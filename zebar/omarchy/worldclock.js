// The world clock (Omarchy's omarchy.elsewhen, without the globe): a row per city with its
// time, the offset from here and a strip of the day. Cities are IANA zones kept in
// localStorage. menu.ahk opens it (bar clock middle click, Super+Ctrl+Alt+E).
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { calm } from './motion.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls, textContent: text ?? '' });

const HERE = Intl.DateTimeFormat().resolvedOptions().timeZone;
// Here, and four well-spread places to start from.
const DEFAULTS = [HERE, 'America/New_York', 'Europe/London', 'Asia/Kolkata', 'Asia/Tokyo'];

let zones = DEFAULTS.filter((z, i, all) => all.indexOf(z) === i);
try {
  const saved = JSON.parse(localStorage.getItem('worldclock') ?? 'null');
  if (Array.isArray(saved) && saved.length) zones = saved;
} catch {}
const save = () => { try { localStorage.setItem('worldclock', JSON.stringify(zones)); } catch {} };

const validZone = z => { try { new Intl.DateTimeFormat('en', { timeZone: z }); return true; } catch { return false; } };
const city = z => z.split('/').pop().replaceAll('_', ' ');
const fmt = (z, opts) => new Intl.DateTimeFormat(env.CLOCK_24H ? 'en-GB' : 'en-US', { timeZone: z, ...opts });

// Minutes east of UTC for a zone right now (the difference of the same instant read in
// both zones, which handles DST without a timezone database of our own).
function offsetMinutes(z, now) {
  const p = Object.fromEntries(fmt(z, { hourCycle: 'h23', year: 'numeric', month: 'numeric', day: 'numeric', hour: 'numeric', minute: 'numeric' })
    .formatToParts(now).map(x => [x.type, x.value]));
  return (Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute) - Math.floor(now / 60000) * 60000) / 60000;
}
function relative(z, now) {
  const d = offsetMinutes(z, now) - offsetMinutes(HERE, now);
  if (!d) return 'same time';
  const h = Math.floor(Math.abs(d) / 60), m = Math.abs(d) % 60;
  return `${h}${m ? `:${String(m).padStart(2, '0')}` : ''}h ${d > 0 ? 'ahead' : 'behind'}`;
}

function render() {
  const now = new Date();
  $('rows').replaceChildren(...zones.map(z => {
    const p = Object.fromEntries(fmt(z, { hourCycle: 'h23', hour: 'numeric', minute: 'numeric' }).formatToParts(now).map(x => [x.type, x.value]));
    const hour = Number(p.hour);
    const row = el('div', z === HERE ? 'row here' : 'row');
    row.append(el('span', 'name', city(z)), el('span', 'time', fmt(z, { hour: env.CLOCK_24H ? '2-digit' : 'numeric', minute: '2-digit', hourCycle: env.CLOCK_24H ? 'h23' : 'h12' }).format(now)));
    const del = el('button', 'del', '×');
    del.title = 'Remove';
    del.onclick = () => { zones = zones.filter(x => x !== z); save(); render(); };
    row.append(del);
    row.append(el('span', 'sub', `${fmt(z, { weekday: 'short' }).format(now)} · ${relative(z, now)}`));
    const strip = el('div', 'strip');
    for (let h = 0; h < 24; h++) strip.append(el('i', [h >= 6 && h < 18 ? 'day' : '', h === hour ? 'now' : ''].join(' ').trim()));
    row.append(strip);
    return row;
  }));
}

function addZone(text) {
  const z = text.trim().replaceAll(' ', '_');
  const match = Intl.supportedValuesOf('timeZone').find(x => x.toLowerCase() === z.toLowerCase() || city(x).toLowerCase() === z.toLowerCase().replaceAll('_', ' '));
  const pick = match ?? (validZone(z) ? z : null);
  if (!pick) return false;
  if (!zones.includes(pick)) { zones.push(pick); save(); }
  render();
  return true;
}

// ---- lifecycle
let closing = false;
function close() {
  if (closing) return;
  closing = true;
  document.body.classList.remove('shown');
  setTimeout(() => Promise.resolve(zebar.currentWidget().window.tauri.close()).catch(() => {}), calm.matches ? 0 : 110);
}

document.querySelector('.head .glyph').textContent = '\u{F01E7}';     // earth
for (const z of Intl.supportedValuesOf('timeZone')) $('zones').append(Object.assign(document.createElement('option'), { value: z }));
$('city').addEventListener('keydown', e => {
  if (e.key !== 'Enter') return;
  if (addZone(e.target.value)) e.target.value = '';
  else e.target.style.borderColor = 'var(--alert, #f7768e)';
});
$('city').addEventListener('input', e => { e.target.style.borderColor = ''; });
document.addEventListener('mousedown', e => { if (!$('panel').contains(e.target)) close(); });
window.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });

setInterval(render, 5000);
document.documentElement.style.setProperty('--top', `${(env.BAR_HEIGHT ?? 26) + (env.GAP ?? 10)}px`);
render();
// menu.ahk activates the window once it exists: open then (the webview paints on focus).
const shown = () => requestAnimationFrame(() => document.body.classList.add('shown'));
if (document.hasFocus()) shown();
else { window.addEventListener('focus', shown, { once: true }); setTimeout(shown, 300); }
setTimeout(() => window.addEventListener('blur', () => { if (document.activeElement !== $('city')) close(); }), 400);
