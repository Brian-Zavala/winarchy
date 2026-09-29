// Omarchy Quattro's Bluetooth panel (shell/plugins/panels/bluetooth) on Windows. menu.ahk opens
// it from the bar's Bluetooth icon (Super+Ctrl+B). bluetooth.json (ps51/bluetooth.ps1, run
// through `menu.ahk bluetooth <state|on|off>`) says whether the radio is on and lists the
// paired devices with their connection state. Windows has no API to connect a device, so a
// device row opens Windows' own Bluetooth settings, where that is one click.
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { panel } from './panel.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls ?? '', textContent: text ?? '' });
const act = (...args) => zebar.shellExec(env.AHK, [env.MENU, ...args.map(String)]).catch(e => console.error(e));
const getJson = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).catch(() => null);

const G = { on: '\u{F00AF}', off: '\u{F00B2}', device: '\u{F00AF}', headset: '\u{F02CB}', pair: '\u{F0415}', check: '\u{F012C}' };

let bt = null;       // bluetooth.json
let busy = false;

function render() {
  const on = !!bt?.on;
  $('heroMark').textContent = on ? G.on : G.off;
  $('heroMark').classList.toggle('off', !on);
  const devs = bt?.devices ?? [];
  const connected = devs.filter(d => d.connected);
  $('title').textContent = !bt ? 'Bluetooth' : !bt.present ? 'No Bluetooth adapter' : on ? (connected.length ? connected.map(d => d.name).join(', ') : 'Bluetooth') : 'Bluetooth is off';
  $('meta').textContent = !bt ? 'Checking…' : !bt.present ? '' : on ? (connected.length ? `${connected.length} connected` : 'Not connected to anything') : 'Turn it on to see your devices';
  const power = $('power');
  power.classList.toggle('hidden', !bt?.present);
  power.classList.toggle('on', on);
  power.classList.toggle('busy', busy);
  power.setAttribute('aria-checked', String(on));
  power.title = on ? 'Turn Bluetooth off (t)' : 'Turn Bluetooth on (t)';
  power.onclick = toggle;

  $('devBox').classList.toggle('hidden', !on || !devs.length);
  $('devCount').textContent = devs.length ? `${devs.length} paired` : '';
  $('devices').replaceChildren(...devs.map(d => {
    const r = el('button', `row${d.connected ? ' on live' : ''}`);
    const name = el('span', 'name', d.name);
    name.append(el('small', '', d.connected ? 'Connected' : 'Paired: not connected'));
    r.append(el('span', 'glyph', G.device), name, el('span', 'check', d.connected ? G.check : ''));
    r.title = d.connected ? 'Open Bluetooth settings' : 'Open Bluetooth settings to connect';
    r.onclick = () => act('settings', 'ms-settings:bluetooth');
    return r;
  }));
  $('addBox').classList.toggle('hidden', !on);
  $('pair').querySelector('.glyph').textContent = G.pair;
  $('pair').onclick = () => act('settings', 'ms-settings:bluetooth');
  place();
}

async function load() {
  // The bar rewrites this file every 30 s with just the radio; keep the device list we had.
  const next = await getJson('bluetooth.json');
  if (next) bt = { ...next, devices: next.devices ?? bt?.devices };
}
async function refresh() {
  await act('bluetooth', 'state');
  await load();
  render();
}
async function toggle() {
  if (busy || !bt?.present) return;
  busy = true;
  render();
  await act('bluetooth', bt.on ? 'off' : 'on');
  await load();
  busy = false;
  render();
}

// ---- position (as the Display panel)
let anchorX = null;
function place() {
  const w = $('wrap').getBoundingClientRect().width;
  const x = anchorX ?? window.innerWidth / 2;
  document.documentElement.style.setProperty('--left', `${Math.max(12, Math.min(window.innerWidth - w - 12, x - w / 2))}px`);
}

// ---- lifecycle (panel.js: the window hides on close and is shown again next time)
const close = () => p.close();
window.addEventListener('keydown', e => {
  const k = e.key.length === 1 ? e.key.toLowerCase() : e.key;
  if (k === 'Escape') return close();
  if (k === 't') toggle();
  else if (k === 'r') refresh();
  else return;
  e.preventDefault();
});

const p = panel({
  name: 'bluetooth',
  async open({ anchor }) {
    anchorX = Number.isFinite(anchor.x) ? anchor.x : null;
    busy = false;
    await load();
    render();
    refresh();                   // the radio and devices now, behind what was there
  },
});
// (every() skips a round while the last one - a PowerShell 5.1 WinRT query - still runs.)
p.every(6000, async () => { if (!busy) await refresh(); });
