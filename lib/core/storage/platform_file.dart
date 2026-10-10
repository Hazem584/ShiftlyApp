// Native callers retain dart:io types; browsers use private IndexedDB media.
export 'native_platform_file.dart'
    if (dart.library.js_interop) 'browser_platform_file.dart';
