(function () {
  'use strict';

  // ---- Theme -------------------------------------------------------------
  var root = document.documentElement;
  var STORAGE_KEY = 'showdown-theme';

  function systemTheme() {
    return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(theme) {
    if (theme === 'dark') {
      root.setAttribute('data-theme', 'dark');
    } else {
      root.removeAttribute('data-theme');
    }
  }

  var stored = null;
  try { stored = localStorage.getItem(STORAGE_KEY); } catch (e) { /* private mode */ }
  applyTheme(stored || systemTheme());

  if (window.matchMedia) {
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', function () {
      var s = null;
      try { s = localStorage.getItem(STORAGE_KEY); } catch (e) { /* ignore */ }
      if (!s) applyTheme(systemTheme());
    });
  }

  var toggle = document.getElementById('theme-toggle');
  if (toggle) {
    toggle.addEventListener('click', function () {
      var next = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
      applyTheme(next);
      try { localStorage.setItem(STORAGE_KEY, next); } catch (e) { /* ignore */ }
    });
  }

  // ---- Tabs --------------------------------------------------------------
  document.querySelectorAll('[data-tabs]').forEach(function (tabs) {
    var buttons = Array.prototype.slice.call(tabs.querySelectorAll('[role="tab"]'));
    var panels = Array.prototype.slice.call(tabs.querySelectorAll('[role="tabpanel"]'));

    function select(index) {
      buttons.forEach(function (b, i) {
        var on = i === index;
        b.setAttribute('aria-selected', on ? 'true' : 'false');
        b.tabIndex = on ? 0 : -1;
      });
      panels.forEach(function (p, i) { p.hidden = i !== index; });
    }

    buttons.forEach(function (b, i) {
      b.addEventListener('click', function () { select(i); });
      b.addEventListener('keydown', function (ev) {
        var next = null;
        if (ev.key === 'ArrowRight') next = (i + 1) % buttons.length;
        if (ev.key === 'ArrowLeft') next = (i - 1 + buttons.length) % buttons.length;
        if (ev.key === 'Home') next = 0;
        if (ev.key === 'End') next = buttons.length - 1;
        if (next !== null) {
          ev.preventDefault();
          select(next);
          buttons[next].focus();
        }
      });
    });
  });

  // ---- Copy buttons ------------------------------------------------------
  document.querySelectorAll('[data-copy]').forEach(function (block) {
    var btn = block.querySelector('.copy');
    var code = block.querySelector('code');
    if (!btn || !code) return;

    btn.addEventListener('click', function () {
      var text = code.textContent;
      var done = function () {
        btn.textContent = 'Copied';
        btn.classList.add('copied');
        setTimeout(function () {
          btn.textContent = 'Copy';
          btn.classList.remove('copied');
        }, 1600);
      };

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, function () { fallback(text, done); });
      } else {
        fallback(text, done);
      }
    });
  });

  function fallback(text, done) {
    var ta = document.createElement('textarea');
    ta.value = text;
    ta.setAttribute('readonly', '');
    ta.style.position = 'fixed';
    ta.style.opacity = '0';
    document.body.appendChild(ta);
    ta.select();
    try { document.execCommand('copy'); done(); } catch (e) { /* ignore */ }
    document.body.removeChild(ta);
  }
})();
