import '../../../../core/utils/result.dart';
import '../../data/models/payment_record.dart';

abstract class PaymentRepository {
  Future<Result<List<PaymentRecord>>> getAllPayments();
  Future<Result<List<PaymentRecord>>> getPaymentsByAppointment(
    String appointmentId,
  );
  Future<Result<List<PaymentRecord>>> getPaymentsByPatient(String patientId);
  Future<Result<PaymentRecord?>> getPaymentById(String id);
  Future<Result<PaymentRecord?>> getPaymentByInvoice(String invoiceId);
  Future<Result<PaymentRecord>> createPayment(PaymentRecord payment);
  Future<Result<PaymentRecord>> updatePayment(PaymentRecord payment);
  Future<Result<bool>> deletePayment(String id);
  Future<Result<List<PaymentRecord>>> getPendingPayments();
  Future<Result<void>> updatePaymentStatus(
    String id,
    PaymentStatus status, {
    String? transactionId,
  });
}
