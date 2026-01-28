# Vigor — UX Specification

**Version**: 1.3
**Date**: January 27, 2026
**Status**: Production
**Design Philosophy**: Invisible Excellence
**Aligned with**: PRD-Vigor.md v5.0, Tech_Spec_Vigor.md v2.6

> _"Vigor is not an app. It is a system event that occasionally manifests as UI."_

---

## The Design Manifesto

> _"Design is not just what it looks like and feels like. Design is how it works."_
> — Steve Jobs

Vigor is not an app. Vigor is infrastructure for human performance.

The most profound design achievement is **invisibility**—when technology serves so seamlessly that the user forgets it exists. Every pixel, every interaction, every moment of silence in Vigor serves one purpose: to make fitness inevitable without demanding attention.

**The success metric of our design: How often users forget we exist, yet still get fitter.**

---

## Part I: Design Philosophy

### 1.1 The Invisibility Principle

The best interface is no interface.

Most fitness apps demand:

- Your attention (notifications)
- Your time (logging workouts)
- Your decisions (choosing exercises)
- Your willpower (motivation prompts)

Vigor demands nothing. It **gives** without asking.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     THE INVISIBILITY SPECTRUM                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  VISIBLE (Bad)              AMBIENT (Better)           INVISIBLE (Ideal)   │
│  ─────────────              ────────────────           ─────────────────   │
│  "Log your workout"    →    "Logged. Tap if wrong."  → Auto-logged         │
│  "How are you feeling" →    Calendar block appears   → Block transformed   │
│  "Choose exercises"    →    "Do this. Trust me."     → It's just there     │
│  Daily notifications   →    Weekly Value Receipt     → Silence             │
│                                                                             │
│  User Effort: High          User Effort: Minimal     User Effort: Zero     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 The Three Laws of Vigor Design

**Law I: Never ask what can be sensed.**
If the Watch knows sleep was 4 hours, the app never asks "How did you sleep?"
If the calendar shows back-to-back meetings, the Ghost stays silent about workouts.

**Law II: One decision, not ten.**
When Vigor speaks, the answer is Yes or No. Binary only.
Never "tap to learn more." Never a menu. Never a choice of five options.

**Law III: Magic in five minutes.**
The first insight arrives before the first workout.
Not "after 30 days of use." Not "once you've logged 10 sessions."
Day 1. Five minutes. Magic.

### 1.3 The Trust Equation

Invisibility is earned, not assumed.

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    │    TRUST  =  ACCURACY  ×  HUMILITY      │
                    │                                         │
                    │    • Right 95% of the time              │
                    │    • Acknowledge the 5% uncertainty     │
                    │    • Never defend a wrong prediction    │
                    │    • Always allow override              │
                    │                                         │
                    └─────────────────────────────────────────┘
```

The Ghost earns invisibility through demonstrated competence. Users grant permissions progressively as trust accrues.

### 1.4 Design Principles

| Principle     | Implementation                                                       |
| ------------- | -------------------------------------------------------------------- |
| **Reduction** | Every element must justify its existence. Remove until it breaks.    |
| **Clarity**   | One screen, one purpose. No cognitive load.                          |
| **Deference** | The interface recedes. Content dominates.                            |
| **Depth**     | Simple surface, powerful capability beneath.                         |
| **Silence**   | The app that doesn't speak earns the right to be heard when it does. |
| **Precision** | Numbers over adjectives. "5h 12m sleep" not "You slept okay."        |
| **Calm**      | No urgency. No anxiety. No guilt.                                    |

### 1.5 The Voice of the Ghost

The Vigor voice is: **High-end concierge meets cardiologist.**

| ❌ Never                                     | ✅ Always                            |
| -------------------------------------------- | ------------------------------------ |
| "Great job today! You crushed it! 💪"        | "45 min. 312 kcal. Logged."          |
| "Hey! Looks like you might need rest today!" | "Recovery day. Light movement only." |
| "Don't forget to hydrate! 💧"                | _(Silence)_                          |
| "You skipped yesterday—no worries!"          | "Block moved to tomorrow."           |

**Tone characteristics:**

- **Concise.** One sentence when one will do.
- **Precise.** Specific numbers, never vague encouragement.
- **Professional.** Not a friend. Not a buddy. Not a cheerleader.
- **Calm authority.** The Ghost knows. It doesn't need to prove it.

### 1.6 Designing for Absence

The PRD is radical. The Tech Spec is disciplined. The UX must be **brave enough to remove**.

Most UX specifications define screens, flows, and interactions. This one must define **what does not exist**.

**The Three Surfaces:**

Vigor has exactly three surfaces. Everything else is noise.

| Surface                        | Purpose                                       | Frequency        |
| ------------------------------ | --------------------------------------------- | ---------------- |
| **System-driven moment**       | Calendar mutation, notification, Watch tap    | Daily (ambient)  |
| **Confirmation micro-surface** | Yes / Undo / Snooze                           | Seconds per week |
| **Reflection view**            | Why the Ghost did what it did (Value Receipt) | Weekly           |

**Any UI element must answer: "What breaks if this does not exist?"**

If the answer is "clarity" or "comfort"—cut it.

**The Litmus Test:**

| If you're designing... | Ask yourself...                                             |
| ---------------------- | ----------------------------------------------------------- |
| An explanation         | Why can't the action speak for itself?                      |
| A confirmation dialog  | Why isn't one-tap undo sufficient?                          |
| A settings screen      | Why can't the system learn this?                            |
| An onboarding flow     | Why can't Day 1 magic teach instead?                        |
| A dashboard            | Why does the user need to monitor what should be automatic? |

**Radical success metric:**

> Most users should go **weeks** without opening the app.
> If they open it, something is wrong—either with the product or with their week.

The moment users think "I should open Vigor," we've already lost the war against friction.

---

## Part II: Device-Specific Design

### 2.1 Design Hierarchy

**The Calendar IS the Home Screen.**

Most fitness apps treat the app as the experience and calendar as an output. Vigor inverts this completely. The calendar is the primary interface. The app is a fallback.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        INTERFACE HIERARCHY                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                         ┌─────────────┐                                     │
│                         │  CALENDAR   │  ← THE Home Screen                  │
│                         │  (Ambient)  │    Blocks appear. User never        │
│                         └──────┬──────┘    "uses" this. It just IS.         │
│                                │                                            │
│                    ┌───────────┴───────────┐                                │
│                    │                       │                                │
│             ┌──────┴──────┐         ┌──────┴──────┐                         │
│             │ APPLE WATCH │         │   iPHONE    │                         │
│             │ (Executor)  │         │  (Fallback) │                         │
│             └──────┬──────┘         └──────┬──────┘                         │
│                    │                       │                                │
│    • Silent haptics         • Value Receipt (weekly)                        │
│    • One-tap confirmations  • Trust configuration (rarely)                  │
│    • Workout execution      • Phenome curiosity (optional)                  │
│    • The Ghost's whisper    • The Ghost's memory                            │
│                                                                             │
│  ───────────────────────────────────────────────────────────────────────── │
│                                                                             │
│  SUCCESS METRICS (Radical):                                                 │
│                                                                             │
│  • User opens iPhone app: < 3 times per MONTH (not week)                    │
│  • User goes WEEKS without thinking about Vigor                             │
│  • If user opens app, ask: "What failed?"                                   │
│  • Calendar is never "checked"—blocks just appear in life                  │
│                                                                             │
│  If the calendar experience is perfect, the app can be mediocre and win.   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### 2.2 Apple Watch — The Ghost's Executor

The Watch is not a companion device. It is a **co-processor**. It is the Ghost's whisper, the conscience tap, the last-mile executor.

Given the PRD's Apple Watch–required stance, the Watch must be elevated to first-class UX—not a lightweight mirror of the phone.

**Watch Exclusives — Moments Where ONLY the Watch Speaks:**

| Moment                   | Why Watch-Only                |
| ------------------------ | ----------------------------- |
| Pre-workout confirmation | Intimate. On body. One tap.   |
| Workout execution        | Phone should be put away.     |
| Post-workout feel check  | Immediate. Contextual.        |
| Recovery warning         | Whisper, not announcement.    |
| Mid-day movement prompt  | Gentle tap, not notification. |

**The Rule:** If it can be a haptic instead of a notification, use haptic. If it can be a complication instead of an app screen, use complication. If it can be Watch instead of phone, use Watch.

#### 2.2.1 Design Philosophy: Whisper, Not Announce

The Watch face is real estate too precious for complexity. Information must be absorbed in under 2 seconds.

**Information density:** Low
**Interaction frequency:** Rare
**Purpose:** Confirmation, not exploration

#### 2.2.2 Complications — Living, Not Static

Complications are Vigor's most visible surface. But static complications are pedestrian. Every fitness app has a ring.

**Vigor complications transform throughout the day.** The same complication slot shows contextually relevant information based on time, state, and user patterns.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                   CONTEXT-AWARE COMPLICATIONS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  MORNING (Wake → 10 AM)                                                     │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│        ┌─────────────────────┐                                              │
│        │    ╭───────────╮    │                                              │
│        │   ╱   ╭─────╮   ╲   │    Recovery Score                            │
│        │  │   │ 78  │   │   │    • The first thing you need to know        │
│        │   ╲   ╰─────╯   ╱   │    • Color indicates state                   │
│        │    ╰───────────╯    │    • Drives your entire day                  │
│        └─────────────────────┘                                              │
│                                                                             │
│  WORKDAY (10 AM → 5 PM)                                                     │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│        ┌─────────────────────┐                                              │
│        │                     │    Next Block Countdown                      │
│        │        💪           │    • Shows workout type icon                 │
│        │       2h 30m        │    • Time until scheduled block              │
│        │                     │    • Transforms to "Now" at block time       │
│        └─────────────────────┘                                              │
│                                                                             │
│        If stress detected (elevated HR during meetings):                    │
│        ┌─────────────────────┐                                              │
│        │                     │    Movement Prompt                           │
│        │        🚶           │    • Gentle reminder to move                 │
│        │     10 min walk     │    • Based on real-time HRV                  │
│        │                     │    • Not a workout—just movement             │
│        └─────────────────────┘                                              │
│                                                                             │
│  EVENING (5 PM → Sleep)                                                     │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│        ┌─────────────────────┐                                              │
│        │                     │    Ghost Status                              │
│        │        👻           │    • Schedule protected for tomorrow         │
│        │        ✓            │    • Everything handled                      │
│        │                     │    • Visual confirmation of autonomy         │
│        └─────────────────────┘                                              │
│                                                                             │
│  POST-WORKOUT (1 hour after)                                                │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│        ┌─────────────────────┐                                              │
│        │                     │    Streak + Completion                       │
│        │       🔥 7          │    • Celebrates consistency                  │
│        │        ✓            │    • Brief, not attention-seeking            │
│        │                     │    • Fades back to default after 1 hour      │
│        └─────────────────────┘                                              │
│                                                                             │
│  UNIVERSAL FALLBACK                                                         │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│        ┌─────────────────────┐                                              │
│        │                     │    Streak Only                               │
│        │       🔥 7          │    • When nothing else is relevant           │
│        │                     │    • Simple. Motivational. Non-intrusive.    │
│        │                     │                                              │
│        └─────────────────────┘                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Implementation Note:** Complication transitions are imperceptible—they update during natural wrist-down moments. The user never sees the change happen; they only see the right information at the right time.

**Staleness Honesty on the Wrist:**

The Tech Spec describes hybrid orchestration where Watch data may be stale if iPhone sync fails. If we show yesterday's Recovery Score and it looks identical to a fresh score, **we have broken trust.**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     COMPLICATION STALENESS STATES                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  FRESH (< 2 hours)           STALE (2-6 hours)        VERY STALE (> 6 hr)  │
│  ─────────────────            ──────────────────       ──────────────────   │
│                                                                             │
│        ┌───────┐                  ┌───────┐                ┌───────┐       │
│        │       │                  │       │                │       │       │
│        │  78   │                  │  ~78  │                │   ?   │       │
│        │       │                  │       │                │       │       │
│        └───────┘                  └───────┘                └───────┘       │
│      Full color               70% saturation            50% saturation     │
│      Full ring                Dimmed ring               Dashed ring        │
│                               "~" prefix                 "?" glyph         │
│                                                                             │
│  The interface admits when it doesn't know.                                 │
│  Honesty > Consistency.                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

| Data Age  | Ring Color      | Number Display | Meaning            |
| --------- | --------------- | -------------- | ------------------ |
| < 2 hours | Full saturation | `78`           | Fresh, trustworthy |
| 2-6 hours | 70% saturation  | `~78`          | Recent, estimated  |
| > 6 hours | 50% saturation  | `?`            | Stale, needs sync  |

#### 2.2.3 Watch App Screens

The Watch app has exactly **three screens**. No more.

**Screen 1: Today (Default)**

```
┌─────────────────────────────┐
│                             │
│         TODAY               │
│                             │
│    ┌───────────────────┐    │
│    │                   │    │
│    │   Recovery: 78%   │    │    Recovery score
│    │   ▓▓▓▓▓▓▓▓░░      │    │    with visual bar
│    │                   │    │
│    └───────────────────┘    │
│                             │
│    Next: 6:00 PM            │    Next scheduled block
│    Upper Body • 30 min      │    Type and duration
│                             │
│    ┌─────────────────┐      │
│    │   Start Now     │      │    One button
│    └─────────────────┘      │
│                             │
│    🔥 7 day streak          │    Streak at bottom
│                             │
└─────────────────────────────┘
```

**Screen 2: Active Workout**

```
┌─────────────────────────────┐
│                             │
│    UPPER BODY               │
│    ━━━━━━━━━━━━━━           │    Progress bar
│                             │
│    ┌───────────────────┐    │
│    │                   │    │
│    │   Push-ups        │    │    Current exercise
│    │   3 × 12          │    │    Sets × Reps
│    │                   │    │
│    │      ♡ 134        │    │    Heart rate
│    │                   │    │
│    └───────────────────┘    │
│                             │
│    REST: 0:45               │    Rest timer
│    ━━━━━━━▓▓▓▓▓▓▓           │    (when active)
│                             │
│    ┌─────┐     ┌─────┐      │
│    │ ← │     │ → │      │    Prev / Next
│    └─────┘     └─────┘      │
│                             │
└─────────────────────────────┘
```

**Screen 3: Post-Workout Summary**

```
┌─────────────────────────────┐
│                             │
│         COMPLETE ✓          │
│                             │
│    32 min                   │
│    267 kcal                 │
│    Avg HR: 142              │
│                             │
│    ┌─────────────────────┐  │
│    │                     │  │
│    │  How did it feel?   │  │
│    │                     │  │
│    │ ┌───┐ ┌───┐ ┌───┐  │  │
│    │ │ 😓│ │ 😊│ │ 💪│  │  │    One-tap feedback
│    │ │   │ │   │ │   │  │  │    Too hard / Good / Easy
│    │ └───┘ └───┘ └───┘  │  │
│    │                     │  │
│    └─────────────────────┘  │
│                             │
│    ┌─────────────────┐      │
│    │      Done       │      │
│    └─────────────────┘      │
│                             │
└─────────────────────────────┘
```

#### 2.2.4 Watch Notifications

**Critical Rule: Maximum 1 notification per day on Watch.**

Notifications on the wrist are the most intimate interruption possible. Use with extreme restraint.

**Allowed Notifications:**

| Trigger                 | Notification                 | Action       |
| ----------------------- | ---------------------------- | ------------ |
| Workout block in 15 min | "Training in 15 min. Ready?" | [Yes] [Skip] |
| Workout detected        | "32 min workout. Log?"       | [Yes] [Undo] |
| Recovery crashed        | "HRV low. Rest today."       | [OK]         |

**Forbidden Notifications:**

- Motivational messages
- Streak reminders
- Feature announcements
- Any question beyond Yes/No

#### 2.2.5 Watch Typography & Color

```
Typography:
├── SF Compact Rounded
├── Sizes: 16pt (primary), 13pt (secondary), 11pt (tertiary)
└── Weight: Medium (numbers), Regular (labels)

Colors:
├── Recovery Green:  #34C759 (80-100%)
├── Caution Yellow:  #FFCC00 (50-79%)
├── Warning Orange:  #FF9500 (30-49%)
├── Alert Red:       #FF3B30 (<30%)
├── Ghost White:     #F5F5F7
├── Ghost Gray:      #8E8E93
└── Background:      System (adapts to watch face)
```

---

### 2.3 iPhone — The Ghost's Mind

The iPhone app is where the Ghost **thinks**, but users should rarely need to see it.

#### 2.3.1 Design Philosophy: Depth on Demand

The iPhone app exists for three purposes:

1. **Initial setup** (once)
2. **Trust configuration** (rarely)
3. **Phenome exploration** (curiosity)

It should feel **empty** most of the time. When you open it, there's one thing to do—or nothing at all.

#### 2.3.2 Navigation Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        iPHONE NAVIGATION                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                           GHOST VIEW                                │   │
│  │                        (Primary Screen)                             │   │
│  │                                                                     │   │
│  │   • Today's status                                                  │   │
│  │   • Next action (if any)                                            │   │
│  │   • Empty when nothing to do                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│         │                    │                     │                        │
│         ▼                    ▼                     ▼                        │
│   ┌───────────┐       ┌───────────┐        ┌───────────┐                   │
│   │  PHENOME  │       │  HISTORY  │        │ SETTINGS  │                   │
│   │           │       │           │        │           │                   │
│   │ Patterns  │       │ Workouts  │        │ Trust     │                   │
│   │ Insights  │       │ Timeline  │        │ Profile   │                   │
│   │ Metrics   │       │ Stats     │        │ Privacy   │                   │
│   └───────────┘       └───────────┘        └───────────┘                   │
│                                                                             │
│  Tab bar: 3 items maximum. Hidden most of the time.                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### 2.3.3 Ghost View (Primary Screen)

The Ghost View is the heart of the iPhone experience. It embodies the principle: **"Show me only what I need to know right now."**

**State 1: Nothing Scheduled — Active Silence**

When you open the Ghost View, it tells you what you need to know. Nothing more. Nothing less.

No animation. No pulsing. No "breathing." Static perfection is more confident than motion.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                       ⚙     │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                              ●                                              │
│                                                                             │
│                   Everything is handled.                                    │
│                                                                             │
│                   ─────────────────────                                     │
│                                                                             │
│                   Recovery: 82%                                             │
│                   Last workout: Yesterday                                   │
│                   Next scheduled: Tomorrow, 6 PM                            │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│   ──────────────────────────────────────────────────────────────────────   │
│                     👻              📊              ⚙️                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Design Rationale:**

- **No animation.** Animation implies real-time connection. HealthKit data may be 30 minutes old due to background fetch latency. A pulse synced to heart rate would be a _lie_ if the data is stale. We do not design lies.
- **Static confidence.** The Ghost is infrastructure, not a pet. It does not need to prove it's alive.
- **Instant clarity.** When you open this screen—which should be rare—you get information, not a screensaver.

**Staleness Honesty:**

If Phenome data is > 2 hours old (background sync failed), the interface admits it:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                       ⚙     │
│                                                                             │
│                              ●                                              │
│                           (dimmed)                                          │
│                                                                             │
│                   Last sync: 4 hours ago                                    │
│                                                                             │
│                   ─────────────────────                                     │
│                                                                             │
│                   Recovery: ~78%                                            │
│                   (estimated from last night)                               │
│                                                                             │
│                   Next scheduled: Tomorrow, 6 PM                            │
│                                                                             │
│   ──────────────────────────────────────────────────────────────────────   │
│                     👻              📊              ⚙️                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Visual Staleness Indicators:**

| Data Age      | Visual Treatment        | Label Modification        |
| ------------- | ----------------------- | ------------------------- |
| < 30 min      | Full saturation         | Normal                    |
| 30 min - 2 hr | 90% opacity             | Normal                    |
| 2 - 6 hr      | 70% opacity, dimmed     | "~" prefix, "(estimated)" |
| > 6 hr        | 50% opacity, amber tint | "Last sync: X hours ago"  |

**The principle:** Honesty > Consistency. A dimmed number says "working on old data" without words. Never present stale data as fresh truth.

**State 2: Workout Available**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                       ⚙     │
│                                                                             │
│                                                                             │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                                                                     │  │
│   │                     UPPER BODY STRENGTH                             │  │
│   │                                                                     │  │
│   │                         30 minutes                                  │  │
│   │                      ──────────────                                 │  │
│   │                                                                     │  │
│   │                   Dumbbell Press • Rows                             │  │
│   │                   Push-ups • Curls                                  │  │
│   │                                                                     │  │
│   │                                                                     │  │
│   │   ┌───────────────────────────────────────────────────────────┐    │  │
│   │   │                        START                               │    │  │
│   │   └───────────────────────────────────────────────────────────┘    │  │
│   │                                                                     │  │
│   │                  or speak: "20 min, bodyweight only"                │  │
│   │                                                                     │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│                                                                             │
│   ──────────────────────────────────────────────────────────────────────   │
│                     👻              📊              ⚙️                       │
└─────────────────────────────────────────────────────────────────────────────┘

One card. One action. No decisions.
The workout was chosen based on:
• What you worked last
• Your recovery score
• Your schedule
```

**State 3: Recovery Required**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                       ⚙     │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                           🛌                                                │
│                                                                             │
│                                                                             │
│                       Recovery Day                                          │
│                                                                             │
│              Your HRV is 34% below baseline.                                │
│              Sleep was 4h 20m.                                              │
│                                                                             │
│              Heavy training today risks injury.                             │
│              Tomorrow's block adjusted automatically.                       │
│                                                                             │
│                                                                             │
│           ┌──────────────────────────────────────┐                         │
│           │      I'll train anyway →             │                         │
│           └──────────────────────────────────────┘                         │
│                                                                             │
│                                                                             │
│   ──────────────────────────────────────────────────────────────────────   │
│                     👻              📊              ⚙️                       │
└─────────────────────────────────────────────────────────────────────────────┘

The override option is present but muted.
The Ghost respects agency but protects ego.
No guilt if they train anyway—just quiet adaptation.
```

#### 2.3.4 The Phenome Dashboard

Patterns, not statistics. The Phenome Dashboard reveals what the Ghost has learned about the user.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ←                        PHENOME                                     ⚙     │
│                                                                             │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                                                             │
│   YOUR PATTERNS                                                             │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │  🟢 Sleep Impact                                        HIGH CONF.  │  │
│   │                                                                     │  │
│   │  You're 23% weaker after less than 6 hours of sleep.                │  │
│   │                                                                     │  │
│   │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░  Based on 47 workouts                       │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │  🟢 Best Time                                           HIGH CONF.  │  │
│   │                                                                     │  │
│   │  Morning workouts outperform evening by 18%.                        │  │
│   │                                                                     │  │
│   │  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░  Based on 52 workouts                       │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │  🟡 Recovery Needs                                    EMERGING      │  │
│   │                                                                     │  │
│   │  You need 72 hours between leg-heavy sessions.                      │  │
│   │                                                                     │  │
│   │  ▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░  Based on 18 workouts                       │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │  🟡 Skip Risk                                         EMERGING      │  │
│   │                                                                     │  │
│   │  High when: meetings > 5 AND sleep < 6h (73% skip rate)             │  │
│   │                                                                     │  │
│   │  ▓▓▓▓▓▓▓░░░░░░░░░░░░░░  Based on 22 data points                    │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   ⚪ More patterns will emerge with continued use.                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Confidence Indicators:**

- 🟢 **High confidence** — 40+ data points, consistent signal
- 🟡 **Emerging pattern** — 15-40 data points, signal stabilizing
- ⚪ **Observing** — Not enough data yet

#### 2.3.5 The Value Receipt (Sunday Truth)

The Value Receipt is the Ghost's weekly proof of value. It solves the invisibility paradox: users forget the value of something they never see working.

**Presentation:**

- Arrives Sunday evening as a subtle card in the app
- Optional notification: "Your week with Vigor" (no action required)
- Beautiful enough to frame. This is art, not a report.
- Disappears after viewing (ephemeral, not cluttering)

**Speed Is Luxury:**

No entrance animation. No staggered reveal. No 800ms of stolen time.

When you tap the notification, the receipt is _there_. Instant. It existed before you looked. The delight comes from the **typography** and the **data**, not the motion.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     VALUE RECEIPT PRESENTATION                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ANIMATION: None.                                                           │
│                                                                             │
│  The receipt appears instantly, fully rendered.                             │
│  Like high-quality stationery: it doesn't slide in—it exists.               │
│                                                                             │
│  The luxury is in the typesetting:                                          │
│  • SF Pro Display for headers                                               │
│  • Generous whitespace (48px between sections)                              │
│  • Perfect alignment to 4px grid                                            │
│  • Numbers in tabular figures for clean columns                             │
│                                                                             │
│  VISUAL TREATMENT OF AVOIDED RISKS:                                         │
│  • Risk items appear with strikethrough already applied                     │
│  • Muted color (not red—that implies active danger)                         │
│  • Visual message: these were *handled*                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Rationale:** You are building a tool for people who do not have time for tools. Respect their time by being instant.

**Clean Mode — For Sharing:**

The PRD demands the Value Receipt become a marketing engine. Users must be able to share their wins without exposing biometrics.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                    SHARE: CLEAN MODE                                        │
│                                                                             │
│                    ─────────────────                                        │
│                                                                             │
│                                                                             │
│              This week, Vigor made 3 decisions for me.                      │
│                                                                             │
│              • Rescheduled a workout when my afternoon filled               │
│              • Transformed Heavy Legs → Recovery Walk                       │
│              • Removed a block when I needed rest                           │
│                                                                             │
│                                                                             │
│              I didn't have to think about it.                               │
│              It just happened.                                              │
│                                                                             │
│                                                                             │
│                           VIGOR                                             │
│                    Fitness. Inevitable.                                     │
│                                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Clean Mode removes:**

- All biometric numbers (HR, HRV, kcal)
- Specific times and dates
- Workout counts

**Clean Mode keeps:**

- "Decisions Made" text (the magic)
- Number of decisions ("3 decisions")
- Vigor branding

**Typography for Share Image:**

- Background: Vigor Blue (#0A84FF) or Ghost White
- Text: 24pt SF Pro, centered
- Generous whitespace
- Rendered at 2x for Instagram/Twitter clarity

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                                                                             │
│                     YOUR WEEK WITH VIGOR                                    │
│                     January 20-26, 2026                                     │
│                                                                             │
│                           ─────────                                         │
│                                                                             │
│                                                                             │
│    COMPLETED                                                                │
│                                                                             │
│        ●  ●  ○  ●  ○  ●  ○                                                 │
│       Mon Tue Wed Thu Fri Sat Sun                                           │
│                                                                             │
│        4 workouts · 2h 14m total · 892 kcal burned                         │
│                                                                             │
│                                                                             │
│    DECISIONS MADE FOR YOU                                                   │
│                                                                             │
│    ┌────────────────────────────────────────────────────────────────────┐  │
│    │  Tue  Rescheduled HIIT to 7 AM when afternoon filled up.           │  │
│    │  Thu  Transformed Heavy Legs → Recovery Walk (HRV 34% low)         │  │
│    │  Fri  Removed scheduled block (4h sleep detected)                  │  │
│    └────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│                                                                             │
│    RISK SIGNALS DETECTED                                                    │
│                                                                             │
│    ┌────────────────────────────────────────────────────────────────────┐  │
│    │  Thu  Elevated injury risk (HRV 34% below baseline)                │  │
│    │  Fri  High skip probability (87% based on patterns)                │  │
│    └────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│                                                                             │
│    YOUR PHENOME THIS WEEK                                                   │
│                                                                             │
│        Resting HR       ↓ 2 bpm                                            │
│        Recovery trend   Improving                                           │
│        Best sessions    Morning (+22% vs evening)                           │
│                                                                             │
│                                                                             │
│             ┌───────────────────────────────────────┐                      │
│             │              Share                     │                      │
│             └───────────────────────────────────────┘                      │
│                                                                             │
│                     The Ghost earned its keep.                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Language Discipline:**

| Never Say                | Always Say                         |
| ------------------------ | ---------------------------------- |
| "Prevented an injury"    | "Elevated injury risk detected"    |
| "You would have skipped" | "High skip probability (X%)"       |
| "Saved you from burnout" | "Strain accumulation was elevated" |
| "We fixed your workout"  | "Adjusted based on recovery data"  |

Probabilistic language protects legally and builds trust. Counterfactuals feel like guesses. Data feels like truth.

#### 2.3.6 Trust State Visualization — Resolution, Not Volume

Trust is not a volume knob. Trust is a _state of being_. It is organic growth.

A linear slider feels mechanical and cold. Users are granting autonomy to an AI agent—this is profound. The visualization must communicate the _depth_ of the bond, not just a position on a track.

**The Resolution Metaphor:**

Trust is visualized as the **clarity** of the Ghost itself. As trust grows, the Ghost comes into focus. At full trust, it disappears into infrastructure—invisible because it's now simply part of how life works.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ←                    GHOST SETTINGS                                        │
│                                                                             │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                                                             │
│   YOUR GHOST                                                                │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                                                                     │  │
│   │                                                                     │  │
│   │                          ╭─────────╮                                │  │
│   │                         │           │                               │  │
│   │                         │    👻     │    ← Ghost at current clarity │  │
│   │                         │           │                               │  │
│   │                          ╰─────────╯                                │  │
│   │                                                                     │  │
│   │                     AUTO-SCHEDULER                                  │  │
│   │                                                                     │  │
│   │   The Ghost adds blocks automatically.                              │  │
│   │   You can undo any block with one tap.                              │  │
│   │                                                                     │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│                                                                             │
│   TRUST PHASES                                                              │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                                                                     │  │
│   │    👻        👻        👻        👻        ·                        │  │
│   │   ░░░       ▒▒▒       ▓▓▓       ███       ···                       │  │
│   │   Hazy    Forming    Solid   Defined  Invisible                     │  │
│   │                                                                     │  │
│   │  Observer  Scheduler  Auto     Trans-   Full                        │  │
│   │                     Scheduler  former   Ghost                       │  │
│   │                        ↑                                            │  │
│   │                       You                                           │  │
│   │                                                                     │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   Phase 1 (Observer):   Ghost is hazy, translucent, barely there.          │
│                         You see all suggestions. You decide everything.    │
│                                                                             │
│   Phase 3 (Auto):       Ghost is solid and defined. ← You are here         │
│                         It acts; you can undo.                             │
│                                                                             │
│   Phase 5 (Full Ghost): Ghost disappears into the background.              │
│                         UI becomes minimal. It's now infrastructure.       │
│                         You don't see it—you just live better.             │
│                                                                             │
│   ─────────────────────────────────────────────────────────────────────    │
│                                                                             │
│   Trust Score: 74%                                                          │
│   Suggestions accepted: 23/27                                               │
│   Workouts completed: 18                                                    │
│                                                                             │
│   The Ghost is earning your trust. ~8 days to next phase.                   │
│                                                                             │
│                                                                             │
│           ┌─────────────────────────────────────────────┐                  │
│           │       Step back to Scheduler                │                  │
│           └─────────────────────────────────────────────┘                  │
│                                                                             │
│   You can always step back. The Ghost never takes authority—it's granted.  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Ritualized Trust Transitions:**

Phase transitions should not feel administrative. They should feel **earned**.

When autonomy is about to expand, the Ghost delivers a short, sober statement—not a celebration:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                              👻                                             │
│                                                                             │
│                                                                             │
│         You've accepted 8 of my last 9 suggestions.                        │
│                                                                             │
│         I'm ready to act without asking.                                    │
│         You can stop me anytime.                                            │
│                                                                             │
│                                                                             │
│           ┌─────────────────────────────────────────────┐                  │
│           │                 Proceed                    │                  │
│           └─────────────────────────────────────────────┘                  │
│                                                                             │
│                       Not yet →                                            │
│                                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Transition Principles:**

1. **No celebration.** This is not a level-up. It's a transfer of authority.
2. **Clear stakes.** User understands what the Ghost will now do.
3. **Easy retreat.** "Not yet" is always visible and unjudged.
4. **UI removal.** After each phase increase, remove controls. Literally hide UI elements that are no longer needed.

**The UI should disappear as confidence grows.**

| Phase | What Disappears                                           |
| ----- | --------------------------------------------------------- |
| 2 → 3 | Confirmation prompts for scheduling                       |
| 3 → 4 | Block adjustment UI (Ghost handles it)                    |
| 4 → 5 | Settings screen simplifies to single toggle               |
| 5     | Ghost View shows almost nothing. It's infrastructure now. |

**Visual Implementation:**

| Phase              | Ghost Appearance     | Opacity | Blur | UI Density                     |
| ------------------ | -------------------- | ------- | ---- | ------------------------------ |
| 1 - Observer       | Hazy, barely visible | 20%     | 8px  | High (all suggestions visible) |
| 2 - Scheduler      | Forming, translucent | 40%     | 4px  | Medium                         |
| 3 - Auto-Scheduler | Solid, defined       | 70%     | 2px  | Lower                          |
| 4 - Transformer    | Fully defined        | 90%     | 0px  | Minimal                        |
| 5 - Full Ghost     | Invisible (dot only) | 5%      | 0px  | Almost nothing                 |

At Phase 5, the Ghost View becomes nearly empty—not because we're lazy, but because there's nothing to show. The Ghost is now part of the infrastructure of your life.

#### 2.3.7 The Single Command Interface

**This is not a feature. This is a system verdict.**

The Single Command exists because sometimes the user must express something the sensors cannot detect: an upcoming trip, a changed goal, a hotel gym. When the user speaks, the Ghost issues an **order**, not a **suggestion**.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                       ✕     │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│       What do you need?                                                     │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                                                                     │  │
│   │   20 minutes. Dumbbells. My shoulder is bothering me.               │  │
│   │   _                                                                 │  │
│   │                                                                     │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│           ┌─────────────────────────────────────────────┐                  │
│           │                   Execute                    │                  │
│           └─────────────────────────────────────────────┘                  │
│                                                                             │
│                                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Design Principles:**

1. **Minimal chrome.** No examples. No hints. User knows why they're here.
2. **Button says "Execute", not "Generate".** This is an order, not a request.
3. **Response is immediate.** Block appears in calendar within 3 seconds.
4. **No confirmation.** The system does not ask "Is this okay?" It acts.

**Aircraft cockpit philosophy:** Pilots don't get chatty interfaces in emergencies. When the user speaks a command, they need execution, not negotiation.

---

### 2.4 Calendar — The Invisible Interface

The calendar is Vigor's primary interface—but users never "use" it.

#### 2.4.1 Calendar Block Design

Vigor creates a dedicated calendar called "Vigor Training" with local-only storage (never syncs to corporate Exchange).

**Block Appearance:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     CALENDAR BLOCK TYPES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TRAINING BLOCK                                                             │
│  ┌──────────────────────────────────────────┐                              │
│  │ 💪 Upper Body Strength                    │   Color: Vigor Blue         │
│  │ 30 min                                    │   Emoji indicates type      │
│  │                                           │   Duration visible          │
│  └──────────────────────────────────────────┘                              │
│                                                                             │
│  RECOVERY BLOCK                                                             │
│  ┌──────────────────────────────────────────┐                              │
│  │ 🧘 Recovery Walk                          │   Color: Vigor Green        │
│  │ 20 min                                    │   Lower intensity           │
│  └──────────────────────────────────────────┘                              │
│                                                                             │
│  TRANSFORMED BLOCK                                                          │
│  ┌──────────────────────────────────────────┐                              │
│  │ ⚠️ Recovery Walk (Was: Heavy Legs)        │   Color: Vigor Yellow       │
│  │ 20 min • HRV low, protecting you         │   Shows transformation      │
│  └──────────────────────────────────────────┘                              │
│                                                                             │
│  REST INDICATOR (Optional)                                                  │
│  ┌──────────────────────────────────────────┐                              │
│  │ 🛌 Rest Day                               │   Color: Vigor Gray         │
│  │ Ghost: Recovery needed today              │   Explanatory               │
│  └──────────────────────────────────────────┘                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

#### 2.4.2 Dynamic Transformation

The most magical moment: when the calendar block transforms before the user even thinks about it.

**Before (Scheduled)**

```
┌──────────────────────────────────────────┐
│ 💪 Heavy Legs                             │
│ 45 min                                    │
└──────────────────────────────────────────┘
```

**After (Auto-transformed at 6 AM due to HRV crash)**

```
┌──────────────────────────────────────────┐
│ ⚠️ Recovery Walk (Was: Heavy Legs)        │
│ 20 min                                    │
│ Your HRV is crashed. Heavy lifting today  │
│ risks injury. Tap to revert.              │
└──────────────────────────────────────────┘
```

The user wakes up, checks calendar, and the decision is already made for them—with full explanation and override capability.

---

## Part III: Interaction Patterns

### 3.1 The Notification Doctrine

**The Rules:**

1. **Maximum 1 notification per day.** Ever. Across all devices.
2. **Never ask a question that requires thought.** Yes or No only.
3. **Never notify what can be silent.** Calendar blocks just appear.
4. **Silence is golden.** If sleep < 5 hours, say nothing. They know.

**Notification Anatomy:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  VIGOR                                                                 now  │
│                                                                             │
│  Training block added to calendar. 6 PM.                                    │
│                                                                             │
│  ┌──────────────────────┐      ┌──────────────────────┐                    │
│  │       Adjust         │      │        OK            │                    │
│  └──────────────────────┘      └──────────────────────┘                    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Binary actions only. "Adjust" opens time picker, not the app.
```

**Allowed Notification Types:**

| Type              | Copy                                      | Actions             |
| ----------------- | ----------------------------------------- | ------------------- |
| Block added       | "Training added to calendar. 6 PM."       | [Adjust] [OK]       |
| Block transformed | "Block changed: Recovery Walk (HRV low)." | [Revert] [OK]       |
| Workout detected  | "32 min workout logged. Tap if wrong."    | [Undo]              |
| Weekly receipt    | "Your week: 4 workouts. View."            | Opens Value Receipt |

**Forbidden Notifications:**

- "Good morning! How are you feeling?"
- "Don't break your streak!"
- "You've been sitting for 2 hours!"
- "Great job on yesterday's workout!"
- "Check out this new feature!"

### 3.2 One-Tap Patterns

Every user action should resolve in one tap maximum.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ONE-TAP PATTERNS                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  PASSIVE ACCEPTANCE                                                         │
│  ─────────────────────                                                      │
│  "Workout logged (45 min). Tap if I'm wrong."                               │
│                                                                             │
│  The action is already done. User taps ONLY if incorrect.                   │
│  Expected interaction: 90% no tap, 10% correction.                          │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  BINARY PROPOSAL                                                            │
│  ─────────────────                                                          │
│  "Training block for 6 PM?"                                                 │
│  [Yes]  [No]                                                                │
│                                                                             │
│  No customization in the proposal. Accept or reject.                        │
│  Customization is a separate flow for power users.                          │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  ONE-TAP OVERRIDE                                                           │
│  ─────────────────                                                          │
│  "HRV is low. Rest today?"                                                  │
│  [Rest]  [Train anyway →]                                                   │
│                                                                             │
│  Override exists but is visually de-emphasized.                             │
│  Ghost's recommendation is the primary action.                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 The Override Protocol

When users rebel against Ghost recommendations, the system responds with grace, not guilt.

**User says:** "I'm doing the heavy lift anyway."

**Ghost response:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│     Understood.                                                             │
│                                                                             │
│     Tomorrow's block adjusted to Recovery.                                  │
│     Extra sleep will help absorption.                                       │
│                                                                             │
│     You've got this.                                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Principles:**

1. **Never argue.** The user is always right about their body in the moment.
2. **Manage the aftermath.** Quietly adjust the next 48 hours.
3. **No guilt.** Never say "I told you so." Never track "compliance."
4. **Celebrate agency.** Sometimes breaking the plan is right.

### 3.4 Contextual Silence

The Ghost knows when to stay quiet.

| Condition                         | Ghost Behavior                      |
| --------------------------------- | ----------------------------------- |
| Sleep < 5 hours                   | No workout suggestions. No nagging. |
| Calendar shows "Travel"           | Pause auto-scheduling.              |
| User rejected 3 blocks in a row   | Downgrade to Observer phase.        |
| Weekend before 9 AM               | Protected by default.               |
| 3+ hours of back-to-back meetings | Suggest walk, not workout.          |

Silence is a feature. The app that doesn't speak earns the right to be heard when it does.

### 3.5 The Safety Breaker — The Apology

The Tech Spec (v2.6) defines a **Safety Breaker**: if a user deletes 3 calendar blocks in a row, the Ghost immediately downgrades its Trust Phase to protect the relationship.

This moment cannot be silent. When the Ghost pulls back, it must do so with _immense humility_. This is not a bug—it's empathy. It humanizes the algorithm.

**Trigger:** User deletes/rejects 3 consecutive Ghost-created blocks.

**Immediate Response:** Trust Phase drops to Observer (Phase 1).

**Next App Open — The Apology State:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                       ⚙     │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                           👻                                                │
│                          ░░░                                                │
│                         (hazy)                                              │
│                                                                             │
│                                                                             │
│                                                                             │
│               I pushed too hard.                                            │
│                                                                             │
│               I've stepped back to Observer Mode.                           │
│               I'll suggest. You decide.                                     │
│                                                                             │
│               Let's rebuild.                                                │
│                                                                             │
│                                                                             │
│                                                                             │
│           ┌──────────────────────────────────────┐                         │
│           │              Understood               │                         │
│           └──────────────────────────────────────┘                         │
│                                                                             │
│                                                                             │
│   ──────────────────────────────────────────────────────────────────────   │
│                     👻              📊              ⚙️                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Visual Details:**

- Ghost View background: Dimmed (85% brightness, not dark mode)
- Ghost glyph: Returns to Phase 1 hazy state
- Typography: Softer than usual. No boldness. Humility in the font weight.
- No defensive explanation. No "Here's why I was wrong." Just: "I pushed too hard."

**What This Achieves:**

1. **Humanizes the algorithm.** Machines don't apologize. Vigor does.
2. **Turns failure into feature.** Bad scheduling becomes empathetic recovery.
3. **Protects the relationship.** User feels heard, not judged.
4. **Corporate resilience.** Executives see a system that respects boundaries.

**The Ghost rebuilds trust from zero—and the user witnesses humility.**

### 3.6 System Degraded State — Technical Failure

The Safety Breaker (above) handles _emotional_ failure—"I was wrong about your schedule."

But the Tech Spec also describes _technical_ failure: battery death, revoked permissions, stale data, silent crashes. These require a different visual language.

**The distinction:**

- **Trust Downgrade (Apology):** Emotional. Humble. "I pushed too hard."
- **System Degraded:** Clinical. Amber. "I am flying blind."

**Do not conflate emotional failure with technical failure.**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                       ⚙     │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                                                                     │  │
│   │                          ⚠️                                         │  │
│   │                                                                     │  │
│   │                   LIMITED VISIBILITY                                │  │
│   │                                                                     │  │
│   │   I cannot see your calendar.                                       │  │
│   │   Calendar access was revoked 2 days ago.                           │  │
│   │                                                                     │  │
│   │   Without calendar access, I cannot:                                │  │
│   │   • Schedule blocks automatically                                   │  │
│   │   • Detect conflicts with your meetings                             │  │
│   │   • Transform blocks based on your day                              │  │
│   │                                                                     │  │
│   │   ┌─────────────────────────────────────────────────────────────┐  │  │
│   │   │                  Restore Access                              │  │  │
│   │   └─────────────────────────────────────────────────────────────┘  │  │
│   │                                                                     │  │
│   │                  Continue in Manual Mode →                          │  │
│   │                                                                     │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│   ──────────────────────────────────────────────────────────────────────   │
│                     👻              📊              ⚙️                       │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Visual Language Comparison:**

| Aspect         | Trust Downgrade (Apology) | System Degraded          |
| -------------- | ------------------------- | ------------------------ |
| **Tone**       | Humble, soft              | Clinical, matter-of-fact |
| **Icon**       | 👻 (hazy)                 | ⚠️ (amber warning)       |
| **Background** | Dimmed (85%)              | Normal with amber card   |
| **Typography** | Light weight, quiet       | Regular weight, clear    |
| **Message**    | "I pushed too hard"       | "I cannot see X"         |
| **Action**     | "Understood" (accept)     | "Restore Access" (fix)   |

**System Degraded Triggers:**

| Condition                   | Message                                  | Action            |
| --------------------------- | ---------------------------------------- | ----------------- |
| Calendar access revoked     | "I cannot see your calendar"             | Restore Access    |
| HealthKit access revoked    | "I cannot see your health data"          | Restore Access    |
| Watch disconnected > 48h    | "I haven't heard from your Watch"        | Check Watch       |
| Background refresh disabled | "I can only work when you open the app"  | Enable Background |
| iCloud sync failing         | "Your data isn't syncing across devices" | Check iCloud      |

**The principle:** When the Ghost is blind, it says so—clearly, clinically, without apology. Technical failures are not emotional moments. They require action, not forgiveness.

### 3.7 One-Tap Triage — Learning from Misses

The Tech Spec mentions asking "Why did you miss?" to distinguish between life circumstances and bad scheduling. The UX must reconcile this with passive acceptance.

**Solution:** Non-intrusive, ephemeral inquiry.

When a workout is missed (block passed without detection), the _next_ time the user opens the app, a subtle card appears:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐  │
│   │                                                                     │  │
│   │     Yesterday's block didn't happen.                                │  │
│   │                                                                     │  │
│   │     ┌───────────────────┐      ┌───────────────────┐               │  │
│   │     │    Just life      │      │   Bad timing      │               │  │
│   │     └───────────────────┘      └───────────────────┘               │  │
│   │                                                                     │  │
│   └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**One tap. Then it vanishes.**

| Response     | Ghost Learning                                           |
| ------------ | -------------------------------------------------------- |
| "Just life"  | External factor. Pattern not adjusted. No blame.         |
| "Bad timing" | Schedule issue. Ghost adjusts that time slot's priority. |

**Principles:**

- Never ask during the missed block. That's nagging.
- Never ask more than once per miss.
- Card auto-dismisses after 24 hours if untapped.
- No guilt. No follow-up. Just learning.

### 3.7 The Red Button (Emergency Protocol)

For moments of crisis. Not fitness—survival.

**Siri Shortcut:** "Hey Siri, I'm crashing."

**Immediate Response:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                                                                             │
│                           I've cleared 15 minutes.                          │
│                                                                             │
│                           Focus Mode enabled.                               │
│                           Breathe.                                          │
│                                                                             │
│                                                                             │
│                    ┌───────────────────────┐                               │
│                    │   Start NSDR Session  │                               │
│                    └───────────────────────┘                               │
│                                                                             │
│                    ┌───────────────────────┐                               │
│                    │   Box Breathing       │                               │
│                    └───────────────────────┘                               │
│                                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**What Happens:**

1. Calendar blocked for 15 minutes as "Focus Time"
2. Do Not Disturb enabled
3. NSDR or breathing exercise queued
4. Event logged for pattern detection

**Future Pattern Detection:**

> "Your crashes cluster around Thursday afternoons after all-hands meetings. I've added a 10-minute buffer after those meetings for the next month."

---

## Part IV: Visual Design System

### 4.1 The Ghost Aesthetic

Vigor's visual language is **austere luxury**—the design equivalent of a high-end hotel lobby. Nothing excess. Everything intentional.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DESIGN CHARACTERISTICS                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   RESTRAINT          Maximum white space. Content breathes.                 │
│   HIERARCHY          One focus per screen. Everything else recedes.         │
│   PRECISION          Aligned to 4px grid. No exceptions.                    │
│   SUBTLETY           Animations at 200-300ms. Never jarring.                │
│   DEPTH              Minimal but purposeful shadows.                        │
│   HONESTY            What you see is what exists. No hidden menus.          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Color System

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           COLOR PALETTE                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  PRIMARY                                                                    │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  Ghost White        #FFFFFF     Primary background                          │
│  Ghost Black        #1C1C1E     Primary text, dark mode bg                  │
│  Ghost Gray         #8E8E93     Secondary text, borders                     │
│                                                                             │
│                                                                             │
│  ACCENT                                                                     │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  Vigor Blue         #0A84FF     Primary actions, links                      │
│  Vigor Indigo       #5E5CE6     Premium features (future)                   │
│                                                                             │
│                                                                             │
│  SEMANTIC                                                                   │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  Recovery Green     #34C759     Good recovery (80-100%)                     │
│  Caution Yellow     #FFCC00     Moderate recovery (50-79%)                  │
│  Warning Orange     #FF9500     Low recovery (30-49%)                       │
│  Alert Red          #FF3B30     Compromised (<30%)                          │
│                                                                             │
│                                                                             │
│  SURFACES                                                                   │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  Surface Primary    #F2F2F7     Card backgrounds (light)                    │
│  Surface Secondary  #E5E5EA     Dividers, subtle borders                    │
│  Surface Elevated   #FFFFFF     Elevated cards, modals                      │
│                                                                             │
│  (Dark mode values adapt using iOS semantic colors)                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.3 Typography

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TYPOGRAPHY SCALE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TYPEFACE: SF Pro (iOS), SF Compact (watchOS)                               │
│                                                                             │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  HEADLINE                                                                   │
│  Large Title     34pt / Bold      Screen titles (rare)                      │
│  Title 1         28pt / Bold      Section headers                           │
│  Title 2         22pt / Bold      Card titles                               │
│  Title 3         20pt / Semibold  Subsection headers                        │
│                                                                             │
│  BODY                                                                       │
│  Body            17pt / Regular   Primary content                           │
│  Callout         16pt / Regular   Secondary content                         │
│  Subhead         15pt / Regular   Supporting text                           │
│  Footnote        13pt / Regular   Metadata, timestamps                      │
│  Caption 1       12pt / Regular   Labels, hints                             │
│  Caption 2       11pt / Regular   Legal, tertiary                           │
│                                                                             │
│  NUMBERS                                                                    │
│  Stats           28pt / Semibold  Dashboard numbers                         │
│  Metrics         20pt / Medium    Inline metrics                            │
│  Data            17pt / Monospace Precise values (tabular nums)             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.4 Iconography

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ICON SYSTEM                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STYLE: SF Symbols (native), Weight: Regular/Medium                         │
│                                                                             │
│  ACTIVITY                                                                   │
│  ─────────────────────────────────────────────────────────────              │
│  💪  figure.strengthtraining.traditional    Strength                        │
│  🏃  figure.run                              Cardio/Running                  │
│  🧘  figure.mind.and.body                   Recovery/Yoga                   │
│  🚶  figure.walk                             Walking                         │
│  🛌  bed.double.fill                         Rest day                        │
│                                                                             │
│  STATUS                                                                     │
│  ─────────────────────────────────────────────────────────────              │
│  ❤️  heart.fill                              Heart rate                      │
│  💤  moon.zzz.fill                           Sleep                           │
│  📈  chart.line.uptrend.xyaxis              Progress                        │
│  🔥  flame.fill                              Streak                          │
│  ⚠️  exclamationmark.triangle.fill          Warning/Transform               │
│                                                                             │
│  NAVIGATION                                                                 │
│  ─────────────────────────────────────────────────────────────              │
│  👻  Custom "Ghost" glyph                   App icon, Ghost View            │
│  📊  chart.bar.fill                         Phenome                          │
│  ⚙️  gearshape.fill                         Settings                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.5 Motion & Animation

Animation in Vigor is **restrained and purposeful**. Motion communicates state, never decorates.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MOTION PRINCIPLES                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TIMING                                                                     │
│  ─────────────────────────────────────────────────────────────              │
│  Micro          100-200ms     Button states, toggles                        │
│  Standard       250-300ms     Cards, modals, transitions                    │
│  Deliberate     400-500ms     Major state changes, celebrations             │
│                                                                             │
│  EASING                                                                     │
│  ─────────────────────────────────────────────────────────────              │
│  Default        ease-in-out   Most transitions                              │
│  Enter          ease-out      Elements appearing                            │
│  Exit           ease-in       Elements disappearing                         │
│  Spring         damping: 0.7  Organic, playful (rare)                       │
│                                                                             │
│  ALLOWED ANIMATIONS                                                         │
│  ─────────────────────────────────────────────────────────────              │
│  • Cards sliding in/out                                                     │
│  • Progress rings filling                                                   │
│  • Numbers counting up (when workout completes)                             │
│  • Fade transitions between states                                          │
│                                                                             │
│  FORBIDDEN ANIMATIONS                                                       │
│  ─────────────────────────────────────────────────────────────              │
│  • Bouncing elements                                                        │
│  • Confetti / celebrations                                                  │
│  • Spinning loaders (use skeleton states instead)                           │
│  • Parallax scrolling                                                       │
│  • Anything that draws attention to itself                                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.6 Haptic Vocabulary — The Voice on Your Wrist

We defined the "Voice of the Ghost" as text (Section 1.5). But we missed the _feeling_.

The Watch is on the skin. Haptics are the most intimate communication channel we have. They bypass cognition and speak directly to the nervous system.

**Vigor defines a custom haptic vocabulary:**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           HAPTIC VOCABULARY                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ACKNOWLEDGMENT                                                             │
│  ─────────────────────────────────────────────────────────────              │
│  Pattern:     Single crisp tap                                              │
│  WKHaptic:    .click                                                        │
│  When:        Action confirmed (block added, workout logged)                │
│  Feeling:     "Got it."                                                     │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  GENTLE CORRECTION                                                          │
│  ─────────────────────────────────────────────────────────────              │
│  Pattern:     Two soft pulses (250ms apart)                                 │
│  WKHaptic:    .notification(.warning) × 2                                   │
│  When:        Ghost transformed a block, gentle override                    │
│  Feeling:     "I've adjusted something."                                    │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  COMPLETION                                                                 │
│  ─────────────────────────────────────────────────────────────              │
│  Pattern:     Solid resonant pulse                                          │
│  WKHaptic:    .success                                                      │
│  Duration:    Single event                                                  │
│  When:        Workout auto-logged, streak milestone, first Phenome insight  │
│  Feeling:     "Done."                                                       │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  ALERT (Rare)                                                               │
│  ─────────────────────────────────────────────────────────────              │
│  Pattern:     Strong single pulse                                           │
│  WKHaptic:    .notification(.error)                                         │
│  When:        Recovery crashed, Red Button activated                        │
│  Feeling:     "Pay attention."                                              │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  BREATHING (Crisis Protocol)                                                │
│  ─────────────────────────────────────────────────────────────              │
│  Pattern:     4-second swell in, 4-second swell out                         │
│  WKHaptic:    Custom extended session haptics                               │
│  When:        Box breathing / NSDR guidance                                 │
│  Feeling:     "Breathe with me."                                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Implementation Notes:**

```swift
// VigorHaptics.swift
import WatchKit

enum VigorHaptic {
    case acknowledgment
    case gentleCorrection
    case magicMoment
    case alert
    case breatheIn
    case breatheOut

    func play() {
        let device = WKInterfaceDevice.current()
        switch self {
        case .acknowledgment:
            device.play(.click)

        case .gentleCorrection:
            device.play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                device.play(.notification)
            }

        case .magicMoment:
            device.play(.start)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                device.play(.click)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                device.play(.success)
            }

        case .alert:
            device.play(.failure)

        case .breatheIn, .breatheOut:
            // Extended haptic session for breathing guidance
            // Implemented via WKExtendedRuntimeSession
            break
        }
    }
}
```

**The Rule:** Every haptic must earn its place. A haptic without meaning is noise. Noise erodes trust.

### 4.7 Spacing & Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SPACING SYSTEM                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  BASE UNIT: 4px                                                             │
│                                                                             │
│  SCALE                                                                      │
│  ─────────────────────────────────────────────────────────────              │
│  2xs         4px       Tight groupings                                      │
│  xs          8px       Related elements                                     │
│  sm          12px      Default element spacing                              │
│  md          16px      Section spacing                                      │
│  lg          24px      Card padding                                         │
│  xl          32px      Screen margins                                       │
│  2xl         48px      Major section breaks                                 │
│  3xl         64px      Hero spacing                                         │
│                                                                             │
│  LAYOUT GRID                                                                │
│  ─────────────────────────────────────────────────────────────              │
│  iPhone      16px margins, 16px gutters                                     │
│  Watch       8px margins (horizontal edges)                                 │
│                                                                             │
│  CONTENT WIDTH                                                              │
│  ─────────────────────────────────────────────────────────────              │
│  Cards       Full width - 32px (16px each side)                             │
│  Text        Max 60 characters for readability                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Part V: Onboarding — The First Five Minutes

### 5.1 The Sacred Promise

Onboarding is the first test of our design philosophy. If we ask too much, we've already failed.

**Target time: < 2 minutes**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ONBOARDING FLOW                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STEP 1: CONNECT (30 seconds)                                               │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│                    ┌─────────────────────────────────┐                     │
│                    │                                 │                     │
│                    │  Let me see the last 90 days.   │                     │
│                    │                                 │                     │
│                    │  One tap connects your health   │                     │
│                    │  data. I'll know your sleep,    │                     │
│                    │  your heart rate, your history. │                     │
│                    │                                 │                     │
│                    │  ┌───────────────────────────┐  │                     │
│                    │  │     Connect Health        │  │                     │
│                    │  └───────────────────────────┘  │                     │
│                    │                                 │                     │
│                    └─────────────────────────────────┘                     │
│                                                                             │
│  STEP 2: CALENDAR (15 seconds)                                              │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│                    ┌─────────────────────────────────┐                     │
│                    │                                 │                     │
│                    │  Let me see your schedule.      │                     │
│                    │                                 │                     │
│                    │  I'll find the gaps in your     │                     │
│                    │  day—and protect them for you.  │                     │
│                    │                                 │                     │
│                    │  ┌───────────────────────────┐  │                     │
│                    │  │     Connect Calendar      │  │                     │
│                    │  └───────────────────────────┘  │                     │
│                    │                                 │                     │
│                    └─────────────────────────────────┘                     │
│                                                                             │
│  STEP 3: BASICS (30 seconds)                                                │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│                    ┌─────────────────────────────────┐                     │
│                    │                                 │                     │
│                    │  What do you have access to?    │                     │
│                    │                                 │                     │
│                    │  ○ Bodyweight only              │                     │
│                    │  ○ Dumbbells                    │                     │
│                    │  ○ Full gym                     │                     │
│                    │                                 │                     │
│                    │  Any limitations?               │                     │
│                    │                                 │                     │
│                    │  ┌─────────────────────────┐    │                     │
│                    │  │ Shoulder │ Back │ Knee  │    │                     │
│                    │  └─────────────────────────┘    │                     │
│                    │                                 │                     │
│                    │  ┌───────────────────────────┐  │                     │
│                    │  │          Continue         │  │                     │
│                    │  └───────────────────────────┘  │                     │
│                    │                                 │                     │
│                    └─────────────────────────────────┘                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 The Absolution Moment

After data import (90 days of HealthKit in < 5 seconds), the user receives their first insight. This is **Day 1 Magic**.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                   I've looked at your last 90 days.                         │
│                                                                             │
│                   ─────────────────────────────                             │
│                                                                             │
│                   Your schedule has been impossible.                        │
│                   Back-to-back meetings 4 days a week.                      │
│                                                                             │
│                   Your sleep has been inconsistent—                         │
│                   ranging from 4 to 8 hours.                                │
│                                                                             │
│                   Your last detected workout was 23 days ago.               │
│                                                                             │
│                   ─────────────────────────────                             │
│                                                                             │
│                   It wasn't your fault you fell off.                        │
│                                                                             │
│                   Your schedule was designed to make you fail.              │
│                   Most people blame themselves.                             │
│                   The truth is: you never had a chance.                     │
│                                                                             │
│                   That changes now.                                         │
│                                                                             │
│                                                                             │
│                   ┌───────────────────────────────────────┐                │
│                   │               Continue                 │                │
│                   └───────────────────────────────────────┘                │
│                                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.3 The First Block

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                   I found one window this week                              │
│                   where you can actually succeed:                           │
│                                                                             │
│                   ┌─────────────────────────────────┐                      │
│                   │                                 │                      │
│                   │     Tomorrow                    │                      │
│                   │     5:30 – 6:15 PM              │                      │
│                   │                                 │                      │
│                   │     20-minute movement session  │                      │
│                   │                                 │                      │
│                   └─────────────────────────────────┘                      │
│                                                                             │
│                   It's already on your calendar.                            │
│                   We start simple. We start winnable.                       │
│                                                                             │
│                                                                             │
│                   ┌───────────────────────────────────────┐                │
│                   │               Got it                   │                │
│                   └───────────────────────────────────────┘                │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**User's reaction:** Not just "That was fast." But: "Someone finally _gets it_."

---

## Part VI: Graceful Degradation

### 6.1 When Things Go Wrong

Great products define graceful failure.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FAILURE RESPONSES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  WATCH BATTERY DIES                                                         │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  "I couldn't see your workout today. Did you train?"                        │
│                                                                             │
│  [Yes, around 6 PM]    [No]                                                 │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  DATA SEEMS WRONG                                                           │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  "Your HRV looks unusual today—significantly elevated.                      │
│   Is this accurate?"                                                        │
│                                                                             │
│  [Seems right]    [Ignore this reading]                                     │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  CALENDAR ACCESS REVOKED                                                    │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  "I can't see your calendar anymore.                                        │
│   Here are suggestions for today—schedule them yourself."                   │
│                                                                             │
│  [Reconnect Calendar]    [Continue without]                                 │
│                                                                             │
│  ────────────────────────────────────────────────────────────────────────   │
│                                                                             │
│  GHOST SUGGESTION WAS WRONG                                                 │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  "Understood. I'm learning."                                                │
│                                                                             │
│  (Lower confidence for that pattern. No defensive explanation.)             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.2 Transparency on Request

Users can always ask: **"Why did this happen?"**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│  GHOST DECISION LOG                                                         │
│                                                                             │
│  ───────────────────────────────────────────────────────────────            │
│                                                                             │
│  🔄 Changed 'Heavy Legs' → 'Recovery Walk'                                  │
│     Today, 6:14 AM                                                          │
│                                                                             │
│     Reason: HRV 23% below your baseline. Sleep: 4.2 hours.                  │
│     Confidence: 87%                                                         │
│                                                                             │
│     [Tap to revert]                                                         │
│                                                                             │
│  ───────────────────────────────────────────────────────────────            │
│                                                                             │
│  📅 Added training block at 6 PM                                            │
│     Yesterday, 9:02 PM                                                      │
│                                                                             │
│     Reason: 45-minute gap detected. 3 days since last session.              │
│     Confidence: 72%                                                         │
│                                                                             │
│  ───────────────────────────────────────────────────────────────            │
│                                                                             │
│  ⏭️ Skipped scheduling                                                      │
│     2 days ago                                                              │
│                                                                             │
│     Reason: You rejected this time slot twice before.                       │
│     Learned: Not a good time for you.                                       │
│                                                                             │
│  ───────────────────────────────────────────────────────────────            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Part VII: Accessibility

### 7.1 Core Principles

Vigor must work for everyone. Accessibility is not an afterthought.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ACCESSIBILITY REQUIREMENTS                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  VISION                                                                     │
│  ─────────────────────────────────────────────────────────────              │
│  • All text passes WCAG 2.1 AA contrast (4.5:1 minimum)                     │
│  • VoiceOver fully supported with meaningful labels                         │
│  • Dynamic Type supported (up to xxxLarge)                                  │
│  • No information conveyed by color alone                                   │
│  • Reduce Motion respected (no essential animations)                        │
│                                                                             │
│  MOTOR                                                                      │
│  ─────────────────────────────────────────────────────────────              │
│  • All tap targets minimum 44×44pt                                          │
│  • Full keyboard navigation on iPad                                         │
│  • Switch Control compatible                                                │
│  • No time-dependent interactions required                                  │
│                                                                             │
│  COGNITIVE                                                                  │
│  ─────────────────────────────────────────────────────────────              │
│  • One action per screen (reduce cognitive load)                            │
│  • Clear, consistent language                                               │
│  • No jargon or fitness terminology without explanation                     │
│  • Undo available for all destructive actions                               │
│                                                                             │
│  HEARING                                                                    │
│  ─────────────────────────────────────────────────────────────              │
│  • No audio-only content                                                    │
│  • Haptic feedback accompanies all sound cues                               │
│  • Visual indicators for all timed events                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 7.2 VoiceOver Labels

```swift
// Example VoiceOver implementation
recoveryScoreView.accessibilityLabel = "Recovery score"
recoveryScoreView.accessibilityValue = "78 percent. Good recovery."
recoveryScoreView.accessibilityHint = "Based on sleep and heart rate variability"

workoutCard.accessibilityLabel = "Today's workout"
workoutCard.accessibilityValue = "Upper body strength, 30 minutes"
workoutCard.accessibilityHint = "Double tap to start workout"
```

---

## Part VIII: Design Metrics

### 8.1 Success Metrics

These metrics define whether our design is working:

| Metric                        | Target            | Why It Matters                           |
| ----------------------------- | ----------------- | ---------------------------------------- |
| **Time to First Magic**       | < 5 min           | User knows this is different immediately |
| **App Opens / Month**         | < 3               | Invisible means successful               |
| **Weeks Without Thinking**    | 2+ weeks average  | True infrastructure status achieved      |
| **Zero-Input Workouts**       | 50%+              | The Ghost is working                     |
| **Notification Dismiss Rate** | < 10%             | We speak when we should                  |
| **Trust Phase Progression**   | 80% reach Phase 3 | Users grant autonomy                     |
| **Value Receipt Open Rate**   | 70%+              | Users want proof of value                |
| **Calendar Block Completion** | 60%+              | Scheduling converts to action            |

### 8.2 Anti-Metrics

What we deliberately avoid optimizing:

| Anti-Metric           | Why It's Bad                                      |
| --------------------- | ------------------------------------------------- |
| Daily Active Users    | We don't want daily opens. We want daily fitness. |
| Time in App           | More time = more friction. Less = better Ghost.   |
| Notification Tap Rate | High tap = we're nagging, not helping.            |
| Feature Usage Breadth | We want depth on core, not exploration.           |
| Session Length        | Shorter is better. Get in, get out.               |
| App Open Count        | If users open the app, ask: "What failed?"        |

---

## Appendix A: Component Library

### A.1 Cards

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  STANDARD CARD                                                              │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  Card Title                                                 →       │   │
│  │  Secondary text or description                                      │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  • Background: Surface Primary (#F2F2F7 light / #1C1C1E dark)              │
│  • Corner radius: 12px                                                      │
│  • Padding: 16px                                                            │
│  • Shadow: 0 2px 8px rgba(0,0,0,0.04)                                      │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  WORKOUT CARD                                                               │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │                     UPPER BODY STRENGTH                             │   │
│  │                         30 minutes                                  │   │
│  │                                                                     │   │
│  │   Dumbbell Press • Rows • Push-ups • Curls                          │   │
│  │                                                                     │   │
│  │   ┌───────────────────────────────────────────────────────────┐    │   │
│  │   │                        START                               │    │   │
│  │   └───────────────────────────────────────────────────────────┘    │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  • Background: White                                                        │
│  • Corner radius: 16px                                                      │
│  • Padding: 24px                                                            │
│  • Shadow: 0 4px 16px rgba(0,0,0,0.08)                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### A.2 Buttons

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PRIMARY                                                                    │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────┐             │
│  │                        START                               │             │
│  └───────────────────────────────────────────────────────────┘             │
│                                                                             │
│  • Background: Vigor Blue (#0A84FF)                                         │
│  • Text: White, 17pt Semibold                                               │
│  • Height: 50px                                                             │
│  • Corner radius: 12px                                                      │
│  • Full width (with margins)                                                │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  SECONDARY                                                                  │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────┐             │
│  │                   Skip for now →                           │             │
│  └───────────────────────────────────────────────────────────┘             │
│                                                                             │
│  • Background: Transparent                                                  │
│  • Text: Ghost Gray (#8E8E93), 17pt Regular                                │
│  • Height: 44px                                                             │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  DESTRUCTIVE                                                                │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────┐             │
│  │                       Remove                               │             │
│  └───────────────────────────────────────────────────────────┘             │
│                                                                             │
│  • Background: Transparent                                                  │
│  • Text: Alert Red (#FF3B30), 17pt Regular                                 │
│  • Height: 44px                                                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### A.3 Progress Indicators

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  RECOVERY RING                                                              │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│       ╭───────────╮                                                         │
│      ╱   ╭─────╮   ╲        • Stroke width: 8px (iPhone), 4px (Watch)      │
│     │   │ 78  │   │        • Track: 10% opacity of ring color              │
│     │   │     │   │        • Color: Recovery Green/Yellow/Orange/Red       │
│      ╲   ╰─────╯   ╱        • Animation: ease-out, 400ms                    │
│       ╰───────────╯                                                         │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  WORKOUT PROGRESS                                                           │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  ━━━━━━━━━━━━━━━━━━━━━━━━░░░░░░░░░░                                         │
│  Exercise 4 of 6                                                            │
│                                                                             │
│  • Height: 4px                                                              │
│  • Track: Ghost Gray 20%                                                    │
│  • Fill: Vigor Blue                                                         │
│  • Corner radius: 2px                                                       │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  REST TIMER                                                                 │
│  ─────────────────────────────────────────────────────────────              │
│                                                                             │
│  ━━━━━━━━━▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                                             │
│  REST: 0:45                                                                 │
│                                                                             │
│  • Height: 4px                                                              │
│  • Fill: Counts DOWN from right to left                                     │
│  • Color: Vigor Blue → Recovery Green when complete                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Appendix B: SwiftUI Implementation Notes

### B.1 Design System Setup

```swift
// VigorDesignSystem.swift

import SwiftUI

enum VigorColors {
    static let ghostWhite = Color(UIColor.systemBackground)
    static let ghostBlack = Color(UIColor.label)
    static let ghostGray = Color(UIColor.secondaryLabel)

    static let vigorBlue = Color(red: 10/255, green: 132/255, blue: 255/255)
    static let recoveryGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    static let cautionYellow = Color(red: 255/255, green: 204/255, blue: 0/255)
    static let warningOrange = Color(red: 255/255, green: 149/255, blue: 0/255)
    static let alertRed = Color(red: 255/255, green: 59/255, blue: 48/255)

    static func recoveryColor(for score: Double) -> Color {
        switch score {
        case 0.8...1.0: return recoveryGreen
        case 0.5..<0.8: return cautionYellow
        case 0.3..<0.5: return warningOrange
        default: return alertRed
        }
    }
}

enum VigorSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

struct VigorCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(VigorSpacing.lg)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct VigorPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(VigorColors.vigorBlue)
                .cornerRadius(12)
        }
    }
}
```

### B.2 Animation Standards

```swift
// VigorAnimations.swift

import SwiftUI

extension Animation {
    static let vigorMicro = Animation.easeInOut(duration: 0.15)
    static let vigorStandard = Animation.easeInOut(duration: 0.25)
    static let vigorDeliberate = Animation.easeInOut(duration: 0.4)

    static let vigorSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
}

struct VigorTransition {
    static let card = AnyTransition
        .opacity
        .combined(with: .offset(y: 20))
}
```

---

## Document History

| Version | Date             | Author      | Changes                                                                                                                                                                                                                                                                                                  |
| ------- | ---------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0     | January 27, 2026 | Design Team | Initial specification                                                                                                                                                                                                                                                                                    |
| 1.1     | January 27, 2026 | Design Team | Bio-rhythmic Ghost View, Trust as resolution metaphor, Haptic vocabulary, Safety Breaker Apology UI, Context-aware complications, One-Tap Triage, Value Receipt motion & Clean Mode                                                                                                                      |
| 1.2     | January 27, 2026 | Design Team | Stripped vanity: killed Ghost pulse animation, removed Value Receipt animation (instant truth), added staleness indicators (Watch + iPhone), added System Degraded state distinct from Apology, simplified haptics                                                                                       |
| 1.3     | January 27, 2026 | Design Team | Radical absence: added "Designing for Absence" principle, elevated Calendar to THE Home Screen, promoted Watch to co-processor/executor with exclusive moments, added ritualized trust transitions with UI removal, Single Command as verdict (not feature), success metrics changed to MONTH (not week) |

---

_"Simplicity is the ultimate sophistication."_
— Leonardo da Vinci

_"When you're a carpenter making a beautiful chest of drawers, you're not going to use a piece of plywood on the back, even though it faces the wall and nobody will see it. You'll know it's there, so you're going to use a beautiful piece of wood on the back."_
— Steve Jobs

---

**The Ghost exists to serve, not to control.**
**When it works perfectly, no one notices it at all.**
