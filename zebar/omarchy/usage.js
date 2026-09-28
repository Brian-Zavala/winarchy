// The bar's agent usage panel: a port of Omarchy Quattro's shell/plugins/agents panel.
// Strictly a display of agents.json, which `winarchy agent-usage` writes from the usage
// collectors (lib/agents). menu.ahk opens it from the bar's agent icon, after writing the
// click's x to usage-anchor.json so the card drops under the icon.
//   h / l, arrows: switch subscription    r, Enter: refresh    Esc: close
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { calm } from './motion.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls ?? '', textContent: text ?? '' });
const act = (...args) => zebar.shellExec(env.AHK, [env.MENU, ...args]).catch(e => console.error(e));
const get = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).catch(() => null);

const GLYPH = { agent: '\u{F06A9}', alert: '\u{F0026}' };

// ---- numbers
const int = n => Math.round(Number(n) || 0);
const commas = n => int(n).toLocaleString('en-US');
// Auto-compact for the value column: 1,284 / 12.9K / 4.2M / 1.1B.
function compact(n) {
  n = int(n);
  if (n >= 1e9) return `${(n / 1e9).toFixed(1)}B`;
  if (n >= 1e6) return `${(n / 1e6).toFixed(1)}M`;
  if (n >= 1e4) return `${Math.round(n / 1e3)}K`;
  if (n >= 1e3) return `${(n / 1e3).toFixed(1)}K`;
  return `${n}`;
}
const modelTotal = b => int(b.inputTokens) + int(b.outputTokens) + int(b.cacheReadInputTokens) + int(b.cacheCreationInputTokens);

// ---- time
function resetText(iso) {
  if (!iso) return '';
  const at = new Date(iso);
  if (Number.isNaN(+at)) return '';
  const mins = Math.round((at - Date.now()) / 60000);
  if (mins <= 0) return 'resetting now';
  if (mins < 60) return `resets in ${mins}m`;
  if (mins < 24 * 60) return `resets in ${Math.floor(mins / 60)}h ${mins % 60}m`;
  const day = at.toLocaleDateString('en-US', { weekday: 'short' });
  const time = at.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: !env.CLOCK_24H });
  return `resets ${day} ${time}`;
}
function agoText(iso) {
  const mins = Math.round((Date.now() - new Date(iso)) / 60000);
  if (!Number.isFinite(mins)) return '';
  if (mins < 1) return 'updated just now';
  if (mins < 60) return `updated ${mins} min ago`;
  return `updated ${Math.floor(mins / 60)} h ago`;
}
const localDay = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};
// "Mon 21". Built by hand: Intl orders weekday and day differently from engine to engine.
function dayLabel(date) {
  const [y, m, d] = date.split('-').map(Number);
  return `${new Date(y, m - 1, d).toLocaleDateString('en-US', { weekday: 'short' })} ${d}`;
}

// ---- state
let data = null;          // agents.json
let stamp = null;         // its updatedAt: re-render only when it changes (no flash on poll)
let picked = null;        // the selected agent's id, remembered across opens
try { picked = localStorage.getItem('agent'); } catch {}
let refreshing = false;

const agents = () => data?.agents ?? [];
function current() {
  const list = agents();
  return list.find(a => a.id === picked) ?? list[0] ?? null;
}
function pick(delta) {
  const list = agents();
  if (list.length < 2) return;
  const i = Math.max(0, list.findIndex(a => a.id === current()?.id));
  picked = list[(i + delta + list.length) % list.length].id;
  try { localStorage.setItem('agent', picked); } catch {}
  render();
}

// ---- render
function render() {
  const a = current();
  document.querySelector('#hero .glyph').textContent = GLYPH.agent;
  if (!a) {
    $('name').textContent = 'No agent usage yet';
    $('plan').textContent = 'It appears after a coding agent has run on this PC.';
    for (const id of ['status', 'chips', 'limitsBox', 'daysBox', 'modelsBox']) $(id).classList.add('hidden');
    $('totals').textContent = '';
    $('updated').textContent = data?.updatedAt ? agoText(data.updatedAt) : '';
    return place();
  }

  $('name').textContent = a.name;
  $('plan').textContent = a.tierLabel ?? '';
  $('plan').classList.toggle('hidden', !a.tierLabel);

  // Auth and endpoint problems replace nothing: local stats still show below them.
  const status = $('status');
  status.classList.toggle('hidden', !a.usageStatusText);
  if (a.usageStatusText) {
    const text = el('div');
    text.append(el('strong', '', a.usageStatusText), el('span', 'help', a.authHelpText ?? ''));
    status.replaceChildren(el('span', 'icon', GLYPH.alert), text);
  }

  const chips = $('chips');
  chips.classList.toggle('hidden', agents().length < 2);
  chips.replaceChildren(...agents().map(x => {
    const c = el('button', `chip${x.id === a.id ? ' on' : ''}`, x.name);
    c.onclick = () => { picked = x.id; try { localStorage.setItem('agent', picked); } catch {} render(); };
    return c;
  }));

  renderLimits(a.limits ?? []);
  renderDays(a);
  renderModels(a.modelUsage ?? {});

  const days = int(a.activeDays);
  $('totals').textContent = int(a.totalPrompts)
    ? `${commas(a.totalPrompts)} prompts · ${commas(a.totalSessions)} sessions · ${days} day${days === 1 ? '' : 's'}`
    : '';
  $('updated').textContent = refreshing ? 'refreshing…' : agoText(a.updatedAt ?? data.updatedAt);
  place();
}

function renderLimits(limits) {
  $('limitsBox').classList.toggle('hidden', !limits.length);
  $('limits').replaceChildren(...limits.map(l => {
    const p = Math.max(0, Math.min(1, Number(l.percent) || 0));
    const level = p >= 0.9 ? 'crit' : p >= 0.75 ? 'warn' : '';
    const row = el('div', `limit ${level}`.trim());
    const pct = el('span', 'pct');
    if (level) pct.append(el('span', 'flag', GLYPH.alert));
    pct.append(`${Math.round(p * 100)}% used`);
    const meter = el('span', 'meter');
    meter.setAttribute('role', 'meter');
    meter.setAttribute('aria-valuemin', '0');
    meter.setAttribute('aria-valuemax', '100');
    meter.setAttribute('aria-valuenow', String(Math.round(p * 100)));
    meter.setAttribute('aria-label', l.title ?? l.label);
    const fill = el('span');
    fill.style.width = `${p * 100}%`;
    meter.append(fill);
    row.append(el('span', 'label', l.title ?? l.label), pct, meter, el('span', 'reset', resetText(l.resetsAt)));
    return row;
  }));
}

// One row per day for the last week, oldest first, so today lands bolded at the bottom.
// recentDays[].messageCount is a token total (a legacy name upstream keeps for syncing).
function renderDays(a) {
  const today = localDay();
  const days = (a.recentDays ?? []).slice(-7);
  $('daysBox').classList.toggle('hidden', !days.some(d => int(d.messageCount) > 0));
  const max = Math.max(1, ...days.map(d => int(d.messageCount)));
  $('days').replaceChildren(...days.map(d => {
    const n = int(d.messageCount);
    const isToday = d.date === today;
    const tip = isToday
      ? `Today: ${commas(n)} tokens\n${commas(a.todayPrompts)} prompts in ${commas(a.todaySessions)} session${int(a.todaySessions) === 1 ? '' : 's'}`
      : `${dayLabel(d.date)}: ${commas(n)} tokens`;
    return barRow(isToday ? 'Today' : dayLabel(d.date), n, max, tip, isToday);
  }));
}

// Tokens per model, heaviest first, each bar scaled to the heaviest model.
function renderModels(usage) {
  const models = Object.entries(usage)
    .map(([name, b]) => ({ name, b, total: modelTotal(b) }))
    .filter(m => m.total > 0)
    .sort((x, y) => y.total - x.total);
  $('modelsBox').classList.toggle('hidden', !models.length);
  const max = Math.max(1, ...models.map(m => m.total));
  $('models').replaceChildren(...models.map(m => barRow(m.name, m.total, max, [
    `${m.name}: ${commas(m.total)} tokens`,
    `  input         ${commas(m.b.inputTokens)}`,
    `  output        ${commas(m.b.outputTokens)}`,
    `  cache read    ${commas(m.b.cacheReadInputTokens)}`,
    `  cache write   ${commas(m.b.cacheCreationInputTokens)}`,
  ].join('\n'))));
}

function barRow(label, n, max, tip, bold = false) {
  const row = el('div', `row${bold ? ' today' : ''}`);
  row.tabIndex = 0;   // keyboard focus shows the same detail as hover
  const track = el('span', 'track');
  const bar = el('span', `bar${n ? '' : ' zero'}`);
  bar.style.width = `${(n / max) * 100}%`;
  track.append(bar);
  row.append(el('span', 'label', label), track, el('span', 'value', compact(n)));
  row.setAttribute('aria-label', tip.split('\n').join(', '));
  const show = () => showTip(row, tip);
  row.addEventListener('mouseenter', show);
  row.addEventListener('focus', show);
  row.addEventListener('mouseleave', hideTip);
  row.addEventListener('blur', hideTip);
  return row;
}

// ---- hover / focus detail
function showTip(row, text) {
  const tip = $('tip');
  tip.textContent = text;
  tip.classList.remove('hidden');
  // Right-aligned to the value column, under the row; above it if it would run off the card.
  const panel = $('panel');
  let top = row.offsetTop + row.offsetHeight + 4;
  if (top + tip.offsetHeight > panel.clientHeight) top = row.offsetTop - tip.offsetHeight - 4;
  tip.style.top = `${top}px`;
  tip.style.left = `${Math.max(8, row.offsetLeft + row.offsetWidth - tip.offsetWidth)}px`;
}
function hideTip() { $('tip').classList.add('hidden'); }

// ---- position: under the bar, centered on the icon, kept on the monitor
let anchorX = null;
function place() {
  const panel = $('panel');
  const w = panel.offsetWidth;
  const x = anchorX ?? window.innerWidth / 2;
  const left = Math.max(12, Math.min(window.innerWidth - w - 12, x - w / 2));
  document.documentElement.style.setProperty('--left', `${left}px`);
}

// ---- data
async function poll() {
  const next = await get('agents.json');
  if (!next) return;   // keep what is on screen rather than flashing empty
  const changed = next.updatedAt !== stamp;
  data = next;
  stamp = next.updatedAt;
  if (changed) { refreshing = false; render(); }
}

let refreshTimer = null;
function refresh() {
  refreshing = true;
  $('updated').textContent = 'refreshing…';
  act('usage-refresh');
  // A refresh that never writes (no Python, a collector hung past its 60 s) must not
  // leave "refreshing…" up for good: show the last update again.
  clearTimeout(refreshTimer);
  refreshTimer = setTimeout(() => { if (refreshing) { refreshing = false; render(); } }, 90000);
}

// ---- lifecycle (as the calendar)
let closing = false;
function close() {
  if (closing) return;
  closing = true;
  document.body.classList.remove('shown');
  setTimeout(() => Promise.resolve(zebar.currentWidget().window.tauri.close()).catch(() => {}), calm.matches ? 0 : 110);
}

document.addEventListener('mousedown', e => { if (!$('panel').contains(e.target)) close(); });
window.addEventListener('keydown', e => {
  const k = e.key;
  if (k === 'Escape') close();
  else if (k === 'h' || k === 'ArrowLeft') pick(-1);
  else if (k === 'l' || k === 'ArrowRight') pick(1);
  else if (k === 'r' || k === 'R' || k === 'Enter') refresh();
  else return;
  e.preventDefault();
});

document.documentElement.style.setProperty('--top', `${(env.BAR_HEIGHT ?? 26) + (env.GAP ?? 10)}px`);
const [first, anchor] = await Promise.all([get('agents.json'), get('usage-anchor.json')]);
anchorX = Number.isFinite(anchor?.x) ? anchor.x : null;
data = first;
stamp = first?.updatedAt ?? null;
render();
setInterval(poll, 2000);
// Reset times count down while the panel is open.
setInterval(() => { if (!refreshing) render(); }, 30000);

const shown = () => requestAnimationFrame(() => document.body.classList.add('shown'));
if (document.hasFocus()) shown();
else { window.addEventListener('focus', shown, { once: true }); setTimeout(shown, 300); }
setTimeout(() => window.addEventListener('blur', close), 400);
