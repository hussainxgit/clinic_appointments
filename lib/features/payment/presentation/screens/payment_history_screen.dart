import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../data/models/payment_record.dart';
import '../../domain/providers.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentHistoryProvider.notifier).loadAllPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(paymentHistoryProvider);
    final payments = historyState.payments.cast<PaymentRecord>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                () =>
                    ref.read(paymentHistoryProvider.notifier).loadAllPayments(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),

          Expanded(
            child:
                historyState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : historyState.error != null
                    ? Center(child: Text('Error: ${historyState.error}'))
                    : _buildPaymentsList(payments),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by ID or patient',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),

          const SizedBox(height: 12),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('Pending', 'pending'),
                _buildFilterChip('Successful', 'successful'),
                _buildFilterChip('Failed', 'failed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _statusFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _statusFilter = filter;
          });
        },
        backgroundColor: Colors.grey.shade200,
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildPaymentsList(List<PaymentRecord> allPayments) {
    // Apply filters
    final filteredPayments =
        allPayments.where((payment) {
          // Status filter
          if (_statusFilter != 'all' &&
              payment.status.toStorageString() != _statusFilter) {
            return false;
          }

          // Search filter
          if (_searchQuery.isNotEmpty) {
            return payment.appointmentId.toLowerCase().contains(_searchQuery) ||
                payment.patientId.toLowerCase().contains(_searchQuery) ||
                payment.id.toLowerCase().contains(_searchQuery);
          }

          return true;
        }).toList();

    if (filteredPayments.isEmpty) {
      return EmptyState(
        message: 'No payments found',
        icon: Icons.payment,
        actionLabel: 'Refresh',
        onAction:
            () => ref.read(paymentHistoryProvider.notifier).loadAllPayments(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(paymentHistoryProvider.notifier).loadAllPayments();
      },
      child: ListView.builder(
        itemCount: filteredPayments.length,
        itemBuilder: (context, index) {
          final payment = filteredPayments[index];
          return _buildPaymentItem(payment);
        },
      ),
    );
  }

  Widget _buildPaymentItem(PaymentRecord payment) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final createdDate = dateFormat.format(payment.createdAt);

    // Status indicators
    final (color, icon, statusText) = _getStatusIndicators(payment.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Amount
                  Text(
                    '${payment.amount.toStringAsFixed(3)} ${payment.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: color),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    createdDate,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const Spacer(),
                  Icon(
                    payment.linkSent ? Icons.check_circle : Icons.pending,
                    size: 14,
                    color: payment.linkSent ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    payment.linkSent ? 'Link sent' : 'Link pending',
                    style: TextStyle(
                      fontSize: 12,
                      color: payment.linkSent ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(),

              Text(
                'Appointment ID: ${payment.appointmentId}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 4),

              Text(
                'Payment ID: ${payment.id}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, IconData, String) _getStatusIndicators(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.successful:
        return (Colors.green, Icons.check_circle, 'PAID');
      case PaymentStatus.pending:
        return (Colors.orange, Icons.pending, 'PENDING');
      case PaymentStatus.failed:
        return (Colors.red, Icons.cancel, 'FAILED');
      case PaymentStatus.refunded:
        return (Colors.blue, Icons.replay, 'REFUNDED');
      case PaymentStatus.cancelled:
        return (Colors.grey, Icons.cancel, 'CANCELLED');
    }
  }

  void _showPaymentDetails(PaymentRecord payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.5,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Center(
                      child: Text(
                        'Payment Details',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status
                    _buildStatusHeader(payment),
                    const SizedBox(height: 24),

                    // Details
                    _buildInfoRow('Payment ID', payment.id),
                    _buildInfoRow('Appointment ID', payment.appointmentId),
                    _buildInfoRow('Patient ID', payment.patientId),
                    _buildInfoRow(
                      'Amount',
                      '${payment.amount.toStringAsFixed(3)} ${payment.currency}',
                    ),
                    _buildInfoRow(
                      'Method',
                      _formatMethod(payment.paymentMethod),
                    ),
                    _buildInfoRow(
                      'Created',
                      _formatDateTime(payment.createdAt),
                    ),
                    if (payment.completedAt != null)
                      _buildInfoRow(
                        'Completed',
                        _formatDateTime(payment.completedAt!),
                      ),
                    if (payment.invoiceId != null)
                      _buildInfoRow('Invoice ID', payment.invoiceId!),
                    if (payment.transactionId != null)
                      _buildInfoRow('Transaction ID', payment.transactionId!),

                    const SizedBox(height: 16),

                    if (payment.paymentLink != null) ...[
                      const Divider(),
                      const SizedBox(height: 8),

                      // Payment link
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Link',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    payment.paymentLink!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    // Copy to clipboard
                                  },
                                  tooltip: 'Copy to clipboard',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
                    if (payment.status == PaymentStatus.pending)
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _checkPaymentStatus(payment),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check Status'),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildStatusHeader(PaymentRecord payment) {
    final (color, icon, statusText) = _getStatusIndicators(payment.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                _getStatusDescription(payment.status),
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusDescription(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.successful:
        return 'Payment has been successfully processed';
      case PaymentStatus.pending:
        return 'Payment is waiting to be completed';
      case PaymentStatus.failed:
        return 'Payment processing failed';
      case PaymentStatus.refunded:
        return 'Payment has been refunded';
      case PaymentStatus.cancelled:
        return 'Payment was cancelled';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatMethod(String method) {
    switch (method.toLowerCase()) {
      case 'myfatoorah':
        return 'MyFatoorah';
      case 'whatsapp':
        return 'WhatsApp Payment Link';
      default:
        return method;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
  }

  Future<void> _checkPaymentStatus(PaymentRecord payment) async {
    // Implementation of payment status check
    Navigator.pop(context); // Close details sheet

    final paymentService = ref.read(paymentServiceProvider);
    await paymentService.checkPaymentStatus(payment.id);

    // Refresh payment list
    ref.read(paymentHistoryProvider.notifier).loadAllPayments();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment status updated')));
  }
}
