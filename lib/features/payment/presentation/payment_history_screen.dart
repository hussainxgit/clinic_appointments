// lib/features/payment/presentation/screens/payment_history_screen.dart
import 'package:clinic_appointments/features/payment/data/models/payment_record.dart';
import 'package:clinic_appointments/features/payment/presentation/providers/payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/ui/widgets/empty_state.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Get all patients' payments (in a real app, you might filter by selected patient)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Just as an example, load payments for a specific patient
      // In a real app, you'd either get the currently viewed patient or show all
      ref
          .read(paymentNotifierProvider.notifier)
          .loadPaymentHistory('selectedPatientId');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Successful'),
            Tab(text: 'Pending'),
            Tab(text: 'Failed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by reference ID or amount',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Payment List
          Expanded(
            child:
                paymentState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : paymentState.error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${paymentState.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(paymentNotifierProvider.notifier)
                                  .loadPaymentHistory('selectedPatientId');
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPaymentList(paymentState.payments, null),
                        _buildPaymentList(paymentState.payments, 'successful'),
                        _buildPaymentList(paymentState.payments, 'pending'),
                        _buildPaymentList(paymentState.payments, 'failed'),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(List<PaymentRecord> payments, String? statusFilter) {
    // Apply filters
    final filteredPayments =
        payments.where((payment) {
          // Apply status filter
          final statusMatch =
              statusFilter == null || payment.status == statusFilter;

          // Apply search filter
          final searchMatch =
              _searchQuery.isEmpty ||
              payment.referenceId.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              payment.amount.toString().contains(_searchQuery);

          return statusMatch && searchMatch;
        }).toList();

    if (filteredPayments.isEmpty) {
      return EmptyState(
        message:
            statusFilter == null
                ? 'No payment records found'
                : 'No $statusFilter payments found',
        icon: Icons.payment,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(paymentNotifierProvider.notifier)
            .loadPaymentHistory('selectedPatientId');
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
    // Format date
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = dateFormat.format(payment.createdAt);

    // Determine status color
    Color statusColor;
    IconData statusIcon;

    switch (payment.status) {
      case 'successful':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
      case 'processing':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'refunded':
      case 'partially_refunded':
        statusColor = Colors.blue;
        statusIcon = Icons.replay;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Reference: ${payment.referenceId}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payment.status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${payment.amount.toStringAsFixed(3)} ${payment.currency}'),
            Text(
              formattedDate,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Gateway: ${payment.gatewayId}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing:
            payment.status == 'successful'
                ? IconButton(
                  icon: const Icon(Icons.receipt_long),
                  onPressed: () => _showReceiptOptions(payment),
                  tooltip: 'Receipt',
                )
                : const SizedBox.shrink(),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
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
                    Center(
                      child: Text(
                        'Payment Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildDetailRow('Status', payment.status.toUpperCase()),
                    _buildDetailRow('Reference ID', payment.referenceId),
                    _buildDetailRow('Gateway', payment.gatewayId),
                    _buildDetailRow(
                      'Amount',
                      '${payment.amount.toStringAsFixed(3)} ${payment.currency}',
                    ),
                    _buildDetailRow(
                      'Date',
                      DateFormat(
                        'MMM d, yyyy h:mm a',
                      ).format(payment.createdAt),
                    ),
                    if (payment.transactionId != null)
                      _buildDetailRow('Transaction ID', payment.transactionId!),
                    if (payment.errorMessage != null)
                      _buildDetailRow('Error', payment.errorMessage!),

                    const SizedBox(height: 24),

                    // Action buttons
                    if (payment.status == 'successful')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.receipt_long,
                            label: 'Receipt',
                            onTap: () {
                              Navigator.pop(context);
                              _showReceiptOptions(payment);
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.replay,
                            label: 'Refund',
                            onTap: () {
                              Navigator.pop(context);
                              _showRefundDialog(payment);
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Check status button for pending payments
                    if (payment.status == 'pending' ||
                        payment.status == 'processing')
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Check Status'),
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref
                                .read(paymentNotifierProvider.notifier)
                                .checkPaymentStatus(payment.id);
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  void _showReceiptOptions(PaymentRecord payment) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email Receipt'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt sent via email')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('Print Receipt'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Printing receipt...')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Download PDF'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading receipt as PDF'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showRefundDialog(PaymentRecord payment) {
    final TextEditingController amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(3),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Process Refund'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter the refund amount:'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Refund Amount',
                    suffixText: payment.currency,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // Process refund
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid amount')),
                    );
                    return;
                  }

                  final result = await ref
                      .read(paymentNotifierProvider.notifier)
                      .processRefund(payment.id, amount: amount);

                  if (result.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refund processed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${result.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Process Refund'),
              ),
            ],
          ),
    );
  }
}
