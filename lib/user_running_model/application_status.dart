import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ApplicationStatus extends StatefulWidget{
  const ApplicationStatus({super.key});

  @override
  State<ApplicationStatus> createState() => _ApplicationStatusState();
}

class _ApplicationStatusState extends State<ApplicationStatus> {
  bool currentlyRecurring = false;
  bool pending = true;
  bool accepted = false;
  bool rejected = false;

  void switchBack() {
    setState(() {
      currentlyRecurring = false;
    });
  }

  void switchToRecur() {
    setState(() {
      currentlyRecurring = true;    
    });
  }

  void switchToPending() {
    setState(() {
      pending = true;
      accepted = false;
      rejected = false;
    });
  }

  void switchToAccepted() {
    setState(() {
      pending = false;
      accepted = true;
      rejected = false;
    });
  }

  void switchToRejected() {
    setState(() {
      pending = false;
      accepted = false;
      rejected = true;
    });
  }

  List<Widget> getPosts(Box usedBox, Box userBox) {
    List<Widget> returned = [];
    List<String> names = [];
    if (pending) {
      List pendingIDs = userBox.get('applied', defaultValue: []);
      for (String ID in pendingIDs.reversed.toList()) {
        if (usedBox.containsKey(ID)) {
          names.add(usedBox.get(ID)['title']);
        }
      }
    } else if (accepted) {
      List acceptedIDs = userBox.get('accepted', defaultValue: []);
      for (String ID in acceptedIDs.reversed.toList()) {
        if (usedBox.containsKey(ID)) {
          names.add(usedBox.get(ID)['title']);
        }
      }
    } else {
      List rejectedIDs = userBox.get('rejected', defaultValue: []);
      for (String ID in rejectedIDs.reversed.toList()) {
        if (usedBox.containsKey(ID)) {
          names.add(usedBox.get(ID)['title']);
        }
      }
    }

    for (String postName in names) {
      returned.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              ListTile(
                title: Text(postName, style: GoogleFonts.montserrat(fontSize: 18)),
              ),
              const Divider()
            ],
          ),
        )
      );
    }

    return returned;
  }

  @override
  Widget build(BuildContext context) {
    Box usedBox = currentlyRecurring ? Hive.box('recurringBox') : Hive.box('nonRecurringBox');
    Box userBox = Hive.box(FirebaseAuth.instance.currentUser!.uid);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Applications Status"),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Post Type Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: MaterialButton(                 
                  elevation: 4,   
                  minWidth: double.infinity,
                  onPressed: switchBack,
                  color: !currentlyRecurring ?  Colors.brown : Colors.grey[400], 
                  child: Text(
                    "Non-Recurring Posts", 
                    style: GoogleFonts.montserrat(
                      color: !currentlyRecurring ? Colors.white : Colors.black, 
                      fontWeight: FontWeight.w600
                    )
                  )
                )
              ),
              Expanded(
                flex: 1,
                child: MaterialButton(
                  elevation: 4,
                  minWidth: double.infinity,
                  onPressed: switchToRecur,
                  color: currentlyRecurring ?  Colors.brown : Colors.grey[400], 
                  child: Text(
                    "Recurring Posts", 
                    style: GoogleFonts.montserrat(
                      color: currentlyRecurring ? Colors.white : Colors.black, 
                      fontWeight: FontWeight.w600
                    )
                  )
                )
              ),
            ]
          ),
          // Status Buttons
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(                 
                    elevation: 4,   
                    minWidth: double.infinity,
                    onPressed: switchToPending,
                    color: pending ?  Colors.brown : Colors.grey[400], 
                    child: Text(
                      "Pending", 
                      style: GoogleFonts.montserrat(
                        color: pending ? Colors.white : Colors.black, 
                        fontWeight: FontWeight.w500
                      )
                    )
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    elevation: 4,
                    minWidth: double.infinity,
                    onPressed: switchToAccepted,
                    color: accepted ?  Colors.brown : Colors.grey[400], 
                    child: Text(
                      "Accepted", 
                      style: GoogleFonts.montserrat(
                        color: accepted ? Colors.white : Colors.black, 
                        fontWeight: FontWeight.w500
                      )
                    )
                  ),
                )
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    elevation: 4,
                    minWidth: double.infinity,
                    onPressed: switchToRejected,
                    color: rejected ?  Colors.brown : Colors.grey[400], 
                    child: Text(
                      "Rejected", 
                      style: GoogleFonts.montserrat(
                        color: rejected ? Colors.white : Colors.black, 
                        fontWeight: FontWeight.w500
                      )
                    )
                  ),
                )
              ),
            ],
          ),
          const Divider(),
          // List of Posts
          Expanded(
            child: ListView(
              children: getPosts(usedBox, userBox)
            ),
          )
        ],
      ),
    );
  }
}
