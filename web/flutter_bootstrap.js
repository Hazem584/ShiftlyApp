{{flutter_js}}
{{flutter_build_config}}

const arabic = navigator.language.toLowerCase().startsWith('ar');
if (arabic) {
  document.documentElement.lang = 'ar';
  document.getElementById('loading-message').textContent = 'بنجهّز مساحة العمل…';
  document.getElementById('retry').textContent = 'حاول مرة تانية';
}
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine({
        canvasKitBaseUrl: 'canvaskit/',
      });
      await appRunner.runApp();
      document.getElementById('loading')?.remove();
    } catch (error) {
      document.getElementById('loading-message').textContent = arabic
        ? 'تعذّر فتح التطبيق. راجع اتصال الإنترنت وحاول تاني.'
        : 'Could not open Shiftly. Check your connection and try again.';
      document.getElementById('retry').hidden = false;
    }
  }
});
