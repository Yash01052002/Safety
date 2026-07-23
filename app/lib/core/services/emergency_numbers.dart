import 'dart:ui';

/// Resolves the local emergency / police number for the user's region, so the
/// guardian "Call police" action dials the right number instead of a hardcoded
/// one. Falls back to the broadly-recognized 112 where unknown.
///
/// This is a pragmatic starter table — expand per launch market and verify
/// against official sources before shipping to a region.
class EmergencyNumbers {
  static const _police = <String, String>{
    'IN': '112', // India (unified)
    'US': '911',
    'CA': '911',
    'GB': '999',
    'IE': '112',
    'AU': '000',
    'NZ': '111',
    'AE': '999',
    'SG': '999',
    'ZA': '10111',
    'DE': '110',
    'FR': '17',
    'ES': '091',
    'IT': '112',
    'JP': '110',
    'BR': '190',
    'MX': '911',
    'NG': '112',
    'KE': '999',
    'PK': '15',
    'BD': '999',
  };

  /// Emergency number for [countryCode] (ISO 3166-1 alpha-2), or 112.
  static String forCountry(String? countryCode) {
    if (countryCode == null) return '112';
    return _police[countryCode.toUpperCase()] ?? '112';
  }

  /// Best-effort from the device locale when no explicit country is known.
  static String forDeviceLocale() {
    final region = PlatformDispatcher.instance.locale.countryCode;
    return forCountry(region);
  }
}
