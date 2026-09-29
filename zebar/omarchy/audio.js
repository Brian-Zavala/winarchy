// Omarchy Quattro's Audio panel (shell/plugins/panels/audio) on Windows. menu.ahk opens it
// from the bar's audio icon (Super+Ctrl+A). Zebar's audio provider gives the devices and the
// master volume, live; the default-device switch and the per-app mixer go through winarchy
// (`audio ...`), which answers with audio.json.
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { panel } from './panel.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls ?? '', textContent: text ?? '' });
const act = (...args) => zebar.shellExec(env.AHK, [env.MENU, ...args.map(String)]).catch(e => console.error(e));
const getJson = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).catch(() => null);

const G = { speaker: ['\u{F0581}', '\u{F057F}', '\u{F0580}', '\u{F057E}'], muted: '\u{F0581}', mic: '\u{F036C}', micOff: '\u{F036D}', check: '\u{F012C}', headphones: '\u{F02CB}', app: '\u{F0F1D}' };
G.muted = '\u{F075F}';

const provider = zebar.createProvider({ type: 'audio' });
let out = null;          // the provider's output
let apps = [];           // audio.json sessions
let dragging = false;    // a slider is under the pointer: leave it alone

const volGlyph = (v, muted) => (muted || v === 0 ? G.muted : G.speaker[v < 34 ? 1 : v < 67 ? 2 : 3]);
const fill = (input, v) => input.style.setProperty('--fill', `${v}%`);

function render() {
  const dev = out?.defaultPlaybackDevice;
  const v = Math.round(dev?.volume ?? 0);
  $('heroMark').textContent = volGlyph(v, dev?.isMuted);
  $('heroMark').classList.toggle('off', !!dev?.isMuted);
  $('title').textContent = dev?.name ?? 'No output device';
  $('meta').textContent = dev ? (dev.isMuted ? 'Muted' : 'Volume') : '';
  $('pct').textContent = dev ? `${dev.isMuted ? 0 : v}%` : '';
  const master = $('master');
  master.classList.toggle('muted', !!dev?.isMuted);
  master.disabled = !dev;
  if (!dragging) { master.value = String(v); fill(master, v); }

  // ---- outputs
  const outs = out?.playbackDevices ?? [];
  $('outBox').classList.toggle('hidden', outs.length < 1);
  $('outputs').replaceChildren(...outs.map(d => {
    const on = d.deviceId === dev?.deviceId;
    const r = el('button', `row${on ? ' on' : ''}`);
    r.append(el('span', 'glyph', G.headphones), el('span', 'name', d.name), el('span', 'check', on ? G.check : ''));
    r.onclick = () => { if (!on) switchOutput(d); };
    return r;
  }));

  // ---- microphone
  const mic = out?.defaultRecordingDevice;
  $('inBox').classList.toggle('hidden', !mic);
  if (mic) {
    const mv = Math.round(mic.volume ?? 0);
    $('micName').textContent = mic.name;
    $('micMute').textContent = mic.isMuted ? G.micOff : G.mic;
    $('micMute').classList.toggle('off', !!mic.isMuted);
    $('micPct').textContent = `${mic.isMuted ? 0 : mv}%`;
    if (!dragging) { $('mic').value = String(mv); fill($('mic'), mv); }
  }

  // ---- apps
  $('appBox').classList.toggle('hidden', !apps.length);
  $('appCount').textContent = apps.length ? `${apps.length} playing` : '';
  if (!dragging) {
    $('apps').replaceChildren(...apps.map(a => {
      const row = el('div', 'app');
      const slider = Object.assign(el('input'), { type: 'range', min: '0', max: '100', step: '1', value: String(a.volume) });
      slider.classList.toggle('muted', a.muted);
      fill(slider, a.volume);
      slider.oninput = () => { dragging = true; fill(slider, slider.value); num.textContent = `${slider.value}%`; };
      slider.onchange = () => { act('audio', 'app-volume', a.pid, slider.value); dragging = false; };
      const num = el('span', 'num', `${a.muted ? 0 : a.volume}%`);
      const mute = el('button', `glyph tiny${a.muted ? ' off' : ''}`, a.muted ? G.muted : G.speaker[2]);
      mute.title = a.muted ? 'Unmute' : 'Mute';
      mute.onclick = async () => { await act('audio', 'app-mute', a.pid, a.muted ? 0 : 1); await loadApps(); };
      row.append(el('span', 'name', a.name), slider, num, mute);
      return row;
    }));
  }
  place();
}

// ---- actions
// One volume change per frame while the slider is dragged (each one is a round trip to
// Windows and comes back as a provider update that redraws the panel).
let wantMaster = null, masterFrame = 0;
function setMaster(v) {
  wantMaster = v;
  masterFrame ||= requestAnimationFrame(() => {
    masterFrame = 0;
    const dev = out?.defaultPlaybackDevice;
    if (!dev) return;
    provider.setVolume(wantMaster, { deviceId: dev.deviceId });
    if (dev.isMuted && wantMaster > 0) provider.setMute(false, { deviceId: dev.deviceId });
  });
}
const toggleMute = () => {
  const dev = out?.defaultPlaybackDevice;
  if (dev) provider.setMute(!dev.isMuted, { deviceId: dev.deviceId });
};
async function switchOutput(d) {
  await act('audio', 'default', d.deviceId);
  await loadApps();
}
async function loadApps() {
  const s = await getJson('audio.json');
  apps = s?.sessions ?? [];
  render();
}

$('master').addEventListener('input', e => { dragging = true; fill(e.target, e.target.value); $('pct').textContent = `${e.target.value}%`; setMaster(Number(e.target.value)); });
$('master').addEventListener('change', () => { dragging = false; });
let wantMic = null, micFrame = 0;
$('mic').addEventListener('input', e => {
  dragging = true; fill(e.target, e.target.value); $('micPct').textContent = `${e.target.value}%`;
  wantMic = Number(e.target.value);
  micFrame ||= requestAnimationFrame(() => {
    micFrame = 0;
    const mic = out?.defaultRecordingDevice;
    if (mic) provider.setVolume(wantMic, { deviceId: mic.deviceId });
  });
});
$('mic').addEventListener('change', () => { dragging = false; });
$('micMute').onclick = () => { const mic = out?.defaultRecordingDevice; if (mic) provider.setMute(!mic.isMuted, { deviceId: mic.deviceId }); };
$('heroMark').onclick = toggleMute;
$('wrap').addEventListener('wheel', e => {
  if (e.target.closest('#apps')) return;
  setMaster(Math.max(0, Math.min(100, Math.round((out?.defaultPlaybackDevice?.volume ?? 0) + (e.deltaY < 0 ? 5 : -5)))));
}, { passive: true });

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
  if (e.target.tagName === 'INPUT' && (e.key === 'ArrowLeft' || e.key === 'ArrowRight')) return;   // the slider's own
  const k = e.key.length === 1 ? e.key.toLowerCase() : e.key;
  const cur = Math.round(out?.defaultPlaybackDevice?.volume ?? 0);
  if (k === 'Escape') return close();
  if (k === 'm') toggleMute();
  else if (k === 'ArrowLeft') setMaster(Math.max(0, cur - 5));
  else if (k === 'ArrowRight') setMaster(Math.min(100, cur + 5));
  else return;
  e.preventDefault();
});

// The provider stays subscribed while the panel is hidden; drawing waits for the next open.
provider.onOutput(o => { out = o; if (p.open) render(); });
const refreshApps = async () => { if (!dragging) await act('audio', 'sessions').then(loadApps); };
const p = panel({
  name: 'audio',
  async open({ anchor }) {
    anchorX = Number.isFinite(anchor.x) ? anchor.x : null;
    dragging = false;
    out = provider.output ?? out;
    await loadApps();            // the list from last time, at once
    refreshApps();               // and a fresh one behind it
  },
  onHidden() { dragging = false; },
});
p.every(5000, refreshApps);
