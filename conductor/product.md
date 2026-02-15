# Initial Concept
The user wants to add smart notifications (nags) that respect item intervals and only fire on due days. The project is an existing Flutter habit tracker called Daily Inc.

# Product Guide - Daily Inc

## Product Vision
Daily Inc is a highly focused personal habit tracker designed for the creator and a broad range of users including meditators, yoga practitioners, fitness enthusiasts, and students. The app’s core purpose is to facilitate incremental daily improvement through a variety of tracking methods (Minutes, Reps, Check, Percentage).

## Core Goals
- **Consistency through Incremental Progress:** Automatically adjust daily targets based on user consistency and predefined rules to ensure sustainable growth.
- **Visual Progress Visualization:** Provide clear, high-level category graphs to help users visualize their journey and maintain motivation over time.
- **Distraction-Free Experience:** Offer a minimalist and focused interface for timing and logging activities, minimizing friction in the daily routine.
- **Smart Reminders (Nags):** Proactively remind users when it is time to perform a habit, specifically on days when that habit is due.

## Key Features
- **Dynamic Task Types:** support for MINUTES (timer-based), REPS (incrementing counts), CHECK (binary completion), and PERCENTAGE (progress tracking).
- **Smart Progression Logic:** Targets that automatically increment or pause based on historical performance and user-defined duration/goals.
- **Intelligent Notification System:**
  - Per-item "Nag" controls with custom times and messages.
  - Notifications fire only on "Due Days" (respecting daily/weekday intervals).
  - Seamless permission handling to guide users through platform-specific requirements.
- **Data Portability:** Local-first approach with JSON import/export capabilities.
