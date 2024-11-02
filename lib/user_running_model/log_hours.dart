import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogHours extends StatefulWidget {
  const LogHours({super.key});

  @override
  LogHoursState createState() => LogHoursState();
}

class LogHoursState extends State<LogHours> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> pendingNonRecurringLogs = [];
  List<Map<String, dynamic>> pendingRecurringLogs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchPendingLogs();
  }

  Future<void> fetchPendingLogs() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    List<Map<String, dynamic>> nonRecurringLogs = [];
    List<Map<String, dynamic>> recurringLogs = [];

    final recurringBox = await Hive.openBox('recurringBox');
    final nonRecurringBox = await Hive.openBox('nonRecurringBox');
    final userBox = await Hive.openBox(userId); 

    final pendingLogsHive = List<Map<String, dynamic>>.from(userBox.get('pending_logs', defaultValue: []));

    nonRecurringBox.toMap().forEach((postID, post) {
      if (post['current'] == false) {
        for (var volunteers in post['accepted_volunteers']) {
          for (String ID in volunteers.keys) {
            if (ID == userId) {
              final date = post['start_date'] != null
                  ? DateFormat('yyyy-MM-dd').format(post['start_date'].toDate())
                  : null;

              if (date != null) {
                bool isPending = pendingLogsHive.any((pendingLog) =>
                    pendingLog['post_id'] == postID &&
                    pendingLog['dates'].contains(date));

                if (isPending) {
                  nonRecurringLogs.add({
                    'post_id': postID,
                    'post_title': post['title'] ?? 'No Title',
                    'org_name': post['org_name'] ?? 'Unknown Organization',
                    'is_recurring': false,
                    'date': date,
                    'start_time': null,
                    'end_time': null,
                  });
                }
              }
              break;
            }
          }
        }
      }
    });

    recurringBox.toMap().forEach((postID, post) {
      if (post['current'] == false) {
        for (var volunteers in post['accepted_volunteers']) {
          for (String ID in volunteers.keys) {
            if (ID == userId) {
              final startDate = post['start_date'].toDate();
              final endDate = post['end_date'].toDate();

              List<String> dates = [];
              for (var dt = startDate;
                  dt.isBefore(endDate) || dt.isAtSameMomentAs(endDate);
                  dt = dt.add(const Duration(days: 1))) {
                dates.add(DateFormat('yyyy-MM-dd').format(dt));
              }

              final pendingLog = pendingLogsHive.firstWhere(
                  (pl) => pl['post_id'] == postID,
                  orElse: () => {'dates': []});
              final pendingDates = List<String>.from(pendingLog['dates'] ?? []);

              final filteredDates = dates.where((date) => pendingDates.contains(date)).toList();

              if (filteredDates.isNotEmpty) {
                recurringLogs.add({
                  'post_id': postID,
                  'post_title': post['title'] ?? 'No Title',
                  'org_name': post['org_name'] ?? 'Unknown Organization',
                  'is_recurring': true,
                  'dates': filteredDates,
                  'selected_date': filteredDates.first,
                  'start_time': null,
                  'end_time': null,
                });
              }
              break;
            }
          }
        }
      }
    });

    setState(() {
      pendingNonRecurringLogs = nonRecurringLogs;
      pendingRecurringLogs = recurringLogs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Log Hours',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Non-Recurring'),
            Tab(text: 'Recurring'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildLogList(pendingNonRecurringLogs, false),
          buildLogList(pendingRecurringLogs, true),
        ],
      ),
    );
  }

  Widget buildLogList(List<Map<String, dynamic>> logs, bool isRecurring) {
    if (logs.isEmpty) {
      return Center(
        child: Text(
          'No pending logs to display.',
          style: GoogleFonts.lato(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];

        return buildLogCard(log, isRecurring);
      },
    );
  }

  Widget buildLogCard(Map<String, dynamic> log, bool isRecurring) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log['post_title'],
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              log['org_name'],
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isRecurring)
                  DropdownButton<String>(
                    value: log['selected_date'],
                    items: log['dates'].map<DropdownMenuItem<String>>((String date) {
                      return DropdownMenuItem<String>(
                        value: date,
                        child: Text(
                          DateFormat.yMMMd().format(DateTime.parse(date)),
                          style: GoogleFonts.lato(fontSize: 16),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newDate) {
                      setState(() {
                        log['selected_date'] = newDate!;
                      });
                    },
                    isExpanded: true,
                  )
                else
                  Text(
                    'Date: ${DateFormat.yMMMd().format(DateTime.parse(log['date']))}',
                    style: GoogleFonts.lato(fontSize: 16),
                  ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    log['start_time'] != null
                        ? 'Start Time: ${log['start_time'].format(context)}'
                        : 'Select Start Time',
                    style: GoogleFonts.lato(fontSize: 16),
                  ),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        log['start_time'] = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                    log['end_time'] != null
                        ? 'End Time: ${log['end_time'].format(context)}'
                        : 'Select End Time',
                    style: GoogleFonts.lato(fontSize: 16),
                  ),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        log['end_time'] = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    submitHours(log);
                  },
                  child: Text(
                    'Submit',
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void submitHours(Map<String, dynamic> log) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (log['start_time'] == null || log['end_time'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times.')),
      );
      return;
    }

    final dateStr = log['is_recurring'] ? log['selected_date'] : log['date'];
    final date = DateTime.parse(dateStr);

    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      log['start_time'].hour,
      log['start_time'].minute,
    );
    final endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      log['end_time'].hour,
      log['end_time'].minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    final hoursWorked = endDateTime.difference(startDateTime).inMinutes / 60.0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Submission'),
          content: Text(
            'You are about to submit your hours for:\n\n'
            'Post: ${log['post_title']}\n'
            'Organization: ${log['org_name']}\n'
            'Date: ${DateFormat.yMMMd().format(date)}\n'
            'Start Time: ${log['start_time'].format(context)}\n'
            'End Time: ${log['end_time'].format(context)}\n'
            'Total Hours: ${hoursWorked.toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final firestore = FirebaseFirestore.instance;

    List<Map<String, dynamic>> pendingLogs = [];

    try {
      await firestore.runTransaction((transaction) async {
        String collectionName = log['is_recurring'] ? 'recurring' : 'non_recurring';
        final postRef = firestore.collection(collectionName).doc(log['post_id']);

        final userRef = firestore.collection('users').doc(userId);

        final userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) {
          throw Exception('User document does not exist.');
        }
        final userData = userSnapshot.data()!;
        pendingLogs = List<Map<String, dynamic>>.from(userData['pending_logs'] ?? []);

        final postSnapshot = await transaction.get(postRef);
        if (!postSnapshot.exists) {
          throw Exception('Post document does not exist.');
        }
        final postData = postSnapshot.data()!;
        Map<String, dynamic> postLog = Map<String, dynamic>.from(postData['log'] ?? {});

        Map<String, dynamic>? pendingLog;
        for (var pl in pendingLogs) {
          if (pl['post_id'] == log['post_id']) {
            pendingLog = pl;
            break;
          }
        }

        if (pendingLog != null) {
          pendingLog['dates'].remove(dateStr);
          if (pendingLog['dates'].isEmpty) {
            pendingLogs.remove(pendingLog);
          } else {
            int index = pendingLogs.indexOf(pendingLog);
            pendingLogs[index] = pendingLog;
          }

          transaction.update(userRef, {'pending_logs': pendingLogs});
        }

        if (log['is_recurring']) {
          Map<String, dynamic> userLog = Map<String, dynamic>.from(postLog[userId] ?? {});
          userLog[dateStr] = {
            'hours_worked': hoursWorked,
            'start_time': log['start_time'].format(context),
            'end_time': log['end_time'].format(context),
          };
          postLog[userId] = userLog;
        } else {
          postLog[userId] = {
            'hours_worked': hoursWorked,
            'start_time': log['start_time'].format(context),
            'end_time': log['end_time'].format(context),
            'date': dateStr,
          };
        }

        transaction.update(postRef, {'log': postLog});
      });

      setState(() {
        if (log['is_recurring']) {
          log['dates'].remove(log['selected_date']);
          if (log['dates'].isEmpty) {
            pendingRecurringLogs.remove(log);
          } else {
            log['selected_date'] = log['dates'].first;
          }
        } else {
          pendingNonRecurringLogs.remove(log);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hours submitted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
      print('Error submitting hours: $e');
    }
  }
}
