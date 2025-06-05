# Vigor – Your AI Fitness & Wellness Coach

## 🧭 Overview

**Vigor** is an AI-powered fitness and wellness companion designed to evolve with users across their health journey. From personalized workout plans to form analysis, emotional well-being, and behavior change, Vigor combines AI, computer vision, and behavioral science to deliver a proactive, motivating, and intelligent fitness experience.

---

## 🚩 Phase 1: Minimum Viable Product (MVP)

### ✅ Features

1. **Secure Onboarding & User Profile**
   - Collect: goals, fitness level, equipment, injuries, preferences.
   - Auth: OAuth2/JWT, encrypted data, GDPR-compliant storage.

2. **Personalized Workout Plan Generator (LLM)**
   - Plan based on user profile.
   - Explain rationale behind each decision in plain language.

3. **Workout Logging + Progress Tracker**
   - Log sets/reps/weights, RPE.
   - Visual progress tracking (graphs, milestones).

4. **Motivational Coaching & Q&A (LLM)**
   - Daily nudges, workout-specific encouragement.
   - “Ask your coach” button for questions (e.g., “Why deload?” or “What is DOMS?”).

---

## 🛠️ Phase 2: Smarter Intelligence & Async Coaching

### 💪 CV-Based Form Feedback
- Upload workout videos → get CV + LLM-based feedback.
- Tools: MediaPipe/OpenPose → AI explains what to fix in plain English.

### 🧠 Adaptive Recovery Readiness
- Combines RPE, HRV (via wearables), soreness, sleep to rate readiness.
- Suggests workout modifications or recovery days.

### 📚 Explore & Learn Hub (LLM)
- Curated learning: strength training myths, recovery tips, nutrition 101.
- Personalized content based on user behavior.

### 📱 Wearables Integration
- Pull data from Apple Health, Garmin, Google Fit: steps, sleep, HRV.
- Foundation for readiness and behavior models.

---

## 🚀 Phase 3: Whole-Person Wellness

### 🧱 Habit Builder with Smart Nudges
- Track hydration, mobility, journaling, sleep hygiene.
- Build streaks, get gentle nudges: “You’re 2 days into your hydration streak!”

### ⚡ Stackable Micro Workouts
- 5–10 min workouts for stress relief or when pressed for time.
- Dynamic suggestions based on schedule, soreness, goal alignment.

### 🔊 Voice-Guided Workouts
- AI narrates reps, gives feedback and motivation.
- Voice style options: Calm Yogi, Tough Trainer, Nerd Coach.

### ☀️ Mood + Energy Check-Ins
- Morning/evening check-ins influence coaching tone and plan difficulty.

### 📅 Smart Calendar Integration
- Vigor finds ideal workout times based on user calendar.
- Automatically reschedules workouts if conflicts arise.

### 🤝 Community Challenges
- Group-based challenges (e.g., “Move 20 Days This Month”).
- Progress bars, social accountability, celebration GIFs.

### 📓 Post-Workout AI Reflections
- Ask “How was it?” → AI builds a journal of highs/lows.
- Detects trends: “You train better at lunch than in the evening.”

---

## 🔐 Tech Stack

- **Backend**: Python (FastAPI), PostgreSQL, LangChain/OpenAI, MediaPipe/OpenCV.
- **Frontend**: React (Web), future mobile app (Flutter or React Native).
- **Auth**: OAuth2/JWT, secure profile and health data storage.
- **LLM Use**:
  - Plan creation & Q&A
  - Motivational messages & education
  - Voice narration scripting
  - Reflective journaling feedback
- **CV Use**:
  - Async form feedback → real-time edge feedback in future
- **AI Pipelines**:
  - Readiness scoring, trend detection, behavior nudging

---

## 🧪 Deliverables for Dev (Cursor, GitHub, etc.)

1. ✅ Directory & code scaffold
2. ✅ Backend module stubs:
   - `WorkoutPlanner`, `ReadinessEngine`, `UserTracker`, `AIJournalService`, `HabitService`, etc.
3. ✅ REST API endpoints: `/users`, `/plan`, `/log`, `/habit`, `/coach`, `/journal`, `/upload-video`
4. ✅ LLM prompt libraries (plan generation, journaling, Q&A)
5. ✅ Frontend wireframes: dashboard, planner, coach chat, journal, habits, calendar
6. ✅ Integration stubs for wearables + calendar API
7. ✅ Docker + deployment script
