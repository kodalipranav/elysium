import 'package:elysium/user_running_model/application_status.dart';
import 'package:elysium/user_running_model/grid_item.dart';
import 'package:elysium/user_running_model/log_hours.dart';
import 'package:elysium/user_running_model/org_search_delegate.dart';
import 'package:elysium/user_running_model/schedule.dart';
import 'package:elysium/user_running_model/search_by_date.dart';
import 'package:elysium/user_running_model/search_by_location.dart';
import 'package:elysium/user_running_model/information/user_information.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key, required this.signOut});

  final Function() signOut;

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int pendingLogsCount = 0;

  @override
  void initState() {
    super.initState();
    computePendingLogsCount();
  }

  Future<void> computePendingLogsCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    int count = 0;

    final recurringBox = await Hive.openBox('recurringBox');
    final nonRecurringBox = await Hive.openBox('nonRecurringBox');

    nonRecurringBox.toMap().forEach((postID, postInformation) {
      if (nonRecurringBox.get(postID)['current'] == false) {
        for (var volunteers in nonRecurringBox.get(postID)['accepted_volunteers']) {
          for (String ID in volunteers.keys) {
            if (ID == userId) {
              count++;
              break;
            }
          }
        }
      }
    });

    recurringBox.toMap().forEach((postID, postInformation) {
      if (recurringBox.get(postID)['current'] == false) {
        for (var volunteers in recurringBox.get(postID)['accepted_volunteers']) {
          for (String ID in volunteers.keys) {
            if (ID == userId) {
              count++;
              break;
            }
          }
        }
      }
    });

    setState(() {
      pendingLogsCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Colors.white;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: OrgSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          children: const [
            GridItem(
              text: "User Information",
              icon: Icons.person_outline,
              color: Color(0xFF4CAF50),
              newScreen: UserInformation(),
            ),
            GridItem(
              text: "Schedule",
              icon: Icons.calendar_today_outlined,
              color: Color(0xFF2196F3),
              newScreen: Schedule(),
            ),
            GridItem(
              text: "Applications",
              icon: Icons.assignment_outlined,
              color: Color(0xFFFFC107),
              newScreen: ApplicationStatus(),
            ),
            GridItem(
              text: "Log Hours",
              icon: Icons.access_time_outlined,
              color: Color(0xFF3F51B5),
              newScreen: LogHours(),
            ),
            GridItem(
              text: "Search by Date",
              icon: Icons.date_range_outlined,
              color: Color(0xFFFF5722),
              newScreen: SearchByDate(),
            ),
            GridItem(
              text: "Search by Location",
              icon: Icons.location_on_outlined,
              color: Color(0xFF9C27B0), 
              newScreen: SearchByLocation(),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Log Out",
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to log out?",
            style: GoogleFonts.lato(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                FirebaseAuth.instance.signOut();
                widget.signOut();
              },
              child: Text(
                'Log Out',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
