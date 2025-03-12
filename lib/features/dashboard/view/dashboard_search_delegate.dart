import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clinic_appointments/shared/services/clinic_service.dart';
import 'package:clinic_appointments/features/appointment/view/appointment_details_screen.dart';
import 'package:clinic_appointments/features/patient/view/patient_profile_screen.dart';
import 'package:clinic_appointments/features/doctor/view/doctor_profile_screen.dart';

class ClinicSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search patients, doctors, appointments...';

  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => query = '',
    ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Text(
          'Enter a search term',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
        ),
      );
    }
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Search for patients, doctors, appointments...',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return _buildSearchResults(context);
  }
  
  Widget _buildSearchResults(BuildContext context) {
    final clinicService = Provider.of<ClinicService>(context, listen: false);
    
    final patients = clinicService.searchPatientByQuery(query);
    final doctors = clinicService.searchDoctorByQuery(query);
    final appointments = clinicService.searchAppointmentsByQuery(query);
    
    final hasResults = patients.isNotEmpty || doctors.isNotEmpty || appointments.isNotEmpty;
    
    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No results found for "$query"',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                text: 'Patients (${patients.length})',
              ),
              Tab(
                text: 'Doctors (${doctors.length})',
              ),
              Tab(
                text: 'Appointments (${appointments.length})',
              ),
            ],
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Patients Tab
                patients.isEmpty
                    ? _buildEmptyTabContent('No patients found')
                    : ListView.builder(
                        itemCount: patients.length,
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Text(
                                patient.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(patient.name),
                            subtitle: Text(patient.phone),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => PatientProfileScreen(
                                    patient: patient,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                
                // Doctors Tab
                doctors.isEmpty
                    ? _buildEmptyTabContent('No doctors found')
                    : ListView.builder(
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctor = doctors[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              backgroundImage: doctor.imageUrl != null && doctor.imageUrl!.isNotEmpty
                                  ? NetworkImage(doctor.imageUrl!)
                                  : null,
                              child: doctor.imageUrl == null || doctor.imageUrl!.isEmpty
                                  ? Text(
                                      doctor.name[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white),
                                    )
                                  : null,
                            ),
                            title: Text(doctor.name),
                            subtitle: Text(doctor.specialty),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => DoctorProfileScreen(
                                    doctor: doctor,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                
                // Appointments Tab
                appointments.isEmpty
                    ? _buildEmptyTabContent('No appointments found')
                    : ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment = appointments[index]['appointment'];
                          final patient = appointments[index]['patient'];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(
                                Icons.calendar_today,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            title: Text(patient.name),
                            subtitle: Text(
                              '${appointment.dateTime.day}/${appointment.dateTime.month}/${appointment.dateTime.year} - ${appointment.status}',
                            ),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => AppointmentDetailsScreen(
                                    appointmentId: appointment.id,
                                  ),
                                ),
                              );
                            },
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
  
  Widget _buildEmptyTabContent(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
      ),
    );
  }
}