# P2-001 — Enable Week & Month modes in Explore (UI)

**Problem**  
Users can currently browse only Day mode. We need to expose Week and Month modes (rolling windows) in the Explore UI.

**Solution (Scope)**  
- Enable the segmented control options **Week** and **Month** (were disabled in Phase 1).  
- When selected, update the header to show a **series label** (e.g., “Week ending 19 Sep 2025” / “30 days ending 19 Sep 2025”).  
- Hide the Day dots indicator in Week/Month for now.  
- Hook the period change to state (`ExploreCubit.changePeriod`).

**Acceptance Criteria**  
- Segmented control: Day/Week/Month are selectable; the selected pill is visually distinct.  
- On Week/Month selection, the subtitle/series label renders below the date/location pill.  
- Dots indicator is hidden in Week/Month (TODO: future timeline UI).  
- Switching back to Day restores the dots indicator and day labels.

**Test Cases**  
1) Tap Week → series label appears; dots disappear.  
2) Tap Month → series label appears; dots disappear.  
3) Return to Day → dots reappear.  
4) VoiceOver reads period selection and series label correctly.


---

# P2-002 — Models: RollingSeries / RollingStats + mapper

**Problem**  
We need a client-side model for rolling window series (week/month) and a mapper from API JSON to models.

**Solution (Scope)**  
- Add `RollingSeries`, `RollingStats`, `Extremum` classes in `lib/models/`.  
- Implement `mapRolling(Map<String,dynamic>)` that maps API JSON to `RollingSeries` with fields: `anchorDate`, `windowDays`, `years`, `valuesC`, `stats`, `label`, `compareLabel`.

**Acceptance Criteria**  
- New model classes compile and are documented.  
- `mapRolling()` correctly maps the sample payload (see API contract).  
- Null handling: missing values for some years map to `null` entries in `valuesC`.

**Test Cases**  
1) Given a full JSON payload, `mapRolling()` returns expected fields and lengths.  
2) Given missing values, mapper produces `null` entries without throwing.  
3) Trend/rank fields are correctly parsed into `RollingStats`.


---

# P2-003 — Repo: extend WeatherRepo with fetchRolling(...)

**Problem**  
Explore needs a repository method to fetch rolling window data from the backend.

**Solution (Scope)**  
- Extend `WeatherRepo` with:

```dart
Future<Map<String, dynamic>> fetchRolling({
  required double lat,
  required double lon,
  required DateTime anchorLocalDate,
  required ExplorePeriod period, // week | month
});
```

- Provide a temporary stub implementation (returns deterministic sample data) to allow UI development in parallel.

**Acceptance Criteria**  
- Interface compiles; stub returns correct shape (years, values_celsius, stats, label, compareLabel).  
- Later swap-in of real API client only changes the concrete impl, not call sites.

**Test Cases**  
1) Stub returns 50 years of data and non-null stats fields.  
2) Passing `ExplorePeriod.week` results in `windowDays=7` in the payload; `month` → `windowDays=30/31`.


---

# P2-004 — Cache: keyForRolling() + TTL policy

**Problem**  
Rolling series will be reused frequently; we need cache keys and TTL to avoid repeated API calls.

**Solution (Scope)**  
- In `CacheService`, add `keyForRolling(lat, lon, anchor, period)` producing:  
  `roll:{windowDays}:{lat3}:{lon3}:{yyyy-mm-dd}`.  
- Set TTL: 12–24h for both week and month windows.  
- Reuse rounding strategy from daily cache (3 decimal places).

**Acceptance Criteria**  
- Cache key helper exists and matches spec.  
- Rolling fetch path uses cache-first, write-through on miss.  
- TTL respected; expired keys refetch on demand.

**Test Cases**  
1) First request → fetch + put into cache.  
2) Second request same key within TTL → served from cache only.  
3) After TTL, refetch occurs.


---

# P2-005 — Cubit/State: integrate rolling loading + swipeBy() stepping

**Problem**  
ExploreCubit currently loads only Day mode and uses 1-day swipe steps.

**Solution (Scope)**  
- Extend `ExploreState` with `windowDays (int?)`, `seriesLabel (String?)`, `compareLabel (String?)`.  
- In `_loadCurrent()`:
  - Day → use existing daily path.  
  - Week/Month → use cache→`fetchRolling()`→`mapRolling()`→apply to state.  
- Implement `swipeBy(int deltaUnits)`:
  - Day: ±1 day, clamped at today and (Phase 1) last-7-day window.  
  - Week: ±7 days, clamped at today.  
  - Month: ±30 (or 31) days, clamped at today.  
- Maintain the in-flight debounce behavior.

**Acceptance Criteria**  
- Changing period triggers correct data loading and state updates.  
- Swiping in Week moves by 7 days, Month by 30/31.  
- Today clamp prevents future dates.  
- No concurrent loads (debounce).

**Test Cases**  
1) Period = Week, do 3 left swipes → anchor shifts by −21 days total.  
2) Period = Month, right swipe on today → no change.  
3) Rapid swipes → only one in-flight fetch at any time.  
4) Switching locations preserves period+anchor and reloads.


---

# P2-006 — Chart: reuse for rolling series (year vs mean window)

**Problem**  
We need to render rolling series (x=year, y=mean window temp) using the existing chart widget.

**Solution (Scope)**  
- Keep the same chart; feed it `years` + `valuesC`.  
- Show the anchor year’s point with a subtle emphasis if supported (optional).  
- Tooltip: year and value with units.  
- Ensure gaps for `null` values are handled gracefully (no crashes).

**Acceptance Criteria**  
- Day, Week, Month datasets all render without widget changes beyond data injection.  
- No exceptions when `valuesC` contains nulls.

**Test Cases**  
1) Render with complete data → line/bar renders for all points.  
2) Render with sparse data → gaps are tolerated; no crash.  
3) Tooltip shows “{year}: {value} °C”.


---

# P2-007 — Insights for rolling windows (rank, anomaly, extremes, trend)

**Problem**  
Users need context for Week/Month windows similar to Day.

**Solution (Scope)**  
- Populate InsightsRow from `RollingStats`:  
  - Rank label: “{n}th warmest since {firstYear}”  
  - Anomaly vs mean: “{±X.X} °C vs 50-yr avg”  
  - Extremes: “{min.value} °C ({min.year}) • {max.value} °C ({max.year})”  
  - Trend: “{slope} °C/dec”

**Acceptance Criteria**  
- Insights show non-null values when present; cards hide when a value is missing.  
- Units included; rounded to sensible precision (1–2 dp).

**Test Cases**  
1) Full stats → all 4 cards render with correct strings.  
2) Missing min/max → Extremes card omitted; others remain.  
3) Trend rounding shows 2 dp.


---

# P2-008 — A11y & UI polish for rolling: labels, focus, semantics

**Problem**  
Rolling modes add new semantics; ensure accessibility and clarity.

**Solution (Scope)**  
- Header Semantics: include series label after date.  
- Period control: accessible labels reflect selection and availability.  
- Swipe area: announce change on date update (accessibility announcement).  
- Hide dots in Week/Month; keep spacing consistent.

**Acceptance Criteria**  
- Screen reader announces: “Week ending 19 September 2025, London, United Kingdom.”  
- Period control navigable via keyboard/VoiceOver.  
- No visual jumps when toggling period.

**Test Cases**  
1) Screen reader focus on header reads full label.  
2) Toggling to Month updates announcement.  
3) No layout jumps when dots hide/show.


---

# P2-009 — Backend contract doc for /history/rolling (client-facing)

**Problem**  
We need a stable contract between app and API for rolling windows.

**Solution (Scope)**  
- Create `/docs/api-rolling.md` in this repo describing the endpoint used by the app:

```http
GET /history/rolling?loc={lat,lon}&anchor=YYYY-MM-DD&period=week|month&windowDays=7|30&minYear=1975
```

- Response shape (fields & types), examples, units, rounding.  
- Caching expectations and error codes.  
- Note that server computes windows by **location local date**.

**Acceptance Criteria**  
- Markdown file exists with example JSON and field explanations.  
- Decision recorded: 30-day window for Month (or 31 if chosen), and how we label.

**Test Cases**  
1) File renders with code fences and examples.  
2) Another engineer can implement the client using this doc alone.


---

# P2-010 — QA test plan: Explore Week/Month

**Problem**  
We need a repeatable checklist to validate Week/Month functionality across devices and time zones.

**Solution (Scope)**  
- Add `/docs/qa-explore-phase2.md` with scenarios:
  - Period switching Day↔Week↔Month.
  - Swiping step sizes and clamping at today.
  - Location changes preserve anchor and period.
  - Cache hit/miss behavior.
  - Offline/cached paths.
  - Accessibility reads and announcements.
  - Sparse data years and null handling.

**Acceptance Criteria**  
- QA doc covers iOS light/dark mode, Dynamic Type, VoiceOver.  
- Includes steps to simulate API error and confirm retry flow.

**Test Cases**  
1) Doc includes at least 10 scenarios with expected outcomes.  
2) Team can follow the doc and reproduce results.


---
