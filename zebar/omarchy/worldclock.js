// The world clock (Omarchy's omarchy.elsewhen, without the globe): a row per city with its
// time, the offset from here and a strip of the day. Cities are IANA zones kept in
// localStorage. menu.ahk opens it (bar clock middle click, Super+Ctrl+Alt+E).
import * as env from './env.js';
import { panel } from './panel.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls, textContent: text ?? '' });

const HERE = Intl.DateTimeFormat().resolvedOptions().timeZone;
// Here, and four well-spread places to start from.
const DEFAULTS = [HERE, 'America/New_York', 'Europe/London', 'Asia/Kolkata', 'Asia/Tokyo'];

let zones = [];
// (Read again on every open: another monitor's world clock may have changed them.)
function loadZones() {
  zones = DEFAULTS.filter((z, i, all) => all.indexOf(z) === i);
  try {
    const saved = JSON.parse(localStorage.getItem('worldclock') ?? 'null');
    if (Array.isArray(saved) && saved.length) zones = saved;
  } catch {}
}
const save = () => { try { localStorage.setItem('worldclock', JSON.stringify(zones)); } catch {} };

const validZone = z => { try { new Intl.DateTimeFormat('en', { timeZone: z }); return true; } catch { return false; } };
const city = z => z.split('/').pop().replaceAll('_', ' ');
// Formatters are costly to build and a render asks for about six per city: kept.
const formats = new Map();
function fmt(z, opts) {
  const k = `${z}|${JSON.stringify(opts)}`;
  let f = formats.get(k);
  if (!f) formats.set(k, f = new Intl.DateTimeFormat(env.CLOCK_24H ? 'en-GB' : 'en-US', { timeZone: z, ...opts }));
  return f;
}

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

// ---- lifecycle (panel.js: the window hides on close and is shown again next time)
const close = () => p.close();

document.querySelector('.head .glyph').textContent = '\u{F01E7}';     // earth
for (const z of Intl.supportedValuesOf('timeZone')) $('zones').append(Object.assign(document.createElement('option'), { value: z }));
$('city').addEventListener('keydown', e => {
  if (e.key !== 'Enter') return;
  if (addZone(e.target.value)) e.target.value = '';
  else e.target.style.borderColor = 'var(--alert, #f7768e)';
});
$('city').addEventListener('input', e => { e.target.style.borderColor = ''; });
window.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });

const p = panel({
  name: 'worldclock',
  anchor: false,
  // Typing a city: the zone list pops up outside the page, which takes the focus.
  stayOnBlur: () => document.activeElement === $('city'),
  open() {
    loadZones();
    $('city').value = '';
    $('city').style.borderColor = '';
    render();
  },
});
p.every(5000, render);
