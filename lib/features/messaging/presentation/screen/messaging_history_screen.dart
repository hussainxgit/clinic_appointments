// lib/features/messaging/presentation/screens/messaging_history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../data/models/sms_record.dart';
import '../../services/sms_service.dart';

class MessagingHistoryScreen extends ConsumerStatefulWidget {
  const MessagingHistoryScreen({super.key});

  @override
  ConsumerState<MessagingHistoryScreen> createState() =>
      _MessagingHistoryScreenState();
}

class _MessagingHistoryScreenState extends ConsumerState<MessagingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  String? _selectedStatus;
  String? _selectedProvider;
  DateTime? _fromDate;
  DateTime? _toDate;

  final List<String> _statuses = [
    'sent',
    'delivered',
    'failed',
    'queued',
    'undelivered',
    'unknown',
  ];

  bool _isLoading = false;
  List<SmsRecord> _messages = [];
  String? _errorMessage;

  // Recipient for viewing messages (in a real app, might be the current patient's phone)
  final String _recipient = '+1234567890'; // This would be set dynamically

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMessages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final smsService = ref.read(smsServiceProvider);
      final messages = await smsService.getMessageHistory(_recipient);

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading messages: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'All Messages'), Tab(text: 'Filtered')],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMessageList(filtered: false),
                _buildMessageList(filtered: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search messages',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  : IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: _showFilterDialog,
                  ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildMessageList({required bool filtered}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Apply filters
    final filteredMessages = _getFilteredMessages(filtered);

    if (filteredMessages.isEmpty) {
      return EmptyState(
        message:
            filtered ? 'No messages match your filters' : 'No messages found',
        icon: Icons.message,
        actionLabel: 'Send New Message',
        onAction: () {
          Navigator.pop(context);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        itemCount: filteredMessages.length,
        itemBuilder: (context, index) {
          final message = filteredMessages[index];
          return _buildMessageItem(message);
        },
      ),
    );
  }

  List<SmsRecord> _getFilteredMessages(bool applyFilters) {
    if (!applyFilters && _searchQuery.isEmpty) {
      return _messages;
    }

    return _messages.where((message) {
      // Always apply search filter
      final searchMatch =
          _searchQuery.isEmpty ||
          message.body.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          message.to.contains(_searchQuery) ||
          message.from.contains(_searchQuery);

      // Only apply other filters in filtered tab
      if (!applyFilters) return searchMatch;

      final statusMatch =
          _selectedStatus == null || message.status == _selectedStatus;
      final providerMatch =
          _selectedProvider == null || message.providerId == _selectedProvider;

      final dateMatch =
          (_fromDate == null || message.createdAt.isAfter(_fromDate!)) &&
          (_toDate == null ||
              message.createdAt.isBefore(
                _toDate!.add(const Duration(days: 1)),
              ));

      return searchMatch && statusMatch && providerMatch && dateMatch;
    }).toList();
  }

  Widget _buildMessageItem(SmsRecord message) {
    final statusColor = _getStatusColor(message.status);
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  message.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(message.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    'From:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(child: Text(message.from)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    'To:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(child: Text(message.to)),
              ],
            ),
            const SizedBox(height: 16),
            Text(message.body, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Provider: ${message.providerId}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                if (message.messageId.isNotEmpty)
                  Text(
                    'ID: ${message.messageId.substring(0, min(8, message.messageId.length))}...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
            if (message.errorMessage != null &&
                message.errorMessage!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${message.errorMessage}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sent':
      case 'delivered':
        return Colors.green;
      case 'failed':
      case 'undelivered':
        return Colors.red;
      case 'queued':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showFilterDialog() {
    final smsService = ref.read(smsServiceProvider);
    final providers = smsService.getProviders();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Messages'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status filter
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedStatus,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ..._statuses.map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status.toUpperCase()),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Provider filter
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Provider',
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedProvider,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Providers'),
                          ),
                          ...providers.map(
                            (provider) => DropdownMenuItem<String>(
                              value: provider.providerId,
                              child: Text(provider.displayName),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedProvider = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date range
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _fromDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _fromDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'From Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _fromDate != null
                                      ? DateFormat(
                                        'MM/dd/yyyy',
                                      ).format(_fromDate!)
                                      : 'Select',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _toDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setState(() {
                                    _toDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'To Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  _toDate != null
                                      ? DateFormat(
                                        'MM/dd/yyyy',
                                      ).format(_toDate!)
                                      : 'Select',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _selectedStatus = null;
                  _selectedProvider = null;
                  _fromDate = null;
                  _toDate = null;
                  Navigator.pop(context);
                  // Move to filtered tab and refresh
                  _tabController.animateTo(1);
                  setState(() {});
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Move to filtered tab and refresh
                  _tabController.animateTo(1);
                  setState(() {});
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }
}

// Helper function to get minimum value
int min(int a, int b) => a < b ? a : b;
