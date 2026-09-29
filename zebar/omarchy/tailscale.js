// Omarchy Quattro's Tailscale panel (shell/plugins/panels/tailscale) on Windows. menu.ahk
// opens it from the bar's Tailscale icon; winarchy.ahk / menu.ahk keep these up to date:
//   tailscale-status.json    `tailscale status --json`
//   tailscale-exits.txt      `tailscale exit-node list` (Mullvad locations)
//   tailscale-accounts.json  `tailscale switch --list --json`
// Parsing follows Quattro's Model.js. Actions go back through menu.ahk tailscale <what>.
//   j / k, arrows: move · Enter: choose · c / n / d: copy IP / name / DNS name
//   s: send files (Taildrop) · t: on/off · r: refresh · Esc: close
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { panel } from './panel.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls ?? '', textContent: text ?? '' });
const act = (...args) => zebar.shellExec(env.AHK, [env.MENU, ...args.map(String)]).catch(e => console.error(e));
const getText = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.text() : '')).catch(() => '');

// ---- Quattro's Model.js
const filterIPv4 = ips => (ips ?? []).map(String).filter(ip => /^100\./.test(ip));
const cleanDns = n => { const v = String(n ?? ''); return v.endsWith('.') ? v.slice(0, -1) : v; };
const shortDns = n => cleanDns(n).split('.')[0] ?? '';
const hostName = (host, dns) => (host && String(host).toLowerCase() !== 'localhost' ? String(host) : shortDns(dns) || host || 'Unknown');
const isMullvadHost = n => { const v = String(n ?? '').toLowerCase(); return v.length > 16 && v.endsWith('.mullvad.ts.net'); };
function osIcon(os) {
  const v = String(os ?? '').toLowerCase();
  if (v === 'linux') return '\u{F033D}';
  if (v === 'macos' || v === 'ios') return '\u{F0035}';
  if (v === 'windows') return '\u{F05B3}';
  if (v === 'android') return '\u{F0032}';
  if (v === 'mullvad') return '\u{F0582}';
  return '\u{F07C0}';
}
function hasFileSharing(self) {
  const cap = 'https://tailscale.com/cap/file-sharing';
  if (self?.CapMap && self.CapMap[cap] !== undefined) return true;
  return (self?.Capabilities ?? []).map(String).includes(cap);
}
// Tailscale grades every peer itself; fall back to same-owner for daemons too old to say.
function isTaildropTarget(peer, selfUser) {
  const t = peer?.TaildropTarget;
  if (typeof t === 'number' && t !== 0) return t === 1;
  return peer?.UserID !== undefined && String(peer.UserID) === String(selfUser ?? '');
}
function parseStatus(raw) {
  const text = String(raw ?? '').trim();
  if (!text) return { unavailable: true, message: 'Unavailable' };
  let d;
  try { d = JSON.parse(text); } catch { return { unavailable: true, message: 'Status error' }; }
  const state = String(d.BackendState ?? 'Unknown');
  const self = d.Self ?? {};
  const peers = [];
  for (const [id, p] of Object.entries(d.Peer ?? {})) {
    const dns = cleanDns(p.DNSName);
    if (isMullvadHost(dns) || isMullvadHost(p.HostName) || p.Online !== true) continue;
    peers.push({
      id, name: hostName(p.HostName, p.DNSName), dns, ips: filterIPv4(p.TailscaleIPs), os: String(p.OS ?? ''),
      exitOption: p.ExitNodeOption === true, exitActive: p.ExitNode === true,
      taildrop: isTaildropTarget(p, self.UserID),
    });
  }
  peers.sort((a, b) => a.name.localeCompare(b.name));
  return {
    state, running: state === 'Running', needsLogin: state === 'NeedsLogin',
    selfName: hostName(self.HostName, self.DNSName), selfIp: filterIPv4(self.TailscaleIPs ?? d.TailscaleIPs)[0] ?? '',
    tailnet: d.CurrentTailnet?.Name ?? '', fileSharing: hasFileSharing(self), peers,
    exitNodes: peers.filter(p => p.exitOption),
  };
}
// `tailscale exit-node list`: a fixed-width table; Mullvad rows folded to one per city.
function parseExitList(raw) {
  const lines = String(raw ?? '').split(/\r?\n/);
  const h = lines.findIndex(l => /^\s*IP\s+HOSTNAME\s+COUNTRY\s+CITY\s+STATUS\s*$/.test(l));
  if (h < 0) return [];
  const head = lines[h];
  const cols = ['IP', 'HOSTNAME', 'COUNTRY', 'CITY', 'STATUS'].map(c => head.indexOf(c));
  const cut = (l, i) => l.substring(cols[i], i + 1 < cols.length ? cols[i + 1] : undefined).trim();
  const byCity = new Map();
  for (const l of lines.slice(h + 1)) {
    if (!l.trim() || l.trim().startsWith('#')) continue;
    const host = cut(l, 1), country = cut(l, 2), city = cut(l, 3), status = cut(l, 4);
    if (!isMullvadHost(host) || !country || !city || city === 'Any') continue;
    const key = `${country}\n${city}`;
    const row = byCity.get(key) ?? { id: `mullvad:${key}`, name: `${city}, ${country}`, ips: [], os: 'mullvad', mullvad: true, exitActive: false };
    if (!row.ips.length && cut(l, 0)) row.ips = [cut(l, 0)];
    if (status && status !== '-') { row.exitActive = true; row.ips = [cut(l, 0)]; }
    byCity.set(key, row);
  }
  return [...byCity.values()].sort((a, b) => a.name.localeCompare(b.name));
}
function parseAccounts(raw) {
  let list = [];
  try { list = JSON.parse(String(raw ?? '').trim() || '[]'); } catch { list = []; }
  if (!Array.isArray(list)) return [];
  return list.map(a => ({
    id: String(a.id ?? a.ID ?? ''),
    label: String(a.nickname ?? a.Nickname ?? '') || String(a.tailnet ?? a.Tailnet ?? '') || String(a.account ?? a.Account ?? a.loginName ?? a.LoginName ?? '') || String(a.id ?? 'Unknown account'),
    detail: String(a.account ?? a.Account ?? a.loginName ?? a.LoginName ?? ''),
    selected: a.selected === true || a.Selected === true,
  })).filter(a => a.id);
}

// Quattro's hero phrases while connected, rotated every 2.8 s.
const PHRASES = ['Private network, anywhere', 'All your devices, one tailnet', 'Encrypted, peer to peer', 'Tunnels up'];

// ---- state
let st = { unavailable: true, message: 'Checking…' };
let mullvad = [];
let accounts = [];
let busy = false;         // an action is on its way: the switch shows it
let cursorOn = false;
let cursor = 0;           // index into rows()
let phrase = 0;

// ---- actions
async function run(...args) {
  busy = true;
  render();
  await act('tailscale', ...args);
  await load();
  busy = false;
  render();
}
const toggle = () => run('toggle');
const copy = text => { if (text) act('copy', text); };
function setExit(p) {
  if (!p) return run('exit-node', 'none');
  if (p.exitActive) return run('exit-node', 'none');
  const target = p.ips[0] ?? p.dns;
  if (target) run('exit-node', target);
}
function send(p) {
  if (!p || !st.fileSharing || !p.taildrop) return;
  act('tailscale', 'send', p.ips[0] ?? p.dns ?? p.name);
}

// ---- render
function mark(node, crossed, warning) {
  const faint = [0, 1, 2, 6, 8];
  const dots = [...Array(9)].map((_, i) =>
    `<circle cx="${1.2 + (i % 3) * 3.8}" cy="${1.2 + Math.floor(i / 3) * 3.8}" r="1.2" opacity="${faint.includes(i) ? 0.24 : 1}"/>`).join('');
  node.innerHTML = `<svg viewBox="0 0 10 10"><g fill="currentColor">${dots}</g>`
    + '<line class="ts-strike" x1="-0.6" y1="10.6" x2="10.6" y2="-0.6" stroke="currentColor" stroke-width="1.1" stroke-linecap="round"/>'
    + '<g class="ts-badge"><circle cx="8.6" cy="8.6" r="2.4"/><text x="8.6" y="9.9" text-anchor="middle">!</text></g></svg>';
  node.classList.toggle('off', crossed);
  node.classList.toggle('login', warning);
}

function row(glyph, name, detail, side, on, handlers) {
  const r = el('button', `row${on ? ' on' : ''}`);
  const n = el('span', 'name', name);
  if (detail) n.append(el('small', '', detail));
  r.append(el('span', 'glyph', glyph), n, side ?? el('span', 'side'));
  Object.assign(r, handlers);
  return r;
}

// The line under the name (its phrase rotates on its own, without redrawing every list).
function renderMeta() {
  const on = !!st.running, login = !!st.needsLogin;
  $('meta').textContent = st.unavailable ? st.message
    : login ? 'Needs login: press t or the switch to sign in'
    : on ? `${PHRASES[phrase % PHRASES.length]}${st.selfIp ? ` · ${st.selfIp}` : ''}`
    : 'Tailscale is disconnected';
}

function render() {
  const on = !!st.running, login = !!st.needsLogin;
  mark($('heroMark'), !on && !login, login);
  $('title').textContent = st.selfName || 'Tailscale';
  renderMeta();
  const power = $('power');
  power.classList.toggle('on', on);
  power.classList.toggle('busy', busy);
  power.setAttribute('aria-checked', String(on));
  power.title = on ? 'Turn Tailscale off (t)' : login ? 'Sign in (t)' : 'Turn Tailscale on (t)';
  power.onclick = toggle;

  const status = $('status');
  const msg = st.unavailable && st.message !== 'Checking…' ? 'Tailscale is not answering. Is its service running? (r to try again)' : '';
  status.textContent = msg;
  status.classList.toggle('hidden', !msg);

  // Connections (several accounts): click switches to one.
  $('accountsBox').classList.toggle('hidden', accounts.length < 2);
  $('accounts').replaceChildren(...accounts.map(a =>
    row('\u{F0004}', a.label, a.detail !== a.label ? a.detail : '', el('span', 'check', a.selected ? '\u{F012C}' : ''), a.selected,
      { onclick: () => { if (!a.selected) run('switch', a.id); }, title: a.selected ? 'In use' : 'Switch to this connection' })));

  // Exit nodes: none, the tailnet's, then Mullvad's cities.
  const exits = [...st.exitNodes ?? [], ...mullvad];
  const current = exits.find(p => p.exitActive);
  $('exitBox').classList.toggle('hidden', !on || !exits.length);
  $('exitValue').textContent = current ? current.name : 'None';
  $('exits').replaceChildren(
    row('\u{F0156}', 'None', 'Use your own connection', el('span', 'check', current ? '' : '\u{F012C}'), !current, { onclick: () => setExit(null) }),
    ...exits.map(p => row(p.mullvad ? '\u{F0582}' : '\u{F1062}', p.name, p.mullvad ? 'Mullvad' : p.ips[0] ?? '', el('span', 'check', p.exitActive ? '\u{F012C}' : ''), p.exitActive,
      { onclick: () => setExit(p), title: p.exitActive ? 'Stop using this exit node' : 'Send all traffic through this machine' })));

  // Machines: online peers; hover shows copy / send.
  $('peersBox').classList.toggle('hidden', !on);
  $('peerCount').textContent = on ? `${st.peers.length} online` : '';
  const peers = st.peers ?? [];
  $('peers').replaceChildren(...(peers.length ? peers.map(p => {
    const side = el('span', 'side');
    side.append(el('span', 'ip', p.ips[0] ?? ''));
    const tools = el('span', 'tools');
    const tool = (label, tip, fn) => { const b = el('button', 'tool', label); b.title = tip; b.onclick = e => { e.stopPropagation(); fn(); }; return b; };
    tools.append(tool('ip', 'Copy IP (c)', () => copy(p.ips[0])), tool('name', 'Copy name (n)', () => copy(p.name)), tool('dns', 'Copy DNS name (d)', () => copy(p.dns)));
    if (st.fileSharing && p.taildrop) tools.append(tool('send', 'Send files (s)', () => send(p)));
    side.append(tools);
    return row(osIcon(p.os), p.name, p.dns, side, false, { onclick: () => copy(p.ips[0]), title: 'Click: copy its IP', _peer: p });
  }) : [el('div', 'empty', 'No machines online on this tailnet.')]));

  nodeList = null;
  paintCursor();
  place();
}

// ---- keyboard cursor: one list, top to bottom (switch, connections, exit nodes, machines)
// Worked out once per render: offsetParent lays the panel out, and the pointer moving over
// the rows asks for the list at every step.
let nodeList = null;
function nodes() {
  nodeList ??= [$('power'), ...$('accounts').children, ...(st.running ? [...$('exits').children, ...$('peers').querySelectorAll('.row')] : [])]
    .filter(n => n.offsetParent !== null);
  return nodeList;
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
// The machine under the cursor (c / n / d / s act on it).
const selectedPeer = () => (cursorOn ? nodes()[cursor]?._peer ?? null : null);

// ---- position (as the Display panel)
let anchorX = null;
function place() {
  const w = $('wrap').getBoundingClientRect().width;
  const x = anchorX ?? window.innerWidth / 2;
  document.documentElement.style.setProperty('--left', `${Math.max(12, Math.min(window.innerWidth - w - 12, x - w / 2))}px`);
}

// ---- data
// true when a file changed since the last look (the 3 s poll redrew every list each time).
let seen = null;
async function load() {
  const [status, exits, accts] = await Promise.all([getText('tailscale-status.json'), getText('tailscale-exits.txt'), getText('tailscale-accounts.json')]);
  const now = `${status}\u0000${exits}\u0000${accts}`;
  if (now === seen) return false;
  seen = now;
  st = parseStatus(status);
  mullvad = st.running ? parseExitList(exits) : [];
  accounts = parseAccounts(accts);
  return true;
}
async function refresh() {
  await act('tailscale', 'refresh');
  await load();
  render();
}

// ---- lifecycle (panel.js: the window hides on close and is shown again next time)
const close = () => p.close();
document.addEventListener('mouseover', e => {
  const i = nodes().findIndex(n => n.contains(e.target));
  if (i >= 0 && (!cursorOn || i !== cursor)) { cursorOn = true; cursor = i; paintCursor(); }
});
window.addEventListener('keydown', e => {
  const k = e.key.length === 1 ? e.key.toLowerCase() : e.key;
  if (k === 'Escape') return close();
  const dy = k === 'j' || k === 'ArrowDown' ? 1 : k === 'k' || k === 'ArrowUp' ? -1 : 0;
  if (dy) {
    e.preventDefault();
    if (!cursorOn) cursorOn = true; else cursor += dy;
    return paintCursor();
  }
  if (k === 'Enter' || k === ' ') { e.preventDefault(); if (cursorOn) nodes()[cursor]?.click(); return; }
  const peer = selectedPeer();
  if (k === 't') toggle();
  else if (k === 'r') refresh();
  else if (k === 'c') copy(peer?.ips[0]);
  else if (k === 'n') copy(peer?.name);
  else if (k === 'd') copy(peer?.dns);
  else if (k === 's') send(peer);
  else return;
  e.preventDefault();
});

const p = panel({
  name: 'tailscale',
  async open({ anchor }) {
    anchorX = Number.isFinite(anchor.x) ? anchor.x : null;
    cursorOn = false; cursor = 0; busy = false;
    seen = null;
    await load();                // what winarchy.ahk last wrote (every 30 s), at once
    render();
    refresh();                   // and the tailnet now, behind it
  },
});
// Quattro refreshes every 30 s; the files change under us when winarchy.ahk refreshes.
p.every(3000, async () => { if (!busy && await load()) render(); });
p.every(2800, () => { if (st.running) { phrase++; renderMeta(); } });
