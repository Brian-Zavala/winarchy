// The bar's panels (audio, network, Bluetooth, display, Tailscale, power, agent usage, calendar,
// world clock) outlive a close, as the menu does: they fade and hide, and menu.ahk shows the
// hidden window again for the next open on that monitor (lib\widgets.ahk). Starting a new
// webview for every click was most of the wait between the click and the panel.
//
//   const p = panel({ name, open, onHidden, anchor, stayOnBlur, ttl });
//   open({ again, anchor }) - load and draw this showing (again = shown before), and reset
//                             what a fresh page used to start with; anchor = <name>-anchor.json
//   onHidden()              - drop what should not outlive this showing
//   p.every(ms, fn)         - a refresh that runs only while the panel is open, and never
//                             starts while its last run (often a PowerShell behind act)
//                             is still going
//   p.close()               - Escape, the panel's own keys
// A click outside the panel, focus going elsewhere and menu.ahk's toggle close it too. A
// panel hidden for `ttl` closes for real, so a spare doesn't hold its memory for good.
import * as zebar from './zebar.mjs';
import * as env from './env.js';
import { calm } from './motion.js';
import { restyle } from './style.js';

const sleep = ms => new Promise(r => setTimeout(r, ms));
const frame = () => new Promise(r => requestAnimationFrame(() => r()));
const getJson = f => fetch(`./${f}?t=${Date.now()}`, { cache: 'no-store' }).then(r => (r.ok ? r.json() : null)).catch(() => null);

export function panel({ name, open, onHidden, anchor = true, stayOnBlur = () => false, ttl = 20 * 60e3, root = 'panel' }) {
  const win = () => zebar.currentWidget().window.tauri;
  let state = 'opening';   // opening -> open -> closing -> hidden -> opening ... | quitting
  let gen = 0, openedAt = 0, wakeLater = false, expiry = 0;
  const loops = new Set();
  // Right under the bar (winarchy apply writes its height and the window gap).
  document.documentElement.style.setProperty('--top', `${(env.BAR_HEIGHT ?? 26) + (env.GAP ?? 10)}px`);

  async function start(again) {
    const my = ++gen;
    state = 'opening';
    openedAt = Date.now();
    clearTimeout(expiry);
    if (again) Promise.resolve(win().show()).catch(() => {});   // Tauri's own flag, after menu.ahk's WinShow
    const [a] = await Promise.all([anchor ? getJson(`${name}-anchor.json`) : null, restyle()]);
    if (my !== gen) return;
    try { await open({ again, anchor: a ?? {} }); } catch (e) { console.error(e); }
    if (my !== gen || state !== 'opening') return;   // closed while it loaded
    state = 'open';
    loops.forEach(l => l.start());
    // menu.ahk activates the window once it is there: fade in then (the webview paints on focus).
    if (!document.hasFocus()) await Promise.race([new Promise(r => addEventListener('focus', r, { once: true })), sleep(300)]);
    if (my === gen && state === 'open') requestAnimationFrame(() => document.body.classList.add('shown'));
  }

  async function close() {
    if (state !== 'open' && state !== 'opening') return;
    state = 'closing';
    gen++;
    loops.forEach(l => l.stop());
    document.body.classList.remove('shown');
    await sleep(calm.matches ? 0 : 110);
    await frame(); await frame();                // the faded frame is on screen before the hide
    try { onHidden?.(); } catch (e) { console.error(e); }
    document.activeElement?.blur?.();
    try { await win().hide(); } catch { return quit(); }
    state = 'hidden';
    expiry = setTimeout(quit, ttl);
    // Shown again while it was on its way out: open for it, or it stays up and empty.
    if (wakeLater) {
      wakeLater = false;
      start(true);
      Promise.resolve(win().setFocus?.()).catch(() => {});
    }
  }

  // Closed for real. Without the close-request handler below, Tauri closes the window itself.
  const unlisten = Promise.resolve(win().onCloseRequested?.(e => {
    if (state === 'quitting') return;
    e.preventDefault();                          // synchronously: Tauri looks right after the handler
    if (state === 'hidden') quit(); else close();   // menu.ahk: toggle when shown; a stale spare when hidden
  })).catch(() => null);
  async function quit() {
    state = 'quitting';
    clearTimeout(expiry);
    try { (await unlisten)?.(); } catch {}
    Promise.resolve(win().close()).catch(() => {});
  }

  const wake = () => {
    if (state === 'hidden') start(true);
    else if (state === 'closing') wakeLater = true;
  };
  addEventListener('focus', wake);
  document.addEventListener('visibilitychange', () => { if (!document.hidden) wake(); });
  addEventListener('blur', () => { if (state === 'open' && Date.now() - openedAt > 400 && !stayOnBlur()) close(); });
  // The window covers the monitor (transparent): a click outside the panel closes it, and one
  // on the bar's icon lands here too, so the icon toggles it.
  document.addEventListener('mousedown', e => {
    if (state === 'hidden') return wake();       // shown but never activated: this click opens it
    if (!document.getElementById(root).contains(e.target)) close();
  });

  start(false);
  return {
    close,
    get open() { return state === 'open' || state === 'opening'; },
    every(ms, fn) {
      let t = 0, running = false;
      const loop = {
        start() {
          clearInterval(t);
          t = setInterval(async () => {
            if (running || state !== 'open') return;
            running = true;
            try { await fn(); } catch (e) { console.error(e); } finally { running = false; }
          }, ms);
        },
        stop() { clearInterval(t); t = 0; },
      };
      loops.add(loop);
      if (state === 'open') loop.start();
      return loop;
    },
  };
}
