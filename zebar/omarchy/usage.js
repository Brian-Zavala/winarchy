// The bar's agents panel: a port of Omarchy's shell/plugins/agents panel. Every
// subscription in agents.json, which `winarchy agent-usage` writes from the usage
// collectors (lib/agents), with its limits; opening one shows its tokens by day and by
// model. Its buttons are menu.ahk verbs: + adds a subscription (another account),
// Use switches account, Make default picks the default agent, Sign in runs a login,
// Autoswitch lets an agent move to its next account when one runs low, and the Make
// something tiles start the default agent with a starter prompt. menu.ahk opens it from
// the bar's agent icon, after writing the click's x to usage-anchor.json so the card
// drops under the icon.
//   j / k, arrows: move    Enter, Space: press    a: add    r: refresh    Esc: close
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { calm } from './motion.js';

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
let switching = {};       // provider -> account id a Use click is waiting to see active

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
  // Buttons are rebuilt: keep keyboard focus on the same one (by data-key).
  const focused = document.activeElement?.dataset?.key;
  for (const a of agents()) {
    if (switching[a.id] && (a.accounts ?? []).some(x => x.active && x.id === switching[a.id])) delete switching[a.id];
  }
  document.querySelector('#hero .glyph').textContent = GLYPH.agent;
  const list = agents();
  const today = list.reduce((sum, a) => sum + int(a.todayTotalTokens), 0);
  $('today').textContent = today ? `${compact(today)} tokens today` : 'No tokens today';
  $('empty').classList.toggle('hidden', list.length > 0);
  $('agents').replaceChildren(...list.map(renderAgent));
  $('updated').textContent = refreshing ? 'refreshing…' : (data?.updatedAt ? agoText(data.updatedAt) : '');
  place();
  if (focused) document.querySelector(`[data-key="${CSS.escape(focused)}"]`)?.focus();
  paintCursor();
}

const keyed = (node, key) => { node.dataset.key = key; return node; };

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
  // With several accounts each shows its own plan below.
  if (a.tierLabel && !((a.accounts ?? []).length > 1)) name.append(el('span', 'plan', `· ${planText(a.tierLabel)}`));
  name.onclick = () => toggle(a.id);
  head.append(keyed(name, `open:${a.id}`));
  const accounts = a.accounts ?? [];
  const multi = accounts.length > 1;
  if (multi) {
    // Autoswitch: move to the next account by itself when this one runs low.
    const on = a.accountSwitch?.mode === 'auto';
    const auto = keyed(el('button', 'auto', 'Autoswitch'), `auto:${a.id}`);
    auto.setAttribute('aria-pressed', String(on));
    auto.title = on ? `Switches account by itself at ${a.accountSwitch?.threshold ?? 95}%. Click to switch by hand.`
      : `Switch account by itself when one reaches ${a.accountSwitch?.threshold ?? 95}%`;
    auto.onclick = () => {
      a.accountSwitch = { ...(a.accountSwitch ?? {}), mode: on ? 'manual' : 'auto' };
      act('agent-account-mode', a.id, on ? 'manual' : 'auto');
      render();
    };
    head.append(auto);
  }
  const k = agentKey(a.id);
  if (a.id === data?.default) head.append(el('span', 'state default', 'Default'));
  else if (k?.installed) {
    const use = keyed(el('button', 'use', 'Make default'), `default:${a.id}`);
    use.title = `Make ${k.label} the default agent, and start it`;
    use.onclick = () => { act('default-agent', a.id); close(); };
    head.append(use);
  }
  box.append(head);

  if (multi) {
    box.append(...accounts.map(x => renderAccount(a, x, k)));
    if (isOpen) box.append(renderDetail(a));
    return box;
  }
  box.append(...statusBlock(a, a, k, a.id));
  const credits = creditsLine(a.resetCredits);
  if (credits) box.append(credits);

  const limits = a.limits ?? [];
  if (limits.length) {
    const rows = el('div', 'limits');
    rows.append(...limits.map(limitRow));
    box.append(rows);
  }
  if (isOpen) box.append(renderDetail(a));
  return box;
}

// One account of several: label · plan, then ACTIVE or Use, its problems and its limits.
function renderAccount(a, x, k) {
  const ref = `${a.id}/${x.id}`;
  const box = el('div', `account${x.stale && x.limits?.length ? ' stale' : ''}`);
  box.setAttribute('aria-label', `${a.name}: ${x.label}`);
  const head = el('div', 'acct-head');
  const name = el('span', 'acct-name', x.label);
  if (x.plan) name.append(el('span', 'plan', ` · ${planText(x.plan)}`));
  if (x.email) name.title = x.email;
  head.append(name);
  if (x.active) head.append(el('span', 'state active', 'Active'));
  else if (switching[a.id] === x.id) head.append(el('span', 'state', 'Switching…'));
  else {
    const use = keyed(el('button', 'use', 'Use'), `use:${ref}`);
    use.title = `New ${a.name} sessions use ${x.label}${x.email ? ` (${x.email})` : ''}. Running sessions stay as they are.`;
    use.onclick = () => { switching[a.id] = x.id; act('agent-account-use', ref); render(); };
    head.append(use);
  }
  box.append(head);
  const credits = creditsLine(x.resetCredits);
  if (credits) box.append(credits);
  // A parked account whose sign-in expired still shows what it last knew, dimmed: only
  // the account in use, or one that was never signed in, asks for a sign-in.
  const expiredParked = !x.active && x.limits?.length && /expired/i.test(x.usageStatusText ?? '');
  if (expiredParked) box.append(el('span', 'note', 'Last known limits. Use it to refresh its sign-in.'));
  else box.append(...statusBlock(a, x, k, ref));
  if (x.limits?.length) {
    const rows = el('div', 'limits');
    rows.append(...x.limits.map(limitRow));
    box.append(rows);
  }
  return box;
}

function creditsLine(c) {
  const n = int(c?.available);
  if (!n) return null;
  const line = el('span', 'credits', `${n} free reset${n === 1 ? '' : 's'}`);
  if (c.nextExpiresAt) {
    line.dataset.expires = c.nextExpiresAt;
    line.dataset.count = String(n);
    line.textContent += ` · next expires in ${leftText(c.nextExpiresAt)}`;
  }
  return line;
}

// Auth and endpoint problems replace nothing: the limits and stats still show below.
function statusBlock(a, x, k, ref) {
  if (!x.usageStatusText) return [];
  const status = el('div', 'status');
  status.setAttribute('role', 'status');
  const text = el('div', 'text');
  text.append(el('strong', '', x.usageStatusText), el('span', 'help', x.authHelpText ?? ''));
  status.append(el('span', 'icon', GLYPH.alert), text);
  if (k?.login && /auth|sign.?in|log.?in|expired/i.test(x.usageStatusText)) {
    const login = keyed(el('button', 'login', 'Sign in'), `login:${ref}`);
    login.onclick = () => { act('agent-login', ref); close(); };
    status.append(login);
  }
  return [status];
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
  const when = el('span', 'when', leftText(l.resetsAt));
  left.append(when);
  row.append(el('span', 'label', label), meter, left);
  // Its countdown and tip are text that tick() rewrites; the row itself stays put.
  row.tickText = () => {
    when.textContent = leftText(l.resetsAt);
    const tip = [`${title}: ${Math.round(p * 100)}% used`, resetText(l.resetsAt)].filter(Boolean).join('\n');
    row.setAttribute('aria-label', tip.split('\n').join(', '));
    return tip;
  };
  row.tickText();
  hoverTip(row, () => row.tickText());
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
  const show = () => showTip(row, typeof tip === 'function' ? tip() : tip);
  row.addEventListener('mouseenter', show);
  row.addEventListener('focus', show);
  row.addEventListener('mouseleave', hideTip);
  row.addEventListener('blur', hideTip);
}
function showTip(row, text) {
  const tip = $('tip');
  tip.textContent = text;
  tip.classList.remove('hidden');
  tipRow = row;
  // Right-aligned to the row, under it; above it if it would run off the visible card,
  // and never past either edge of the card (which would scroll it sideways).
  const panel = $('panel');
  const r = offsetIn(row, panel);
  const view = { top: panel.scrollTop + 4, bottom: panel.scrollTop + panel.clientHeight - 4 };
  let top = r.top + row.offsetHeight + 4;
  if (top + tip.offsetHeight > view.bottom) top = r.top - tip.offsetHeight - 4;
  top = Math.max(view.top, Math.min(view.bottom - tip.offsetHeight, top));
  tip.style.top = `${top}px`;
  const maxLeft = panel.clientWidth - tip.offsetWidth - 8;
  tip.style.left = `${Math.max(8, Math.min(maxLeft, r.left + row.offsetWidth - tip.offsetWidth))}px`;
}
let tipRow = null;
// A row's position inside the card, whatever its offsetParent.
function offsetIn(node, panel) {
  let top = 0, left = 0;
  for (let n = node; n && n !== panel; n = n.offsetParent) { top += n.offsetTop; left += n.offsetLeft; }
  return { top, left };
}
function hideTip() { $('tip').classList.add('hidden'); tipRow = null; }

// Every 30 s: countdowns, tips and free-reset expiries, with no rebuild, so focus, the
// cursor and a showing tip all stay where they are.
function tick() {
  for (const row of document.querySelectorAll('.limit')) {
    const tip = row.tickText?.();
    if (row === tipRow && tip) $('tip').textContent = tip;
  }
  for (const c of document.querySelectorAll('.credits[data-expires]')) {
    const n = int(c.dataset.count);
    c.textContent = `${n} free reset${n === 1 ? '' : 's'} · next expires in ${leftText(c.dataset.expires)}`;
  }
  if (!refreshing && data?.updatedAt) $('updated').textContent = agoText(data.updatedAt);
}

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
  const w = $('wrap').getBoundingClientRect().width;
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
  if (refreshing) return;   // one collector run at a time
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

$('add').textContent = GLYPH.add;
const addAccount = () => { act('agent-account-add'); close(); };
$('add').onclick = addAccount;
$('refresh').textContent = GLYPH.refresh;
$('refresh').onclick = refresh;
for (const t of document.querySelectorAll('.tile')) {
  t.querySelector('.icon').textContent = GLYPH[t.dataset.kind];
  t.title = `Start your default agent to make a ${t.dataset.kind}`;
  t.onclick = () => { act('agent-make', t.dataset.kind); close(); };
}

// A text size or monitor change re-measures the zoomed card.
window.addEventListener('resize', place);
document.addEventListener('mousedown', e => { if (!$('panel').contains(e.target)) close(); });
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
  else if (k === 'a') addAccount();
  else return;
  e.preventDefault();
});

document.documentElement.style.setProperty('--top', `${(env.BAR_HEIGHT ?? 26) + (env.GAP ?? 10)}px`);
const [first, defaults, anchor] = await Promise.all([get('agents.json'), get('defaults.json'), get('usage-anchor.json')]);
anchorX = Number.isFinite(anchor?.x) ? anchor.x : null;
known = defaults?.agents ?? [];
data = first;
stamp = first?.updatedAt ?? null;
render();
setInterval(poll, 2000);
// Reset times count down while the panel is open.
setInterval(tick, 30000);

const shown = () => requestAnimationFrame(() => document.body.classList.add('shown'));
if (document.hasFocus()) shown();
else { window.addEventListener('focus', shown, { once: true }); setTimeout(shown, 300); }
setTimeout(() => window.addEventListener('blur', close), 400);
