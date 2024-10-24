import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VerificationCard extends StatefulWidget {
  const VerificationCard({super.key, required this.recurring, required this.postID, required this.applicantData, required this.remove});

  final bool recurring;
  final Function() remove;
  final String postID;
  final Map applicantData;

  @override
  State<VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends State<VerificationCard> {
  ValueNotifier<bool> showApplicants = ValueNotifier<bool>(false);

  late Box postBox;
  late Map<dynamic, dynamic> applicantData;
  late String postTitle;

  @override
  void initState() {
    super.initState();
    applicantData = widget.applicantData;
    postBox  = widget.recurring ? Hive.box('recurringBox') : Hive.box('nonRecurringBox');
    postTitle = postBox.get(widget.postID)['title'];
  }

  
  void rejectUser(bool recurring, String docID, String userID, String userName, String docName) async {
    String collect = recurring ? 'recurring' : 'non_recurring';
    await FirebaseFirestore.instance.collection(collect).doc(docID).update({
      'applied_volunteers.$userID' : FieldValue.delete()
    });
    await FirebaseFirestore.instance.collection(collect).doc(docID).update({
      'denied' : FieldValue.arrayUnion([{userID : userName}])
    });
    await FirebaseFirestore.instance.collection('users').doc(userID).update({
      'applied' : FieldValue.arrayRemove([docID]),
      'rejected' : FieldValue.arrayUnion([docID]),
    });
    setState(() {
      applicantData.remove(userID);
      if (applicantData.isEmpty) {
        widget.remove;
      }
    });
  }

  void acceptUser(bool recurring, String docID, String userID, String userName, String docName) async {
    String collect = recurring ? 'recurring' : 'non_recurring';
    await FirebaseFirestore.instance.collection(collect).doc(docID).update({
      'applied_volunteers.$userID' : FieldValue.delete()
    });
    await FirebaseFirestore.instance.collection(collect).doc(docID).update({
      'accepted_volunteers' : FieldValue.arrayUnion([{userID : userName}])
    });
    await FirebaseFirestore.instance.collection('users').doc(userID).update({
      'applied' : FieldValue.arrayRemove([docID]),
      'accepted' : FieldValue.arrayUnion([docID]),
      'upcoming' : FieldValue.arrayUnion([{docID : recurring}]),
    });
    setState(() {
      applicantData.remove(userID);
      if (applicantData.isEmpty) {
        widget.remove;
      }
    });
  }

  @override 
  Widget build (context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showApplicants,
      builder: (context, showApplicantsValue, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          child: SizedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => showApplicants.value = !showApplicants.value,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                            child: Text(
                              postTitle, 
                              style: GoogleFonts.montserrat(
                                fontSize: 20, 
                                fontWeight: FontWeight.w600),
                              softWrap: true,
                            ),
                          )),
                          const SizedBox(width: 10,),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Colors.red,shape: BoxShape.circle,),
                                  constraints: const BoxConstraints(minHeight: 20, minWidth: 20),
                                  child: Center(child: Text('${widget.applicantData.length}', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold))),
                                ),
                              ),
                              const SizedBox(width: 10),
                              showApplicantsValue ? const Icon(Icons.arrow_drop_up) : const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (showApplicantsValue)
                Container(
                  decoration: BoxDecoration(color: Colors.amber[50]),
                  height: 175,
                  child: ListView.builder(
                    itemCount: widget.applicantData.length,
                    itemBuilder: (context, index) {
                      String userID = widget.applicantData.keys.elementAt(index);
                      Map details = widget.applicantData[userID];
                      return ListTile(
                        title: Text(details['name'], style: GoogleFonts.montserrat()),
                        onLongPress: () => showDialog(
                          context: context, builder: (context) {
                            return AlertDialog(
                              title: Text('${details['name']}', style: GoogleFonts.montserrat(),),
                              content: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min, 
                                  children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 1, child: Text("Age: ${details['age']}", style: GoogleFonts.montserrat(fontSize: 14)),),
                                      Expanded(flex: 2, child: Text("Gender: ${details['gender']}", style: GoogleFonts.montserrat(fontSize: 14)))
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text("Email: ${details['email']}", style: GoogleFonts.montserrat(fontSize: 14)),
                                  const SizedBox(height: 10),
                                  Text("Status: ${details['occupation']}", style: GoogleFonts.montserrat(fontSize: 14)),
                                  const SizedBox(height: 10),
                                  Text("Description: ", style: GoogleFonts.montserrat(fontSize: 14)),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 94,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            border: Border.all(color: Colors.grey[350]!, width: 2)
                                          ),
                                          child: SingleChildScrollView(
                                            child: Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                details['description'],
                                                style: GoogleFonts.montserrat(fontSize: 14),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                ],),
                              ),
                              actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: GoogleFonts.montserrat()))],
                            );
                          }
                        ),
                        trailing: SizedBox(
                          width: 180,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              MaterialButton(minWidth: 20, onPressed: () => showDialog(context: context, builder: (context) =>
                                SimpleDialog(
                                  title: Center(child: Text("Confirm Rejection", style: GoogleFonts.montserrat())),
                                  children: [
                                    MaterialButton(
                                      elevation: 10,
                                      onPressed: () {
                                        rejectUser(widget.recurring, widget.postID, userID, details['name'], postTitle);
                                        Navigator.pop(context);}, 
                                      color: Colors.redAccent,
                                      child: Text("Reject", style: GoogleFonts.montserrat(color: Colors.white)),),
                                    MaterialButton(
                                      elevation: 10,
                                      color: Colors.grey[100],
                                      onPressed: (){Navigator.pop(context);}, 
                                      child: Text("Cancel", style: GoogleFonts.montserrat()),),
                                  ],
                                )),color: Colors.redAccent,
                                child: const Text("Reject", style: TextStyle(color: Colors.white)),
                              ),
                              const SizedBox(width: 10),
                              MaterialButton(minWidth: 20, onPressed: () => showDialog(context: context, builder: (context) =>
                                SimpleDialog(
                                  title: Center(child: Text("Confirm Acceptance", style: GoogleFonts.montserrat())),
                                  children: [
                                    MaterialButton(
                                      elevation: 10,
                                      onPressed: () {
                                        acceptUser(widget.recurring, widget.postID, userID, details['name'], postTitle);
                                        Navigator.pop(context);}, 
                                      color: Colors.green[700],
                                      child: Text("Accept", style: GoogleFonts.montserrat(color: Colors.white)),),
                                    MaterialButton(
                                      elevation: 10,
                                      color: Colors.grey[100],
                                      onPressed: (){Navigator.pop(context);}, 
                                      child: Text("Cancel", style: GoogleFonts.montserrat()),),
                                  ],
                                )),color: Colors.green[700],
                                child: const Text("Accept", style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  )
                )
              ],
            ),
          ),
        );
      },
    );
  }
}