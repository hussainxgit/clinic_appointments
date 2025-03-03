import '../../features/appointment_slot/models/appointment_slot.dart';
import '../../features/appointment/models/appointment.dart';
import '../../features/doctor/models/doctor.dart';
import '../../features/patient/models/patient.dart';

List<Doctor> mockDoctors = [
  Doctor(
    id: 'D1',
    name: 'Dr. Ahmed Ali',
    specialty: 'General Practitioner',
    phoneNumber: '+96512345678',
    email: 'ahmed@example.com',
    imageUrl:
        'https://www.nvisioncenters.com/wp-content/uploads/types-of-eye-care-professionals.jpg',
    isAvailable: true,
    socialMedia: {'facebook': 'url', 'instagram': 'url'},
    bio:
        'Dr. Ahmed Ali is a dedicated General Practitioner with over 15 years of experience in providing comprehensive healthcare. Known for his compassionate approach, he specializes in preventive care and chronic disease management, ensuring patients receive personalized treatment plans. Dr. Ali earned his medical degree from the University of Kuwait and has since been committed to improving community health at Eastern Avenue Clinic in New York. Patients appreciate his clear communication and thorough follow-ups, often praising his ability to make complex medical concepts easy to understand."',
  ),
  Doctor(
      id: 'D2',
      name: 'Dr. Fatima Al-Sabah',
      specialty: 'Pediatrician',
      phoneNumber: '+96587654321',
      email: 'fatima.alsabah@example.com',
      imageUrl:
          'https://mytpmg.com/wp-content/uploads/2021/02/eyedoctor-360-x-240.jpg',
      isAvailable: true,
      socialMedia: {'facebook': 'url', 'instagram': 'url'}),
  Doctor(
    id: 'D3',
    name: 'Dr. Khalid Al-Mutairi',
    specialty: 'Cardiologist',
    phoneNumber: '+96523456789',
    email: 'khalid.almutairi@example.com',
    imageUrl: '',
    isAvailable: false,
  ),
];

List<Patient> mockPatients = [
  Patient(
      id: '1',
      name: 'John Doe',
      phone: '62228494',
      registeredAt: DateTime(2025, 1, 10)),
  Patient(
      id: '2',
      name: 'Jane Smith',
      phone: '+96523456789',
      registeredAt: DateTime(2025, 1, 12)),
  Patient(
      id: '3',
      name: 'Ali Hassan',
      phone: '+96534567890',
      registeredAt: DateTime(2025, 2, 5)),
  Patient(
      id: '4',
      name: 'Sara Ahmed',
      phone: '+96545678901',
      registeredAt: DateTime(2025, 2, 10)),
  Patient(
      id: '5',
      name: 'Michael Lee',
      phone: '+96556789012',
      registeredAt: DateTime(2025, 2, 15)),
  Patient(
      id: '6',
      name: 'Fatima Noor',
      phone: '+96567890123',
      registeredAt: DateTime(2025, 3, 1)),
  Patient(
      id: '7',
      name: 'Omar Abdullah',
      phone: '+96578901234',
      registeredAt: DateTime(2025, 3, 8)),
  Patient(
      id: '8',
      name: 'Linda Wong',
      phone: '+96589012345',
      registeredAt: DateTime(2025, 3, 15)),
  Patient(
      id: '9',
      name: 'David Kim',
      phone: '+96590123456',
      registeredAt: DateTime(2025, 3, 20)),
  Patient(
      id: '10',
      name: 'Sophia Al-Farsi',
      phone: '+96512349876',
      registeredAt: DateTime(2025, 3, 25)),
];

List<Appointment> mockAppointments = [
  Appointment(
      id: 'A1',
      patientId: mockPatients[0].id,
      doctorId: mockDoctors[0].id,
      appointmentSlotId: '1',
      dateTime: DateTime(2025, 2, 7),
      status: 'scheduled',
      paymentStatus: 'unpaid'),
  Appointment(
      id: 'A3',
      patientId: mockPatients[2].id,
      doctorId: mockDoctors[0].id,
      appointmentSlotId: '4',
      dateTime: DateTime(2025, 2, 28,),
      status: 'scheduled',
      paymentStatus: 'unpaid'),
  Appointment(
      id: 'A4',
      patientId: mockPatients[3].id,
      doctorId: mockDoctors[0].id,
      appointmentSlotId: '1',
      dateTime: DateTime(2025, 2, 7),
      status: 'scheduled',
      paymentStatus: 'paid'),
  Appointment(
      id: 'A5',
      patientId: mockPatients[4].id,
      doctorId: mockDoctors[0].id,
      appointmentSlotId: '3',
      dateTime: DateTime(2025, 03, 25),
      status: 'completed',
      paymentStatus: 'paid'),
];

List<AppointmentSlot> mockAppointmentSlots = [
  AppointmentSlot(
    id: '1',
    doctorId: 'D1',
    date: DateTime(2025, 02, 07),
    maxPatients: 7,
    bookedPatients: 2,
  ),
  AppointmentSlot(
    id: '2',
    doctorId: 'D2',
    date: DateTime(2025, 03, 01),
    maxPatients: 8,
    bookedPatients: 0,
  ),
  AppointmentSlot(
    id: '3',
    doctorId: 'D1',
    date: DateTime(2025, 03, 25),
    maxPatients: 12,
    bookedPatients: 1,
  ),
  AppointmentSlot(
    id: '4',
    doctorId: 'D1',
    date: DateTime(2025, 02, 28),
    maxPatients: 6,
    bookedPatients: 1,
  ),
  AppointmentSlot(
    id: '5',
    doctorId: 'D2',
    date: DateTime(2025, 02, 28),
    maxPatients: 10,
    bookedPatients: 0,
  ),
  AppointmentSlot(
    id: '6',
    doctorId: 'D2',
    date: DateTime(2025, 04, 17),
    maxPatients: 10,
    bookedPatients: 0,
  ),
];
