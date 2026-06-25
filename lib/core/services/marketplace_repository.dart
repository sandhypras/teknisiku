import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mobile_models.dart';

class MarketplaceRepository {
  MarketplaceRepository(this._client);

  final SupabaseClient _client;

  String? get userId => _client.auth.currentUser?.id;

  Future<List<ServiceCategory>> categories() async {
    final data = await _client
        .from('categories')
        .select('id, name, description')
        .eq('is_active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(
      data,
    ).map(ServiceCategory.fromJson).toList();
  }

  Future<List<TechnicianSummary>> technicians({String? query}) async {
    final data = await _client
        .from('technician_profiles')
        .select(
          'id, user_id, service_area, skills, description, experience, verification_status, profile:profiles!user_id(full_name, email)',
        )
        .eq('verification_status', 'verified')
        .order('created_at', ascending: false);
    final technicians = List<Map<String, dynamic>>.from(
      data,
    ).map(TechnicianSummary.fromJson).toList();
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
          completedJobs: (orders as List).length,
          rating: rating,
        );
      }),
    );
    final normalized = query?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return enriched;
    return enriched
        .where(
          (item) =>
              item.name.toLowerCase().contains(normalized) ||
              item.skills.join(' ').toLowerCase().contains(normalized),
        )
        .toList();
  }

  Future<TechnicianSummary> technician(String id) async {
    final row = await _client
        .from('technician_profiles')
        .select(
          'id, user_id, service_area, skills, description, experience, verification_status, profile:profiles!user_id(full_name, email)',
        )
        .eq('id', id)
        .single();
    return TechnicianSummary.fromJson(row);
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
          'id, label, recipient_name, phone, full_address, city, is_primary',
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
          'city': 'Solo',
          'is_primary': true,
        })
        .select(
          'id, label, recipient_name, phone, full_address, city, is_primary',
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
          'id, order_number, status, problem_description, schedule_date, schedule_time, estimated_total, final_total, created_at, customer:profiles!customer_id(full_name), technician:technician_profiles!technician_id(profile:profiles!user_id(full_name))',
        )
        .eq('customer_id', id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(
      data,
    ).map(OrderSummary.fromJson).toList();
  }

  Future<TechnicianSummary?> myTechnicianProfile() async {
    final id = userId;
    if (id == null) return null;
    final row = await _client
        .from('technician_profiles')
        .select(
          'id, user_id, service_area, skills, description, experience, verification_status, profile:profiles!user_id(full_name, email)',
        )
        .eq('user_id', id)
        .maybeSingle();
    return row == null ? null : TechnicianSummary.fromJson(row);
  }

  Future<void> upsertTechnicianProfile({
    required String address,
    required String experience,
    required String skills,
    required String serviceArea,
    required String description,
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
    }, onConflict: 'user_id');
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
          'id, order_number, status, problem_description, schedule_date, schedule_time, estimated_total, final_total, created_at, customer:profiles!customer_id(full_name), technician:technician_profiles!technician_id(profile:profiles!user_id(full_name))',
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
