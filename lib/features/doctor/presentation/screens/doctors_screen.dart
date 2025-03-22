import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../domain/entities/doctor.dart';
import '../../presentation/provider/doctor_notifier.dart';

class DoctorsScreen extends ConsumerStatefulWidget {
  const DoctorsScreen({super.key});

  @override
  ConsumerState<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends ConsumerState<DoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doctorState = ref.watch(doctorNotifierProvider);
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: _buildAppBar(navigationService, doctorState.doctors.length),
      body: Container(
        color: Colors.grey[50],
        child: doctorState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : doctorState.error != null
                ? _buildErrorView(doctorState.error!)
                : _buildDoctorList(doctorState.doctors),
      ),
    );
  }

  AppBar _buildAppBar(NavigationService navigationService, int count) {
    return AppBar(
      title: Row(
        children: [
          Text(count.toString(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.deepOrange,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(width: 8),
          Text('Doctors', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
      actions: [
        ElevatedButton.icon(
          onPressed: () => navigationService.navigateTo('/doctor/add'),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Add Doctor', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 16),
      ],
      backgroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildDoctorList(List<Doctor> doctors) {
    final filteredDoctors = doctors
        .where((doctor) => _searchQuery.isEmpty || 
            doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredDoctors.length,
              itemBuilder: (context, index) => _buildDoctorCard(filteredDoctors[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search doctors',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => ref.read(navigationServiceProvider).navigateTo('/doctor/details', arguments: doctor),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(doctor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doctor.name, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Project Manager', 
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow('Department', doctor.specialty),
                  const SizedBox(height: 4),
                  _buildInfoRow('Hired Date', _formatDate()),
                  const SizedBox(height: 12),
                  _buildContactInfo(Icons.email_outlined, doctor.email ?? 'Ronald043@gmail.com'),
                  const SizedBox(height: 8),
                  _buildContactInfo(Icons.phone_outlined, 
                      doctor.phoneNumber.isNotEmpty ? doctor.phoneNumber : '(229) 555-0109'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Doctor doctor) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: doctor.imageUrl?.isNotEmpty ?? false
                    ? NetworkImage(doctor.imageUrl!)
                    : null,
                child: doctor.imageUrl?.isEmpty ?? true
                    ? _buildDoctorAvatar(doctor)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: doctor.isAvailable ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.black45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (value) => _handleMenuSelection(value, doctor),
            itemBuilder: (context) => [
              _buildMenuItem('edit', Icons.edit, 'Edit'),
              _buildMenuItem('delete', Icons.delete, 'Delete'),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildDoctorAvatar(Doctor doctor) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: Colors.blueGrey[300],
      child: Text(
        doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[600],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: TextStyle(color: Colors.grey[600]))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  String _formatDate() => DateTime.now().day.isEven ? '7/27/15' : '9/14/12';

  void _handleMenuSelection(String value, Doctor doctor) {
    if (value == 'edit') {
      ref.read(navigationServiceProvider).navigateTo('/doctor/edit', arguments: doctor);
    } else if (value == 'delete') {
      _confirmDelete(doctor);
    }
  }

  Future<void> _confirmDelete(Doctor doctor) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Doctor'),
        content: Text('Are you sure you want to delete ${doctor.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    final notifier = ref.read(doctorNotifierProvider.notifier);
    final result = await notifier.deleteDoctor(doctor.id);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor deleted successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result.error}')),
      );
    }
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(doctorNotifierProvider.notifier).refreshDoctors(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}