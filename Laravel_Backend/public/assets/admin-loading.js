(() => {
  'use strict';
  const loader = document.getElementById('cc-page-loader');
  const main = document.querySelector('main');
  let navigationTimeout;
  function resetNavigation() {
    clearTimeout(navigationTimeout);
    if (loader) loader.hidden = true;
    main?.removeAttribute('aria-busy');
    document.querySelectorAll('[data-cc-submitting]').forEach(button => {
      button.disabled = false;
      button.classList.remove('cc-submit-loading');
      delete button.dataset.ccSubmitting;
    });
  }
  function startNavigation() {
    if (loader) loader.hidden = false;
    main?.setAttribute('aria-busy', 'true');
    // Recover if navigation is cancelled or a response becomes a download.
    navigationTimeout = setTimeout(resetNavigation, 15000);
  }
  window.addEventListener('pageshow', resetNavigation);
  document.addEventListener('click', event => {
    const link = event.target.closest('a[href]');
    if (!link || event.defaultPrevented || event.button !== 0 || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || link.hasAttribute('download') || (link.target && link.target !== '_self')) return;
    const url = new URL(link.href, location.href);
    if (url.origin !== location.origin || (url.pathname === location.pathname && url.search === location.search && url.hash)) return;
    startNavigation();
  });
  document.addEventListener('submit', event => {
    if (event.defaultPrevented || event.target.hasAttribute('data-no-page-loader') || event.target.target === '_blank') return;
    const button = event.submitter;
    // Keep the submitter's name/value in the submitted form data.
    if (button && !button.name) {
      button.dataset.ccSubmitting = 'true';
      button.disabled = true;
      button.classList.add('cc-submit-loading');
    }
    startNavigation();
  });

  const refresh = document.querySelector('[data-refresh-stats]');
  if (!refresh) return;
  refresh.addEventListener('click', async () => {
    if (refresh.disabled) return;
    const stats = [...document.querySelectorAll('[data-stat]')];
    const status = document.getElementById('cc-stats-status');
    const grid = document.getElementById('cc-stats');
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 15000);
    refresh.disabled = true;
    grid.setAttribute('aria-busy', 'true');
    status.textContent = 'Refreshing dashboard…';
    stats.forEach(stat => { stat.classList.add('cc-skeleton'); stat.setAttribute('aria-hidden', 'true'); });
    try {
      const response = await fetch(refresh.dataset.refreshStats, {
        headers: { Accept: 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
        credentials: 'same-origin', cache: 'no-store', signal: controller.signal,
      });
      if (!response.ok || !response.headers.get('content-type')?.includes('application/json')) throw new Error('Request failed');
      const data = await response.json();
      if (!stats.every(stat => Number.isFinite(data.stats?.[stat.dataset.stat]))) throw new Error('Invalid response');
      stats.forEach(stat => { stat.textContent = data.stats[stat.dataset.stat]; });
      status.textContent = 'Dashboard updated.';
    } catch (_) {
      status.textContent = 'Could not refresh. Your previous figures are still shown. Please try again.';
    } finally {
      clearTimeout(timeout);
      refresh.disabled = false;
      grid.removeAttribute('aria-busy');
      stats.forEach(stat => { stat.classList.remove('cc-skeleton'); stat.removeAttribute('aria-hidden'); });
    }
  });
})();
