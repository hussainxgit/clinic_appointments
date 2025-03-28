import '../../data/models/payment_record.dart';

abstract class PaymentRepository {
  Future<List<PaymentRecord>> getAllPayments();
  Future<List<PaymentRecord>> getPaymentsByAppointment(String appointmentId);
  Future<List<PaymentRecord>> getPaymentsByPatient(String patientId);
  Future<PaymentRecord?> getPaymentById(String id);
  Future<PaymentRecord?> getPaymentByInvoice(String invoiceId);
  Future<PaymentRecord> createPayment(PaymentRecord payment);
  Future<PaymentRecord> updatePayment(PaymentRecord payment);
  Future<bool> deletePayment(String id);
  Future<List<PaymentRecord>> getPendingPayments();
  Future<void> updatePaymentStatus(
    String id,
    PaymentStatus status, {
    String? transactionId,
  });
}
