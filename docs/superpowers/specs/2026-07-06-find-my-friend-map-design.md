# Find My Friend — Design Spec

Date: 2026-07-06

## Summary

A Flutter app (iOS + Android only) where any signed-up user shows up on
every other signed-up user's map in real time, with their name and avatar.
Auth via Firebase Auth (email/password), profile + live location stored in
Cloud Firestore, avatars in Firebase Storage, map rendered with
`yandex_mapkit`.

## Scope decisions

- **Visibility**: all authenticated users see all other authenticated
  users. No friend graph, no requests/approvals.
- **Auth**: email/password only.
- **Location updates**: foreground-only live tracking. No background
  location service.
- **State management**: `flutter_bloc`.
- **Platforms**: Android and iOS only.
- **Marker style**: circular avatar image + name label, natively rendered
  by the map SDK (not tap-to-reveal).
- **Profile setup**: one-time on first sign-up; editable afterwards via an
  "Edit profile" screen.

## Existing project state

- Fresh Flutter project (default counter-app template in `lib/main.dart`).
- `yandex_mapkit: ^4.2.1` already in `pubspec.yaml`. Yandex MapKit API key:
  `5de15677-efee-4a22-894e-4bb1836c9ed9`.
- A Firebase project already exists and is linked via `.firebaserc`
  (project id `chattingapp-5685c`), with `firebase.json` configuring
  Firestore only. `firestore.rules` is currently in default test mode
  (open read/write, expires 2026-07-12) — this will be replaced with real
  rules (below).
- No Flutter app is registered with that Firebase project yet: no
  `google-services.json`, `GoogleService-Info.plist`, or
  `lib/firebase_options.dart` exist. No Storage bucket/rules are
  configured in `firebase.json` yet.
- The `firebase` CLI is installed (`/c/firebase/firebase`) but its
  first-run "welcome" banner currently throws a JSON parse error; this
  needs to be confirmed as cosmetic (or fixed) before relying on
  `firebase`/`flutterfire` CLI commands during implementation.

## Architecture

- **Firebase Auth** — email/password sign-in/sign-up.
- **Cloud Firestore** — single source of truth per user: profile fields
  plus current location. One document per user, always fresh (no history
  collection).
- **Firebase Storage** — one avatar image per user.
- **yandex_mapkit** — renders all users' markers on a map.
- **flutter_bloc** — auth state, profile setup form state, and the map's
  live user-list state.
- **geolocator** + **permission_handler** — location permission flow and
  foreground position stream.
- **image_picker** — avatar selection from camera or gallery.

## Data model

Firestore collection `users`, document id = Firebase Auth `uid`:

```
users/{uid}
{
  name: string,
  avatarUrl: string,
  location: GeoPoint,
  updatedAt: Timestamp,   // server timestamp, refreshed on every location update
  createdAt: Timestamp    // server timestamp, set once
}
```

Storage path: `avatars/{uid}.jpg` (one file per user, overwritten on
profile edit).

A user's Firestore document is considered "profile complete" once `name`
and `avatarUrl` are both non-empty.

## Screens & flow

1. **AuthGate** (root widget, driven by `AuthBloc`)
   - Listens to `FirebaseAuth.authStateChanges()`.
   - Not signed in → `AuthScreen`.
   - Signed in → fetch `users/{uid}`; profile incomplete/missing →
     `ProfileSetupScreen`; profile complete → `MapScreen`.

2. **AuthScreen**
   - Toggle between sign-in and sign-up, email + password fields with
     inline validation.
   - `FirebaseAuthException` codes (`invalid-email`, `user-not-found`,
     `wrong-password`, `email-already-in-use`, `weak-password`, etc.)
     mapped to friendly messages shown in a snackbar.

3. **ProfileSetupScreen** (shown once on first sign-up; also reachable
   later as "Edit profile" from the map screen's app bar)
   - Name text field (required, non-empty).
   - Avatar picker: tapping an avatar circle opens a bottom sheet with
     "Camera" / "Gallery" (via `image_picker`).
   - "Continue" button, only enabled once name + avatar are set:
     1. Request location permission (`permission_handler`/`geolocator`);
        if denied, show a dialog explaining the map won't work without
        it, with a button to open app settings.
     2. Get a one-shot current position.
     3. Upload the avatar image to `avatars/{uid}.jpg`, read back the
        download URL.
     4. Write/merge the `users/{uid}` Firestore document (name,
        avatarUrl, location, timestamps).
     5. Navigate to `MapScreen`.
   - When reached as "Edit profile" (profile already complete), the same
     form pre-fills current values; skips the location-permission step
     unless permission was previously denied.

4. **MapScreen**
   - Renders a `YandexMap`.
   - On entering the screen, starts a `geolocator` position stream
     (foreground only, distance filter ~10 meters) and writes each new
     position to the signed-in user's `users/{uid}` document
     (`location` + `updatedAt`). Stream is cancelled when the screen is
     disposed.
   - Subscribes to a live snapshot of the whole `users` collection.
     For every document (including the signed-in user), builds/updates a
     `PlacemarkMapObject`:
     - `icon`: a circular-cropped avatar rendered to PNG bytes via
       `dart:ui` canvas operations, passed through
       `BitmapDescriptor.fromBytes`. Rendered bitmaps are cached per
       `avatarUrl` so unchanged avatars aren't re-rendered on every
       snapshot tick.
     - `text`: a `PlacemarkText` showing the user's name beneath the
       icon.
   - On the first successful position fix, moves the camera to center on
     the signed-in user; the user can freely pan/zoom afterward.
   - App bar actions: sign out, edit profile.

## Bloc structure

- `AuthBloc` — wraps `authStateChanges()`; emits
  `AuthInitial` / `Authenticated(uid)` / `Unauthenticated`. Also exposes
  sign-in/sign-up/sign-out methods that call `FirebaseAuth` directly and
  surface `FirebaseAuthException`s as failure states for the UI to
  render.
- `ProfileCubit` — drives `ProfileSetupScreen`: holds form field state,
  runs the permission → location → avatar-upload → Firestore-write
  sequence, emits `submitting` / `success` / `failure(message)`.
- `UsersMapCubit` — owns the `MapScreen`'s two subscriptions (own location
  stream, Firestore users snapshot), combines them into a single
  `List<MapUser>` (uid, name, avatarUrl, point) for the UI to turn into
  placemarks. Starts both subscriptions in an `init`/`start` method called
  from the screen's `initState`, cancels both in `close()`.

## Firebase / native setup (implementation-time checklist)

1. Confirm the `firebase` CLI's welcome-script error doesn't block actual
   commands; fix if it does.
2. Install `flutterfire_cli` and run `flutterfire configure` against the
   existing `chattingapp-5685c` project, selecting Android + iOS only.
   This generates `lib/firebase_options.dart`,
   `android/app/google-services.json`, and
   `ios/Runner/GoogleService-Info.plist`.
3. Enable Email/Password sign-in provider in the Firebase console (or via
   CLI if supported).
4. Enable Firebase Storage for the project (not yet configured in
   `firebase.json`) and add a `storage.rules` file, wired up in
   `firebase.json`.
5. Replace `firestore.rules` (currently open/test-mode) with:
   - any authenticated user may `read` any `users/{uid}` document.
   - a user may `write` only `users/{request.auth.uid}`, and only when
     the payload's `name` is a non-empty string and `location` is a
     `GeoPoint`.
6. `storage.rules`: any authenticated user may `read` any file under
   `avatars/`; a user may `write` only to `avatars/{request.auth.uid}.jpg`.
7. Deploy both rule sets (`firebase deploy --only firestore:rules,storage`).
8. Wire the Yandex MapKit API key (`5de15677-efee-4a22-894e-4bb1836c9ed9`)
   into Android (`AndroidManifest.xml` meta-data or
   `MapKitFactory.setApiKey` at startup) and iOS (`AppDelegate`), per
   `yandex_mapkit`'s setup docs.
9. Add Android/iOS location permission entries
   (`ACCESS_FINE_LOCATION`/`NSLocationWhenInUseUsageDescription`) and
   camera/photo-library usage descriptions for `image_picker`.

## Error handling

- Auth errors → snackbar with friendly text, form stays filled in.
- Location permission denied → explanatory dialog with "Open Settings"
  action; user can retry.
- Avatar upload failure → inline error, "Try again" button, does not
  block re-attempting; doesn't lose the entered name.
- Location-update write failures while on `MapScreen` → silently retried
  on the next stream tick; logged, not surfaced to the user (a single
  missed update isn't disruptive).
- Firestore snapshot-stream errors on `MapScreen` → non-blocking banner
  ("Reconnecting…") while the stream auto-recovers; existing markers stay
  visible using last-known data.

## Testing

- Bloc/cubit unit tests (`bloc_test` + `mocktail`, `fake_cloud_firestore`
  for Firestore interactions) covering:
  - `AuthBloc`: state transitions on sign-in/up/out and Firebase
    exceptions.
  - `ProfileCubit`: the permission → location → upload → write sequence,
    including each failure branch.
  - `UsersMapCubit`: combining a fake location stream with a fake
    Firestore snapshot stream into the expected marker list.
- Widget tests for form validation on `AuthScreen` and
  `ProfileSetupScreen` (e.g., empty name, invalid email format rejected
  before hitting Firebase).
- Out of scope: automated tests for the live map rendering, real GPS
  behavior, or real Firebase permission prompts — these require a real
  device and a real Firebase project, and will be exercised manually.

## Out of scope (explicitly not building)

- Friend requests / approval flow.
- Background location tracking.
- Push notifications (e.g., "friend arrived nearby").
- Location history / trails.
- Any web or desktop target.
