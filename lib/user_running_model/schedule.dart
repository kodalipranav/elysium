import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  ScheduleState createState() => ScheduleState();
}

class ScheduleState extends State<Schedule> {
  late List<Appointment> appointments;
  late List<Task> allTasks;
  late List<Task> dateTasks;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    appointments = [];
    allTasks = [];
    dateTasks = [];
    loadData();
  }

  void loadData() {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;
    var userBox = Hive.box(userId);
    List<Map<String, dynamic>> upcomingPosts =
        List<Map<String, dynamic>>.from(userBox.get('upcoming', defaultValue: []));
    List<Appointment> addedAppointments = [];
    List<Task> addedTasks = [];
    for (var entry in upcomingPosts) {
      entry.forEach((postId, isRecurring) {
        if (isRecurring) {
          var recurringBox = Hive.box('recurringBox');
          var recurringPost = recurringBox.get(postId);
          if (recurringPost != null) {
            Timestamp startTimestamp = recurringPost['start_date'];
            Timestamp endTimestamp = recurringPost['end_date'];
            Map<String, dynamic> schedule = recurringPost['schedule'] ?? {};
            String title = recurringPost['title'] ?? 'Recurring Activity';
            DateTime startDate = startTimestamp.toDate();
            DateTime endDate = endTimestamp.toDate();
            Map<String, dynamic> scheduleLowercase = {};
            schedule.forEach((key, value) {
              scheduleLowercase[key.toLowerCase()] = value;
            });
            DateTime currentDate = startDate;
            while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
              String weekday = DateFormat('EEEE').format(currentDate).toLowerCase();
              if (scheduleLowercase.containsKey(weekday)) {
                List<dynamic> times = scheduleLowercase[weekday];
                if (times.length >= 2) {
                  String startTimeStr = times[0].toString().trim().toUpperCase();
                  String endTimeStr = times[1].toString().trim().toUpperCase();
                  DateTime? startTime = parseTime(startTimeStr, currentDate);
                  DateTime? endTime = parseTime(endTimeStr, currentDate);
                  if (startTime != null && endTime != null && endTime.isAfter(startTime)) {
                    addedAppointments.add(Appointment(
                        startTime: startTime, endTime: endTime, subject: title, color: Colors.blue));
                    Task task = Task(
                        title: title,
                        startTime: startTimeStr,
                        endTime: endTimeStr,
                        date: currentDate,
                        isRecurring: true);
                    addedTasks.add(task);
                  }
                }
              }
              currentDate = currentDate.add(const Duration(days: 1));
            }
          }
        } else {
          var nonRecurringBox = Hive.box('nonRecurringBox');
          var nonRecurringPost = nonRecurringBox.get(postId);
          if (nonRecurringPost != null) {
            String title = nonRecurringPost['title'] ?? 'No Title';
            String startTimeStr = nonRecurringPost['start_time']?.toString().trim().toUpperCase() ?? '';
            String endTimeStr = nonRecurringPost['end_time']?.toString().trim().toUpperCase() ?? '';
            Timestamp startTimestamp = nonRecurringPost['start_date'];
            DateTime startDate = startTimestamp.toDate();
            DateTime? startTime = parseTime(startTimeStr, startDate);
            DateTime? endTime = parseTime(endTimeStr, startDate);
            if (startTime != null && endTime != null && endTime.isAfter(startTime)) {
              addedAppointments.add(Appointment(
                  startTime: startTime, endTime: endTime, subject: title, color: Colors.red));
              Task task = Task(
                  title: title,
                  startTime: startTimeStr,
                  endTime: endTimeStr,
                  date: startDate,
                  isRecurring: false);
              addedTasks.add(task);
            }
          }
        }
      });
    }
    setState(() {
      appointments = addedAppointments;
      allTasks = addedTasks;
      addDateTasks();
    });
  }

  DateTime? parseTime(String timeStr, DateTime date) {
    timeStr = timeStr.trim().toUpperCase();
    timeStr = timeStr.replaceAll(RegExp(r'\s+'), ' ');
    RegExp timeRegExp = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
    Match? match = timeRegExp.firstMatch(timeStr);
    if (match != null) {
      String hourStr = match.group(1)!;
      String minuteStr = match.group(2)!;
      String period = match.group(3)!;
      int hour = int.parse(hourStr);
      int minute = int.parse(minuteStr);
      if (period == 'PM' && hour != 12) hour += 12;
      else if (period == 'AM' && hour == 12) hour = 0;
      DateTime dateTime = DateTime(date.year, date.month, date.day, hour, minute);
      return dateTime;
    } else
      return null;
  }

  void onDateSelected(CalendarSelectionDetails details) {
    setState(() {
      selectedDate = details.date ?? DateTime.now();
      addDateTasks();
    });
  }

  void addDateTasks() {
    dateTasks = allTasks.where((task) => isSameDate(task.date, selectedDate)).toList();
  }

  bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  String formatDate(DateTime date) {
    String daySuffix(int day) {
      if (day >= 11 && day <= 13) return 'th';
      switch (day % 10) {
        case 1:
          return 'st';
        case 2:
          return 'nd';
        case 3:
          return 'rd';
        default:
          return 'th';
      }
    }

    String month = DateFormat('MMMM').format(date);
    String day = date.day.toString();
    String suffix = daySuffix(date.day);
    String year = date.year.toString();
    return '$month $day$suffix, $year';
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = formatDate(selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 370,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SfCalendar(
                  view: CalendarView.month,
                  dataSource: AppointmentDataSource(appointments),
                  onSelectionChanged: onDateSelected,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                    showAgenda: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Activities on $formattedDate',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: dateTasks.isNotEmpty
                  ? ListView.builder(
                      itemCount: dateTasks.length,
                      itemBuilder: (context, index) {
                        Task task = dateTasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Padding(
                            padding: const EdgeInsets.all(13.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${task.startTime} - ${task.endTime}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          color: task.isRecurring ? Colors.blue : Colors.red,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.isRecurring ? 'Recurring' : 'Non Recurring',
                                          style: GoogleFonts.montserrat(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(task.title),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'No activities scheduled.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String startTime;
  final String endTime;
  final DateTime date;
  final bool isRecurring;

  Task({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.isRecurring,
  });
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
