
# Project Blueprint

## Overview

This document outlines the style, design, and features of the Anzen application. It serves as a single source of truth for the project's current state and future development plans.

## Style and Design

The application will follow Material Design 3 principles to ensure a modern, accessible, and consistent user experience.

*   **App Name**: The app's name has been updated to "Anzen," which means "safety" in Japanese.
*   **Logo Concept: "The Guardian Shield"**:
    *   **Visual**: A stylized letter 'A' shaped like a modern, sleek shield. The crossbar of the 'A' is a gentle, upward-curving line, suggesting a supportive embrace or a subtle smile. Inside the top of the 'A', there is a small, soft glow, symbolizing hope and a safe space.
    *   **Color Palette**:
        *   Primary: Deep teal (`#008080`) for the main shield shape (calmness, strength, trust).
        *   Accent: Warm coral (`#FF7F50`) for the curving crossbar and inner glow (warmth, humanity, empowerment).
        *   Text: Dark charcoal (`#333333`) for the app name.
    *   **Typography**: A clean, sans-serif font like **Montserrat** or **Lato**.
*   **Theming**: A centralized theme using `ColorScheme.fromSeed` will be implemented.
*   **Typography**: The `google_fonts` package will be used for custom, readable fonts.
*   **Layout**: The UI will be responsive and adapt to various screen sizes.

## Features

### Implemented Features

*   **Firebase Realtime Database Integration**: The app connects to Firebase Realtime Database to listen for status changes.
*   **Status Display**: The app displays the current status (e.g., "SAFE" or "ALERT") based on the value in the database.
*   **Direct SMS Alert**:
    *   The app can send SMS alerts with location to a designated contact.
    *   It uses the `another_telephony` package for this functionality.
    *   It requests SMS and location permissions at runtime.

### Next Steps

*   **Registration/Onboarding**: Implement a user registration and onboarding process in a future version.
*   **App Icon Implementation**: Create and add the app icon files to the Android and iOS projects.

