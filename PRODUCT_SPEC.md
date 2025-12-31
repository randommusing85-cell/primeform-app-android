# PrimeForm / PhysIQ  
*A calm, intelligent fitness system for consistency over confusion*

---

## Overview

PrimeForm (working name: PhysIQ) is a fitness and nutrition app designed to reduce confusion, overwhelm, and decision fatigue—especially for beginners, restarters, and busy adults.

Rather than chasing perfect accuracy or extreme optimisation, PrimeForm prioritises:
- consistency
- clarity
- conservative, safe guidance
- long-term habit building

The app combines structured fitness principles with AI-assisted coaching, while deliberately avoiding cluttered dashboards, social feeds, and obsession-driven mechanics.

---

## Product Philosophy

**What PrimeForm believes**
- Consistency matters more than precision
- Habits come before optimisation
- Calm guidance beats aggressive motivation
- Trends matter more than day-to-day noise
- AI should interpret and guide—not judge or shame

**What PrimeForm is not**
- Not a calorie database race
- Not a social fitness platform
- Not a “30-day shredded” app
- Not an analytics overload tool

---

## Target Users

- Beginners who feel lost
- People restarting fitness in their 30s–40s
- Users overwhelmed by conflicting advice
- Users who “know what to do” but struggle with consistency
- Working adults who want guidance without obsession

---

## Monetisation & Control

- RevenueCat is used for subscriptions and entitlements
- Paywall modes are remotely configurable:
  - **OFF** – full access (beta/testing)
  - **SOFT** – limited premium usage
  - **HARD** – premium locked behind subscription
- Entitlements are checked:
  - client-side (UI/UX gating)
  - server-side (AI cost protection)
- Paywall can be toggled without rebuilding the app

---

# Feature Roadmap

---

## v0.1 — Foundation Build (Internal / Beta)

**Purpose:**  
Validate the core loop and architecture. No monetisation pressure.

### Core Architecture
- User profile:
  - age, sex, height, weight
  - training level
- Goal selection:
  - fat loss
  - recomposition
  - muscle gain
- Equipment selection:
  - gym
  - home
  - dumbbells
  - bodyweight
- Training days per week
- Entitlements system (RevenueCat-ready)

---

### Nutrition (v0.1)
- AI-generated daily calorie target
- AI-generated protein target
- Simple food logging:
  - generic foods
  - portion-based estimation
- End-of-day compliance check (yes/no + notes)
- No forced full macro tracking

---

### Workouts (v0.1)
- AI-generated workout plans:
  - exercises
  - sets
  - reps
- Workout session logging
- Session completion tracking
- Fixed, curated exercise list

---

### Check-ins & Trends (v0.1)
- Weekly check-in:
  - body weight
  - waist measurement
  - adherence %
- Simple AI trend interpretation:
  - “stay the course”
  - “don’t adjust yet”
- No aggressive auto-adjustments

---

### UI / UX (v0.1)
- Clean, minimal interface
- No cluttered dashboards
- Clear primary actions
- Calm, neutral tone

---

## v1.0 — Public Free Tier (Habit Builder)

**Purpose:**  
Help users stay consistent without overwhelm.

---

### Nutrition (Free Tier)
- Calories + protein as primary focus
- Carbs/fats hidden or deemphasised
- Simple food logging UX
- No daily calorie changes
- Weekly check-in feedback only

---

### Home Screen (Free Tier)
Exactly **three core elements**:
1. Calories/macros so far  
2. Calories/macros remaining  
3. Log food  

All analytics, trends, and insights:
- live in secondary tabs
- optional to view

---

### Workouts (Free Tier)
- Structured workout plans
- Workout logging
- Limited custom exercises
- Standard tracking mode:
  - weight + reps
- No advanced progression logic

---

### AI Coaching (Free Tier)
- Explains plans in plain language
- Encourages consistency
- Conservative guardrails
- No body critique
- No extreme recommendations

---

## Phase 2 — Paid Tier (Power & Precision)

**Purpose:**  
Unlock depth *after* habits are established.

---

### Advanced Nutrition (Paid)
- Full macro control (carbs / fats / protein)
- Training-day vs rest-day targets
- Weekly adaptive calorie algorithm (MacroFactor-style)
- Diet breaks and fatigue-aware logic
- Local food support (SG context):
  - hawker foods
  - local drinks
  - NTUC / local bentos
- Barcode scanning (Open Food Facts + extensions)

---

### Advanced Workouts (Paid)
- Unlimited custom exercises
- Per-exercise tracking modes:
  - weight + reps
  - weight + distance
  - reps + time
  - weight + time
  - distance + time
- Progressive overload tracking
- Historical bests
- Optional plateau detection

---

### Scheduling & Automation (Paid)
- Scheduled workouts
- Guided workout sessions
- Exercise sequencing:
  - circuits
  - supersets
- Reduced manual interaction during workouts

---

### Integrations (Paid)
- Apple Health / Apple Watch sync
- Garmin sync
- Strava / Runkeeper data import
- No double data entry
- Battery-efficient background behaviour

---

### UI / UX Enhancements (Paid)
- Polished, modern UI
- Subtle, pleasant animations
- Optional dashboard customisation
- Minimal by default

---

## Phase 3 — Identity & Motivation Layer (Premium Differentiator)

---

### Aspiration Archetypes
- Users select preferred celebrities or fictional characters
- AI suggests a realistic archetype range based on:
  - body frame
  - habits
  - timeline
- Framed as trajectory, not comparison
- “Closest path to X-style physique”

---

### Progress Photo Check-ins (Paid)
- Optional photo uploads
- Face & background blur by default
- Pose & lighting guidance
- AI feedback focuses on:
  - consistency
  - trend direction
  - encouragement
  - practical next steps
- No ratings
- No harsh critique
- Tone selectable:
  - Coach
  - Neutral
  - Encouraging

---

### Women-Specific Intelligence (Optional, Paid)
- Menstrual cycle awareness
- Cycle-based trend interpretation
- Training intensity suggestions
- Nutrition guidance by cycle phase
- Insight-only (no medical claims)

---

## Long-Term Vision

PrimeForm / PhysIQ aims to become:
> A trusted, calm fitness companion people rely on—like MyFitnessPal for logging, but personalised, humane, and intelligent.

The app is designed to grow with the user:
- simple when they need structure
- powerful when they’re ready for control
- always grounded in safety and realism
