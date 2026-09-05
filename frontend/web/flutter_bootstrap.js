// Custom Flutter loader (the build substitutes the two placeholders). It keeps
// the loading screen from index.html on screen until the app is running and
// shows an error line when the engine cannot be loaded.
{{flutter_js}}
{{flutter_build_config}}

(function () {
  function done() {
    var el = document.getElementById("loading");
    if (el) el.remove();
  }
  function failed() {
    var err = document.getElementById("loading-error");
    if (err) err.style.display = "block";
    var bar = document.querySelector("#loading .bar");
    if (bar) bar.style.display = "none";
  }
  try {
    _flutter.loader.load({
      onEntrypointLoaded: async function (engineInitializer) {
        try {
          var appRunner = await engineInitializer.initializeEngine();
          await appRunner.runApp();
          // The first frame follows right after runApp; a short delay avoids a
          // flash of the empty page.
          setTimeout(done, 150);
        } catch (e) {
          failed();
          throw e;
        }
      },
    });
  } catch (e) {
    failed();
    throw e;
  }
})();
