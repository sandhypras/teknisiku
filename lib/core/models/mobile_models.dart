enum AppRole {
  customer('customer', 'Customer'),
  technician('technician', 'Teknisi'),
  admin('admin', 'Admin');

  const AppRole(this.value, this.label);

  final String value;
  final String label;

  static AppRole fromValue(String? value) {
    return AppRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AppRole.customer,
    );
  }
}

class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.phone,
  });

  final String id;
  final String email;
  final String fullName;
  final AppRole role;
  final bool isActive;
  final String? phone;

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    return AppProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      role: AppRole.fromValue(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
  });

  final String id;
  final String name;
  final String? description;
  final String? iconUrl;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String,
      name: json['name'] as String? ?? '-',
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
    );
  }
}

class TechnicianSummary {
  const TechnicianSummary({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.serviceArea,
    required this.skills,
    required this.status,
    required this.completedJobs,
    required this.rating,
    this.description,
    this.experience,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String serviceArea;
  final List<String> skills;
  final String status;
  final int completedJobs;
  final double rating;
  final String? description;
  final String? experience;

  factory TechnicianSummary.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    return TechnicianSummary(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: profile['full_name'] as String? ?? 'Teknisi',
      email: profile['email'] as String? ?? '',
      serviceArea: json['service_area'] as String? ?? 'Solo',
      skills: (json['skills'] as List?)?.map((item) => '$item').toList() ?? [],
      status: json['verification_status'] as String? ?? 'pending',
      description: json['description'] as String?,
      experience: json['experience'] as String?,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TechnicianService {
  const TechnicianService({
    required this.id,
    required this.technicianId,
    required this.name,
    required this.price,
    required this.status,
    required this.isActive,
    this.categoryId,
    this.categoryName,
    this.description,
    this.duration,
  });

  final String id;
  final String technicianId;
  final String name;
  final double price;
  final String status;
  final bool isActive;
  final String? categoryId;
  final String? categoryName;
  final String? description;
  final String? duration;

  factory TechnicianService.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return TechnicianService(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String? ?? '',
      categoryId: json['category_id'] as String?,
      categoryName: category?['name'] as String?,
      name: json['name'] as String? ?? '-',
      description: json['description'] as String?,
      price: (json['estimated_price'] as num?)?.toDouble() ?? 0,
      duration: json['estimated_duration'] as String?,
      status: json['approval_status'] as String? ?? 'pending',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class TechnicianDocument {
  const TechnicianDocument({
    required this.id,
    required this.technicianId,
    required this.documentType,
    required this.fileUrl,
    required this.uploadedAt,
  });

  final String id;
  final String technicianId;
  final String documentType;
  final String fileUrl;
  final DateTime? uploadedAt;

  factory TechnicianDocument.fromJson(Map<String, dynamic> json) {
    return TechnicianDocument(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String? ?? '',
      documentType: json['document_type'] as String? ?? '',
      fileUrl: json['file_url'] as String? ?? '',
      uploadedAt: DateTime.tryParse('${json['uploaded_at']}'),
    );
  }
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
    required this.city,
    required this.isPrimary,
  });

  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String fullAddress;
  final String city;
  final bool isPrimary;

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Alamat',
      recipientName: json['recipient_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fullAddress: json['full_address'] as String? ?? '',
      city: json['city'] as String? ?? 'Solo',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.problemDescription,
    required this.finalTotal,
    required this.estimatedTotal,
    required this.scheduleDate,
    required this.scheduleTime,
    required this.customerName,
    required this.technicianName,
    required this.createdAt,
    this.customerPhone,
    this.address,
    this.city,
  });

  final String id;
  final String orderNumber;
  final String status;
  final String problemDescription;
  final double finalTotal;
  final double estimatedTotal;
  final String scheduleDate;
  final String scheduleTime;
  final String customerName;
  final String technicianName;
  final DateTime? createdAt;
  final String? customerPhone;
  final String? address;
  final String? city;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final address = json['address'] as Map<String, dynamic>?;
    final technician =
        (json['technician'] as Map<String, dynamic>?)?['profile']
            as Map<String, dynamic>?;
    return OrderSummary(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '-',
      status: json['status'] as String? ?? 'waiting_confirmation',
      problemDescription: json['problem_description'] as String? ?? '',
      finalTotal: (json['final_total'] as num?)?.toDouble() ?? 0,
      estimatedTotal: (json['estimated_total'] as num?)?.toDouble() ?? 0,
      scheduleDate: '${json['schedule_date'] ?? '-'}',
      scheduleTime: '${json['schedule_time'] ?? ''}',
      customerName: customer?['full_name'] as String? ?? '-',
      customerPhone: customer?['phone'] as String?,
      technicianName: technician?['full_name'] as String? ?? '-',
      createdAt: DateTime.tryParse('${json['created_at']}'),
      address: address?['full_address'] as String?,
      city: address?['city'] as String?,
    );
  }
}
