// lib/features/patient/presentation/screens/patients_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../providers/patient_notifier.dart';
import '../../domain/entities/patient.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({super.key});

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientState = ref.watch(patientNotifierProvider);
    final navigationService = ref.read(navigationServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              navigationService.navigateTo('/patient/add');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
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
          Expanded(
            child: patientState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : patientState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${patientState.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.read(patientNotifierProvider.notifier).refreshPatients(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildPatientList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          ref.read(navigationServiceProvider).navigateTo('/patient/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPatientList() {
    final patients = _searchQuery.isEmpty
        ? ref.read(patientNotifierProvider).patients
        : ref.read(patientNotifierProvider.notifier).searchPatients(_searchQuery);

    if (patients.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return EmptyState(
          message: 'No patients found for "$_searchQuery"',
          icon: Icons.search_off,
        );
      }

      return EmptyState(
        message: 'No patients found',
        icon: Icons.people_outline,
        actionLabel: 'Add Patient',
        onAction: () {
          ref.read(navigationServiceProvider).navigateTo('/patient/add');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(patientNotifierProvider.notifier).refreshPatients(),
      child: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return PatientListItem(patient: patient);
        },
      ),
    );
  }
}

class PatientListItem extends ConsumerWidget {
  final Patient patient;

  const PatientListItem({super.key, required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: patient.status == PatientStatus.active
              ? Theme.of(context).primaryColor
              : Colors.grey,
          child: Text(
            patient.name.isNotEmpty ? patient.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          patient.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: patient.status == PatientStatus.active ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.phone),
            if (patient.dateOfBirth != null)
              Text(
                'Age: ${_calculateAge(patient.dateOfBirth!)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            patient.appointmentIds.isNotEmpty
                ? Badge(
                    label: Text(patient.appointmentIds.length.toString()),
                    child: const Icon(Icons.calendar_today, size: 20),
                  )
                : const SizedBox(),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                navigationService.navigateTo(
                  '/patient/edit',
                  arguments: patient,
                );
              },
            ),
          ],
        ),
        onTap: () {
          navigationService.navigateTo(
            '/patient/details',
            arguments: patient,
          );
        },
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    final currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month &&
            currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}