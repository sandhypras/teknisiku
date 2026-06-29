import 'dart:convert';
import 'dart:math' as math;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class CurrentLocationResult {
  const CurrentLocationResult({
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    required this.city,
    this.district,
    this.village,
    this.postalCode,
  });

  final double latitude;
  final double longitude;
  final String fullAddress;
  final String city;
  final String? district;
  final String? village;
  final String? postalCode;
}

Future<CurrentLocationResult> getCurrentAddress() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) {
    throw StateError('Layanan lokasi belum aktif di perangkat ini.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw StateError('Izin lokasi ditolak.');
  }
  if (permission == LocationPermission.deniedForever) {
    throw StateError(
      'Izin lokasi ditolak permanen. Aktifkan dari pengaturan aplikasi.',
    );
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  );
  Placemark? place;
  try {
    final places = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places.isNotEmpty) place = places.first;
  } catch (_) {
    place = null;
  }

  var city = _firstNotEmpty([
    place?.locality,
    place?.subAdministrativeArea,
    place?.administrativeArea,
  ]);
  var district = _firstNotEmpty([
    place?.subAdministrativeArea,
    place?.locality,
  ]);
  var village = _firstNotEmpty([place?.subLocality, place?.thoroughfare]);
  var postalCode = _firstNotEmpty([place?.postalCode]);
  var addressParts = [
    place?.street,
    place?.subLocality,
    place?.locality,
    place?.subAdministrativeArea,
    place?.administrativeArea,
    place?.postalCode,
  ].where((item) => item != null && item.trim().isNotEmpty).toSet().toList();

  if (city == null ||
      district == null ||
      village == null ||
      postalCode == null ||
      addressParts.isEmpty) {
    final fallback = await _reverseGeocodeHttp(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    city ??= fallback?.city;
    district ??= fallback?.district;
    village ??= fallback?.village;
    postalCode ??= fallback?.postalCode;
    if (addressParts.isEmpty && fallback != null) {
      addressParts = fallback.fullAddress
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
  }

  return CurrentLocationResult(
    latitude: position.latitude,
    longitude: position.longitude,
    fullAddress: addressParts.isEmpty
        ? 'Lat ${position.latitude.toStringAsFixed(6)}, Long ${position.longitude.toStringAsFixed(6)}'
        : addressParts.join(', '),
    city: city ?? 'Solo',
    district: district,
    village: village,
    postalCode: postalCode,
  );
}

Future<CurrentLocationResult?> _reverseGeocodeHttp({
  required double latitude,
  required double longitude,
}) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'format': 'jsonv2',
    'lat': '$latitude',
    'lon': '$longitude',
    'accept-language': 'id',
    'zoom': '18',
    'addressdetails': '1',
  });
  try {
    final response = await http
        .get(
          uri,
          headers: const {
            'User-Agent': 'SiTeknisi/1.0 teknisiku-location-reverse-geocoding',
          },
        )
        .timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final city = _firstNotEmpty([
      address['city'] as String?,
      address['town'] as String?,
      address['municipality'] as String?,
      address['county'] as String?,
      address['state'] as String?,
    ]);
    final district = _firstNotEmpty([
      address['city_district'] as String?,
      address['district'] as String?,
      address['suburb'] as String?,
      address['county'] as String?,
    ]);
    final village = _firstNotEmpty([
      address['village'] as String?,
      address['suburb'] as String?,
      address['neighbourhood'] as String?,
      address['hamlet'] as String?,
      address['quarter'] as String?,
    ]);
    final postalCode = _firstNotEmpty([address['postcode'] as String?]);
    final fullAddress =
        (json['display_name'] as String?) ??
        [address['road'], village, district, city, postalCode]
            .whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .join(', ');
    return CurrentLocationResult(
      latitude: latitude,
      longitude: longitude,
      fullAddress: fullAddress,
      city: city ?? 'Solo',
      district: district,
      village: village,
      postalCode: postalCode,
    );
  } catch (_) {
    return null;
  }
}

double distanceKm({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(toLatitude - fromLatitude);
  final dLon = _degToRad(toLongitude - fromLongitude);
  final lat1 = _degToRad(fromLatitude);
  final lat2 = _degToRad(toLatitude);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double value) => value * math.pi / 180;

String? _firstNotEmpty(Iterable<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}
