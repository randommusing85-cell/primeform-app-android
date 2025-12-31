# PrimeForm — Technical Specification

This document describes the technical stack, architecture decisions, and build instructions for PrimeForm.

---

## Tech Stack

- Flutter (stable channel)
- Dart
- Android (primary platform)
- Firebase
  - Firebase Functions (AI calls, entitlement checks)
  - Firebase Remote Config (paywall modes, feature flags)
- Isar (offline-first local database)
- RevenueCat (subscriptions & entitlements)

---

## Architecture Overview

### Client (Flutter)
- Offline-first design using Isar
- Riverpod for state management
- Clear separation of:
  - free features
  - premium-gated features
- Minimal, uncluttered UI by default

### Backend (Firebase)
- Callable Cloud Functions for:
  - AI plan generation
  - AI coaching responses
  - premium feature enforcement
- Server-side entitlement verification to protect AI costs
- Remote Config used for:
  - paywall mode (OFF / SOFT / HARD)
  - beta feature toggles

---

## Entitlements & Monetisation

- RevenueCat is the single source of truth for:
  - subscription status
  - entitlement validity
- Entitlements are checked:
  - client-side (UX gating)
  - server-side (API access control)

---

## Local Data (Isar)

Current / planned collections include:
- UserProfile
- PrimePlan (training + nutrition targets)
- CheckIn (weight, waist, adherence)
- WorkoutTemplate
- WorkoutSession
- FoodLog (simplified in early versions)

Schema is designed to:
- support progressive feature unlocks
- avoid migrations where possible
- remain offline-safe

---

## Getting Started

### Install dependencies
```bash
flutter pub get
