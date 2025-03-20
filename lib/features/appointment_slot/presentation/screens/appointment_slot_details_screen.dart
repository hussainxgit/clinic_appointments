import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppointmentSlotDetailsScreen extends ConsumerStatefulWidget {
  const AppointmentSlotDetailsScreen({super.key});

  @override
  AppointmentSlotDetailsState createState() => AppointmentSlotDetailsState();
}

class AppointmentSlotDetailsState
    extends ConsumerState<AppointmentSlotDetailsScreen> {
  // Updated class name to match widget name
  final List<PatientModel> patients = [
    PatientModel(
      name: 'Haylie Saris',
      department: 'Cornea',
      birthDate: '12/12/1988',
    ),
    PatientModel(name: 'Hussain Al-Hussain', department: 'Cornea'),
    PatientModel(name: 'Ali Al-Hussain', department: 'Cornea'),
    PatientModel(name: 'Mohammad Jassim', department: 'Cornea'),
    PatientModel(name: 'Kareem Akbar', department: 'Cornea'),
  ];

  int _selectedPatientIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slot patients'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              onPressed: () {},
              tooltip: 'Configer slot',
              icon: const Icon(Icons.settings),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(onPressed: () {}, child: Text('Add patient')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildSearchAndFilterBar(),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildPatientsList()),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: _buildPatientDetails()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: const InputDecoration(
              hintText: 'Search patients...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {},
          child: Row(
            spacing: 4.0,
            children: [const Icon(Icons.filter_list), const Text('Filter')],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {},
          child: Row(
            spacing: 4.0,
            children: [const Icon(Icons.sort), const Text('Sort')],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientsList() {
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: patients.length,
        itemBuilder: (context, index) {
          final patient = patients[index];
          return InkWell(
            onTap: () {
              setState(() {
                _selectedPatientIndex = index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                selected: _selectedPatientIndex == index,
                selectedTileColor:
                    Theme.of(context).colorScheme.primaryContainer,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(patient.name[0].toUpperCase()),
                ),
                title: Text(patient.name),
                subtitle: Text(patient.department),
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit patient',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPatientDetails() {
    final selectedPatient = patients[_selectedPatientIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 350,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPatientProfileCard(selectedPatient)),
              const SizedBox(width: 16),
              Expanded(child: _buildTreatmentCard()),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildNextVisit()),
            const SizedBox(width: 16),
            Expanded(flex: 1, child: _buildEyeAnatomyCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientProfileCard(PatientModel patient) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _buildPatientImage(),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildPatientInfoOverlay(patient),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientImage() {
    return Image.network(
      'https://images.unsplash.com/photo-1552162864-987ac51d1177?q=80&w=1160&auto=format&fit=crop&ixlib=rb-4.0.3',
      fit: BoxFit.cover,
      height: double.infinity,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value:
                loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
          ),
        );
      },
      errorBuilder:
          (context, error, stackTrace) => Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
    );
  }

  Widget _buildPatientInfoOverlay(PatientModel patient) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  patient.birthDate != null
                      ? '35 years old, ${patient.birthDate}'
                      : 'No birth date available',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.chat_rounded, color: Colors.white),
                tooltip: 'Chat with patient',
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.call_rounded, color: Colors.white),
                tooltip: 'Call patient',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTreatmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12.0,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Treatment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit treatments',
                ),
              ],
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(
                  4,
                  (index) => _buildMedicationCard('10 G', 'Depamine'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(String dosage, String medicationName) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Make content use full width
          children: [
            Text(
              dosage,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              medicationName,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextVisit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard('Detailed diagnosis', 'Cornea ulcer, Cornea ulcer'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard('Diagnosis', 'Cornea ulcer, Cornea ulcer'),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 150,
              child: _buildInfoCard('Next Visit', '2025/3/25'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content) {
    return Card(
      child: Container(
        height: 120, // Fixed height to match _buildEyeAnatomyCard
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                content,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEyeAnatomyCard() {
    return Card(
      child: Container(
        height: 265, // Fixed height to match _buildInfoCard
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eye Anatomy',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://media.istockphoto.com/id/1128850304/vector/vector-human-eye-crossection-close-up-isolated-on-white-baclground.jpg?s=612x612&w=0&k=20&c=LDT6TjJZhfU9MtHkUIwxAJaPpr8Dh8XBdi8DwcHfMQE=',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PatientModel {
  final String name;
  final String department;
  final String? birthDate;

  PatientModel({required this.name, required this.department, this.birthDate});
}
