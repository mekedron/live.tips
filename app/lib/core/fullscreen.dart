// Cross-platform fullscreen toggle. Only the web build actually does anything
// — native platforms already run the stage immersive/full-window, so the stub
// reports it unsupported and the button hides itself.
export 'fullscreen_stub.dart'
    if (dart.library.js_interop) 'fullscreen_web.dart';
