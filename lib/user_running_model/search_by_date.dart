import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elysium/widgets/non_recurring_post.dart';
import 'package:elysium/widgets/recurring_post.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class SearchByDate extends StatefulWidget {
  const SearchByDate({super.key});

  @override
  SearchByDateState createState() => SearchByDateState();
}

class SearchByDateState extends State<SearchByDate> {
  DateTime? startDate;
  DateTime? endDate;
  bool selectedDates = false;
  List<String> nonRecurringIDs = [];
  List<String> recurringIDs = [];
  bool recurring = false;
  bool isRecurring = false;

  void backToNon() {
    setState(() {
      isRecurring = false;
    });
  }

  void goToRecur() {
    setState(() {
      isRecurring = true;
    });
  }

  void showAllDates() {
    if (startDate != null && endDate != null) {
      Box recurBox = Hive.box('recurringBox');
      Box nonRecurBox = Hive.box('nonRecurringBox');

      for (var key in recurBox.keys) {
        final post = recurBox.get(key);
        Timestamp postStartDate = post['start_date'];
        if ((postStartDate.toDate().compareTo(startDate!) >= 0) && (postStartDate.toDate().compareTo(endDate!) <= 0)) {
          setState(() {
            recurringIDs.add(key);
          });
        }
      }

      for (var key in nonRecurBox.keys) {
        final post = nonRecurBox.get(key);
        Timestamp postStartDate = post['start_date'];
        if ((postStartDate.toDate().compareTo(startDate!) >= 0) && (postStartDate.toDate().compareTo(endDate!) <= 0)) {
          setState(() {
            nonRecurringIDs.add(key);
          });
        }
      }

      setState(() {
        selectedDates = true;
      });
    } else {
      showDialog(
        context: context, 
        builder: (ctx) => AlertDialog(
          title: const Text("Complete fields"), 
          content: const Text("Please fill in both the start date and the end date. \nIf you need only one date, make them the same date."),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],));
    }
  }

  void selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (endDate != null) {
        if (picked.compareTo(endDate!) > 0) {
          if (mounted) {
            showDialog(context: context, builder: (ctx) => 
              AlertDialog(
                title: const Text("Time Error"), 
                content: const Text("Start date cannot be after the end date"),
                actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
              )
            );
          }
        } else {
          setState(() {
            startDate = picked;
          });
        }
      } else {
        setState(() {
          startDate = picked;
        });
      }
    }
  }

  void selectEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      if (startDate != null) {
        if (picked.compareTo(startDate!) < 0) {
          if (mounted) {
            showDialog(context: context, builder: (ctx) => 
              AlertDialog(
                title: const Text("Time Error"), 
                content: const Text("End date cannot be before the start date"),
                actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
              )
            );
          }
        } else {
          setState(() {
            endDate = picked;
          });
        }
      } else {
        setState(() {
          endDate = picked;
        });
      }
    }
  }

  List<Widget> buildCards() {
    Box usingBox = isRecurring ? Hive.box("recurringBox") : Hive.box("nonRecurringBox");
    List<Widget> cards = [];

    if (isRecurring) {
      for (String postID in recurringIDs) {
        Map<String, dynamic> postDoc = usingBox.get(postID);
        String nameOfOrg = postDoc['org_name'];
        cards.add(recurringPost(doc: postDoc, shortened: true, orgName: nameOfOrg, role: "user", docID: postID));
      }
    } else {
      for (String postID in nonRecurringIDs) {
        Map<String, dynamic> postDoc = usingBox.get(postID);
        String nameOfOrg = postDoc['org_name'];
        cards.add(nonRecurringPost(doc: postDoc, shortened: true, orgName: nameOfOrg, role: "user", docID: postID));
      }
    }

    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search By Date"),),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: MaterialButton(
                    onPressed: () => selectStartDate(),
                    color: Colors.brown[100],
                    child: Text(startDate == null ? "Select Start Date" : DateFormat.yMMMd().format(startDate!))
                  ),
                ),
              ),
              const Text(" - "),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: MaterialButton(
                    onPressed: () => selectEndDate(),
                    color: Colors.brown[100],
                    child: Text(endDate == null ? "Select End Date" : DateFormat.yMMMd().format(endDate!))
                  ),
                )
              ),
              const SizedBox(width: 6),
              if (selectedDates)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                  child: MaterialButton(
                    onPressed: () => showAllDates(),
                    color: Colors.deepPurple,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Go", style: TextStyle(color: Colors.white)),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward, color: Colors.white,)
                      ],
                    )
                  ),
                )
            ],
          ),
          if (!selectedDates)
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 6, 12, 6),
                  child: MaterialButton(
                    onPressed: () => showAllDates(),
                    color: Colors.deepPurple,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Go", style: TextStyle(color: Colors.white)),
                        SizedBox(width: 5),
                        Icon(Icons.arrow_forward, color: Colors.white,)
                      ],
                    )
                  ),
                ),
              )
            ]
          ),
          if (selectedDates)
            const Divider(),
          if (selectedDates)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: MaterialButton(                 
                            minWidth: double.infinity,
                            onPressed: backToNon,
                            color: !isRecurring ?  Colors.brown : Colors.grey[400], 
                            child: Text(
                              "Non-Recurring Posts", 
                              style: GoogleFonts.montserrat(color: !isRecurring ? Colors.white : Colors.black, fontWeight: FontWeight.w700))
                          )
                        ),
                        Expanded(
                          flex: 1,
                          child: MaterialButton(
                            minWidth: double.infinity,
                            onPressed: goToRecur,
                            color: isRecurring ?  Colors.brown : Colors.grey[400], 
                            child: Text(
                              "Recurring Posts", 
                              style: GoogleFonts.montserrat(color: isRecurring ? Colors.white : Colors.black, fontWeight: FontWeight.w700))
                          )
                        ),
                      ]
                    ),
                  ),
                  Expanded(
                    child: ListView(children: buildCards(),)
                  )
                ],
              )
            )
        ],),
      ),
    );
  }
}
