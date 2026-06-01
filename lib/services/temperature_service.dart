import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/period_temperature_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/debug_utils.dart';
import '../constants/app_constants.dart';
import '../models/app_exceptions.dart';
import 'auth_service.dart';
export '../models/app_exceptions.dart';

class TemperatureService {
  static const int _kMaxCacheEntries = 20;
  static final Map<String, PeriodTemperatureData> _periodCache = {};
  static List<String>? _popularLocationsCache;
  // Keyed by the full "City, Country" location string → ISO 3166-1 alpha-2 CC.
  // Populated alongside [_popularLocationsCache] on first fetch.
  static Map<String, String>? _locationCountryCodeCache;
  // Keyed by country name (as returned by the API) → ISO 3166-1 alpha-2 CC.
  // Used as a fallback for GPS location strings that don't match the popular
  // list exactly (e.g. "Dubai, United Arab Emirates" or
  // "London, Greater London, United Kingdom").
  static Map<String, String>? _countryNameToCodeCache;
  // Keyed by display string → canonical API location id (e.g. "london").
  // Populated from fetchPopularLocations() and searchLocations() responses.
  static final Map<String, String> _locationIdCache = {};
  // Keyed by display string → raw location fields {name, admin1?, country_code}.
  // Populated from searchLocations() so we can submit without a canonical id.
  static final Map<String, Map<String, String>> _locationRawDataCache = {};
  // Keyed by display string → IANA timezone identifier (e.g. "America/Los_Angeles").
  // Populated from fetchPopularLocations() and searchLocations() responses.
  static final Map<String, String> _locationTimezoneCache = {};
  // Session-level dedup: last submitted key (canonical id or display string).
  static String? _lastSubmittedKey;

  /// Static fallback map of English country names → ISO 3166-1 alpha-2 codes.
  ///
  /// Used by [countryCodeFor] when the API-sourced [_countryNameToCodeCache]
  /// is unavailable (e.g. network failure) or does not cover the country.
  /// Includes all ISO 3166-1 entries plus common aliases (Turkey/Türkiye etc.).
  static const Map<String, String> _kCountryNameToCode = {
    'Afghanistan': 'AF', 'Albania': 'AL',
    'Algeria': 'DZ', 'American Samoa': 'AS',
    'Andorra': 'AD', 'Angola': 'AO',
    'Anguilla': 'AI', 'Antarctica': 'AQ',
    'Antigua and Barbuda': 'AG', 'Argentina': 'AR',
    'Armenia': 'AM', 'Aruba': 'AW',
    'Australia': 'AU', 'Austria': 'AT',
    'Azerbaijan': 'AZ', 'Bahamas': 'BS',
    'Bahrain': 'BH', 'Bangladesh': 'BD',
    'Barbados': 'BB', 'Belarus': 'BY',
    'Belgium': 'BE', 'Belize': 'BZ',
    'Benin': 'BJ', 'Bermuda': 'BM',
    'Bhutan': 'BT', 'Bolivia': 'BO',
    'Bolivia, Plurinational State of': 'BO', 'Bonaire, Sint Eustatius and Saba': 'BQ',
    'Bosnia and Herzegovina': 'BA', 'Botswana': 'BW',
    'Bouvet Island': 'BV', 'Brazil': 'BR',
    'British Indian Ocean Territory': 'IO', 'Brunei': 'BN',
    'Brunei Darussalam': 'BN', 'Bulgaria': 'BG',
    'Burkina Faso': 'BF', 'Burundi': 'BI',
    'Cabo Verde': 'CV', 'Cambodia': 'KH',
    'Cameroon': 'CM', 'Canada': 'CA',
    'Cape Verde': 'CV', 'Cayman Islands': 'KY',
    'Central African Republic': 'CF', 'Chad': 'TD',
    'Chile': 'CL', 'China': 'CN',
    'Christmas Island': 'CX', 'Cocos (Keeling) Islands': 'CC',
    'Colombia': 'CO', 'Comoros': 'KM',
    'Congo': 'CG', 'Congo, The Democratic Republic of the': 'CD',
    'Cook Islands': 'CK', 'Costa Rica': 'CR',
    'Croatia': 'HR', 'Cuba': 'CU',
    'Curaçao': 'CW', 'Cyprus': 'CY',
    'Czech Republic': 'CZ', 'Czechia': 'CZ',
    "Côte d'Ivoire": 'CI', 'Democratic Republic of the Congo': 'CD',
    'Denmark': 'DK', 'Djibouti': 'DJ',
    'Dominica': 'DM', 'Dominican Republic': 'DO',
    'East Timor': 'TL', 'Ecuador': 'EC',
    'Egypt': 'EG', 'El Salvador': 'SV',
    'Equatorial Guinea': 'GQ', 'Eritrea': 'ER',
    'Estonia': 'EE', 'Eswatini': 'SZ',
    'Ethiopia': 'ET', 'Falkland Islands (Malvinas)': 'FK',
    'Faroe Islands': 'FO', 'Fiji': 'FJ',
    'Finland': 'FI', 'France': 'FR',
    'French Guiana': 'GF', 'French Polynesia': 'PF',
    'French Southern Territories': 'TF', 'Gabon': 'GA',
    'Gambia': 'GM', 'Georgia': 'GE',
    'Germany': 'DE', 'Ghana': 'GH',
    'Gibraltar': 'GI', 'Greece': 'GR',
    'Greenland': 'GL', 'Grenada': 'GD',
    'Guadeloupe': 'GP', 'Guam': 'GU',
    'Guatemala': 'GT', 'Guernsey': 'GG',
    'Guinea': 'GN', 'Guinea-Bissau': 'GW',
    'Guyana': 'GY', 'Haiti': 'HT',
    'Heard Island and McDonald Islands': 'HM', 'Holy See (Vatican City State)': 'VA',
    'Honduras': 'HN', 'Hong Kong': 'HK',
    'Hungary': 'HU', 'Iceland': 'IS',
    'India': 'IN', 'Indonesia': 'ID',
    'Iran': 'IR', 'Iran, Islamic Republic of': 'IR',
    'Iraq': 'IQ', 'Ireland': 'IE',
    'Isle of Man': 'IM', 'Israel': 'IL',
    'Italy': 'IT', 'Ivory Coast': 'CI',
    'Jamaica': 'JM', 'Japan': 'JP',
    'Jersey': 'JE', 'Jordan': 'JO',
    'Kazakhstan': 'KZ', 'Kenya': 'KE',
    'Kiribati': 'KI', "Korea, Democratic People's Republic of": 'KP',
    'Korea, Republic of': 'KR', 'Kuwait': 'KW',
    'Kyrgyzstan': 'KG', "Lao People's Democratic Republic": 'LA',
    'Laos': 'LA', 'Latvia': 'LV',
    'Lebanon': 'LB', 'Lesotho': 'LS',
    'Liberia': 'LR', 'Libya': 'LY',
    'Liechtenstein': 'LI', 'Lithuania': 'LT',
    'Luxembourg': 'LU', 'Macao': 'MO',
    'Macau': 'MO', 'Madagascar': 'MG',
    'Malawi': 'MW', 'Malaysia': 'MY',
    'Maldives': 'MV', 'Mali': 'ML',
    'Malta': 'MT', 'Marshall Islands': 'MH',
    'Martinique': 'MQ', 'Mauritania': 'MR',
    'Mauritius': 'MU', 'Mayotte': 'YT',
    'Mexico': 'MX', 'Micronesia': 'FM',
    'Micronesia, Federated States of': 'FM', 'Moldova': 'MD',
    'Moldova, Republic of': 'MD', 'Monaco': 'MC',
    'Mongolia': 'MN', 'Montenegro': 'ME',
    'Montserrat': 'MS', 'Morocco': 'MA',
    'Mozambique': 'MZ', 'Myanmar': 'MM',
    'Namibia': 'NA', 'Nauru': 'NR',
    'Nepal': 'NP', 'Netherlands': 'NL',
    'New Caledonia': 'NC', 'New Zealand': 'NZ',
    'Nicaragua': 'NI', 'Niger': 'NE',
    'Nigeria': 'NG', 'Niue': 'NU',
    'Norfolk Island': 'NF', 'North Korea': 'KP',
    'North Macedonia': 'MK', 'Northern Mariana Islands': 'MP',
    'Norway': 'NO', 'Oman': 'OM',
    'Pakistan': 'PK', 'Palau': 'PW',
    'Palestine': 'PS', 'Palestine, State of': 'PS',
    'Panama': 'PA', 'Papua New Guinea': 'PG',
    'Paraguay': 'PY', 'Peru': 'PE',
    'Philippines': 'PH', 'Pitcairn': 'PN',
    'Poland': 'PL', 'Portugal': 'PT',
    'Puerto Rico': 'PR', 'Qatar': 'QA',
    'Republic of Korea': 'KR', 'Republic of the Congo': 'CG',
    'Romania': 'RO', 'Russia': 'RU',
    'Russian Federation': 'RU', 'Rwanda': 'RW',
    'Réunion': 'RE', 'Saint Barthélemy': 'BL',
    'Saint Helena, Ascension and Tristan da Cunha': 'SH', 'Saint Kitts and Nevis': 'KN',
    'Saint Lucia': 'LC', 'Saint Martin (French part)': 'MF',
    'Saint Pierre and Miquelon': 'PM', 'Saint Vincent and the Grenadines': 'VC',
    'Samoa': 'WS', 'San Marino': 'SM',
    'Sao Tome and Principe': 'ST', 'Saudi Arabia': 'SA',
    'Senegal': 'SN', 'Serbia': 'RS',
    'Seychelles': 'SC', 'Sierra Leone': 'SL',
    'Singapore': 'SG', 'Sint Maarten (Dutch part)': 'SX',
    'Slovakia': 'SK', 'Slovenia': 'SI',
    'Solomon Islands': 'SB', 'Somalia': 'SO',
    'South Africa': 'ZA', 'South Georgia and the South Sandwich Islands': 'GS',
    'South Korea': 'KR', 'South Sudan': 'SS',
    'Spain': 'ES', 'Sri Lanka': 'LK',
    'Sudan': 'SD', 'Suriname': 'SR',
    'Svalbard and Jan Mayen': 'SJ', 'Swaziland': 'SZ',
    'Sweden': 'SE', 'Switzerland': 'CH',
    'Syria': 'SY', 'Syrian Arab Republic': 'SY',
    'Taiwan': 'TW', 'Taiwan, Province of China': 'TW',
    'Tajikistan': 'TJ', 'Tanzania': 'TZ',
    'Tanzania, United Republic of': 'TZ', 'Thailand': 'TH',
    'Timor-Leste': 'TL', 'Togo': 'TG',
    'Tokelau': 'TK', 'Tonga': 'TO',
    'Trinidad and Tobago': 'TT', 'Tunisia': 'TN',
    'Turkey': 'TR', 'Turkmenistan': 'TM',
    'Turks and Caicos Islands': 'TC', 'Tuvalu': 'TV',
    'Türkiye': 'TR', 'Uganda': 'UG',
    'Ukraine': 'UA', 'United Arab Emirates': 'AE',
    'United Kingdom': 'GB', 'United States': 'US',
    'United States Minor Outlying Islands': 'UM', 'United States of America': 'US',
    'Uruguay': 'UY', 'Uzbekistan': 'UZ',
    'Vanuatu': 'VU', 'Venezuela': 'VE',
    'Venezuela, Bolivarian Republic of': 'VE', 'Viet Nam': 'VN',
    'Vietnam': 'VN', 'Virgin Islands, British': 'VG',
    'Virgin Islands, U.S.': 'VI', 'Wallis and Futuna': 'WF',
    'Western Sahara': 'EH', 'Yemen': 'YE',
    'Zambia': 'ZM', 'Zimbabwe': 'ZW',
    'Åland Islands': 'AX',
  };
  final String apiBaseUrl;

  /// Clears all cached period data. Call on refresh so stale data is not served.
  static void clearCache() {
    _periodCache.clear();
  }

  /// Writes [value] to the cache under [key], evicting the oldest entry first
  /// if the cache has reached [_kMaxCacheEntries].
  static void _writeCache(String key, PeriodTemperatureData value) {
    if (_periodCache.length >= _kMaxCacheEntries && !_periodCache.containsKey(key)) {
      _periodCache.remove(_periodCache.keys.first);
    }
    _periodCache[key] = value;
  }

  /// Removes a single entry from the in-memory cache so the next call to
  /// [fetchPeriodData] with the same parameters goes to the network.
  static void evictCacheEntry(
    String period,
    String location,
    String identifier, {
    String? unitGroup,
    String? localToday,
  }) {
    final todaySuffix = localToday != null ? '|$localToday' : '';
    final unitSuffix =
        (unitGroup != null && unitGroup != 'celsius') ? '|$unitGroup' : '';
    final cacheKey = '${_apiPeriodPath(period)}|$location|$identifier$todaySuffix$unitSuffix';
    _periodCache.remove(cacheKey);
  }

  /// Fetches the list of popular locations from the API.
  ///
  /// Result is cached in memory for the lifetime of the app so repeated
  /// sheet opens do not make additional network calls.
  /// Throws on network or auth failure — callers should handle and fall back.
  Future<List<String>> fetchPopularLocations() async {
    // Return early only when all derived caches are also populated, so a
    // hot-reload that adds new caches doesn't silently skip populating them.
    if (_popularLocationsCache != null && _locationCountryCodeCache != null) {
      return _popularLocationsCache!;
    }

    final token = await getAuthToken();
    final url = Uri.parse('$apiBaseUrl/v1/locations/popular');

    DebugUtils.logLazy(() => 'Fetching popular locations: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: kApiTimeoutSeconds));

    DebugUtils.logLazy(() =>
        'Popular locations response: ${response.statusCode} — ${response.body}');

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'v1/locations/popular');
    }

    final data = jsonDecode(response.body);
    final List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map && data['locations'] is List) {
      raw = data['locations'] as List;
    } else {
      throw ApiException(0, 'Unexpected format from v1/locations/popular');
    }

    // Build "City, Country" strings matching the format used throughout the app.
    // The API returns rich objects; we use name + country_name (e.g.
    // "Auckland, New Zealand"). toList() forces eager evaluation so any errors
    // surface here rather than propagating lazily to the caller.
    // We also capture country_code into [_locationCountryCodeCache] so that
    // flag emojis can be displayed without an extra network call.
    final ccMap = <String, String>{};
    final countryNameMap = <String, String>{};
    _popularLocationsCache = raw.map<String>((e) {
      if (e is String) return e;
      if (e is Map) {
        final name = e['name']?.toString() ?? '';
        final country = e['country_name']?.toString() ?? '';
        final cc = e['country_code']?.toString() ?? '';
        final id = e['id']?.toString() ?? '';
        if (name.isNotEmpty && country.isNotEmpty) {
          final loc = '$name, $country';
          if (cc.length == 2) {
            ccMap[loc] = cc.toUpperCase();
            // Also map "United Arab Emirates" → "AE" etc. for GPS lookups.
            countryNameMap[country] = cc.toUpperCase();
          }
          if (id.isNotEmpty) {
            _locationIdCache[loc] = id;
          } else {
            DebugUtils.logLazy(() => 'fetchPopularLocations: no id field for "$loc" — selection will not be submitted');
          }
          final tzStr = e['timezone']?.toString() ?? '';
          if (tzStr.isNotEmpty) _locationTimezoneCache[loc] = tzStr;
          return loc;
        }
        // Fallback for unexpected shape
        return (e['location'] ?? name).toString();
      }
      return e.toString();
    }).where((s) => s.isNotEmpty).toList();
    _locationCountryCodeCache = ccMap;
    _countryNameToCodeCache = countryNameMap;

    return _popularLocationsCache!;
  }

  /// Search for locations matching [query] (min 2 characters).
  ///
  /// Delegates to the API's `/v1/locations/search` endpoint, which uses the
  /// Mapbox Geocoding API when configured and falls back to the popular
  /// list in dev/CI environments.
  ///
  /// Returns up to 10 location strings of the form:
  ///   "City, State, Country"   (when a state/province is known)
  ///   "City, Country"          (otherwise)
  ///
  /// Also caches country codes for any returned locations so that flag emojis
  /// work without requiring a separate popular-list fetch.
  Future<List<String>> searchLocations(String query) async {
    if (query.trim().length < 2) return [];

    final token = await getAuthToken();
    final url = Uri.parse(
      '$apiBaseUrl/v1/locations/search'
      '?q=${Uri.encodeQueryComponent(query.trim())}&limit=10',
    );

    DebugUtils.logLazy(() => 'Searching locations: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: kApiTimeoutSeconds));

    DebugUtils.logLazy(() =>
        'Location search response: ${response.statusCode} — ${response.body}');

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'v1/locations/search');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> raw =
        data['locations'] as List<dynamic>? ?? const [];

    // Ensure caches exist so countryCodeFor() works for search results.
    _locationCountryCodeCache ??= {};
    _countryNameToCodeCache ??= {};

    final List<String> results = [];
    for (final item in raw) {
      if (item is! Map) continue;
      final name = item['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final admin1 = item['admin1']?.toString() ?? '';
      final countryName = item['country_name']?.toString() ?? '';
      final countryCode = item['country_code']?.toString() ?? '';
      final id = item['id']?.toString() ?? '';
      if (countryName.isEmpty) continue;

      // Build location string: include admin1 only when it adds disambiguation.
      final String loc;
      if (admin1.isNotEmpty && admin1 != name && admin1 != countryName) {
        loc = '$name, $admin1, $countryName';
      } else {
        loc = '$name, $countryName';
      }

      results.add(loc);

      // Cache country code so flags render without a separate API call.
      if (countryCode.length == 2) {
        _locationCountryCodeCache![loc] = countryCode.toUpperCase();
        _countryNameToCodeCache![countryName] = countryCode.toUpperCase();
      }
      // Cache canonical id so submitLocationSelection() can use it when available.
      if (id.isNotEmpty) {
        _locationIdCache[loc] = id;
      }
      // Always cache raw fields so we can submit without a canonical id.
      final rawData = <String, String>{
        'name': name,
        'country_code': countryCode,
      };
      if (admin1.isNotEmpty) rawData['admin1'] = admin1;
      _locationRawDataCache[loc] = rawData;
      // Cache IANA timezone for location-aware date calculations.
      final tzStr = item['timezone']?.toString() ?? '';
      if (tzStr.isNotEmpty) _locationTimezoneCache[loc] = tzStr;
    }

    return results;
  }

  /// Returns the canonical API location id for [displayLocation], or null.
  ///
  /// First tries an exact match in [_locationIdCache] (populated when
  /// [fetchPopularLocations] or [searchLocations] is called). Falls back to a
  /// city-name fuzzy match so GPS strings like "London, Greater London, United
  /// Kingdom" resolve to the same id as "London, United Kingdom". The mapping
  /// is written into the cache on a fuzzy hit so subsequent lookups are O(1).
  static String? canonicalIdFor(String displayLocation) {
    final exact = _locationIdCache[displayLocation];
    if (exact != null) return exact;

    final city = displayLocation.split(',').first.trim().toLowerCase();
    for (final entry in _locationIdCache.entries) {
      if (entry.key.split(',').first.trim().toLowerCase() == city) {
        _locationIdCache[displayLocation] = entry.value;
        return entry.value;
      }
    }
    return null;
  }

  /// Returns the IANA timezone identifier for [location], or null if unknown.
  ///
  /// Populated when [fetchPopularLocations] or [searchLocations] is called.
  /// Returns null for GPS-detected locations (which fall back to device time).
  static String? timezoneFor(String location) =>
      _locationTimezoneCache[location];

  /// Seed [_locationIdCache] with [entries] for unit tests.
  ///
  /// Also resets [_lastSubmittedKey] so session-dedup state is clean.
  @visibleForTesting
  static void seedLocationIdCacheForTesting(Map<String, String> entries) {
    _locationIdCache
      ..clear()
      ..addAll(entries);
    _locationRawDataCache.clear();
    _lastSubmittedKey = null;
  }

  /// Seed [_locationTimezoneCache] with [entries] for unit tests.
  @visibleForTesting
  static void seedLocationTimezoneCacheForTesting(Map<String, String> entries) {
    _locationTimezoneCache
      ..clear()
      ..addAll(entries);
  }

  /// Returns the ISO 3166-1 alpha-2 country code for [location], or null if
  /// unknown.
  ///
  /// First tries an exact match against the popular list (e.g.
  /// "Auckland, New Zealand" → "NZ").  If that fails, extracts the last
  /// comma-segment and looks it up as a country name — this handles GPS
  /// strings like "London, Greater London, United Kingdom" and
  /// "Dubai, United Arab Emirates" that aren't in the popular list.
  ///
  /// Only populated after [fetchPopularLocations] has been called.
  static String? countryCodeFor(String location) {
    final exact = _locationCountryCodeCache?[location];
    if (exact != null) return exact;

    // Fallback: use the last comma-segment as the country name.
    final parts = location.split(',');
    if (parts.length < 2) return null;
    final lastSegment = parts.last.trim();

    // Try the API-sourced cache first, then fall back to the hardcoded map so
    // GPS strings always get a flag even when fetchPopularLocations has not been
    // called or the API is unavailable.
    return _countryNameToCodeCache?[lastSegment] ?? _kCountryNameToCode[lastSegment];
  }

  /// Converts a 2-letter ISO 3166-1 alpha-2 country code to a Unicode flag
  /// emoji using Regional Indicator Symbol letters (U+1F1E6–U+1F1FF).
  /// Returns an empty string for invalid or unsupported codes.
  static String flagEmoji(String countryCode) {
    if (countryCode.length != 2) return '';
    // Regional Indicator A = U+1F1E6; Latin A = 0x41. Offset every letter.
    const int base = 0x1F1E6 - 0x41;
    return String.fromCharCodes(
      countryCode.toUpperCase().codeUnits.map((c) => c + base),
    );
  }

  /// Submit a location selection signal to `POST /v1/locations/selections`.
  ///
  /// Prefers submitting a canonical [location_id] when cached. Falls back to
  /// submitting raw fields (name, admin1, country_code) from [_locationRawDataCache]
  /// for locations returned by search but without a canonical id.
  ///
  /// Session-level dedup: skips if the same location was already submitted this
  /// session. Failures are always swallowed — this must never degrade the
  /// core weather experience.
  Future<void> submitLocationSelection(String displayLocation) async {
    DebugUtils.logLazy(() => 'submitLocationSelection: called with "$displayLocation"');
    if (displayLocation.isEmpty) return;

    final locationId = canonicalIdFor(displayLocation);
    final submissionKey = locationId ?? displayLocation;

    if (submissionKey == _lastSubmittedKey) {
      DebugUtils.logLazy(() => 'submitLocationSelection: skipping "$submissionKey" — already submitted this session');
      return;
    }

    final Map<String, dynamic> payload;
    if (locationId != null) {
      DebugUtils.logLazy(() => 'submitLocationSelection: submitting by id "$locationId"');
      payload = {'location_id': locationId};
    } else {
      final rawData = _locationRawDataCache[displayLocation];
      if (rawData == null) {
        DebugUtils.logLazy(() => 'submitLocationSelection: skipping "$displayLocation" — no id or raw data cached');
        return;
      }
      DebugUtils.logLazy(() => 'submitLocationSelection: submitting raw fields for "$displayLocation"');
      payload = rawData;
    }

    _lastSubmittedKey = submissionKey;

    try {
      final token = await getAuthToken();
      final response = await http.post(
        Uri.parse('$apiBaseUrl/v1/locations/selections'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: kApiTimeoutSeconds));
      DebugUtils.logLazy(() => 'submitLocationSelection: submitted "$submissionKey" → HTTP ${response.statusCode}');
    } catch (e) {
      DebugUtils.logLazy(() => 'submitLocationSelection: POST failed (swallowed): $e');
    }
  }

  TemperatureService({
    String? apiBaseUrl,
  }) : apiBaseUrl = apiBaseUrl ?? kApiBaseUrl;

  /// Fetch today's forecast temperature for [location].
  ///
  /// Returns the temperature in the requested unit, or null on any error.
  /// Used for the silent daily-period resume check — lightweight single value,
  /// no AI summary generation.
  Future<double?> fetchForecast(
    String location, {
    String? unitGroup,
  }) async {
    try {
      final token = await getAuthToken();
      final encodedLocation = Uri.encodeComponent(location);
      final unit = unitGroup ?? 'celsius';
      final params = unit != 'celsius' ? '?unit_group=$unit' : '';
      final url = Uri.parse('$apiBaseUrl/forecast/$encodedLocation$params');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: kApiTimeoutSeconds));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data.containsKey('error')) return null;
      final temp = data['average_temperature'] as num?;
      return temp?.toDouble();
    } catch (e) {
      DebugUtils.logLazy(() => 'fetchForecast failed: $e');
      return null;
    }
  }

  /// Retrieve Firebase ID token for authentication with retry logic
  Future<String> getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        DebugUtils.logLazy(() => '⚠️ No Firebase user found, attempting to sign in...');
        await AuthService.signInAnonymously(maxRetries: 2);
        final newUser = FirebaseAuth.instance.currentUser;
        if (newUser == null) {
          throw const AuthException('no user after sign-in');
        }
        final token = await newUser.getIdToken();
        if (token == null) throw const AuthException('null ID token');
        return token;
      }

      final token = await user.getIdToken();
      if (token == null) throw const AuthException('null ID token');
      return token;
    } on AuthException {
      rethrow;
    } catch (e) {
      DebugUtils.logLazy(() => '❌ Firebase authentication failed: $e');
      throw AuthException('Firebase auth failed', e);
    }
  }

  /// Build a v1 records URL, optionally appending query parameters.
  Uri _buildV1Url(
    String apiPeriod,
    String encodedLocation,
    String identifier, {
    String? suffix,
    String? unitGroup,
    String? localToday,
  }) {
    final path = suffix != null
        ? '$apiBaseUrl/v1/records/$apiPeriod/$encodedLocation/$identifier/$suffix'
        : '$apiBaseUrl/v1/records/$apiPeriod/$encodedLocation/$identifier';
    final base = Uri.parse(path);
    final params = <String, String>{};
    if (unitGroup != null && unitGroup != 'celsius') params['unit_group'] = unitGroup;
    if (localToday != null) params['local_today'] = localToday;
    if (params.isEmpty) return base;
    return base.replace(queryParameters: params);
  }

  // ---------------------------------------------------------------------------
  // v1 Records API — used for period views (daily, weekly, monthly, yearly)
  // ---------------------------------------------------------------------------

  /// Maps internal period keys to API path segments.
  static String _apiPeriodPath(String period) => kApiRecordsPeriodSegment(period);

  /// Fetch period temperature data using the async job endpoint with a
  /// synchronous fallback, mirroring the web app's approach.
  ///
  /// [period] is one of 'daily', 'week', 'month', 'year'.
  /// [location] is the city/location string (e.g. "London, UK").
  /// [identifier] is the MM-DD date string (e.g. "02-06").
  /// [unitGroup] optional unit preference ('fahrenheit' or null for Celsius).
  /// [onProgress] optional callback invoked while the job is processing.
  /// [onFallbackToSync] optional callback invoked when async polling fails and
  /// the service switches to the synchronous fallback endpoint.
  /// [onFetchComplete] optional callback fired after a network fetch completes,
  /// with wall-clock duration in ms and the API cache-hit status. Not fired
  /// when data is served from the in-memory cache.
  Future<PeriodTemperatureData> fetchPeriodData(
    String period,
    String location,
    String identifier, {
    String? unitGroup,
    String? localToday,
    void Function(AsyncJobStatus)? onProgress,
    void Function()? onFallbackToSync,
    bool Function()? isCancelled,
    void Function(int responseTimeMs, bool? cacheHit)? onFetchComplete,
  }) async {
    final todaySuffix = localToday != null ? '|$localToday' : '';
    final unitSuffix = (unitGroup != null && unitGroup != 'celsius') ? '|$unitGroup' : '';
    final cacheKey = '${_apiPeriodPath(period)}|$location|$identifier$todaySuffix$unitSuffix';
    final cached = _periodCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final stopwatch = Stopwatch()..start();

    try {
      DebugUtils.logLazy(() => 'Attempting async fetch for $period data...');
      final jobId = await _createAsyncJob(period, location, identifier,
          unitGroup: unitGroup, localToday: localToday);
      final result = await _pollJobStatus(
        jobId,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
      stopwatch.stop();
      DebugUtils.logLazy(() => 'Async fetch successful for $period data');
      _writeCache(cacheKey, result.data);
      onFetchComplete?.call(stopwatch.elapsedMilliseconds, result.cacheHit);
      return result.data;
    } catch (e) {
      // Propagate cancellation without falling back to sync
      if (e is CancelledOperationException) rethrow;

      // Fall back to synchronous endpoint on timeout or job failure
      final shouldFallback = e is JobPollingException ||
          e is ApiTimeoutException ||
          e is TimeoutException;
      if (shouldFallback) {
        // Check cancellation before starting the sync fallback
        if (isCancelled != null && isCancelled()) {
          throw const CancelledOperationException();
        }
        onFallbackToSync?.call();
        DebugUtils.logLazy(() => 'Async job failed ($e), falling back to sync API...');
        try {
          final (fallback, fallbackCacheHit) =
              await _fetchPeriodDataSync(period, location, identifier,
                  unitGroup: unitGroup, localToday: localToday);
          stopwatch.stop();
          DebugUtils.logLazy(() => 'Synchronous fallback successful for $period data');
          _writeCache(cacheKey, fallback);
          onFetchComplete?.call(stopwatch.elapsedMilliseconds, fallbackCacheHit);
          return fallback;
        } catch (fallbackError) {
          throw ApiException(0, '$period (async + sync fallback both failed)', fallbackError);
        }
      }
      rethrow;
    }
  }

  /// POST to create an async job, returns the job ID.
  Future<String> _createAsyncJob(
    String period,
    String location,
    String identifier, {
    String? unitGroup,
    String? localToday,
  }) async {
    final token = await getAuthToken();
    final apiPeriod = _apiPeriodPath(period);
    final encodedLocation = Uri.encodeComponent(location);
    final url = _buildV1Url(apiPeriod, encodedLocation, identifier,
        suffix: 'async', unitGroup: unitGroup, localToday: localToday);

    DebugUtils.logLazy(() => 'Creating async job: $url');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: kApiTimeoutSeconds));

    if (response.statusCode == 429) {
      throw RateLimitException('Rate limit exceeded creating async job');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, 'async job creation');
    }

    final json = jsonDecode(response.body);
    final jobId = json['job_id'];
    if (jobId == null || (jobId as String).isEmpty) {
      throw const ApiResponseException('missing job_id in async job response');
    }
    return jobId;
  }

  /// Poll the job status endpoint until the job completes or fails.
  Future<JobResult> _pollJobStatus(
    String jobId, {
    void Function(AsyncJobStatus)? onProgress,
    bool Function()? isCancelled,
    int maxPolls = 100,
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    int pollCount = 0;

    while (pollCount < maxPolls) {
      if (isCancelled != null && isCancelled()) {
        DebugUtils.logLazy(() => 'Job $jobId cancelled at poll #$pollCount');
        throw const CancelledOperationException();
      }
      try {
        final token = await getAuthToken();
        final url = Uri.parse('$apiBaseUrl/v1/jobs/$jobId');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: kJobPollTimeoutSeconds));

        if (response.statusCode == 429) {
          throw RateLimitException('Rate limit exceeded polling job');
        }

        if (response.statusCode != 200) {
          throw ApiException(response.statusCode, 'job status ($jobId)');
        }

        final status = AsyncJobStatus.fromJson(jsonDecode(response.body));
        DebugUtils.verboseWithContextLazy('Job',
            () => '$jobId poll #$pollCount: ${status.status}');

        if (status.isReady) {
          DebugUtils.logLazy(() => 'Job $jobId completed after $pollCount polls');
          return status.result!;
        } else if (status.isError) {
          DebugUtils.logLazy(() => 'Job $jobId failed: ${status.error}');
          throw JobPollingException(status.error ?? 'unknown error');
        }

        // Still processing — notify caller and wait
        if (onProgress != null) {
          onProgress(status);
        }
        await Future.delayed(pollInterval);
        pollCount++;
      } catch (e) {
        if (e is RateLimitException || e is JobPollingException) rethrow;
        if (pollCount > 10) {
          throw JobPollingException('failed after $pollCount attempts', e);
        }
        await Future.delayed(pollInterval);
        pollCount++;
      }
    }

    throw JobPollingException('timed out after $maxPolls attempts');
  }

  /// Synchronous fallback: GET the period data directly.
  ///
  /// Returns the parsed data alongside the `X-Cache` header value — true when
  /// the API served a cached result (`X-Cache: HIT`), false for a MISS, null
  /// when the header is absent.
  Future<(PeriodTemperatureData, bool?)> _fetchPeriodDataSync(
    String period,
    String location,
    String identifier, {
    String? unitGroup,
    String? localToday,
  }) async {
    final token = await getAuthToken();
    final apiPeriod = _apiPeriodPath(period);
    final encodedLocation = Uri.encodeComponent(location);
    final url = _buildV1Url(apiPeriod, encodedLocation, identifier,
        unitGroup: unitGroup, localToday: localToday);

    DebugUtils.logLazy(() => 'Sync fallback: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: kApiLongTimeoutSeconds));

    if (response.statusCode == 429) {
      throw RateLimitException('Rate limit exceeded on sync fallback');
    }

    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'v1/records sync fallback');
    }

    final xCache = response.headers['x-cache'];
    final bool? cacheHit =
        xCache == null ? null : xCache.toLowerCase() == 'hit';

    final json = jsonDecode(response.body);
    return (PeriodTemperatureData.fromJson(json), cacheHit);
  }
}
