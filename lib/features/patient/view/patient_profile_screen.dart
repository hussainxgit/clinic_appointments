import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../appointment/view/create_appointment_modal.dart';
import '../models/patient.dart';
import '../controller/patient_provider.dart';
import 'patient_appointment_list.dart';

class PatientProfileScreen extends StatefulWidget {
  final Patient patient;

  const PatientProfileScreen({super.key, required this.patient});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late Patient _patient;
  bool _isEditing = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  late DateTime? _selectedDateOfBirth;
  late PatientGender _selectedGender;
  late PatientStatus _selectedStatus;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _patient = widget.patient;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _patient.name);
    _phoneController = TextEditingController(text: _patient.phone);
    _emailController = TextEditingController(text: _patient.email ?? '');
    _addressController = TextEditingController(text: _patient.address ?? '');
    _notesController = TextEditingController(text: _patient.notes ?? '');
    _selectedDateOfBirth = _patient.dateOfBirth;
    _selectedGender = _patient.gender;
    _selectedStatus = _patient.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => CreateAppointmentModal(
                    patient: _patient,
                  ));
        },
        label: const Text('Book Appointment'),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _isEditing
                ? PatientEditForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    phoneController: _phoneController,
                    emailController: _emailController,
                    addressController: _addressController,
                    notesController: _notesController,
                    selectedDateOfBirth: _selectedDateOfBirth,
                    selectedGender: _selectedGender,
                    selectedStatus: _selectedStatus,
                    onDateChanged: (date) =>
                        setState(() => _selectedDateOfBirth = date),
                    onGenderChanged: (gender) =>
                        setState(() => _selectedGender = gender),
                    onStatusChanged: (status) =>
                        setState(() => _selectedStatus = status),
                  )
                : PatientDetailsCard(patient: _patient),
            Expanded(
              child: _buildPatientTabs(context),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Patient Profile'),
      scrolledUnderElevation: 0,
      actions: [
        if (_isEditing)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isEditing = false;
                _initControllers(); // Reset controllers to original values
              });
            },
            tooltip: 'Cancel',
          ),
        IconButton(
          icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined),
          onPressed: _isEditing ? _saveChanges : () => _toggleEditMode(),
          tooltip: _isEditing ? 'Save' : 'Edit Profile',
        ),
      ],
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      final patientProvider =
          Provider.of<PatientProvider>(context, listen: false);

      final updatedPatient = _patient.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        dateOfBirth: _selectedDateOfBirth,
        gender: _selectedGender,
        status: _selectedStatus,
      );

      patientProvider.updatePatient(updatedPatient);

      setState(() {
        _patient = updatedPatient;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient profile updated successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildPatientTabs(context) {
    return DefaultTabController(
      length: 1,
      child: Column(
        children: [
          _buildTabBar(context),
          Expanded(
            child: _buildTabBarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: TabBar(
        isScrollable: true,
        tabs: const [
          Tab(text: 'Appointments'),
        ],
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: _buildTabIndicator(colorScheme),
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  UnderlineTabIndicator _buildTabIndicator(ColorScheme colorScheme) {
    return UnderlineTabIndicator(
      borderSide: BorderSide(
        color: colorScheme.primary,
        width: 3,
      ),
      insets: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      children: [AppointmentsTab(patient: _patient)],
    );
  }
}

class PatientEditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController notesController;
  final DateTime? selectedDateOfBirth;
  final PatientGender selectedGender;
  final PatientStatus selectedStatus;
  final Function(DateTime?) onDateChanged;
  final Function(PatientGender) onGenderChanged;
  final Function(PatientStatus) onStatusChanged;

  const PatientEditForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.notesController,
    required this.selectedDateOfBirth,
    required this.selectedGender,
    required this.selectedStatus,
    required this.onDateChanged,
    required this.onGenderChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context),
              const SizedBox(height: 16),
              _buildFormFields(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.edit,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Edit Patient Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return Wrap(
      spacing: 24.0,
      runSpacing: 16.0,
      children: [
        _buildTextField(
          context,
          'Full Name',
          nameController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Name is required';
            }
            return null;
          },
        ),
        _buildTextField(
          context,
          'Phone',
          phoneController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone is required';
            }
            return null;
          },
        ),
        _buildTextField(context, 'Email', emailController),
        _buildTextField(context, 'Address', addressController),
        _buildGenderDropdown(context),
        _buildDatePicker(context),
        _buildStatusDropdown(context),
        _buildTextField(
          context,
          'Notes',
          notesController,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return SizedBox(
      width: 200,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        validator: validator,
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildGenderDropdown(BuildContext context) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<PatientGender>(
        decoration: const InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        value: selectedGender,
        items: PatientGender.values.map((gender) {
          return DropdownMenuItem<PatientGender>(
            value: gender,
            child: Text(gender == PatientGender.male ? 'Male' : 'Female'),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onGenderChanged(value);
          }
        },
      ),
    );
  }

  Widget _buildStatusDropdown(BuildContext context) {
    return SizedBox(
      width: 200,
      child: DropdownButtonFormField<PatientStatus>(
        decoration: const InputDecoration(
          labelText: 'Status',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        value: selectedStatus,
        items: PatientStatus.values.map((status) {
          return DropdownMenuItem<PatientStatus>(
            value: status,
            child: Text(status.toString().split('.').last),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onStatusChanged(value);
          }
        },
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () => _selectDate(context),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Date of Birth',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDateOfBirth != null
                    ? '${selectedDateOfBirth!.day}/${selectedDateOfBirth!.month}/${selectedDateOfBirth!.year}'
                    : 'Not set',
              ),
              const Icon(Icons.calendar_today, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDateOfBirth) {
      onDateChanged(picked);
    }
  }
}

class PatientDetailsCard extends StatelessWidget {
  final Patient patient;

  const PatientDetailsCard({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context),
            const SizedBox(height: 16),
            _buildPatientInfoGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.person_outline,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Personal Information',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoGrid(BuildContext context) {
    return Wrap(
      spacing: 24.0,
      runSpacing: 16.0,
      children: [
        _buildInfoItem(context, 'Full Name', patient.name),
        _buildInfoItem(context, 'Gender', _formatGender()),
        _buildInfoItem(context, 'Date of Birth', _formatDateOfBirth()),
        _buildInfoItem(context, 'Age', _calculateAge()),
        _buildInfoItem(context, 'Address', patient.address ?? 'Not Provided'),
        _buildInfoItem(context, 'Phone', patient.phone),
        _buildInfoItem(context, 'Email', patient.email ?? 'Not Provided'),
        _buildInfoItem(context, 'Status', _formatStatus()),
        if (patient.notes != null && patient.notes!.isNotEmpty)
          _buildInfoItem(context, 'Notes', patient.notes!),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatGender() {
    return patient.gender == PatientGender.male ? 'Male' : 'Female';
  }

  String _formatStatus() {
    return patient.status.toString().split('.').last;
  }

  String _formatDateOfBirth() {
    return patient.dateOfBirth != null
        ? '${patient.dateOfBirth!.day}/${patient.dateOfBirth!.month}/${patient.dateOfBirth!.year}'
        : 'Not Provided';
  }

  String _calculateAge() {
    if (patient.dateOfBirth == null) return 'Not Calculated';

    final now = DateTime.now();
    final age = now.year - patient.dateOfBirth!.year;
    final monthDiff = now.month - patient.dateOfBirth!.month;

    return monthDiff < 0 ||
            (monthDiff == 0 && now.day < patient.dateOfBirth!.day)
        ? '${age - 1}Y'
        : '${age}Y';
  }
}

class AppointmentsTab extends StatelessWidget {
  final Patient patient;

  const AppointmentsTab({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: PatientAppointmentList(patient: patient),
    );
  }
}
