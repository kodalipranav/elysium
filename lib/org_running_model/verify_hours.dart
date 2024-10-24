// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class VerifyHours extends StatefulWidget {
  const VerifyHours({required this.back, super.key});

  final Function() back;

  @override
  State<VerifyHours> createState() => VerifyHoursState();
}

class VerifyHoursState extends State<VerifyHours> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String orgName = '';
  List<Map<String, dynamic>> recurringPosts = [];
  List<Map<String, dynamic>> nonRecurringPosts = [];
  bool isLoading = true;
  late Box<dynamic> recurringBox;
  late Box<dynamic> nonRecurringBox;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    recurringBox = Hive.box('recurringBox');
    nonRecurringBox = Hive.box('nonRecurringBox');
    loadOrgName();
    recurringBox.watch().listen((event) {
      fetchPosts();
    });
    nonRecurringBox.watch().listen((event) {
      fetchPosts();
    });
  }

  Future<void> loadOrgName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final orgBox = Hive.box('orgBox');
    final orgData = orgBox.get(user.uid);
    setState(() {
      orgName = orgData['name'];
    });
    await fetchPosts();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchPosts() async {
    List<Map<String, dynamic>> tempRecurring = [];
    List<Map<String, dynamic>> tempNonRecurring = [];

    for (var entry in recurringBox.toMap().entries) {
      var postID = entry.key;
      var post = entry.value;
      if (post['org_name'] == orgName && post['log'] != null && (post['log'] as Map).isNotEmpty) {
        Map<String, dynamic> filteredLog = {};
        (post['log'] as Map<String, dynamic>).forEach((userId, userLogs) {
          Map<String, dynamic> pendingDates = {};
          (userLogs as Map<String, dynamic>).forEach((dateStr, logData) {
            if (logData['status'] == null || logData['status'] == 'pending') {
              pendingDates[dateStr] = logData;
            }
          });
          if (pendingDates.isNotEmpty) {
            filteredLog[userId] = pendingDates;
          }
        });
        if (filteredLog.isNotEmpty) {
          tempRecurring.add({
            'post_id': postID,
            'title': post['title'] ?? 'No Title',
            'log': filteredLog,
          });
        }
      }
    }

    for (var entry in nonRecurringBox.toMap().entries) {
      var postID = entry.key;
      var post = entry.value;
      if (post['org_name'] == orgName && post['log'] != null && (post['log'] as Map).isNotEmpty) {
        Map<String, dynamic> filteredLog = {};
        (post['log'] as Map<String, dynamic>).forEach((userId, logData) {
          if (logData['status'] == null || logData['status'] == 'pending') {
            filteredLog[userId] = logData;
          }
        });
        if (filteredLog.isNotEmpty) {
          tempNonRecurring.add({
            'post_id': postID,
            'title': post['title'] ?? 'No Title',
            'log': filteredLog,
          });
        }
      }
    }

    setState(() {
      recurringPosts = tempRecurring;
      nonRecurringPosts = tempNonRecurring;
    });
  }

  Future<String> getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.get('name') ?? 'Unknown User';
      } else {
        return 'Unknown User';
      }
    } catch (e) {
      return 'Unknown User';
    }
  }

  void showVerificationDialogNonRecurring(String userId, String userName, Map<String, dynamic> logData, String collection, String postId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Verify Hours", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("User: $userName", style: GoogleFonts.lato(fontSize: 16)),
              const SizedBox(height: 8),
              Text("Date: ${DateFormat.yMMMd().format(DateTime.parse(logData['date']))}", style: GoogleFonts.lato(fontSize: 16)),
              const SizedBox(height: 8),
              Text("Start Time: ${logData['start_time']}", style: GoogleFonts.lato(fontSize: 16)),
              const SizedBox(height: 8),
              Text("End Time: ${logData['end_time']}", style: GoogleFonts.lato(fontSize: 16)),
              const SizedBox(height: 8),
              Text("Hours Worked: ${logData['hours_worked']}", style: GoogleFonts.lato(fontSize: 16)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection(collection).doc(postId).update({
                  'log.$userId.status': 'denied',
                });
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'hours': FieldValue.increment(0),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hours denied for $userName.', style: GoogleFonts.lato())),
                );
              },
              child: Text('Deny', style: GoogleFonts.lato(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection(collection).doc(postId).update({
                  'log.$userId.status': 'approved',
                });
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'hours': FieldValue.increment(logData['hours_worked']),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hours approved for $userName.', style: GoogleFonts.lato())),
                );
              },
              child: Text('Accept', style: GoogleFonts.lato(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  void showVerificationDialogRecurring(String userId, String userName, Map<String, dynamic> userLogs, String collection, String postId) {
    String? selectedDate;
    List<String> pendingDates = userLogs.entries
        .where((entry) => entry.value['status'] == null || entry.value['status'] == 'pending')
        .map((entry) => entry.key)
        .toList();
    pendingDates.sort((a, b) => a.compareTo(b));
    if (pendingDates.isEmpty) return;
    selectedDate = pendingDates.first;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Verify Hours for $userName", style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedDate,
                    items: pendingDates.map<DropdownMenuItem<String>>((String dateStr) {
                      return DropdownMenuItem<String>(
                        value: dateStr,
                        child: Text(DateFormat.yMMMd().format(DateTime.parse(dateStr)), style: GoogleFonts.lato()),
                      );
                    }).toList(),
                    onChanged: (String? newDate) {
                      if (newDate != null) {
                        setState(() {
                          selectedDate = newDate;
                        });
                      }
                    },
                    isExpanded: true,
                    underline: Container(
                      height: 2,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedDate != null && userLogs[selectedDate!] != null) ...[
                    Text("Start Time: ${userLogs[selectedDate!]['start_time']}", style: GoogleFonts.lato(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("End Time: ${userLogs[selectedDate!]['end_time']}", style: GoogleFonts.lato(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("Hours Worked: ${userLogs[selectedDate!]['hours_worked']}", style: GoogleFonts.lato(fontSize: 16)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (selectedDate == null) return;
                    await FirebaseFirestore.instance.collection(collection).doc(postId).update({
                      'log.$userId.$selectedDate.status': 'denied',
                    });
                    await FirebaseFirestore.instance.collection('users').doc(userId).update({
                      'hours': FieldValue.increment(0),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hours denied for $userName on ${DateFormat.yMMMd().format(DateTime.parse(selectedDate!))}.', style: GoogleFonts.lato())),
                    );
                  },
                  child: Text('Deny', style: GoogleFonts.lato(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedDate == null) return;
                    await FirebaseFirestore.instance.collection(collection).doc(postId).update({
                      'log.$userId.$selectedDate.status': 'approved',
                    });
                    await FirebaseFirestore.instance.collection('users').doc(userId).update({
                      'hours': FieldValue.increment(userLogs[selectedDate!]['hours_worked']),
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hours approved for $userName on ${DateFormat.yMMMd().format(DateTime.parse(selectedDate!))}.', style: GoogleFonts.lato())),
                    );
                  },
                  child: Text('Accept', style: GoogleFonts.lato(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      });
    }

  Widget buildPostCard(Map<String, dynamic> post, String collection) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(post['title'], style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
        children: post['log'].entries.map<Widget>((entry) {
          String userId = entry.key;
          Map<String, dynamic> logData = Map<String, dynamic>.from(entry.value);
          if (collection == 'recurring') {
            return FutureBuilder<String>(
              future: getUserName(userId),
              builder: (context, snapshot) {
                String userName = snapshot.data ?? 'Loading...';
                return ListTile(
                  title: Text(userName, style: GoogleFonts.lato(fontSize: 16)),
                  trailing: const Icon(Icons.info_outline, color: Colors.grey),
                  onLongPress: () {
                    if (logData.isNotEmpty) {
                      showVerificationDialogRecurring(userId, userName, logData, collection, post['post_id']);
                    }
                  },
                );
              },
            );
          } else {
            return FutureBuilder<String>(
              future: getUserName(userId),
              builder: (context, snapshot) {
                String userName = snapshot.data ?? 'Loading...';
                return ListTile(
                  title: Text(userName, style: GoogleFonts.lato(fontSize: 16)),
                  trailing: const Icon(Icons.info_outline, color: Colors.grey),
                  onLongPress: () {
                    if (logData.isNotEmpty) {
                      showVerificationDialogNonRecurring(userId, userName, logData, collection, post['post_id']);
                    }
                  },
                );
              },
            );
          }
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Hours', style: GoogleFonts.josefinSans(fontSize: 24, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Non-Recurring'),
            Tab(text: 'Recurring'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.back,
          tooltip: 'Back',
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : TabBarView(
              controller: _tabController,
              children: [
                nonRecurringPosts.isEmpty
                    ? Center(child: Text('No pending logs to verify.', style: GoogleFonts.lato(fontSize: 18, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: nonRecurringPosts.length,
                        itemBuilder: (context, index) {
                          return buildPostCard(nonRecurringPosts[index], 'non_recurring');
                        },
                      ),
                recurringPosts.isEmpty
                    ? Center(child: Text('No pending logs to verify.', style: GoogleFonts.lato(fontSize: 18, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: recurringPosts.length,
                        itemBuilder: (context, index) {
                          return buildPostCard(recurringPosts[index], 'recurring');
                        },
                      ),
              ],
            ),
    );
  }
}
