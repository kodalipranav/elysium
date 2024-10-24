import 'package:elysium/user_running_model/information/modal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';

class UserInformation extends StatefulWidget {
  const UserInformation({super.key});

  @override
  State<UserInformation> createState() => UserInformationState();
}

class UserInformationState extends State<UserInformation> {
  String name = '';
  String email = '';
  int hours = 0;
  String gender = '';
  String contact = '';
  String age = '';
  String occupation = '';
  String description = '';
  List<String>? orgsWorkedWith;
  bool loading = true;

  final Color themeColor = const Color.fromARGB(255, 225, 214, 179);
  final Color darkBrown = const Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var box = Hive.box(user.uid);
      List<dynamic>? orgs = box.get('orgs_worked_with');
      setState(() {
        name = box.get('name', defaultValue: '') as String;
        email = user.email ?? '';
        hours = box.get('hours');
        gender = box.get('gender', defaultValue: '') as String;
        contact = box.get('contact', defaultValue: '') as String;
        age = box.get('age', defaultValue: '') as String;
        occupation = box.get('occupation', defaultValue: '') as String;
        description = box.get('description', defaultValue: '') as String;
        orgsWorkedWith = orgs != null ? List<String>.from(orgs) : null;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Widget sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: darkBrown),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.lato(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget infoRow(String label, String value, IconData icon) {
    if (label == 'Description') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: darkBrown),
                const SizedBox(width: 16),
                Text(
                  '$label:',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.isNotEmpty ? value : 'Not provided.',
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: darkBrown),
                const SizedBox(width: 16),
                Text(
                  '$label:',
                  style: GoogleFonts.lato(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Text(
                value.isNotEmpty ? value : 'Not provided.',
                textAlign: TextAlign.right,
                style: GoogleFonts.lato(
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return ModalSheet(
          name: name,
          age: age,
          gender: gender,
          description: description,
          occupation: occupation,
          onSave: () {
            fetchData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Information'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: darkBrown),
            onPressed: _showEditModal,
          ),
        ],
        backgroundColor: themeColor,
        foregroundColor: darkBrown,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Hours Completed',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: darkBrown,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$hours',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: darkBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  sectionHeader('Personal Information', Icons.person),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        infoRow('Name', name, Icons.person),
                        const Divider(height: 1, color: Colors.grey),
                        infoRow('Age', age, Icons.cake),
                        const Divider(height: 1, color: Colors.grey),
                        infoRow('Gender', gender, Icons.transgender),
                        const Divider(height: 1, color: Colors.grey),
                        infoRow('Description', description, Icons.description),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  sectionHeader('Contact Information', Icons.contact_mail),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        infoRow('Contact', contact, Icons.phone),
                        const Divider(height: 1, color: Colors.grey),
                        infoRow('Email', email, Icons.email),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  sectionHeader('Professional Information', Icons.work),
                  const SizedBox(height: 8),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        infoRow('Occupation', occupation, Icons.business_center),
                        const Divider(height: 1, color: Colors.grey),
                        orgsWorkedWith != null && orgsWorkedWith!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Organizations Worked With:',
                                      style: GoogleFonts.lato(
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8.0,
                                      runSpacing: 4.0,
                                      children: orgsWorkedWith!.map((org) {
                                        return Chip(
                                          label: Text(org, style: GoogleFonts.lato()),
                                          backgroundColor: darkBrown.withOpacity(0.1),
                                          avatar: Icon(Icons.business, size: 16, color: darkBrown),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.business, color: darkBrown),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'No organizations worked with.',
                                        style: GoogleFonts.lato(
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
