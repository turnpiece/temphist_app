# Google Play listing draft — TempHist 1.4.0

Adapted from the live App Store description (ASC, 1.4.0). Play limits: app name 30, short description 80, full description 4000 characters.

## App name (30 max)

TempHist: Temperature History

## Short description (80 max)

Search any city and see how today's temperature compares with the past 50 years.

## Full description (en-GB)

Is it warmer than usual? Search any city in the world and find out how today, this week, this month and this year compare with the past 50 years.

SEARCH ANYWHERE
Type the name of any town or city and see its temperature history straight away. Use your current location, go back to places you've visited, or choose from popular cities around the world.

FOUR WAYS TO LOOK
• Today – today's temperature against the same date in each of the last 50 years
• Week – the past 7 days against the same week in each year
• Month – the past month against the same month in each year
• Year – the past 12 months against the same 12-month period in each year
Tap or swipe between them.

SEE THE TREND
Every chart shows the average and a trend line, with the rate of change per decade and its margin of error, so you can see whether a place is warming or cooling over time. Tap any bar to see exactly how far that year was above or below average.

SIMPLE AND PRIVATE
• No account or sign-in
• °C or °F, whenever you like
• Share any view as a link to a web page showing the same chart
• Your location is used only while the app is open, and the app works fully without it

WHERE THE DATA COMES FROM
Temperatures come from the ERA5 reanalysis produced by ECMWF for the Copernicus Climate Change Service, delivered through Open-Meteo, and go back to 1940. Values are modelled estimates for a grid cell about 25 km across, not readings from a single weather station, so they can differ from local station records.

Weather data by Open-Meteo.com (CC BY 4.0).

## Play Console fields

| Field | Value |
|---|---|
| Category | Weather |
| Website | https://temphist.com |
| Support / contact | https://turnpiece.com/support (add a contact email in Play Console) |
| Privacy policy | https://temphist.com/privacy/app |
| Phone screenshots | `assets/promos/png/1.4/android-phone/` (01–05 and 07; 06 shows "England" as Current) |
| Release notes (production, first release) | Search any city in the world and see how today, this week, this month and this year compare with the past 50 years. |

## Graphics

In `assets/promos/png/1.4/android-play/`, made by `scripts/compose_play_graphics.py`:

- `icon-512.png`: 512×512 32-bit PNG, full square (Play applies the mask), from the iOS 1024 icon.
- `icon-512-launcher-match.png`: the same size drawn from the Android adaptive icon as the launcher shows it. The bars are much smaller, so it reads poorly at store size.
- `feature-graphic-1024x500.png`: headline plus the Today and Year views.
