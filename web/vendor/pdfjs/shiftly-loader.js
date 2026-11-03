// PDF.js 4.6.82 is distributed locally under its Apache-2.0 license.
// Only renderer code/fonts are loaded here; document bytes stay in the browser.
globalThis.shiftlyPdfReady = import('./build/pdf.mjs').then((pdfjsLib) => {
  globalThis.pdfjsLib = pdfjsLib;
  pdfjsLib.GlobalWorkerOptions.workerSrc = new URL('./build/pdf.worker.mjs', import.meta.url).href;
  globalThis.pdfRenderOptions = {
    cMapUrl: new URL('./cmaps/', import.meta.url).href,
    cMapPacked: true,
    standardFontDataUrl: new URL('./standard_fonts/', import.meta.url).href,
    isEvalSupported: false,
  };
});
globalThis.shiftlyPdfReady.catch(() => {});
