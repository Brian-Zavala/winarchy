// The bar's agents panel: a port of Omarchy's shell/plugins/agents panel. Every
// subscription in agents.json, which `winarchy agent-usage` writes from the usage
// collectors (lib/agents), with its limits; opening one shows its tokens by day and by
// model. Its buttons are menu.ahk verbs: + picks the default agent, Use switches to one,
// Sign in runs its login, and the Make something tiles start the default agent with a
// starter prompt. menu.ahk opens it from the bar's agent icon, after writing the click's x
// to usage-anchor.json so the card drops under the icon.
//   j / k, arrows: move    Enter, Space: press    r: refresh    Esc: close
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { panel } from './panel.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls ?? '', textContent: text ?? '' });
const act = (...args) => zebar.shellExec(env.AHK, [env.MENU, ...args]).catch(e => console.error(e));
const get = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).catch(() => null);

const GLYPH = {
  agent: '\u{F06A9}', alert: '\u{F0026}', add: '\u{F0415}', refresh: '\u{F0450}',
  open: '\u{F0140}', closed: '\u{F0142}',
  theme: '\u{F03D8}', plugin: '\u{F0431}', app: '\u{F08C6}',
};

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
// Codex reports its plan as it is spelled in its API ("pro", "plus").
const planText = s => (s ? s.replace(/^\p{Ll}/u, c => c.toUpperCase()) : '');

// ---- time
// The countdown beside a meter: 42m / 4h 42m / 4d 12h.
function leftText(iso) {
  const at = new Date(iso);
  if (!iso || Number.isNaN(+at)) return '';
  const mins = Math.round((at - Date.now()) / 60000);
  if (mins <= 0) return 'now';
  if (mins < 60) return `${mins}m`;
  if (mins < 24 * 60) return `${Math.floor(mins / 60)}h ${mins % 60}m`;
  return `${Math.floor(mins / 1440)}d ${Math.floor((mins % 1440) / 60)}h`;
}
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
let known = [];           // defaults.json agents: which can be the default, and sign in
let stamp = null;         // agents.json's updatedAt: re-render only when it changes (no flash on poll)
let opened = new Set();   // subscriptions showing their tokens by day and by model
try { opened = new Set(JSON.parse(localStorage.getItem('agents-open') ?? '[]')); } catch {}
let refreshing = false;
let cursorOn = false;
let cursor = 0;           // index into nodes()

const agents = () => data?.agents ?? [];
const agentKey = id => known.find(k => k.key === id);

function toggle(id) {
  if (opened.has(id)) opened.delete(id); else opened.add(id);
  try { localStorage.setItem('agents-open', JSON.stringify([...opened])); } catch {}
  render();
}

// ---- render
function render() {
  hideTip();   // its row is about to be replaced
  document.querySelector('#hero .glyph').textContent = GLYPH.agent;
  const list = agents();
  const today = list.reduce((sum, a) => sum + int(a.todayTotalTokens), 0);
  $('today').textContent = today ? `${compact(today)} tokens today` : 'No tokens today';
  $('empty').classList.toggle('hidden', list.length > 0);
  $('agents').replaceChildren(...list.map(renderAgent));
  $('updated').textContent = refreshing ? 'refreshing…' : (data?.updatedAt ? agoText(data.updatedAt) : '');
  place();
  paintCursor();
}

function renderAgent(a) {
  const box = el('section', 'agent');
  box.setAttribute('aria-label', a.name);
  const isOpen = opened.has(a.id);

  // Name · plan, which opens the subscription; then its state: the default agent is
  // ACTIVE, another installed agent can be switched to.
  const head = el('div', 'head');
  const name = el('button', 'toggle');
  name.setAttribute('aria-expanded', String(isOpen));
  name.title = isOpen ? 'Hide tokens by day and model' : 'Tokens by day and model';
  name.append(el('span', 'chev', isOpen ? GLYPH.open : GLYPH.closed), el('span', 'name', a.name));
  if (a.tierLabel) name.append(el('span', 'plan', `· ${planText(a.tierLabel)}`));
  name.onclick = () => toggle(a.id);
  head.append(name);
  const k = agentKey(a.id);
  if (a.id === data?.default) head.append(el('span', 'state active', 'Active'));
  else if (k?.installed) {
    const use = el('button', 'use', 'Use');
    use.title = `Make ${k.label} the default agent, and start it`;
    use.onclick = () => { act('default-agent', a.id); close(); };
    head.append(use);
  }
  box.append(head);

  // Auth and endpoint problems replace nothing: the limits and stats still show below.
  if (a.usageStatusText) {
    const status = el('div', 'status');
    status.setAttribute('role', 'status');
    const text = el('div', 'text');
    text.append(el('strong', '', a.usageStatusText), el('span', 'help', a.authHelpText ?? ''));
    status.append(el('span', 'icon', GLYPH.alert), text);
    if (k?.login && /auth|sign.?in|log.?in/i.test(a.usageStatusText)) {
      const login = el('button', 'login', 'Sign in');
      login.onclick = () => { act('agent-login', a.id); close(); };
      status.append(login);
    }
    box.append(status);
  }

  const limits = a.limits ?? [];
  if (limits.length) {
    const rows = el('div', 'limits');
    rows.append(...limits.map(limitRow));
    box.append(rows);
  }
  if (isOpen) box.append(renderDetail(a));
  return box;
}

// Label | meter | time to reset. Session and Weekly are what the collectors call
// "Session (5-hour)" and "Weekly (7-day)"; model-scoped limits keep their own names.
function limitRow(l) {
  const title = l.title ?? l.label ?? '';
  const label = title.replace(/\s*\((?:\d+-hour|\d+-day)\)$/, '');
  const p = Math.max(0, Math.min(1, Number(l.percent) || 0));
  const level = p >= 0.9 ? 'crit' : p >= 0.75 ? 'warn' : '';
  const row = el('div', `limit ${level}`.trim());
  const meter = el('span', 'meter');
  meter.setAttribute('role', 'meter');
  meter.setAttribute('aria-valuemin', '0');
  meter.setAttribute('aria-valuemax', '100');
  meter.setAttribute('aria-valuenow', String(Math.round(p * 100)));
  meter.setAttribute('aria-label', title);
  const fill = el('span');
  fill.style.width = `${p * 100}%`;
  meter.append(fill);
  const left = el('span', 'left');
  if (level) left.append(el('span', 'flag', GLYPH.alert));
  left.append(leftText(l.resetsAt));
  row.append(el('span', 'label', label), meter, left);
  const tip = [`${title}: ${Math.round(p * 100)}% used`, resetText(l.resetsAt)].filter(Boolean).join('\n');
  row.setAttribute('aria-label', tip.split('\n').join(', '));
  hoverTip(row, tip);
  return row;
}

function renderDetail(a) {
  const box = el('div', 'detail');
  const days = renderDays(a);
  if (days) box.append(days);
  const models = renderModels(a.modelUsage ?? {});
  if (models) box.append(models);
  const n = int(a.activeDays);
  if (int(a.totalPrompts)) {
    box.append(el('span', 'totals', `${commas(a.totalPrompts)} prompts · ${commas(a.totalSessions)} sessions · ${n} day${n === 1 ? '' : 's'}`));
  }
  if (!box.children.length) box.append(el('span', 'totals', 'No tokens recorded on this PC yet.'));
  return box;
}

function chart(title, rows) {
  const s = el('section');
  const list = el('div', 'rows');
  list.append(...rows);
  s.append(el('h2', '', title), list);
  return s;
}

// One row per day for the last week, oldest first, so today lands bolded at the bottom.
// recentDays[].messageCount is a token total (a legacy name upstream keeps for syncing).
function renderDays(a) {
  const today = localDay();
  const days = (a.recentDays ?? []).slice(-7);
  if (!days.some(d => int(d.messageCount) > 0)) return null;
  const max = Math.max(1, ...days.map(d => int(d.messageCount)));
  return chart('Tokens by day', days.map(d => {
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
  if (!models.length) return null;
  const max = Math.max(1, ...models.map(m => m.total));
  return chart('Tokens by model', models.map(m => barRow(m.name, m.total, max, [
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
  hoverTip(row, tip);
  return row;
}

// ---- hover / focus detail
function hoverTip(row, tip) {
  const show = () => showTip(row, tip);
  row.addEventListener('mouseenter', show);
  row.addEventListener('focus', show);
  row.addEventListener('mouseleave', hideTip);
  row.addEventListener('blur', hideTip);
}
function showTip(row, text) {
  const tip = $('tip');
  tip.textContent = text;
  tip.classList.remove('hidden');
  // Right-aligned to the row, under it; above it if it would run off the card.
  const panel = $('panel');
  let top = row.offsetTop + row.offsetHeight + 4;
  if (top + tip.offsetHeight > panel.scrollTop + panel.clientHeight) top = row.offsetTop - tip.offsetHeight - 4;
  tip.style.top = `${top}px`;
  tip.style.left = `${Math.max(8, row.offsetLeft + row.offsetWidth - tip.offsetWidth)}px`;
}
function hideTip() { $('tip').classList.add('hidden'); }

// ---- keyboard cursor (as the Tailscale panel): every button, top to bottom
function nodes() {
  return [...$('panel').querySelectorAll('button')].filter(n => n.offsetParent !== null);
}
function paintCursor() {
  document.body.classList.toggle('cursor-on', cursorOn);
  for (const n of document.querySelectorAll('.has-cursor')) n.classList.remove('has-cursor');
  if (!cursorOn) return;
  const list = nodes();
  cursor = Math.max(0, Math.min(list.length - 1, cursor));
  list[cursor]?.classList.add('has-cursor');
  list[cursor]?.scrollIntoView({ block: 'nearest' });
}

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

// ---- lifecycle (panel.js: the window hides on close and is shown again next time)
const close = () => p.close();

$('add').textContent = GLYPH.add;
$('add').onclick = () => { act('open', 'agent'); close(); };
$('refresh').textContent = GLYPH.refresh;
$('refresh').onclick = refresh;
for (const t of document.querySelectorAll('.tile')) {
  t.querySelector('.icon').textContent = GLYPH[t.dataset.kind];
  t.title = `Start your default agent to make a ${t.dataset.kind}`;
  t.onclick = () => { act('agent-make', t.dataset.kind); close(); };
}

document.addEventListener('mouseover', e => {
  const i = nodes().findIndex(n => n.contains(e.target));
  if (i >= 0 && i !== cursor) { cursor = i; if (cursorOn) paintCursor(); }
});
window.addEventListener('keydown', e => {
  const k = e.key.length === 1 ? e.key.toLowerCase() : e.key;
  if (k === 'Escape') return close();
  const dy = k === 'j' || k === 'ArrowDown' || k === 'l' || k === 'ArrowRight' ? 1
    : k === 'k' || k === 'ArrowUp' || k === 'h' || k === 'ArrowLeft' ? -1 : 0;
  if (dy) {
    e.preventDefault();
    // The first key only shows where the cursor is (Quattro).
    if (!cursorOn) cursorOn = true; else cursor += dy;
    return paintCursor();
  }
  // Enter / Space press the button under the cursor; without one, a Tab-focused button
  // takes them the browser's way.
  if (k === 'Enter' || k === ' ') {
    if (!cursorOn) return;
    e.preventDefault();
    nodes()[cursor]?.click();
    return;
  }
  if (k === 'r') refresh();
  else return;
  e.preventDefault();
});

const p = panel({
  name: 'usage',
  async open({ anchor }) {
    anchorX = Number.isFinite(anchor.x) ? anchor.x : null;
    // Read again on every open: the default agent, or another monitor's panel, may have moved on.
    try { opened = new Set(JSON.parse(localStorage.getItem('agents-open') ?? '[]')); } catch {}
    cursorOn = false;
    cursor = 0;
    const [first, defaults] = await Promise.all([get('agents.json'), get('defaults.json')]);
    known = defaults?.agents ?? known;
    if (first) { data = first; stamp = first.updatedAt ?? null; }
    render();
  },
  onHidden: hideTip,
});
p.every(2000, poll);
// Reset times count down while the panel is open.
p.every(30000, () => { if (!refreshing) render(); });
