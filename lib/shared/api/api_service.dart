// import 'dart:convert';
// import 'package:http/http.dart' as http;

class ApiService {
  // Simulate a base URL for the API
  // static const String _baseUrl = 'https://api.opdapp.com';

  // Simulate a delay to mimic network latency
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  // Fetch total number of patients
  Future<int> getTotalPatients() async {
    await _simulateDelay();
    // Mock data
    return 1200;
  }

  // Fetch total number of appointments
  Future<int> getTotalAppointments() async {
    await _simulateDelay();
    // Mock data
    return 350;
  }

  // Fetch active appointments for today
  Future<int> getActiveAppointmentsToday() async {
    await _simulateDelay();
    // Mock data
    return 25;
  }

  // Fetch completed appointments
  Future<int> getCompletedAppointments() async {
    await _simulateDelay();
    // Mock data
    return 300;
  }

  // Fetch cancelled appointments
  Future<int> getCancelledAppointments() async {
    await _simulateDelay();
    // Mock data
    return 25;
  }

  // Fetch all patients (mock data)
  Future<List<Map<String, dynamic>>> getAllPatients() async {
    await _simulateDelay();
    // Mock data
    return [
      {
        'id': '1',
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'phone': '123-456-7890',
        'registeredAt': '2023-10-01T10:00:00Z',
      },
      {
        'id': '2',
        'name': 'Jane Smith',
        'email': 'jane.smith@example.com',
        'phone': '987-654-3210',
        'registeredAt': '2023-10-02T11:00:00Z',
      },
    ];
  }

  // Fetch all appointments (mock data)
  Future<List<Map<String, dynamic>>> getAllAppointments() async {
    await _simulateDelay();
    // Mock data
    return [
      {
        'id': '1',
        'patient': {
          'id': '1',
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'phone': '123-456-7890',
          'registeredAt': '2023-10-01T10:00:00Z',
        },
        'dateTime': '2023-10-15T09:00:00Z',
        'status': 'scheduled',
        'paymentStatus': 'paid',
      },
      {
        'id': '2',
        'patient': {
          'id': '2',
          'name': 'Jane Smith',
          'email': 'jane.smith@example.com',
          'phone': '987-654-3210',
          'registeredAt': '2023-10-02T11:00:00Z',
        },
        'dateTime': '2023-10-16T10:00:00Z',
        'status': 'completed',
        'paymentStatus': 'paid',
      },
    ];
  }
}
