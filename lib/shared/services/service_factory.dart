import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../../features/appointment/controller/appointment_provider.dart';
import '../../features/appointment_slot/controller/appointment_slot_provdier.dart';
import '../../features/doctor/controller/doctor_provider.dart';
import '../../features/patient/controller/patient_provider.dart';
import 'clinic_service.dart';

class ServiceFactory {
  static ClinicService createClinicService(
    GlobalKey<ScaffoldMessengerState> messengerKey,
    AppointmentProvider appointmentProvider,
    PatientProvider patientProvider,
    DoctorProvider doctorProvider,
    AppointmentSlotProvider appointmentSlotProvider,
  ) {
    final notificationService = SnackBarNotificationService(messengerKey);
    
    return ClinicService(
      appointmentProvider: appointmentProvider,
      patientProvider: patientProvider,
      doctorProvider: doctorProvider,
      appointmentSlotProvider: appointmentSlotProvider,
      notificationService: notificationService,
    );
  }
}