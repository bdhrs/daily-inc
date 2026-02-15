# Product Guidelines - Daily Inc

## Tone and Voice
- **Friendly & Matter-of-Fact:** The app should speak to the user with a helpful, encouraging, yet direct tone. Avoid flowery language or excessive enthusiasm.
- **Action-Oriented:** Messaging (especially notifications) should focus on the task at hand. Example: "Time for Daily Reading!"

## Visual Identity
- **Dark Mode First:** The application prioritizes a dark aesthetic to reduce eye strain and promote a "Zen" or focused environment.
- **Minimalist Layout:** UI elements should be spaced generously, with a focus on high-contrast indicators for status and progress.
- **Consistency:** Adhere to the existing custom dark theme and color palette established in the current codebase.

## Notification (Nag) Behavior
- **Sticky Nags:** All notifications should be persistent (sticky) in the notification drawer. They should remain visible until the user interacts with them or the associated task is marked as completed.
- **System Consistency:** Use standard system notifications for both foreground and background states to ensure the user never misses a nag.
- **Task-Centric:** Each notification must explicitly name the habit it is reminding the user about.

## User Experience (UX)
- **Frictionless Onboarding:** When a user enables a feature requiring platform permissions (like notifications), provide clear, contextual guidance and easy paths to system settings.
- **Privacy First:** All habit data and notification schedules are stored and managed locally on the device.
