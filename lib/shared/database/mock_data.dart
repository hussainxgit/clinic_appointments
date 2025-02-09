import '../../features/doctor_availability/models/doctor_availability.dart';
import '../../features/appointment/models/appointment.dart';
import '../../features/doctor/models/doctor.dart';
import '../../features/patient/models/patient.dart';

List<Doctor> mockDoctors = [
  Doctor(
    id: 'D1',
    name: 'Dr. Ahmed Ali',
    specialty: 'General Practitioner',
    phoneNumber: '+96512345678',
    email: '',
    isAvailable: true,
  ),
  Doctor(
    id: 'D2',
    name: 'Dr. Fatima Al-Sabah',
    specialty: 'Pediatrician',
    phoneNumber: '+96587654321',
    email: 'fatima.alsabah@example.com',
    isAvailable: true,
  ),
  Doctor(
    id: 'D3',
    name: 'Dr. Khalid Al-Mutairi',
    specialty: 'Cardiologist',
    phoneNumber: '+96523456789',
    email: 'khalid.almutairi@example.com',
    isAvailable: false,
  ),
];

List<Patient> mockPatients = [
  Patient(
      id: '1',
      name: 'John Doe',
      phone: '62228494',
      registeredAt: DateTime(2024, 1, 10)),
  Patient(
      id: '2',
      name: 'Jane Smith',
      phone: '+96523456789',
      registeredAt: DateTime(2024, 1, 12)),
  Patient(
      id: '3',
      name: 'Ali Hassan',
      phone: '+96534567890',
      registeredAt: DateTime(2024, 2, 5)),
  Patient(
      id: '4',
      name: 'Sara Ahmed',
      phone: '+96545678901',
      registeredAt: DateTime(2024, 2, 10)),
  Patient(
      id: '5',
      name: 'Michael Lee',
      phone: '+96556789012',
      registeredAt: DateTime(2024, 2, 15)),
  Patient(
      id: '6',
      name: 'Fatima Noor',
      phone: '+96567890123',
      registeredAt: DateTime(2024, 3, 1)),
  Patient(
      id: '7',
      name: 'Omar Abdullah',
      phone: '+96578901234',
      registeredAt: DateTime(2024, 3, 8)),
  Patient(
      id: '8',
      name: 'Linda Wong',
      phone: '+96589012345',
      registeredAt: DateTime(2024, 3, 15)),
  Patient(
      id: '9',
      name: 'David Kim',
      phone: '+96590123456',
      registeredAt: DateTime(2024, 3, 20)),
  Patient(
      id: '10',
      name: 'Sophia Al-Farsi',
      phone: '+96512349876',
      registeredAt: DateTime(2024, 3, 25)),
];

List<Appointment> mockAppointments = [
  Appointment(
      id: 'A1',
      patient: mockPatients[0],
      doctor: mockDoctors[0],
      doctorAvailabilityId: '1',
      dateTime: DateTime(2024, 2, 7, 10, 30),
      status: 'scheduled',
      paymentStatus: 'unpaid'),
  Appointment(
      id: 'A3',
      patient: mockPatients[2],
      doctor: mockDoctors[0],
      doctorAvailabilityId: '1',
      dateTime: DateTime(2024, 2, 7, 9, 15),
      status: 'cancelled',
      paymentStatus: 'unpaid'),
  Appointment(
      id: 'A4',
      patient: mockPatients[3],
      doctor: mockDoctors[0],
      doctorAvailabilityId: '1',
      dateTime: DateTime(2024, 2, 7, 11, 45),
      status: 'scheduled',
      paymentStatus: 'paid'),
  Appointment(
      id: 'A5',
      patient: mockPatients[4],
      doctor: mockDoctors[0],
      doctorAvailabilityId: '1',
      dateTime: DateTime(2024, 2, 7, 16, 30),
      status: 'completed',
      paymentStatus: 'paid'),
  Appointment(
      id: 'A6',
      patient: mockPatients[5],
      doctor: mockDoctors[0],
      doctorAvailabilityId: '1',
      dateTime: DateTime(2024, 2, 7, 13, 0),
      status: 'scheduled',
      paymentStatus: 'unpaid'),
  Appointment(
      id: 'A7',
      patient: mockPatients[6],
      doctor: mockDoctors[0],
      doctorAvailabilityId: '1',
      dateTime: DateTime(2024, 2, 7, 15, 30),
      status: 'cancelled',
      paymentStatus: 'unpaid'),
  Appointment(
      id: 'A8',
      patient: mockPatients[7],
      doctor: mockDoctors[1],
      doctorAvailabilityId: '2',
      dateTime: DateTime(2024, 4, 8, 12, 0),
      status: 'completed',
      paymentStatus: 'paid'),
  Appointment(
      id: 'A9',
      patient: mockPatients[8],
      doctor: mockDoctors[1],
      doctorAvailabilityId: '2',
      dateTime: DateTime(2024, 4, 9, 17, 45),
      status: 'scheduled',
      paymentStatus: 'unpaid'),
  Appointment(
      id: 'A10',
      patient: mockPatients[9],
      doctor: mockDoctors[1],
      doctorAvailabilityId: '2',
      dateTime: DateTime(2024, 4, 10, 10, 0),
      status: 'completed',
      paymentStatus: 'paid'),
  Appointment(
      id: 'A11',
      patient: mockPatients[1],
      doctor: mockDoctors[1],
      doctorAvailabilityId: '2',
      dateTime: DateTime(2024, 4, 11, 11, 30),
      status: 'scheduled',
      paymentStatus: 'unpaid'),
  Appointment(
      id: 'A12',
      patient: mockPatients[2],
      doctor: mockDoctors[1],
      doctorAvailabilityId: '2',
      dateTime: DateTime(2024, 4, 12, 14, 15),
      status: 'cancelled',
      paymentStatus: 'unpaid'),
];

List<DoctorAvailability> mockDoctorAvailability = [
  DoctorAvailability(
    id: '1',
    doctorId: 'D1',
    date: DateTime(2025, 02, 07),
    maxPatients: 7,
    bookedPatients: 7,
  ),
  DoctorAvailability(
    id: '3',
    doctorId: 'D1',
    date: DateTime(2025, 02, 16),
    maxPatients: 12,
    bookedPatients: 0,
  ),
  DoctorAvailability(
    id: '4',
    doctorId: 'D1',
    date: DateTime(2025, 02, 17),
    maxPatients: 6,
    bookedPatients: 0,
  ),
  DoctorAvailability(
    id: '5',
    doctorId: 'D2',
    date: DateTime(2025, 02, 17),
    maxPatients: 10,
    bookedPatients: 0,
  ),
  DoctorAvailability(
    id: '2',
    doctorId: 'D2',
    date: DateTime(2025, 02, 15),
    maxPatients: 8,
    bookedPatients: 5,
  ),
];
