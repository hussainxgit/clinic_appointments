import 'package:clinic_appointments/shared/utilities/utility.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/services/clinic_service.dart';
import '../../appointment/models/appointment.dart';
import '../../patient/models/patient.dart';

class ClinicSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, size: 28),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, size: 28),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
          child: Text(
        'Search for patients, doctors, or appointments',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ));
    }

    final clinicService = Provider.of<ClinicService>(context, listen: false);
    final patients = clinicService.searchPatientByQuery(query);
    final doctors = clinicService.searchDoctorByQuery(query);
    final appointments = clinicService.searchAppointmentsByQuery(query);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: const [
              Tab(text: 'Patients'),
              Tab(text: 'Doctors'),
              Tab(text: 'Appointments'),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontSize: 16),
          ),
          Expanded(
            child: TabBarView(
              children: [
                patients.isEmpty
                    ? const Center(
                        child: Text('No patients found',
                            style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(patient.name[0].toUpperCase()),
                            ),
                            title: Text(patient.name,
                                style: const TextStyle(fontSize: 16)),
                            subtitle: Text(patient.phone),
                            onTap: () => close(context, patient.id),
                          );
                        },
                      ),
                doctors.isEmpty
                    ? const Center(
                        child: Text('No doctors found',
                            style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(doctor.name[0].toUpperCase()),
                            ),
                            title: Text(doctor.name,
                                style: const TextStyle(fontSize: 16)),
                            subtitle: Text(doctor.specialty),
                            onTap: () => close(context, doctor.id),
                          );
                        },
                      ),
                appointments.isEmpty
                    ? const Center(
                        child: Text('No appointments found',
                            style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment =
                              appointments[index]['appointment'] as Appointment;
                          final patient =
                              appointments[index]['patient'] as Patient;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Text(patient.name[0].toUpperCase()),
                            ),
                            title: Text(patient.name,
                                style: const TextStyle(fontSize: 16)),
                            subtitle: Text(appointment.dateTime.dateOnly()),
                            onTap: () => close(context, appointment.id),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
