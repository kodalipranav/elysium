import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elysium/methods/apply_to_post.dart';
import 'package:elysium/org_running_model/edit_post.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

Widget recurringPost ({required Map<String, dynamic> doc, required bool shortened, required orgName, required role, required docID}) {
  final ValueNotifier<bool> isExpanded = ValueNotifier<bool>(!shortened);
  Map<String, dynamic> snap = doc;
  final DateTime startDateTime = snap['start_date'].toDate();
  final DateTime endDateTime = snap['end_date'].toDate();
  final DateTime posted = snap['posted'].toDate();
  final String postedOn = DateFormat.yMMMd().add_jm().format(posted);
  final DateTime closeDateTime = snap['close_date'].toDate();
  DateTime? modified;
  String? modifiedString;
  if (snap['modified'] != null) {
    modified = snap['modified'].toDate();
    modifiedString = 'Modified on ${DateFormat.yMMMd().add_jm().format(modified!)}';
  }

  Widget post;

  void deleteDoc() async {
    DocumentReference postDocRef = FirebaseFirestore.instance.collection('recurring').doc(docID);
    await postDocRef.delete();
  }


  Future<void> deletePost(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {Navigator.pop(context);},
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              deleteDoc();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void handleClick(int item, context) {
    switch (item) {
      case 0:
        showModalBottomSheet(
          useSafeArea: true,
          isDismissible: false,
          isScrollControlled: true,
          shape: const LinearBorder(),
          context: context, builder: (context) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
              child: EditPost(docData: doc, docID: docID, orgName: orgName, isRecurring: true,)
            );
          }
        );
      case 1:
        deletePost(context);
    }
  }

  List<String?> scheduleDays = [null, null, null, null, null, null, null];
  List<String?> scheduleTimes = [null, null, null, null, null, null, null];

  if (snap['schedule'].isNotEmpty) {
    snap['schedule'].forEach((String key, value) {
      String time = '${value[0]} to ${value[1]}';

      if (key == "Monday") {
        scheduleTimes[0] = time;
        scheduleDays[0] = "Mon: ";
      }
      if (key == "Tuesday") {
        scheduleTimes[1] = time;
        scheduleDays[1] = "Tue: ";
      }    
      if (key == "Wednesday") {
        scheduleTimes[2] = time;
        scheduleDays[2] = "Wed: ";
      }    
      if (key == "Thursday") {
        scheduleTimes[3] = time;
        scheduleDays[3] = "Thu: ";
      }    
      if (key == "Friday") {
        scheduleTimes[4] = time;
        scheduleDays[4] = "Fri: ";
      }    
      if (key == "Saturday") {
        scheduleTimes[5] = time;
        scheduleDays[5] = "Sat: ";
      }    
      if (key == "Sunday") {
        scheduleTimes[6] = time;
        scheduleDays[6] = "Sun: ";
      }
    });
  }

  List<String> finalDays = [];
  List<String> finalTimes = [];

  for (var value in scheduleDays) {
    if (value != null) {
      finalDays.add(value);
    }
  }

  for (var value in scheduleTimes) {
    if (value != null) {
      finalTimes.add(value);
    }
  }

  post = ValueListenableBuilder<bool>(
    valueListenable: isExpanded, 
    builder: (context, isExpandedValue, _) {
      return GestureDetector(
        onTap: () => isExpanded.value = !isExpanded.value,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.decelerate,
            padding: EdgeInsets.symmetric(vertical: isExpandedValue ? 16 : 2),
            child: SizedBox(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (role == "user")
                          const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                snap['title'], 
                                style: GoogleFonts.montserrat(
                                  fontSize: 20, fontWeight: FontWeight.w600),
                                softWrap: true, overflow: TextOverflow.visible,
                              )
                            ),
                            role == 'organization' ? PopupMenuButton<int>(
                              onSelected: (item) => handleClick(item, context),
                              itemBuilder: (context) => [
                                const PopupMenuItem<int>(value: 0, child: Text('Edit')),
                                const PopupMenuItem<int>(value: 1, child: Text('Delete'))
                              ]
                            ) : const Text(''),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          Text(orgName, style: GoogleFonts.montserrat(fontSize: 11)),
                          isExpandedValue ? const Text('') : Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Posted on $postedOn', style: GoogleFonts.montserrat(fontSize: 11)),
                              if (snap['modified'] != null) 
                                Text(modifiedString!, style: GoogleFonts.montserrat(fontSize: 11)),
                            ],
                          ),
                        ],),
                        if (isExpandedValue)
                            Column(mainAxisSize: MainAxisSize.min, children: [
                              const Divider(height: 20),
                              const SizedBox(height: 10),
                              Text(snap['description'],
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              style: GoogleFonts.montserrat(fontSize: 14)),
                              const SizedBox(height: 10),
                                const Divider(height: 20),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(
                                    flex: 1,
                                    child: Center(child: Text("Dates", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500))),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Center(child: Text("Schedule", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500))),
                                  )
                                ],),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                            Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                Text("From", style: GoogleFonts.montserrat(fontSize: 11)),
                                                const SizedBox(height: 3),
                                                Text(DateFormat.yMMMd().format(startDateTime), style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
                                                const SizedBox(height: 8),
                                                Text("to", style: GoogleFonts.montserrat(fontSize: 11)),
                                                const SizedBox(height: 3),
                                                Text(DateFormat.yMMMd().format(endDateTime), style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
                                              ],
                                          )
                                        ],
                                      ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, children: [
                                      if (snap['schedule'].isEmpty)...[
                                        Text("Flexible Schedule", style: GoogleFonts.montserrat(fontSize: 14)),
                                        const SizedBox(height: 5),
                                        Text(
                                          "* determined based on circumstances; decided upon approval", 
                                          style: GoogleFonts.montserrat(fontSize: 11),
                                          textAlign: TextAlign.center,
                                        )
                                      ],
                                      if (snap['schedule'].isNotEmpty)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                              Column(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  for (String dayList in finalDays)...[
                                                    Text(dayList, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
                                                    const SizedBox(height: 5)
                                                  ]
                                                ],
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                mainAxisSize: MainAxisSize.max,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  for (String timeList in finalTimes)...[
                                                    Text(timeList, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500)),
                                                    const SizedBox(height: 5)
                                                  ]
                                                ],
                                              )
                                          ],
                                        )
                                    ],),
                                  )
                                ],),
                                const SizedBox(height: 10),
                                const Divider(height: 20),
                                const SizedBox(height: 10),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(children: [
                                      Text("Requirements: ", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 10),
                                      if (snap['requirements'].isEmpty)
                                        Text("None", style: GoogleFonts.montserrat(fontSize: 16))
                                    ],),
                                    if (snap['requirements'].isNotEmpty)...[
                                      const SizedBox(height: 6),
                                      for (String requirement in snap['requirements']) 
                                        Row(
                                          children: [
                                            const SizedBox(width: 30),
                                            Text("- ", style: GoogleFonts.montserrat(fontSize: 14)), 
                                            Expanded(child: Text(requirement, style: GoogleFonts.montserrat(fontSize: 14), softWrap: true,))
                                          ],
                                        )
                                    ],
                                    const SizedBox(height: 10),
                                    const Divider(height: 20),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      Text("Location: ", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          snap['location'], 
                                          style: GoogleFonts.montserrat(fontSize: 14), 
                                          softWrap: true, 
                                          overflow: TextOverflow.visible,
                                        )
                                      )
                                    ],),
                                    const SizedBox(height: 10),
                                    const Divider(height: 20),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Text("Number of Volunteers: ", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          snap['people'].isEmpty ? "Not specified" : snap['people'], 
                                          style: GoogleFonts.montserrat(fontSize: 14), 
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                        ),
                                      )
                                    ]),
                                    const SizedBox(height: 10),
                                    const Divider(height: 20),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Text("Post closes on: ", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 10,),
                                      Text(DateFormat.yMMMd().format(closeDateTime), style: GoogleFonts.montserrat()),
                                    ],),
                                    const SizedBox(height: 10),
                                    const Divider(height: 20),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      Text("Contact: ", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(snap['contact_name'], style: GoogleFonts.montserrat(fontSize: 14)),
                                          const SizedBox(height: 5),
                                          Text(snap['contact_info'], style: GoogleFonts.montserrat(fontSize: 14))
                                        ],
                                      )
                                    ],),
                                    const SizedBox(height: 10),
                                    const Divider(height: 20),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Text("Additional Information: ", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500)),
                                      if (snap['additional_info'].isEmpty)
                                        Text("None", style: GoogleFonts.montserrat(fontSize: 14))
                                    ],),
                                    if (snap['additional_info'].isNotEmpty)...[
                                      const SizedBox(height: 6),
                                      Text(
                                        snap['additional_info'], 
                                        style: GoogleFonts.montserrat(fontSize: 14), 
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      )
                                    ],
                                    const SizedBox(height: 10),
                                    const Divider(height: 20),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Posted on $postedOn", style: GoogleFonts.montserrat(fontSize: 11),),
                                            if (snap['modified'] != null) 
                                                Text(modifiedString!, style: GoogleFonts.montserrat(fontSize: 11)),
                                          ],
                                        ), 
                                        role == 'organization' ? const Text('') : MaterialButton(
                                          onPressed: () async {await applyToPost(context, true, docID);}, 
                                          color: Colors.deepPurple, 
                                          child: Text("Apply Now", style: GoogleFonts.montserrat(color: Colors.white)),)
                                    ],)
                                  ],
                                )
                            ],),
              
                            const SizedBox(height: 5,)
                      ],
                    ),
                )
              ),
            ),
          )
        )
      );
    });

  return post;
}