/* live.tips web push service worker — a config-only shim.
 *
 * The server sends NOTIFICATION messages (firebase/functions/src/
 * notifications.ts), so the Firebase SDK below does all the work in the
 * background: it displays the banner and opens/focuses the app at
 * webpush.fcmOptions.link on click. No custom handlers on purpose — logic
 * added here would run inside a service worker that GitHub Pages/Cloudflare
 * caching updates on the browser's own schedule, not on our deploys.
 *
 * The config is the PUBLIC web app config, inlined verbatim from
 * app/lib/firebase_options.dart (the FlutterFire plugin registers this file
 * relative to the document, so it ships through the normal web build to
 * https://live.tips/app/firebase-messaging-sw.js).
 */
importScripts("https://www.gstatic.com/firebasejs/12.4.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/12.4.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDVUnIyZuFhetEDRmAK_Cw9VBK_r3adExA",
  appId: "1:623278585949:web:c2da5d70dea2854ea4b5b4",
  messagingSenderId: "623278585949",
  projectId: "livetips-app",
  authDomain: "livetips-app.firebaseapp.com",
  storageBucket: "livetips-app.firebasestorage.app",
});

firebase.messaging();
