import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mobile_models.dart';
import 'location_service.dart';

class MarketplaceRepository {
  MarketplaceRepository(this._client);

  final SupabaseClient _client;

  String? get userId => _client.auth.currentUser?.id;

  Future<List<ServiceCategory>> categories() async {
    final data = await _client
        .from('categories')
        .select('id, name, description, icon_url')
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(data).map((json) {
      final rawIcon = json['icon_url'] as String?;
      return ServiceCategory.fromJson({
        ...json,
        'icon_url': _publicCategoryIconUrl(rawIcon),
      });
    }).toList();
  }

  Future<List<TechnicianSummary>> technicians({
    String? query,
    double? latitude,
    double? longitude,
  }) async {
    final data = await _client
        .from('technician_profiles')
        .select(
          'id, user_id, service_area, skills, description, experience, latitude, longitude, verification_status, profile:profiles!user_id(full_name, email, profile_image_url)',
        )
        .eq('verification_status', 'verified')
        .order('created_at', ascending: false);
    final technicians = List<Map<String, dynamic>>.from(data)
        .map(_normalizeTechnicianProfileImage)
        .map(TechnicianSummary.fromJson)
        .toList();
    final enriched = await Future.wait(
      technicians.map((item) async {
        final reviews = await _client
            .from('reviews')
            .select('rating')
            .eq('technician_id', item.id);
        final orders = await _client
            .from('orders')
            .select('id')
            .eq('technician_id', item.id)
            .eq('status', 'completed');
        final ratings = List<Map<String, dynamic>>.from(reviews);
        final rating = ratings.isEmpty
            ? 0.0
            : ratings.fold<double>(
                    0,
                    (sum, row) =>
                        sum + ((row['rating'] as num?)?.toDouble() ?? 0),
                  ) /
                  ratings.length;
        return TechnicianSummary(
          id: item.id,
          userId: item.userId,
          name: item.name,
          email: item.email,
          serviceArea: item.serviceArea,
          skills: item.skills,
          status: item.status,
          description: item.description,
          experience: item.experience,
          profileImageUrl: item.profileImageUrl,
          latitude: item.latitude,
          longitude: item.longitude,
          distanceKm:
              latitude != null &&
                  longitude != null &&
                  item.latitude != null &&
                  item.longitude != null
              ? distanceKm(
                  fromLatitude: latitude,
                  fromLongitude: longitude,
                  toLatitude: item.latitude!,
                  toLongitude: item.longitude!,
                )
              : null,
          completedJobs: (orders as List).length,
          rating: rating,
        );
      }),
    );
    final normalized = query?.trim().toLowerCase();
    final filtered = normalized == null || normalized.isEmpty
        ? enriched
        : enriched
              .where(
                (item) =>
                    item.name.toLowerCase().contains(normalized) ||
                    item.skills.join(' ').toLowerCase().contains(normalized),
              )
              .toList();
    filtered.sort((a, b) {
      final aDistance = a.distanceKm;
      final bDistance = b.distanceKm;
      if (aDistance == null && bDistance == null) return 0;
      if (aDistance == null) return 1;
      if (bDistance == null) return -1;
      return aDistance.compareTo(bDistance);
    });
    return filtered;
  }

  Future<TechnicianSummary> technician(String id) async {
    final row = await _client
        .from('technician_profiles')
        .select(
          'id, user_id, service_area, skills, description, experience, latitude, longitude, verification_status, profile:profiles!user_id(full_name, email, profile_image_url)',
        )
        .eq('id', id)
        .single();
    return TechnicianSummary.fromJson(_normalizeTechnicianProfileImage(row));
  }

  Future<List<TechnicianService>> services({
    String? technicianId,
    bool publicOnly = true,
  }) async {
    var q = _client
        .from('services')
        .select(
          'id, technician_id, category_id, name, description, estimated_price, estimated_duration, approval_status, is_active, category:categories(name)',
        );
    if (technicianId != null) q = q.eq('technician_id', technicianId);
    if (publicOnly) {
      q = q.eq('approval_status', 'approved').eq('is_active', true);
    }
    final data = await q.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      data,
    ).map(TechnicianService.fromJson).toList();
  }

  Future<List<CustomerAddress>> customerAddresses() async {
    final id = userId;
    if (id == null) return [];
    final data = await _client
        .from('customer_addresses')
        .select(
          'id, label, recipient_name, phone, full_address, city, district, village, postal_code, latitude, longitude, is_primary',
        )
        .eq('customer_id', id)
        .order('is_primary', ascending: false);
    return List<Map<String, dynamic>>.from(
      data,
    ).map(CustomerAddress.fromJson).toList();
  }

  Future<CustomerAddress> addAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String fullAddress,
    String city = 'Solo',
    String? district,
    String? village,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool isPrimary = true,
  }) async {
    final id = userId;
    if (id == null) throw StateError('User belum login');
    final row = await _client
        .from('customer_addresses')
        .insert({
          'customer_id': id,
          'label': label,
          'recipient_name': recipientName,
          'phone': phone,
          'full_address': fullAddress,
          'city': city.trim().isEmpty ? 'Solo' : city.trim(),
          'district': district?.trim().isEmpty ?? true
              ? null
              : district!.trim(),
          'village': village?.trim().isEmpty ?? true ? null : village!.trim(),
          'postal_code': postalCode?.trim().isEmpty ?? true
              ? null
              : postalCode!.trim(),
          'latitude': latitude,
          'longitude': longitude,
          'is_primary': isPrimary,
        })
        .select(
          'id, label, recipient_name, phone, full_address, city, district, village, postal_code, latitude, longitude, is_primary',
        )
        .single();
    return CustomerAddress.fromJson(row);
  }

  Future<void> createOrder({
    required TechnicianSummary technician,
    required List<TechnicianService> services,
    required CustomerAddress address,
    required DateTime scheduleDate,
    required String scheduleTime,
    required String problemDescription,
  }) async {
    final id = userId;
    if (id == null) throw StateError('User belum login');
    final total = services.fold<double>(0, (sum, item) => sum + item.price);
    final order = await _client
        .from('orders')
        .insert({
          'order_number': await _client.rpc('generate_order_number'),
          'customer_id': id,
          'technician_id': technician.id,
          'address_id': address.id,
          'schedule_date': scheduleDate.toIso8601String().split('T').first,
          'schedule_time': scheduleTime,
          'problem_description': problemDescription,
          'estimated_total': total,
          'final_total': 0,
        })
        .select('id')
        .single();
    await _client
        .from('order_items')
        .insert(
          services
              .map(
                (service) => {
                  'order_id': order['id'],
                  'service_id': service.id,
                  'service_name': service.name,
                  'estimated_price': service.price,
                },
              )
              .toList(),
        );
  }

  Future<List<OrderSummary>> customerOrders() async {
    final id = userId;
    if (id == null) return [];
    final data = await _client
        .from('orders')
        .select(
          'id, order_number, status, problem_description, schedule_date, schedule_time, estimated_total, final_total, created_at, customer:profiles!customer_id(full_name, phone), address:customer_addresses!address_id(full_address, city), technician:technician_profiles!technician_id(profile:profiles!user_id(full_name))',
        )
        .eq('customer_id', id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      data,
    ).map(OrderSummary.fromJson).toList();
  }

  Future<PaymentCheckout> createMidtransPayment(String orderId) async {
    final response = await _client.functions.invoke(
      'midtrans-create-snap',
      body: {'order_id': orderId},
    );
    if (response.status >= 400) {
      final data = response.data;
      if (data is Map && data['error'] != null) {
        throw StateError('${data['error']}');
      }
      throw StateError('Gagal membuat pembayaran Midtrans');
    }
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('Response pembayaran tidak valid');
    }
    return PaymentCheckout.fromJson(data);
  }

  Future<TechnicianSummary?> myTechnicianProfile() async {
    final id = userId;
    if (id == null) return null;
    final row = await _client
        .from('technician_profiles')
        .select(
          'id, user_id, service_area, skills, description, experience, latitude, longitude, verification_status, profile:profiles!user_id(full_name, email, profile_image_url)',
        )
        .eq('user_id', id)
        .maybeSingle();
    return row == null
        ? null
        : TechnicianSummary.fromJson(_normalizeTechnicianProfileImage(row));
  }

  Future<void> upsertTechnicianProfile({
    required String address,
    required String experience,
    required String skills,
    required String serviceArea,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    final id = userId;
    if (id == null) throw StateError('User belum login');
    await _client.from('technician_profiles').upsert({
      'user_id': id,
      'address': address,
      'experience': experience,
      'skills': skills
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      'service_area': serviceArea.trim().isEmpty ? 'Solo' : serviceArea.trim(),
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    }, onConflict: 'user_id');
  }

  Future<List<TechnicianDocument>> technicianDocuments(
    String technicianId,
  ) async {
    final data = await _client
        .from('technician_documents')
        .select('id, technician_id, document_type, file_url, uploaded_at')
        .eq('technician_id', technicianId)
        .order('uploaded_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      data,
    ).map(TechnicianDocument.fromJson).toList();
  }

  Future<TechnicianDocument> uploadTechnicianDocument({
    required String technicianId,
    required String documentType,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final id = userId;
    if (id == null) throw StateError('User belum login');
    final safeType = documentType.trim().toLowerCase();
    final extension = _fileExtension(fileName, contentType);
    final path =
        '$id/$technicianId/$safeType-${DateTime.now().millisecondsSinceEpoch}$extension';
    await _client.storage
        .from('technician-documents')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType ?? _contentTypeFromExtension(extension),
            upsert: true,
          ),
        );
    final existing = await _client
        .from('technician_documents')
        .select('id')
        .eq('technician_id', technicianId)
        .eq('document_type', safeType)
        .maybeSingle();
    final payload = {
      'technician_id': technicianId,
      'document_type': safeType,
      'file_url': 'technician-documents/$path',
      'uploaded_at': DateTime.now().toIso8601String(),
    };
    final row = existing == null
        ? await _client
              .from('technician_documents')
              .insert(payload)
              .select('id, technician_id, document_type, file_url, uploaded_at')
              .single()
        : await _client
              .from('technician_documents')
              .update(payload)
              .eq('id', existing['id'] as String)
              .select('id, technician_id, document_type, file_url, uploaded_at')
              .single();
    return TechnicianDocument.fromJson(row);
  }

  Future<void> createTechnicianService({
    required String technicianId,
    required String categoryId,
    required String name,
    required String description,
    required double price,
    required String duration,
  }) async {
    await _client.from('services').insert({
      'technician_id': technicianId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'estimated_price': price,
      'estimated_duration': duration,
      'approval_status': 'pending',
      'is_active': true,
    });
  }

  Future<List<OrderSummary>> technicianOrders(String technicianId) async {
    final data = await _client
        .from('orders')
        .select(
          'id, order_number, status, problem_description, schedule_date, schedule_time, estimated_total, final_total, created_at, customer:profiles!customer_id(full_name, phone), address:customer_addresses!address_id(full_address, city), technician:technician_profiles!technician_id(profile:profiles!user_id(full_name))',
        )
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      data,
    ).map(OrderSummary.fromJson).toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _client.from('orders').update({'status': status}).eq('id', orderId);
  }
}

String? _publicCategoryIconUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final value = path.trim();
  if (value.startsWith('http')) return value;

  const supportedBuckets = [
    'category-images',
    'service-images',
    'profile-images',
  ];
  var bucket = 'category-images';
  var objectPath = value;
  for (final candidate in supportedBuckets) {
    final prefix = '$candidate/';
    if (value.startsWith(prefix)) {
      bucket = candidate;
      objectPath = value.substring(prefix.length);
      break;
    }
  }
  if (objectPath.isEmpty) return null;

  return Supabase.instance.client.storage.from(bucket).getPublicUrl(objectPath);
}

Map<String, dynamic> _normalizeTechnicianProfileImage(
  Map<String, dynamic> json,
) {
  final profile = json['profile'];
  if (profile is! Map<String, dynamic>) return json;
  return {
    ...json,
    'profile': {
      ...profile,
      'profile_image_url': _publicCategoryIconUrl(
        profile['profile_image_url'] as String?,
      ),
    },
  };
}

String _fileExtension(String fileName, String? contentType) {
  final normalized = fileName.toLowerCase();
  final dotIndex = normalized.lastIndexOf('.');
  if (dotIndex >= 0 && dotIndex < normalized.length - 1) {
    final extension = normalized.substring(dotIndex);
    if (['.jpg', '.jpeg', '.png', '.webp', '.pdf'].contains(extension)) {
      return extension;
    }
  }
  return switch (contentType) {
    'image/png' => '.png',
    'image/webp' => '.webp',
    'application/pdf' => '.pdf',
    _ => '.jpg',
  };
}

String _contentTypeFromExtension(String extension) {
  return switch (extension) {
    '.png' => 'image/png',
    '.webp' => 'image/webp',
    '.pdf' => 'application/pdf',
    _ => 'image/jpeg',
  };
}
