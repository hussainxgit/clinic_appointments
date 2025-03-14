// lib/features/doctor/presentation/screens/doctors_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/core_providers.dart';
import '../../presentation/provider/doctor_notifier.dart';
import '../../domain/entities/doctor.dart';

class DoctorsScreen extends ConsumerWidget {
  const DoctorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorState = ref.watch(doctorNotifierProvider);
    final navigationService = ref.read(navigationServiceProvider);

    if (doctorState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (doctorState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${doctorState.error}'),
              ElevatedButton(
                onPressed: () => ref.read(doctorNotifierProvider.notifier).refreshDoctors(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    final doctors = doctorState.doctors;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              navigationService.navigateTo('/doctor/add');
            },
          ),
        ],
      ),
      body: doctors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No doctors found'),
                  ElevatedButton(
                    onPressed: () {
                      navigationService.navigateTo('/doctor/add');
                    },
                    child: const Text('Add Doctor'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return DoctorListItem(doctor: doctor);
              },
            ),
    );
  }
}

class DoctorListItem extends ConsumerWidget {
  final Doctor doctor;
  
  const DoctorListItem({super.key, required this.doctor});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationService = ref.read(navigationServiceProvider);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(doctor.name.substring(0, 1)),
        ),
        title: Text(doctor.name),
        subtitle: Text(doctor.specialty),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              doctor.isAvailable ? Icons.check_circle : Icons.cancel,
              color: doctor.isAvailable ? Colors.green : Colors.red,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                navigationService.navigateTo(
                  '/doctor/edit',
                  arguments: doctor,
                );
              },
            ),
          ],
        ),
        onTap: () {
          navigationService.navigateTo(
            '/doctor/details',
            arguments: doctor,
          );
        },
      ),
    );
  }
}