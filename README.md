# LiftLog 🏋️

A chat-first gym workout tracker. Log your workouts by describing them naturally.

## Features

- **Chat-First Logging** — Describe your workout: "Bench 135x10, 185x8, 205x6" and it's logged
- **Voice Input** — Speak your workouts (iOS Speech Framework)
- **AI Parsing** — Claude Haiku extracts structured data from natural language
- **Exercise Library** — 50+ exercises across all muscle groups
- **Progress Tracking** — Volume charts, muscle group breakdown, streaks
- **Clean UI** — Red accent, dark mode support

## Screenshots

```
┌─────────────────────────────┐
│       Log Workout           │
│                             │
│ ┌─────────────────────────┐ │
│ │ "Bench press 135x10,    │ │
│ │  185x8, 205x6..."       │ │
│ └─────────────────────────┘ │
│                             │
│   [🎤 Voice]    [↑ Log]     │
│                             │
│   ── Recent ──              │
│   Push Day - 12,500 lbs     │
└─────────────────────────────┘
```

## Tech Stack

- SwiftUI
- SwiftData
- iOS Speech Framework
- Claude Haiku API (optional)
- Swift Charts

## Setup

1. Clone the repo
2. Open `LiftLog.xcodeproj` in Xcode
3. Build and run

### AI Features (Optional)

To enable AI-powered workout parsing:
1. Get an API key from [console.anthropic.com](https://console.anthropic.com)
2. Go to Profile → AI Settings
3. Enter your API key

Cost: ~$0.002 per workout logged

Without an API key, the app falls back to regex-based parsing (less flexible but free).

## Project Structure

```
LiftLog/
├── App/
│   ├── LiftLogApp.swift
│   └── MainTabView.swift
├── Features/
│   ├── Home/
│   │   └── Views/
│   │       ├── ChatHomeView.swift
│   │       └── WorkoutConfirmationView.swift
│   ├── Workouts/
│   │   └── Views/
│   │       └── WorkoutDetailView.swift
│   ├── History/
│   │   └── Views/
│   │       ├── HistoryView.swift
│   │       └── ProgressView.swift
│   ├── Exercises/
│   │   └── Views/
│   │       └── ExercisesView.swift
│   └── Profile/
│       └── Views/
│           └── ProfileView.swift
└── Shared/
    ├── Models/
    │   ├── Workout.swift
    │   ├── Exercise.swift
    │   └── WorkoutSet.swift
    ├── Services/
    │   └── WorkoutParsingService.swift
    ├── Components/
    └── Extensions/
        └── Color+Theme.swift
```

## Example Inputs

The AI understands various formats:

- `"Bench press 135x10, 185x8, 205x6"`
- `"Squats: warmup 135, then 225 for 5x3"`
- `"Pull-ups 3x10, rows 135x12"`
- `"Push day - bench, incline press, flyes, tricep pushdowns"`
- `"Deadlift 315x5, 365x3, 405x1 PR!"`

## License

MIT
