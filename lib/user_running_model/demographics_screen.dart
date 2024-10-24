import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DemographicsScreen extends StatefulWidget {
  const DemographicsScreen({required this.back, required this.success, super.key});

  final Function() back;
  final Function() success;

  @override
  State<DemographicsScreen> createState() => _DemographicsScreenState();
}

class _DemographicsScreenState extends State<DemographicsScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController gradeController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String status = 'Employed';

  TextField buildTextField(TextEditingController controller, String hint, bool numbersOnly, int length, IconData icon) {
    return TextField(
      maxLines: null,
      controller: controller,
      keyboardType: numbersOnly ? TextInputType.number : TextInputType.text,
      maxLength: length,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  String getOccupation() {
    if (status == "Student") {
      return "Student; Grade: ${gradeController.text}";
    } else {
      return status;
    }
  }

  bool checkStatus() {
    if (status == "Student") {
      return gradeController.text.isNotEmpty;
    } else {
      return true;
    }
  }

  void changeUserData() async {
    if (nameController.text.isNotEmpty && ageController.text.isNotEmpty && genderController.text.isNotEmpty && checkStatus()
      && descriptionController.text.isNotEmpty) {

      User? currentUser = FirebaseAuth.instance.currentUser;
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);

      await userDoc.update({
        'name': nameController.text,
        'age': ageController.text,
        'gender': genderController.text,
        'description': descriptionController.text,
        'occupation': getOccupation(),
      }).then((_) {widget.success();});
    } else {
      showDialog(context: context, builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: const Text("Please fill out all fields completely"),
          actions: [ElevatedButton(onPressed: () {Navigator.pop(context);}, child: const Text("OK"))],
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {FocusScope.of(context).unfocus();},
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          leading: IconButton(onPressed: widget.back, icon: const Icon(Icons.arrow_back)),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: ListView(
              children: [
                Text("About You", style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Text("* necessary for verification and volunteer acceptance", style: GoogleFonts.montserrat(fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                buildTextField(nameController, "Enter your name", false, 25, Icons.person),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: buildTextField(ageController, "Age", true, 2, Icons.calendar_today)),
                  const SizedBox(width: 20),
                  Expanded(child: buildTextField(genderController, "Gender", false, 20, Icons.wc)),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Text("Occupation: ", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField(
                    value: status,
                    items: ["Employed", "Unemployed", "Student"].map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newStatus) {setState(() {status = newStatus!;});},
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  )),
                ]),
                if (status == "Student") ...[
                  const SizedBox(height: 20),
                  buildTextField(gradeController, "Grade", false, 15, Icons.school),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: descriptionController,
                  maxLength: 300,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: "Describe yourself. Be expressive and concise; this is where organizations will get to know you when reviewing your application.",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {changeUserData();},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Save & Continue', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
