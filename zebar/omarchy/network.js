// Omarchy Quattro's Network panel (shell/plugins/panels/network) on Windows. menu.ahk opens
// it from the bar's network icon. Two files feed it, both written by winarchy:
//   netpanel.json   the connection, DNS provider and Wi-Fi list (`winarchy network-state`)
//   speedtest.json  the running speed test (`winarchy speedtest-run`)
// Changes go back through menu.ahk: dns-quick, wifi, speedtest-run, network-state.
//   s: speed test · r: refresh · Esc: close
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { calm } from './motion.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls ?? '', textContent: text ?? '' });
const act = (...args) => zebar.shellExec(env.AHK, [env.MENU, ...args.map(String)]).catch(e => console.error(e));
const getJson = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).catch(() => null);

const GLYPH = { wifi: '\u{F05A9}', ethernet: '\u{F0200}', none: '\u{F05AA}', lock: '\u{F033E}', check: '\u{F012C}' };
const DNS = [['dhcp', 'DHCP'], ['cloudflare', 'Cloudflare'], ['google', 'Google'], ['custom', 'Custom']];
const BARS = ['\u{F091F}', '\u{F0922}', '\u{F0925}', '\u{F0928}'];   // wifi strength 1-4

let net = null;      // netpanel.json
let speed = null;    // speedtest.json
let busy = '';       // an action on its way ('dns', 'radio', an SSID)
let scale = 100;     // top of the dials, Mbps

// The dial's top: the next round figure above what has been measured, so a 300 Mbit/s link
// is not lost in a 1 Gbit/s dial and a gigabit one does not peg it.
function niceMax(v) {
  for (const s of [50, 100, 250, 500, 1000, 2500, 5000, 10000]) if (v <= s * 0.9) return s;
  return 10000;
}

function dial(id, value, live, max) {
  const d = $(id);
  d.classList.toggle('live', live);
  d.querySelector('.fill').style.strokeDashoffset = String(100 - Math.max(0, Math.min(1, value / max)) * 100);
}

function render() {
  const n = net ?? {};
  const wifi = n.type === 'wifi';
  $('heroMark').textContent = GLYPH[n.type] ?? GLYPH.none;
  $('heroMark').classList.toggle('off', !n.type || n.type === 'none');
  $('title').textContent = wifi ? (n.ssid || 'Wi-Fi') : n.type === 'ethernet' ? 'Ethernet' : n.wifiCapable && !n.wifiOn ? 'Wi-Fi is off' : 'Not connected';
  const bits = [];
  if (n.ip) bits.push(n.ip);
  if (wifi && n.signal) bits.push(`${n.signal}%${n.band ? ` · ${n.band}` : ''}`);
  if (n.routerMs != null) bits.push(`router ${n.routerMs} ms`);
  if (n.internetMs != null) bits.push(`internet ${n.internetMs} ms`);
  $('meta').textContent = bits.join(' · ') || (net ? 'No connection' : 'Checking…');

  const radio = $('radio');
  radio.classList.toggle('hidden', !n.wifiCapable);
  radio.classList.toggle('on', !!n.wifiOn);
  radio.classList.toggle('busy', busy === 'radio');
  radio.setAttribute('aria-checked', String(!!n.wifiOn));
  radio.title = n.wifiOn ? 'Turn Wi-Fi off' : 'Turn Wi-Fi on';
  radio.onclick = () => { if (!busy) run('radio', ['wifi', 'radio']); };

  // ---- speed test
  const s = speed ?? {};
  const running = s.phase === 'down' || s.phase === 'up';
  scale = Math.max(scale, niceMax(Math.max(s.down ?? 0, s.up ?? 0, s.mbps ?? 0)));
  if (!running && s.phase !== 'done') scale = 100;
  const shown = (v, phase) => (running && s.phase === phase ? s.mbps : v);
  $('numDown').textContent = s.phase === 'down' || s.down ? fmt(shown(s.down, 'down')) : '--';
  $('numUp').textContent = s.phase === 'up' || s.up ? fmt(shown(s.up, 'up')) : '--';
  dial('dialDown', shown(s.down ?? 0, 'down'), running && s.phase === 'down', scale);
  dial('dialUp', shown(s.up ?? 0, 'up'), running && s.phase === 'up', scale);
  $('speedValue').textContent = running ? (s.phase === 'down' ? 'Testing download…' : 'Testing upload…') : s.phase === 'done' ? 'Done' : '';
  const run_ = $('run');
  run_.disabled = running || !n.type || n.type === 'none';
  run_.textContent = running ? 'Testing…' : s.phase === 'done' ? 'Run again' : 'Run speed test';
  run_.onclick = startSpeed;
  const err = s.phase === 'error' ? `Speed test failed: ${s.error ?? 'no answer'}` : '';
  $('status').textContent = err;
  $('status').classList.toggle('hidden', !err);
  $('status').classList.toggle('error', !!err);

  // ---- DNS
  $('dnsValue').textContent = n.dnsServers?.length ? n.dnsServers.join(', ') : '';
  $('dns').replaceChildren(...DNS.map(([key, label]) => {
    const b = el('button', `pill${n.dns === key ? ' on' : ''}`, label);
    b.title = key === 'custom' ? 'Enter your own servers' : `Use ${label} DNS`;
    b.onclick = () => { if (!busy) run('dns', ['dns-quick', key]); };
    return b;
  }));

  // ---- Wi-Fi networks
  const list = n.wifi ?? [];
  $('wifiBox').classList.toggle('hidden', !n.wifiCapable || !n.wifiOn);
  $('wifiCount').textContent = list.length ? `${list.length} in range` : '';
  $('wifi').replaceChildren(...(list.length ? list.map(w => {
    const r = el('button', `row${w.connected ? ' on' : ''}`);
    const name = el('span', 'name', w.ssid);
    if (busy === w.ssid) name.append(el('small', '', 'Connecting…'));
    else if (!w.known && w.secured) name.append(el('small', '', 'Needs a password: opens Windows Wi-Fi'));
    r.append(el('span', 'glyph', BARS[Math.min(3, Math.floor(w.signal / 26))]), name,
      el('span', 'check', w.connected ? GLYPH.check : w.secured ? GLYPH.lock : ''));
    r.onclick = () => connect(w);
    return r;
  }) : [el('div', 'empty', 'No networks found.')]));
  place();
}

const fmt = v => (v >= 100 ? String(Math.round(v)) : Number(v ?? 0).toFixed(1));

// ---- actions
async function run(kind, args) {
  busy = kind;
  render();
  await act(...args);
  await act('network-state');
  await load();
  busy = '';
  render();
}
function connect(w) {
  if (busy || w.connected) return;
  // Windows keeps a saved network's password; a new secured one needs its own sign-in flow.
  if (!w.known && w.secured) return void act('settings', 'ms-settings:network-wifi');
  run(w.ssid, ['wifi', 'connect', w.ssid]);
}
async function startSpeed() {
  if (speed?.phase === 'down' || speed?.phase === 'up') return;
  speed = { phase: 'down', mbps: 0, down: 0, up: 0 };     // the dials react before the first sample lands
  render();
  act('speedtest-run');
}

// ---- position (as the Display panel)
let anchorX = null;
function place() {
  const w = $('wrap').getBoundingClientRect().width;
  const x = anchorX ?? window.innerWidth / 2;
  document.documentElement.style.setProperty('--left', `${Math.max(12, Math.min(window.innerWidth - w - 12, x - w / 2))}px`);
}

// ---- data
async function load() {
  const [n, s] = await Promise.all([getJson('netpanel.json'), getJson('speedtest.json')]);
  if (n) net = n;
  // A finished run from an earlier session is not this panel's to show.
  if (s && (speed?.phase === 'down' || speed?.phase === 'up' || speed?.phase === 'error' || speed?.phase === 'done' || s.phase === 'down' || s.phase === 'up')) speed = s;
}

// ---- lifecycle
let closing = false;
function close() {
  if (closing) return;
  closing = true;
  document.body.classList.remove('shown');
  setTimeout(() => Promise.resolve(zebar.currentWidget().window.tauri.close()).catch(() => {}), calm.matches ? 0 : 110);
}
document.addEventListener('mousedown', e => { if (!$('panel').contains(e.target)) close(); });
window.addEventListener('keydown', e => {
  const k = e.key.length === 1 ? e.key.toLowerCase() : e.key;
  if (k === 'Escape') return close();
  if (k === 's') startSpeed();
  else if (k === 'r') { act('network-state'); }
  else return;
  e.preventDefault();
});

document.documentElement.style.setProperty('--top', `${(env.BAR_HEIGHT ?? 26) + (env.GAP ?? 10)}px`);
const anchor = await getJson('network-anchor.json');
anchorX = Number.isFinite(anchor?.x) ? anchor.x : null;
act('network-state');          // menu.ahk also asked for it: the file lands a few seconds in
await load();
render();
// The speed test moves fast; the connection details only when something changes.
setInterval(async () => { await load(); render(); }, 400);
setInterval(() => { if (!busy) act('network-state'); }, 8000);

const shown = () => requestAnimationFrame(() => document.body.classList.add('shown'));
if (document.hasFocus()) shown();
else { window.addEventListener('focus', shown, { once: true }); setTimeout(shown, 300); }
setTimeout(() => window.addEventListener('blur', close), 400);
