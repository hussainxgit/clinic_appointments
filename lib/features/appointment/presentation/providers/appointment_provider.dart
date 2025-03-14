// lib/features/appointment/presentation/providers/appointment_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/appointment.dart';
import '../../services/appointment_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentService _appointmentService;
  
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = false;
  String? _error;
  
  AppointmentProvider({
    required AppointmentService appointmentService,
  }) : _appointmentService = appointmentService {
    _loadAppointments();
  }
  
  // Getters
  List<Map<String, dynamic>> get appointments => List.unmodifiable(_appointments);
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load all appointments with related data
  Future<void> _loadAppointments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _appointmentService.getCombinedAppointments();
      
      if (result.isSuccess) {
        _appointments = result.data;
        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _error = result.error;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Refresh appointments
  Future<void> refreshAppointments() async {
    await _loadAppointments();
  }
  
  // Get appointments for a specific patient
  Future<Result<List<Map<String, dynamic>>>> getPatientAppointments(String patientId) async {
    try {
      final result = await _appointmentService.getCombinedAppointments(
        patientId: patientId
      );
      
      if (result.isSuccess) {
        return Result.success(result.data);
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Get appointments for a specific doctor
  Future<Result<List<Map<String, dynamic>>>> getDoctorAppointments(String doctorId) async {
    try {
      final result = await _appointmentService.getCombinedAppointments(
        doctorId: doctorId
      );
      
      if (result.isSuccess) {
        return Result.success(result.data);
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Get appointments for a specific date
  Future<Result<List<Map<String, dynamic>>>> getAppointmentsByDate(DateTime date) async {
    try {
      final result = await _appointmentService.getCombinedAppointments(
        date: date
      );
      
      if (result.isSuccess) {
        return Result.success(result.data);
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Create a new appointment
  Future<Result<Appointment>> createAppointment(Appointment appointment) async {
    try {
      final result = await _appointmentService.createAppointment(appointment);
      
      if (result.isSuccess) {
        // Refresh appointments after creation
        await _loadAppointments();
        return Result.success(result.data);
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Update an existing appointment
  Future<Result<Appointment>> updateAppointment(Appointment appointment) async {
    try {
      final result = await _appointmentService.updateAppointment(appointment);
      
      if (result.isSuccess) {
        // Refresh appointments after update
        await _loadAppointments();
        return Result.success(result.data);
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Cancel an appointment
  Future<Result<bool>> cancelAppointment(String appointmentId) async {
    try {
      final result = await _appointmentService.cancelAppointment(appointmentId);
      
      if (result.isSuccess) {
        // Refresh appointments after cancellation
        await _loadAppointments();
        return Result.success(true);
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
  
  // Complete an appointment
  Future<Result<Appointment>> completeAppointment(
    String appointmentId, 
    {String? notes, String paymentStatus = 'paid'}
  ) async {
    try {
      final result = await _appointmentService.completeAppointment(
        appointmentId,
        notes: notes,
        paymentStatus: paymentStatus
      );
      
      if (result.isSuccess) {
        // Refresh appointments after completion
        await _loadAppointments();
        return Result.success(result.data);
      } else {
        return Result.failure(result.error);
      }
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}