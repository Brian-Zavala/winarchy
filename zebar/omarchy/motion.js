// Small, stateless motion helpers for the menu. Everything here turns itself off when
// Windows' "Animation effects" is off (WebView2 reports it as prefers-reduced-motion).
export const calm = matchMedia('(prefers-reduced-motion: reduce)');

export const wait = ms => new Promise(r => setTimeout(r, ms));

// Route changes run inside a View Transition (menu.css slides the card's old and new
// content by `type`). A new swap or close skips the running one; skipped transitions
// reject their promises, which must not reach the error logger.
let running = null;
export function swap(update, type) {
  if (calm.matches || !document.startViewTransition) return update();
  running?.skipTransition();
  const vt = document.startViewTransition({ update, types: [type] });
  running = vt;
  vt.ready.catch(() => {});
  vt.finished.catch(() => {}).then(() => { if (running === vt) running = null; });
}
export function skipSwap() { running?.skipTransition(); }

// Slide a highlight (list rows, grid ring, tab underline) onto `el`. It lives inside the
// same scroll container as `el`, so offsets are enough and it scrolls along for free.
// data-axis="x" (tab underline) only follows the left edge and width.
export function glide(g, el, instant = false) {
  if (!el) { g.style.opacity = '0'; return; }
  if (instant || calm.matches) g.style.transition = 'none';
  g.style.opacity = '1';
  g.style.translate = `${el.offsetLeft}px ${g.dataset.axis === 'x' ? 0 : el.offsetTop}px`;
  g.style.width = `${el.offsetWidth}px`;
  g.style.height = `${el.offsetHeight}px`;
  if (g.style.transition) {
    void g.offsetWidth;   // commit the jump before transitions come back
    g.style.transition = '';
  }
}

// One-shot WAAPI animation (entry effects that CSS state can't express).
export function pop(el, frames, opts = {}) {
  if (calm.matches || !el) return;
  el.animate(frames, { duration: 260, easing: 'cubic-bezier(.2, .8, .2, 1)', fill: 'backwards', ...opts });
}

// Cascade `els` in, one after another; only the first `cap` wait their turn.
export function stagger(els, frames, step = 18, cap = 16) {
  els.forEach((el, i) => pop(el, frames, { delay: Math.min(i, cap) * step }));
}
