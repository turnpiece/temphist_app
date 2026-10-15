# TempHist — APP REVIEW NOTES

TempHist answers one question: **how does the temperature today, this week, this month or this year compare with the same period in every year back to 1940?** It works for any location in the world, which you can search for by name.

No account, login or test credentials are needed. The app signs in anonymously in the background and works immediately.

---

## 60-second walkthrough

1. **Launch the app.** A short 7-screen introduction appears on first launch. Tap **Get Started** (or **Skip**).
2. **Location permission.** iOS asks whether TempHist may use your location while the app is in use. Either answer works:
   - **Allow While Using App** — the app detects the nearest city and opens on it.
   - **Don't Allow** — the **Choose your location** selector opens straight away and cannot be dismissed, so the next step is to pick a city.
3. **Pick or search for a city.** In the selector, type any city name in the search box (for example _Nairobi_, _Sydney_ or _Reykjavik_) and tap a result. Search covers locations worldwide, not a fixed list.
4. **Read the chart.** Each bar is one year's temperature for the date shown, with the historical average and trend line overlaid. Tap any bar to see its exact value and how far it was above or below the average.
5. **Switch time period.** Tap the **Today · Week · Month · Year** tabs at the top, or swipe left and right.
6. **Change units.** Tap the **gear icon** (top right), then switch between **°C** and **°F**. The same menu has **Change location**, the **Help** page and the **Privacy policy**.
7. **Share.** Tap the **share icon** (top right, next to the gear). The app creates a link to a web page showing the same chart and opens the iOS share sheet.

---

## What the app does

- **Four views of the same question.** Today, Week, Month and Year each compare the current period with the same period in each of the last 51 years (this year and the 50 before it).
- **Worldwide location search.** Search any city by name. The selector also shows your current location, places you have visited, and popular cities, and remembers places you have chosen.
- **Average and trend.** An average line and a trend line, with the rate of change per decade and an error margin, show whether a period is warming or cooling over time.
- **°C / °F.** Switchable at any time and remembered.
- **Sharing.** Each view can be shared as a link to a web page that renders the same chart, with a title and description shown in link previews.
- **Help page.** Explains how to read the chart, how the numbers are calculated and where the data comes from.

| Period | What each year's bar is                          |
| ------ | ------------------------------------------------ |
| Today  | The mean temperature on that date                |
| Week   | The mean of the 7 days ending on that date       |
| Month  | The mean of the 31 days ending on that date      |
| Year   | The mean of the 365 days ending on that date     |

---

## Data

Temperatures are the **ERA5 reanalysis** produced by ECMWF for the Copernicus Climate Change Service, delivered through [Open-Meteo](https://open-meteo.com) (CC BY 4.0). The record starts in 1940. The newest few days come from Open-Meteo's forecast model. Attribution appears on the data screens and in more detail on the Help page.

---

## Location and privacy

- Location permission is **When In Use** only. The app does not use background location.
- The detected city is sent to the TempHist API to fetch data and is saved on the device so the app opens at the most recent location.
- The app works fully without location permission: the user simply chooses or searches for a city.
- Firebase anonymous authentication and Crashlytics are used. There is no advertising and no tracking.
- The privacy policy is at https://temphist.com/privacy/app and is linked in the app under Settings.

---

## Caching and refresh

Fetched data is cached on the device for 24 hours, so a view can open instantly without a network request. This is intentional. Pull down on any period screen to force a fresh fetch.

---

## Network

A network connection is required for the first load of each view, for location search and for creating share links. All requests use HTTPS. Cached data remains available offline.

---

## Accessibility

The location name, the period tabs, and the share and settings buttons are labelled for VoiceOver, and most text follows the system text size setting.

---

## Devices

TempHist runs on iPhone and iPad.
