{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();

    // Hapus loading indicator saat engine siap
    const loader = document.getElementById('loading-indicator');
    if (loader) {
      loader.style.opacity = '0';
      loader.style.transition = 'opacity 0.25s ease-out';
      loader.style.pointerEvents = 'none';
      setTimeout(function() {
        if (loader && loader.parentNode) {
          loader.parentNode.removeChild(loader);
        }
      }, 250);
    }

    await appRunner.runApp();
  }
});
