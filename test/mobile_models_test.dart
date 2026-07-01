import 'package:flutter_test/flutter_test.dart';
import 'package:teknisiku/core/models/mobile_models.dart';
import 'package:teknisiku/shared/mobile_ui.dart';

void main() {
  group('mobile models', () {
    test('parses profile role safely', () {
      final profile = AppProfile.fromJson({
        'id': 'user-1',
        'email': 'customer@example.com',
        'full_name': 'Customer Satu',
        'role': 'customer',
        'is_active': true,
      });

      expect(profile.role, AppRole.customer);
      expect(profile.fullName, 'Customer Satu');
      expect(profile.isActive, isTrue);
    });

    test('parses technician summary with nested profile', () {
      final technician = TechnicianSummary.fromJson({
        'id': 'tech-1',
        'user_id': 'user-2',
        'service_area': 'Surakarta',
        'skills': ['Laptop', 'Printer'],
        'verification_status': 'verified',
        'completed_jobs': 12,
        'rating': 4.8,
        'profile': {
          'full_name': 'Andi Saputra',
          'email': 'andi@example.com',
          'profile_image_url': 'https://example.com/andi.png',
        },
      });

      expect(technician.name, 'Andi Saputra');
      expect(technician.skills, ['Laptop', 'Printer']);
      expect(technician.profileImageUrl, 'https://example.com/andi.png');
      expect(technician.rating, 4.8);
    });

    test('parses notification, invoice, and warranty documents', () {
      final notification = AppNotification.fromJson({
        'id': 'notif-1',
        'type': 'order_update',
        'title': 'Pesanan diterima',
        'message': 'Teknisi sudah menerima pesanan.',
        'is_read': false,
        'created_at': '2026-06-30T08:00:00Z',
      });
      final invoice = InvoiceSummary.fromJson({
        'id': 'inv-1',
        'order_id': 'order-1',
        'invoice_number': 'INV-001',
        'payment_id': 'pay-1',
        'invoice_date': '2026-06-30',
        'total_amount': 150000,
      });
      final warranty = WarrantySummary.fromJson({
        'id': 'war-1',
        'order_id': 'order-1',
        'warranty_number': 'GAR-001',
        'status': 'active',
        'start_date': '2026-06-30',
        'end_date': '2026-07-30',
      });

      expect(notification.type, 'order_update');
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, isNotNull);
      expect(invoice.totalAmount, 150000);
      expect(invoice.invoiceNumber, 'INV-001');
      expect(warranty.status, 'active');
      expect(warranty.endDate, isNotNull);
    });

    test('maps technical errors to friendly messages', () {
      expect(
        friendlyErrorMessage('SocketException: failed host lookup'),
        contains('Koneksi internet'),
      );
      expect(
        friendlyErrorMessage('PostgrestException: row-level security'),
        contains('Akses data'),
      );
    });
  });
}
