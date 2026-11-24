(function () {
  'use strict';

  var root = document.documentElement;
  var themeToggle = document.getElementById('theme-toggle');
  var systemTheme = window.matchMedia('(prefers-color-scheme: dark)');
  var storageKey = 'showdown-theme';
  var savedTheme;

  try {
    savedTheme = localStorage.getItem(storageKey);
  } catch (error) {
    // The toggle still works for this visit when storage is unavailable.
  }

  function syncTheme() {
    var theme = savedTheme || (systemTheme.matches ? 'dark' : 'light');
    root.dataset.theme = theme;
    themeToggle.setAttribute('aria-label', theme === 'dark' ? 'Switch to light theme' : 'Switch to dark theme');
  }

  syncTheme();
  themeToggle.hidden = false;
  systemTheme.addEventListener('change', syncTheme);
  themeToggle.addEventListener('click', function () {
    savedTheme = root.dataset.theme === 'dark' ? 'light' : 'dark';
    syncTheme();

    try {
      localStorage.setItem(storageKey, savedTheme);
    } catch (error) {
      // Keep the selected theme until the page closes.
    }
  });

  var motionPreference = window.matchMedia('(prefers-reduced-motion: reduce)');

  function playFeature(art) {
    if (motionPreference.matches) return;
    art.classList.remove('is-playing');
    // Resolve the resting state before restarting a preview on pointer entry.
    void art.offsetWidth;
    art.classList.add('is-playing');
  }

  if ('IntersectionObserver' in window) {
    var featureObserver = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.intersectionRatio < 0.6) return;
        playFeature(entry.target);
        featureObserver.unobserve(entry.target);
      });
    }, { threshold: 0.6 });

    document.querySelectorAll('.feature-art').forEach(function (art) {
      featureObserver.observe(art);
      art.closest('.feature').addEventListener('pointerenter', function (event) {
        if (event.pointerType === 'mouse') playFeature(art);
      });
    });
  }

  var copyButton = document.getElementById('copy-button');
  var installCode = document.getElementById('install-code');
  var copyFeedback;

  if (navigator.clipboard) {
    copyButton.hidden = false;
    copyButton.addEventListener('click', async function () {
      clearTimeout(copyFeedback);
      try {
        await navigator.clipboard.writeText(installCode.textContent);
        copyButton.textContent = 'Copied';
        copyButton.setAttribute('aria-label', 'Setup commands copied');
      } catch (error) {
        copyButton.textContent = 'Copy failed';
        copyButton.setAttribute('aria-label', 'Could not copy setup commands');
      }
      copyFeedback = setTimeout(function () {
        copyButton.textContent = 'Copy';
        copyButton.setAttribute('aria-label', 'Copy setup commands');
      }, 2200);
    });
  }
})();
