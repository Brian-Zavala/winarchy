// The clock's calendar (a port of Omarchy Quattro's shell/plugins/panels/clock):
// a read-out, not a picker. Today is the only marked day; chevrons, the wheel and
// the arrow keys step the month. menu.ahk opens it (clock click, Super+Ctrl+Alt+D).
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { calm } from './motion.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls, textContent: text ?? '' });
const DAYS = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
const DAY_MS = 86400000;

// ---- date math (Quattro's Model.js)
// ISO-8601 week: the week owning the Thursday of that date's Monday-based week.
function isoWeek(y, m, d) {
  const date = new Date(Date.UTC(y, m, d));
  date.setUTCDate(date.getUTCDate() + 4 - (date.getUTCDay() || 7));
  return Math.ceil(((date - Date.UTC(date.getUTCFullYear(), 0, 1)) / DAY_MS + 1) / 7);
}
const key = d => `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
function yearDone(t) {
  const y = t.getFullYear();
  const day = Math.round((Date.UTC(y, t.getMonth(), t.getDate()) - Date.UTC(y, 0, 1)) / DAY_MS);
  const total = Math.round((Date.UTC(y + 1, 0, 1) - Date.UTC(y, 0, 1)) / DAY_MS);
  return day / total;
}
// Always six rows, so the panel is as tall in February as in August. Each row is
// numbered by the ISO week owning its Thursday (stable for any week start).
function monthGrid(y, m, start, today) {
  const cursor = new Date(y, m, 1 - ((new Date(y, m, 1).getDay() - start + 7) % 7));
  return Array.from({ length: 6 }, () => {
    const days = Array.from({ length: 7 }, () => {
      const d = new Date(cursor);
      cursor.setDate(cursor.getDate() + 1);
      return { d, inMonth: d.getMonth() === m, weekend: d.getDay() % 6 === 0, today: key(d) === today };
    });
    const thu = days.find(x => x.d.getDay() === 4).d;
    return { week: isoWeek(thu.getFullYear(), thu.getMonth(), thu.getDate()), days };
  });
}

// ---- state
// Week start: yours if you toggled it (click "W"), else the locale's first day.
function localeWeekStart() {
  try {
    const loc = new Intl.Locale(navigator.language);
    const info = loc.getWeekInfo?.() ?? loc.weekInfo;
    if (info?.firstDay) return info.firstDay % 7;
  } catch {}
  return 1;
}
let weekStart = localeWeekStart();
try { const s = localStorage.getItem('weekStart'); if (s !== null) weekStart = Number(s) % 7; } catch {}

let today = new Date();
let view = { y: today.getFullYear(), m: today.getMonth() };

function render() {
  const t = today;
  $('heroDate').textContent = t.toLocaleDateString('en-US', { month: 'long', day: 'numeric' });
  $('hero').classList.toggle('away', view.y !== t.getFullYear() || view.m !== t.getMonth());
  const done = yearDone(t);
  $('year').textContent = t.getFullYear();
  $('yearFill').style.width = `${done * 100}%`;
  $('yearPct').textContent = `${Math.round(done * 100)}%`;

  const grid = $('grid');
  const next = DAYS[weekStart === 1 ? 0 : 1];
  const w = el('button', 'wk head', 'W');
  w.title = `Start weeks on ${next[0].toUpperCase()}${next.slice(1)}`;
  w.onclick = toggleWeekStart;
  const cells = [w, el('span', 'gutter')];
  for (let i = 0; i < 7; i++) cells.push(el('span', 'dow', DAYS[(weekStart + i) % 7].slice(0, 3).toUpperCase()));
  for (const row of monthGrid(view.y, view.m, weekStart, key(t))) {
    cells.push(el('span', 'wk', row.week), el('span', 'gutter line'));
    for (const c of row.days) {
      cells.push(el('span', ['day', c.inMonth ? '' : 'out', c.weekend ? 'weekend' : '', c.today ? 'today' : ''].join(' ').trim(), c.d.getDate()));
    }
  }
  grid.replaceChildren(...cells);
  $('month').textContent = new Date(view.y, view.m, 1).toLocaleDateString('en-US', { month: 'long', year: 'numeric' }).toUpperCase();
}

function moveMonth(delta) {
  const d = new Date(view.y, view.m + delta, 1);
  view = { y: d.getFullYear(), m: d.getMonth() };
  render();
}
function goToToday() {
  view = { y: today.getFullYear(), m: today.getMonth() };
  render();
}
function toggleWeekStart() {
  weekStart = weekStart === 1 ? 0 : 1;
  try { localStorage.setItem('weekStart', String(weekStart)); } catch {}
  render();
}

// ---- lifecycle
let closing = false;
function close() {
  if (closing) return;
  closing = true;
  document.body.classList.remove('shown');
  setTimeout(() => Promise.resolve(zebar.currentWidget().window.tauri.close()).catch(() => {}), calm.matches ? 0 : 110);
}

document.querySelector('#hero .glyph').textContent = '\u{F00ED}';   // calendar
$('prev').textContent = '\u{F0141}';                                 // chevron left
$('next').textContent = '\u{F0142}';                                 // chevron right
$('hero').onclick = goToToday;
$('prev').onclick = () => moveMonth(-1);
$('next').onclick = () => moveMonth(1);
$('panel').addEventListener('wheel', e => { if (e.deltaY) moveMonth(e.deltaY < 0 ? -1 : 1); }, { passive: true });
// The window covers the monitor (transparent): a click outside the panel closes it,
// and one on the bar's clock lands here too, so the clock toggles it.
document.addEventListener('mousedown', e => { if (!$('panel').contains(e.target)) close(); });
window.addEventListener('keydown', e => {
  const k = e.key;
  if (k === 'Escape') close();
  else if (k === 'ArrowLeft' || k === '[') moveMonth(-1);
  else if (k === 'ArrowRight' || k === ']') moveMonth(1);
  else if (k === 'ArrowUp' || k === '{') moveMonth(-12);
  else if (k === 'ArrowDown' || k === '}') moveMonth(12);
  else if (k === 'Enter' || k === 't' || k === 'T' || k === 'Home') goToToday();
  else if (k === 'w' || k === 'W') toggleWeekStart();
  else return;
  e.preventDefault();
});
// Midnight rolls today over (and follows it when you are looking at this month).
setInterval(() => {
  const now = new Date();
  if (key(now) === key(today)) return;
  const following = view.y === today.getFullYear() && view.m === today.getMonth();
  today = now;
  if (following) view = { y: now.getFullYear(), m: now.getMonth() };
  render();
}, 30000);

// Right under the bar (winarchy apply writes its height and the window gap).
document.documentElement.style.setProperty('--top', `${(env.BAR_HEIGHT ?? 26) + (env.GAP ?? 10)}px`);
render();
// menu.ahk activates the window once it exists: open then (the webview paints on focus).
const shown = () => requestAnimationFrame(() => document.body.classList.add('shown'));
if (document.hasFocus()) shown();
else { window.addEventListener('focus', shown, { once: true }); setTimeout(shown, 300); }
setTimeout(() => window.addEventListener('blur', close), 400);
