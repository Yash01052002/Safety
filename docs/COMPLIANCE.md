# Compliance & Store Data-Safety Mapping

Reference for filling out the **Play Console Data safety** form and the **App
Store Privacy "Nutrition Label"**, plus regulatory notes. Keep in sync with the
actual code and the privacy policy.

## Data collected & purpose

| Data type | Collected | Shared with | Purpose | Optional? |
|-----------|-----------|-------------|---------|-----------|
| Name | Yes | Guardians | Identify user in alerts | No |
| Phone number | Yes | Guardians (as contact) | Identity / auth | No |
| Contacts (guardians) | Yes | — | Deliver alerts | No |
| Precise location | Yes, **only during SOS / live share** | Chosen guardians | Core safety feature | Feature-gated |
| Audio / photo | Only if user captures | Chosen guardians | Evidence | Yes |
| Push token | Yes | — | Notifications | No |
| Crash / diagnostics | Yes | Google (processor) | Reliability | Can opt out |

## Play Console — background location declaration
Background location **is** used, but only during an active SOS or live-share
session via a foreground service (`FOREGROUND_SERVICE_LOCATION`). Prepare:
- A short screen-recording demo of the SOS → live-share flow.
- Written justification: "Location is shared with user-selected emergency
  contacts only while the user has an active alert or live-share session."
- In-app runtime disclosure before requesting `ACCESS_BACKGROUND_LOCATION`.

## App Store — review notes
- Provide a **demo account** (test phone + OTP bypass or a reviewer number).
- Explain the background `location` mode and the `suraksha://sos` Shortcut.
- If using the **Critical Alerts** entitlement for SOS, include the approval
  request and justification.

## Regulatory checklist
- [ ] GDPR (EU): lawful basis (consent + vital interests), DPA with processors,
      data-subject request path, EU data residency if required.
- [ ] India DPDP Act: consent notice, grievance officer, data-deletion path.
- [ ] CCPA/CPRA (California): "Do not sell" (N/A — we don't), deletion rights.
- [ ] Consent captured at onboarding and logged.
- [ ] Privacy policy URL live and linked in both stores + in-app.

## Anti-abuse / anti-stalking
- Live sharing is **self-initiated** — a user shares *their own* location; the
  app never lets someone silently track another person.
- Rate-limit SOS creation and SMS fan-out (Cloud Function) to prevent spam.
- Provide a block/report path and a way to see and revoke active shares.
