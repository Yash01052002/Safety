# Phase 5 — Hardening & Launch Checklist

Code deliverables shipped in this phase are checked. Unchecked items are
process/testing/ops work to complete before General Availability.

## Security
- [x] Public tracking links expire automatically (24h SOS / session-scoped for
      shares; ~10 min after "safe"), enforced in `firestore.rules`.
- [x] Storage media scoped to the owning user (`storage.rules`).
- [x] Firestore rules scope user data to its owner; acks are guardian-create.
- [ ] End-to-end encryption of location/media (design: per-guardian keys or a
      shared session key; server stores ciphertext only). **Not yet built.**
- [ ] Replace capability-URL doc id with a random, unguessable share token
      (expiry is already enforced; a longer token further reduces guess risk).
- [ ] Tighten the `acks` read rule to actual recipients only.
- [ ] Third-party penetration test + fix findings.
- [ ] App Check (Play Integrity / DeviceCheck) to block abusive clients.
- [ ] Rate-limit SOS/SMS in the Cloud Function.

## Privacy & compliance
- [x] In-app data-controls screen + account/data deletion (`deleteUserData`
      callable + `onAuthUserDeleted` backstop).
- [x] Retention job (`purgeOldData`) deletes resolved events > 90 days and
      expired tracks nightly.
- [ ] Publish the privacy policy (see `PRIVACY_POLICY.md`) and link it.
- [ ] Complete Play Data-safety + App Store Privacy labels (see `COMPLIANCE.md`).
- [ ] Onboarding consent screen + consent logging.
- [ ] Data Processing Agreements with Firebase and the SMS provider.

## Reliability & quality
- [ ] Device matrix test: low-end Android (Go), flagship, older iPhones/SE.
- [ ] OEM battery-killer guidance (Xiaomi/Oppo/Samsung) + whitelist prompt.
- [ ] Background-survival test: screen-locked and app-backgrounded location +
      shake across the matrix; measure battery drain per hour of live share.
- [ ] Firebase-in-isolate writes for the fully-killed case (Phase 2 follow-up).
- [ ] Crashlytics wired; crash-free sessions > 99.5%.
- [ ] SOS trigger-to-delivery latency < 5s p95 (instrument + measure).

## Accessibility & localization
- [x] SOS button exposes a semantic label/hint + assistive-tech activation.
- [x] Localization scaffolding (`l10n.yaml`, `app_en.arb`, `app_hi.arb`,
      delegates wired). **Next:** generate `AppLocalizations`, migrate strings.
- [ ] Screen-reader pass (TalkBack/VoiceOver), large-text, one-handed layout,
      color-contrast audit.

## Store submission
- [ ] Locale-aware emergency numbers verified per launch market
      (`emergency_numbers.dart` — expand & fact-check the table).
- [ ] Bundle `assets/siren.mp3` and declare it.
- [ ] Google Maps API keys (Android + iOS) restricted to the app.
- [ ] Store listings, screenshots, demo video (see `STORE_LISTING.md`).
- [ ] TestFlight + Play Internal → Closed beta → Staged rollout → GA.
- [ ] On-call rotation for safety-critical incidents at launch.
