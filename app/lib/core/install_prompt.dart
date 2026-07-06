// Should we nudge the visitor to add live.tips to their Home Screen? Only a
// phone or tablet *browser* has anything to gain (a chrome-free, full-screen
// launch), so the web build sniffs the platform while the non-web stub — native
// apps already run full-window — always says no.
export 'install_prompt_stub.dart'
    if (dart.library.js_interop) 'install_prompt_web.dart';
