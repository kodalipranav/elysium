import 'package:elysium/methods/count_total_applications.dart';
import 'package:elysium/widgets/sharp_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OrgHome extends StatefulWidget {
  const OrgHome({
    required this.logOut, required this.postPage, required this.verifyApplicationsPage, 
    required this.verifyHoursPage, required this.completedPostsPage, super.key});

  final Function() logOut;
  final Function() postPage;
  final Function() verifyApplicationsPage;
  final Function() verifyHoursPage;
  final Function() completedPostsPage;

  @override
  State<OrgHome> createState() => _OrgHomeState();
}

class _OrgHomeState extends State<OrgHome> {
  String orgName = '';
  int count = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await getOrgName();
    await getCount();
  }

  Future<void> getOrgName () async {
    final user = FirebaseAuth.instance.currentUser;
    final orgBox = Hive.box('orgBox');
    final orgData = orgBox.get(user!.uid);
    setState(() {
      orgName = orgData['name'];
    });
  }

  Future<void> getCount() async {
    print(orgName);
    int tempCount = await countTotalApplications(orgName);
    setState(() {
      count = tempCount;
    });
  }

  @override 
  Widget build (context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 210, 233, 239),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Dashboard',
          style: GoogleFonts.josefinSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              showDialog(context: context, builder: (context) {
                return AlertDialog(
                  title: Text("Log Out", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                  content: Text("Are you sure you want to log out?", style: GoogleFonts.lato()),
                  actions: [
                    TextButton(
                      onPressed: () { Navigator.pop(context); },
                      child: Text('Cancel', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        FirebaseAuth.instance.signOut();
                        widget.logOut();
                      },
                      style: TextButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: Text('Log Out', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                    )
                  ]
                );
              });
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          )
        ]
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  SharpButton(
                    onTap: widget.verifyHoursPage,
                    text: "Verify Hours",
                    icon: Icons.post_add_sharp,
                    color: Colors.white,
                    iconColor: Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      SharpButton(
                        onTap: widget.verifyApplicationsPage,
                        text: "Verify Applications",
                        icon: Icons.add_task,
                        color: Colors.white,
                        iconColor: Colors.teal,
                      ),
                      Positioned(
                        right: 10,
                        top: 5,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minHeight: 30, minWidth: 30),
                            child: Center(
                              child: Text(
                                '$count',
                                style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            ),
                          ),
                        )
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  SharpButton(
                    onTap: widget.postPage,
                    text: "Current Posts",
                    icon: Icons.post_add_sharp,
                    color: Colors.white,
                    iconColor: Colors.teal,
                  ),
                  const SizedBox(height: 16),
                  SharpButton(
                    onTap: widget.completedPostsPage,
                    text: "Completed Posts",
                    icon: Icons.check_box,
                    color: Colors.white,
                    iconColor: Colors.teal,
                  ),
                ],
              ),
            ],
          ),
        )
      ));
  }
}
