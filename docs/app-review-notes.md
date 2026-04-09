# TempHist — App Review Notes

These notes are intended to help reviewers understand how TempHist works and how to test its key features.

---

## Overview

TempHist shows historical temperature data for any location — today's high/low vs. the historical average, week-by-week trends, monthly patterns, and year-on-year comparisons. The app requires no account or login; it uses Firebase anonymous authentication automatically on first launch.

---

## Test Account / Credentials

No test account is needed. The app signs in anonymously via Firebase on launch and works immediately. Reviewers do not need to create an account or enter any credentials.

---

## Onboarding

On first launch, a 7-screen onboarding flow introduces the app's key concepts:

1. **Welcome** — overview of the app
2. **Day view** — how to read today's temperature vs. the historical average
3. **Tap** — tapping a chart bar shows the exact values for that day/week/month
4. **Average trend** — explains the trend line overlaid on charts
5. **Swipe** — introduces horizontal swipe navigation between time periods
6. **Location** — explains how location is detected and how to change it
7. **Temperature unit** — °C / °F preference, which can be changed at any time

Onboarding can be replayed at any time from the Settings panel (gear icon, top right).

---

## Navigation

The main screen has four time periods navigated by **horizontal swipe**:

| Period | Description |
|--------|-------------|
| Day | Today's temperature vs. the 30-year historical average |
| Week | Last 7 days, each day vs. its historical average |
| Month | Each month of the current year vs. historical monthly averages |
| Year | Each year for the past 50 years vs. the long-term average |

The swipe gesture is demonstrated during onboarding. There are no visible tab buttons — swiping left/right is the primary navigation method.

---

## Location

Location works in two modes:

**GPS (automatic)** — on first launch the app requests "Allow While Using App" location permission. If granted, it detects the nearest city automatically. If the permission is denied, the app falls back to a default location and prompts the user to set one manually.

**Manual selection** — tapping the location name at the top of the screen opens the location selector. It shows:
- Recent locations (previously visited)
- A list of pre-approved popular locations
- A search field for free-text entry of any city

The location indicator uses a colour coding system:
- Green — GPS-detected location
- Blue — manually selected location
- Red — location could not be determined

---

## Cache-First Architecture

Temperature data is fetched from the API on the first view of each time period and cached to disk for up to 7 days. On subsequent visits within a session (or after reopening the app), data may load instantly from cache rather than the network — this is intentional behaviour, not a bug.

Reviewers can force a fresh network fetch by pulling down to refresh on any period screen.

---

## Sharing

The share button (top right on each period screen) does the following:

1. Captures the chart as an image with a description footer baked in
2. Creates a share record on the TempHist API and returns a short URL
3. Opens the iOS share sheet with the URL, allowing the user to share via Messages, Mail, or any other app

Sharing requires an active network connection. The share URL resolves to a web page showing the same chart with Open Graph metadata for rich link previews.

---

## Accessibility

The app relies on Flutter's built-in accessibility support, which provides VoiceOver compatibility and Dynamic Type scaling for standard UI elements. Dedicated accessibility enhancements — including explicit semantic labels for chart elements — are planned for a future release.

---

## Network Requirements

The app requires a network connection for:
- Initial data load for each time period
- Location search (fetching the pre-approved locations list)
- Creating share records

All requests use HTTPS. Cached data is served offline after the first successful load.
