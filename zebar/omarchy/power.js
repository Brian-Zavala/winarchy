// Omarchy Quattro's Power panel (shell/plugins/panels/power) on Windows. menu.ahk opens it
// from the bar's battery icon (Super+Ctrl+P) after writing power.json (lib/power.ahk: the
// battery as omarchy-battery-status reports it, and Windows' power mode) and
// power-anchor.json (the click's x). Quattro's power profiles are Windows' power modes.
//   arrows / h j k l: profile · Enter: choose · Esc: close
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { calm } from './motion.js';
import { panel } from './panel.js';

const $ = id => document.getElementById(id);
const el = (tag, cls, text) => Object.assign(document.createElement(tag), { className: cls ?? '', textContent: text ?? '' });
const act = (...args) => zebar.shellExec(env.AHK, [env.MENU, ...args.map(String)]).catch(e => console.error(e));
const getJson = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).catch(() => null);

// Quattro's Model.js: ten steps each, and the full battery.
const CHARGING = ['\u{F089C}', '\u{F0086}', '\u{F0087}', '\u{F0088}', '\u{F089D}', '\u{F0089}', '\u{F089E}', '\u{F008A}', '\u{F008B}', '\u{F0085}'];
const DEFAULT = ['\u{F007A}', '\u{F007B}', '\u{F007C}', '\u{F007D}', '\u{F007E}', '\u{F007F}', '\u{F0080}', '\u{F0081}', '\u{F0082}', '\u{F0079}'];
const FULL = '\u{F0085}';
// Quattro's profiles (power-profiles-daemon's names) and the power mode each one is here.
const PROFILES = [
  { mode: 'saver', label: 'Power-saver', icon: '\u{F032A}' },
  { mode: 'balanced', label: 'Balanced', icon: '\u{F029A}' },
  { mode: 'performance', label: 'Performance', icon: '\u{F04C5}' },
];
const CHARGING_PHRASES = ['Pumping power', 'Injecting electrons', 'Pouring juice', 'Amassing watts',
  'Hoarding joules', 'Sucking volts', 'Topping reserves', 'Soaking amps', 'Inhaling kilowatts'];
const BATTERY_PHRASES = ['Slurping power', 'Spending joules', 'Draining watts', 'Burning electrons',
  'Sipping juice', 'Spending coulombs', 'Bleeding amps', 'Guzzling volts', 'Munching reserves'];

let data = null;       // power.json
let busy = false;
let cursorOn = false, index = 0;
let phrase = 0;

const state = () => data?.state ?? '';
const discharging = () => state() === 'discharging';
const holding = () => state() === 'holding';
const full = () => state() === 'full';
const charging = () => state() === 'charging';

function batteryIcon(d) {
  if (!d?.present) return '';
  const i = Math.max(0, Math.min(9, Math.floor((d.percent ?? 0) / 10)));
  if (d.state === 'holding') return DEFAULT[i];
  if (d.state === 'full') return FULL;
  if (d.state !== 'discharging') return CHARGING[i];
  return DEFAULT[i];
}

function modeLabel() {
  if (holding()) return 'Threshold';
  if (discharging()) return 'On battery';
  if (full()) return 'Fully charged';
  return 'Charging';
}
const phrases = () => (full() ? [] : charging() ? CHARGING_PHRASES : discharging() ? BATTERY_PHRASES : []);
function moodText() {
  if (full()) return 'Fully charged';
  const list = phrases();
  return list.length ? list[phrase % list.length] : modeLabel();
}

// The profile buttons are made once; render() only restyles them.
const buttons = PROFILES.map((p, i) => {
  const b = el('button', 'profile');
  b.setAttribute('role', 'radio');
  b.append(el('span', 'glyph', p.icon), el('span', '', p.label));
  b.onclick = () => setProfile(p.mode);
  b.onmouseenter = () => { cursorOn = true; index = i; render(); };
  return b;
});
$('profiles').replaceChildren(...buttons);

function render() {
  if (data && !data.present) return close();
  const pct = data?.percent;
  $('heroGlyph').textContent = batteryIcon(data);
  $('mood').textContent = data ? moodText() : 'Checking…';
  $('percent').textContent = Number.isFinite(pct) ? `${pct}%` : '—';
  $('meter').style.setProperty('--p', `${Math.max(0, Math.min(100, pct ?? 0))}%`);
  $('meter').classList.toggle('charging', charging());

  // Only hidden until the first read, so the rows never blink around a plug or unplug.
  $('stats').classList.toggle('hidden', !Number.isFinite(pct));
  const idle = full() || holding();
  $('size').textContent = data?.size || '—';
  $('cycles').textContent = data?.cycles || '—';
  $('timeLabel').textContent = holding() ? 'Charge limit' : discharging() ? 'Time left' : 'Time to full';
  $('time').textContent = holding() ? (data?.threshold || '-') : idle ? '-' : (data?.time || '—');
  $('rateLabel').textContent = holding() ? 'Battery state' : discharging() ? 'Discharging' : 'Charging';
  $('rate').textContent = holding() ? 'Holding' : full() ? '-' : (data?.rate || '');

  $('panel').classList.toggle('cursor-on', cursorOn);
  PROFILES.forEach((p, i) => {
    const b = buttons[i];
    b.classList.toggle('on', data?.mode === p.mode);
    b.classList.toggle('has-cursor', cursorOn && i === index);
    b.classList.toggle('busy', busy);
    b.setAttribute('aria-checked', String(data?.mode === p.mode));
  });
  place();
}

async function load() {
  // Keep what we had if a read comes back empty (around a plug / unplug).
  const next = await getJson('power.json');
  if (next) data = next;
}
async function refresh() {
  await act('power-state');
  await load();
  render();
}
async function setProfile(mode) {
  if (busy || !mode) return;
  busy = true;
  render();
  await act('power-mode', mode, 'panel');
  await load();
  busy = false;
  render();
}

// The status line changes phrase every 2.8 s while current flows, with a fade.
function nextPhrase() {
  if (phrases().length < 2) return;
  const mood = $('mood');
  if (calm.matches) { phrase++; mood.textContent = moodText(); return; }
  mood.classList.add('fading');
  setTimeout(() => { phrase++; mood.textContent = moodText(); mood.classList.remove('fading'); }, 180);
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
  const k = e.key;
  if (k === 'Escape') return close();
  const d = k === 'l' || k === 'j' || k === 'ArrowRight' || k === 'ArrowDown' ? 1
    : k === 'h' || k === 'k' || k === 'ArrowLeft' || k === 'ArrowUp' ? -1 : 0;
  if (d) {
    // The first key shows the cursor on the active profile; the next ones move it.
    if (!cursorOn) cursorOn = true;
    else index = Math.max(0, Math.min(PROFILES.length - 1, index + d));
    render();
  } else if (k === 'Enter' || k === ' ') {
    if (cursorOn) setProfile(PROFILES[index].mode);
  } else return;
  e.preventDefault();
});

const p = panel({
  name: 'power',
  async open({ anchor }) {
    anchorX = Number.isFinite(anchor.x) ? anchor.x : null;
    // menu.ahk wrote power.json just before showing it.
    await load();
    cursorOn = false;
    busy = false;
    index = Math.max(0, PROFILES.findIndex(x => x.mode === data?.mode));
    render();
  },
});
p.every(5000, () => (busy ? null : refresh()));
p.every(2800, nextPhrase);
