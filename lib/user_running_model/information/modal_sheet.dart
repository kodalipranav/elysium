import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModalSheet extends StatefulWidget {
  final String name;
  final String age;
  final String gender;
  final String description;
  final String occupation;
  final VoidCallback onSave;

  const ModalSheet({
    super.key,
    required this.name,
    required this.age,
    required this.gender,
    required this.description,
    required this.occupation,
    required this.onSave,
  });

  @override
  State<ModalSheet> createState() => ModalSheetState();
}

class ModalSheetState extends State<ModalSheet> {
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController genderController;
  late TextEditingController descriptionController;
  late TextEditingController gradeController;

  String? selectedOccupationType;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    ageController = TextEditingController(text: widget.age);
    genderController = TextEditingController(text: widget.gender);
    descriptionController = TextEditingController(text: widget.description);
    gradeController = TextEditingController();

    if (widget.occupation.startsWith('Student; Grade ')) {
      selectedOccupationType = 'Student';
      gradeController.text =
          widget.occupation.replaceFirst('Student; Grade ', '');
    } else if (widget.occupation == 'Employed' ||
        widget.occupation == 'Unemployed') {
      selectedOccupationType = widget.occupation;
    } else {
      selectedOccupationType = 'Employed';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    genderController.dispose();
    descriptionController.dispose();
    gradeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16.0,
        left: 16.0,
        right: 16.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit Profile',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: genderController,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              minLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedOccupationType,
              decoration: const InputDecoration(
                labelText: 'Occupation',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Employed',
                  child: Text('Employed'),
                ),
                DropdownMenuItem(
                  value: 'Unemployed',
                  child: Text('Unemployed'),
                ),
                DropdownMenuItem(
                  value: 'Student',
                  child: Text('Student'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedOccupationType = value;
                  if (value != 'Student') {
                    gradeController.clear();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            if (selectedOccupationType == 'Student')
              TextField(
                controller: gradeController,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                String newName = nameController.text.trim();
                String newAge = ageController.text.trim();
                String newGender = genderController.text.trim();
                String newDescription = descriptionController.text.trim();
                String newOccupation;

                if (newName.isEmpty ||
                    newAge.isEmpty ||
                    newGender.isEmpty ||
                    newDescription.isEmpty ||
                    selectedOccupationType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill all required fields')),
                  );
                  return;
                }

                if (int.tryParse(newAge) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Age must be a number')),
                  );
                  return;
                }

                if (selectedOccupationType == 'Student') {
                  String grade = gradeController.text.trim();
                  if (grade.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your grade')),
                    );
                    return;
                  }
                  newOccupation = 'Student; Grade $grade';
                } else {
                  newOccupation = selectedOccupationType!;
                }

                User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({
                      'name': newName,
                      'age': newAge,
                      'gender': newGender,
                      'description': newDescription,
                      'occupation': newOccupation,
                    });

                    var box = Hive.box(user.uid);
                    await box.put('name', newName);
                    await box.put('age', newAge);
                    await box.put('gender', newGender);
                    await box.put('description', newDescription);
                    await box.put('occupation', newOccupation);

                    widget.onSave();

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update profile: $e')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No user is currently signed in')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.purpleAccent,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
