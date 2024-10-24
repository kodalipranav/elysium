import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_place/google_place.dart';
import 'package:intl/intl.dart';

class EditPost extends StatefulWidget {
  const EditPost({required this.docData, required this.docID, super.key, required this.orgName, required this.isRecurring});

  final Map<String, dynamic> docData;
  final String docID;
  final bool isRecurring;
  final String orgName;

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  List<TextEditingController> requirementsControllers = [TextEditingController()];
  TextEditingController locationController = TextEditingController();
  TextEditingController contactNameController = TextEditingController();
  TextEditingController contactInfoController = TextEditingController();
  TextEditingController additionalInfoController = TextEditingController();
  TextEditingController numberController = TextEditingController();
  bool sameTimes = false;
  bool flexibleSchedule = false;
  TimeOfDay? oneStartTime;
  TimeOfDay? oneEndTime;
  TimeOfDay? selectedStartTime;
  TimeOfDay? selectedEndTime;
  DateTime? dateClosed;
  DateTime? oneStartDate;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  List<String> selectedDays = [];
  Map<String, List<TimeOfDay?>> schedule = {
    'Monday' : [null, null],
    'Tuesday' : [null, null],
    'Wednesday' : [null, null],
    'Thursday' : [null, null],
    'Friday' : [null, null],
    'Saturday' : [null, null],
    'Sunday' : [null, null],
  };

  bool checkSchedule () {
    bool result = false;

    schedule.forEach((key, value) {
      if (value[0] != null && value[1] != null) {
        result = true;
      }
    });

    if (flexibleSchedule) {
      result = true;
    }

    return result;
  }

  String getFormattedTime(TimeOfDay time) {
    final int hour = time.hour;
    final int minute = time.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$formattedHour:${minute.toString().padLeft(2, '0')} $period';
  }


  Map<String, List<String>> correctSchedule() {
    Map<String, List<String>> correctedSchedule = {};
    
    schedule.forEach((key, value) {
      if (value[0] != null && value[1] != null) {
        correctedSchedule[key] = [getFormattedTime(value[0]!), getFormattedTime(value[1]!)];
      }
    });


    return correctedSchedule;
  }

  GeoPoint? geopoints;

  bool checkLocation() {
    if (selectedLocation != null) {
      if (selectedLocation!.geometry != null) {
        if (selectedLocation!.geometry!.location != null) {
          if (selectedLocation!.geometry!.location!.lat != null && selectedLocation!.geometry!.location!.lng != null) {
            geopoints = GeoPoint(selectedLocation!.geometry!.location!.lat!, selectedLocation!.geometry!.location!.lng!);
            return true;
          } else {
            return false;
          }
        } else {
          return false;
        }
      } else {
        return false;
      }
    } else if (geopoints != null) { 
      return true;
    } else {
      return false;
    }
  }

  List<String> converted = [];

  void convertRequirements () {
    converted.clear();
    for (TextEditingController controller in requirementsControllers) {
      String temporary = controller.text;
      if (temporary.isNotEmpty) {
        converted.add(temporary);
      }
    }
  }

  void showAlert () {
    showDialog(context: context, builder: (context) => 
      AlertDialog(
        content: const Text("Please make sure all required fields are filled out"),
        actions: [MaterialButton(onPressed: () {Navigator.pop(context);}, child: const Text("OK"))],
      ));
  }

  Future<void> editPost() async {
    convertRequirements();
    if (checkLocation()) {
      DocumentReference postDocRef = widget.isRecurring
          ? FirebaseFirestore.instance.collection('recurring').doc(widget.docID)
          : FirebaseFirestore.instance.collection('non_recurring').doc(widget.docID);

      Map<String, dynamic> updatedData = {
        'org_name': widget.orgName,
        'title': titleController.text,
        'description': descriptionController.text,
        'requirements': converted,
        'people': numberController.text,
        'location': locationController.text,
        'geolocation': geopoints,
        'contact_name': contactNameController.text,
        'contact_info': contactInfoController.text,
        'additional_info': additionalInfoController.text,
        'modified': FieldValue.serverTimestamp(),
        'current': true,
      };

      if (!widget.isRecurring) {
        if (titleController.text.isNotEmpty &&
            descriptionController.text.isNotEmpty &&
            oneStartDate != null &&
            oneStartTime != null &&
            oneEndTime != null &&
            locationController.text.isNotEmpty &&
            contactNameController.text.isNotEmpty &&
            contactInfoController.text.isNotEmpty &&
            dateClosed != null) {
          updatedData.addAll({
            'start_date': Timestamp.fromDate(oneStartDate!),
            'start_time': getFormattedTime(oneStartTime!),
            'end_time': getFormattedTime(oneEndTime!),
            'close_date': Timestamp.fromDate(dateClosed!),
            'recurring': false,
          });

          await postDocRef.update(updatedData).then((value) => Navigator.pop(context));
        } else {
          showAlert();
        }
      }

      else {
        if (sameTimes) {
          if (selectedStartTime != null &&
              selectedEndTime != null &&
              selectedDays.isNotEmpty) {
            for (var day in selectedDays) {
              schedule[day]![0] = selectedStartTime;
              schedule[day]![1] = selectedEndTime;
            }
          } else {
            showAlert();
            return;
          }
        }

        if (titleController.text.isNotEmpty &&
            descriptionController.text.isNotEmpty &&
            selectedStartDate != null &&
            selectedEndDate != null &&
            checkSchedule() &&
            locationController.text.isNotEmpty &&
            contactNameController.text.isNotEmpty &&
            contactInfoController.text.isNotEmpty &&
            dateClosed != null) {
          Map<String, List<String>> correctedSchedule = correctSchedule();

          updatedData.addAll({
            'start_date': Timestamp.fromDate(selectedStartDate!),
            'end_date': Timestamp.fromDate(selectedEndDate!),
            'close_date': Timestamp.fromDate(dateClosed!),
            'schedule': correctedSchedule,
            'recurring': true,
          });

          await postDocRef.update(updatedData).then((value) => Navigator.pop(context));
        } else {
          showAlert();
        }
      }
    } else {
      showAlert();
    }
  }


  bool timeGreater (TimeOfDay time1, TimeOfDay time2) {
    if (time1.hour > time2.hour) {
      return true;
    } else if (time1.hour == time2.hour) {
      if (time1.minute > time2.minute) {
        return true;
      } else if (time1.minute == time2.minute) {
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error: Time formatting"), 
            content: const Text("Start time and end time cannot be equal"), 
            actions: [MaterialButton(onPressed: () {Navigator.pop(context);}, child: const Text("OK"))],
          );
        });
        return false;
      } else {
        showDialog(context: context, builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error: Time formatting"), 
            content: const Text("Start time cannot be after the end time"), 
            actions: [MaterialButton(onPressed: () {Navigator.pop(context);}, child: const Text("OK"))],
          );
        });
        return false;
      }
    } else {
      showDialog(context: context, builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error: Time formatting"), 
          content: const Text("Start time cannot be after the end time"), 
          actions: [MaterialButton(onPressed: () {Navigator.pop(context);}, child: const Text("OK"))],
        );
      });
      return false;
    }
  }

  Future<void> selectTime(BuildContext context, {required bool isStartTime, String? day}) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
        if (widget.isRecurring) {
          if (!sameTimes) {
            if (isStartTime) {
              setState(() {
                if (schedule[day]![1] != null) {
                  if (timeGreater(schedule[day]![1]!, pickedTime)) {
                    schedule[day]![0] = pickedTime;
                  }
                } else {
                schedule[day]![0] = pickedTime;
                }
              });
            } else {
              setState(() {
                if (schedule[day]![0] != null) {
                  if (timeGreater(pickedTime, schedule[day]![0]!)) {
                    schedule[day]![1] = pickedTime;
                  }
                } else {
                  schedule[day]![1] = pickedTime;
                }
              });
            }
          } else {
            if (isStartTime) {
              setState(() {
                if (selectedEndTime != null) {
                  if (timeGreater(selectedEndTime!, pickedTime)) {
                    selectedStartTime = pickedTime;
                  }
                } else {
                  selectedStartTime = pickedTime;
                }
              });
            } else {
              setState(() {
                if (selectedStartTime != null) {
                  if (timeGreater(pickedTime, selectedStartTime!)) {
                    selectedEndTime = pickedTime;
                  }
                } else {
                  selectedEndTime = pickedTime;
                }
              });
            }
          }
        }
        else {
          if (isStartTime) {
            setState(() {
              if (oneEndTime != null) {
                if (timeGreater(oneEndTime!, pickedTime)) {
                  oneStartTime = pickedTime;
                }
              } else {
                oneStartTime = pickedTime;
              }
            });
          } else {
            setState(() {
              if (oneStartTime != null) {
                if (timeGreater(pickedTime, oneStartTime!)) {
                  oneEndTime = pickedTime;
                }
              } else {
                oneEndTime = pickedTime;
              }
            });
          }
        }
    }
  }

  void showDateAlert(String errorMessage) {
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        title: const Text("Error: Date format"), 
        content: Text(errorMessage),
        actions: [MaterialButton(onPressed: () {Navigator.pop(context);}, child: const Text("OK"))]
      );
    });
  }

  bool checkDate(DateTime date1, DateTime date2) {
    if (date1.year > date2.year) {
      return true;
    } else if (date1.year == date2.year) {
      if (date1.month > date2.month) {
        return true;
      } else if (date1.month == date2.month) {
        if (date1.day > date2.day) {
          return true;
        } else if (date1.day == date2.day) {
          showDateAlert("If start date is the same as the end date, use the non-recurring post.");
          return false;
        } else {
          showDateAlert("Start date cannot be after the end date.");
          return false;
        }
      } else {
        showDateAlert("Start date cannot be after the end date.");
        return false;
      }
    } else {
      showDateAlert("Start date cannot be after the end date.");
      return false;
    }
  }

  Future<void> selectDate(BuildContext context, {required bool isStartDate, required bool recur, bool? closingTime}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      if (closingTime != null) {
        setState(() {
          dateClosed = pickedDate;
        });
      } else {
        if (!recur) {
          setState(() {
            oneStartDate = pickedDate;
          });
        } else {
          setState(() {
            if (isStartDate) {
              if (selectedEndDate != null) {
                if (checkDate(selectedEndDate!, pickedDate)) {
                  selectedStartDate = pickedDate;
                }
              } else {
                selectedStartDate = pickedDate;
              }
            } else {
              if (selectedStartDate != null) {
                if (checkDate(pickedDate, selectedStartDate!)) {
                  selectedEndDate = pickedDate;
                }
              } else {
                selectedEndDate = pickedDate;
              }
            }
          });
        }
      }
    }
  }

  Widget buildTextField(String label, TextEditingController controller, int maxLength, bool required) {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        maxLines: null,
        controller: controller,
        maxLength: maxLength,
        decoration: InputDecoration(
          constraints: const BoxConstraints(
            minHeight: 50,
          ),
          hintText: label,
          suffix: required ? const Text("*", style: TextStyle(color: Colors.red)) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  void addRequirements() {
    if (requirementsControllers.length < 5) {
      setState(() {
        requirementsControllers.add(TextEditingController());
      });
    }
  }

  void removeController(controller) {
    setState(() {
      requirementsControllers.remove(controller);
    });
  }

  Timer? debounce;
  List<AutocompletePrediction> predictions = [];
  DetailsResult? selectedLocation;

  void showAutocomplete(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions!;
      });
    }
  }

  late GooglePlace googlePlace;

  Text mandatory (double size) {
    return Text(" *", style: GoogleFonts.montserrat(fontSize: size, color: Colors.red, fontWeight: FontWeight.bold));
  }
  @override  
  void initState() {
    super.initState();
    String apiKey = 'AIzaSyDthfQsr548lxrHTDH7UrdY9vEa1xDf4Ns';
    googlePlace = GooglePlace(apiKey);
    prepopulateData();
  }

  Future<void> prepopulateData() async {
    Map<String, dynamic> existing = widget.docData;

    titleController.text = existing['title'] ?? '';
    descriptionController.text = existing['description'] ?? '';
    locationController.text = existing['location'] ?? '';
    numberController.text = existing['people'] ?? '';
    contactNameController.text = existing['contact_name'] ?? '';
    contactInfoController.text = existing['contact_info'] ?? '';
    additionalInfoController.text = existing['additional_info'] ?? '';

    if (existing['requirements'] != null) {
      List<String> requirementsList = List<String>.from(existing['requirements']);
      for (int i = 0; i < requirementsList.length; i++) {
        if (i < requirementsControllers.length) {
          requirementsControllers[i].text = requirementsList[i];
        } else {
          TextEditingController newController = TextEditingController(text: requirementsList[i]);
          requirementsControllers.add(newController);
        }
      }
    }

    if (widget.isRecurring) {
      setState(() {
        selectedStartDate = existing['start_date']?.toDate();
        selectedEndDate = existing['end_date']?.toDate();
        dateClosed = existing['close_date']?.toDate();
      });

      if (existing['schedule'] != null) {
        Map<String, dynamic> existingSchedule = existing['schedule'];
        setState(() {
          flexibleSchedule = existingSchedule.isEmpty;
          for (String day in existingSchedule.keys) {
            List<dynamic> times = existingSchedule[day];
            if (times.length == 2) {
              schedule[day] = [
                TimeOfDay(
                  hour: int.parse(times[0].split(':')[0]), 
                  minute: int.parse(times[0].split(':')[1].split(' ')[0])),
                TimeOfDay(
                  hour: int.parse(times[1].split(':')[0]), 
                  minute: int.parse(times[1].split(':')[1].split(' ')[0])),
              ];
              selectedDays.add(day);
            }
          }
        });
      }
    } 

    else {
      setState(() {
        oneStartDate = existing['start_date']?.toDate();
        dateClosed = existing['close_date'] != null ? (existing['close_date'] as Timestamp).toDate() : null;
        oneStartTime = _getTimeFromFormattedString(existing['start_time']);
        oneEndTime = _getTimeFromFormattedString(existing['end_time']);
      });
    }

    if (existing['geolocation'] != null) {
      GeoPoint geoPoint = existing['geolocation'];
      setState(() {
        geopoints = geoPoint;
        locationController.text = existing['location'] ?? '';
      });
    }
  }

  TimeOfDay _getTimeFromFormattedString(String formattedTime) {
    final timeParts = formattedTime.split(' ');
    final period = timeParts[1];
    final hourMinuteParts = timeParts[0].split(':');
    int hour = int.parse(hourMinuteParts[0]);
    final int minute = int.parse(hourMinuteParts[1]);

    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: SizedBox(
        height: double.infinity,
        child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            Text("Edit Post", style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () {Navigator.pop(context);}, icon: const Icon(Icons.close))
          ],),
          const SizedBox(height: 10),
          const Divider(thickness: 2),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text("Title", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500),),
                    mandatory(18),
                  ],
                ),
                const SizedBox(height: 8),
                buildTextField('Title', titleController, 50, true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text("Description", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500)),
                    mandatory(18)
                  ],
                ),
                const SizedBox(height: 8),
                buildTextField('Description', descriptionController, 500, true),
                const SizedBox(height: 16),
                if (!widget.isRecurring) 
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Date & Time", 
                                          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500),
                                          textAlign: TextAlign.left,),
                                          mandatory(18),
                                      ],
                                    ),
                                  ]
                                ),
                              )
                            ), 
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: MaterialButton(
                                padding: const EdgeInsets.all(5),
                                color: Colors.brown[100],
                                onPressed: () {selectTime(context, isStartTime: true);}, 
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                    Text(
                                      oneStartTime == null ? widget.docData['start_time'] : oneStartTime!.format(context), 
                                      style: GoogleFonts.montserrat(fontSize: 14)
                                    )
                                  ]
                                  ),
                                )
                              )
                            )
                          ]
                        ),
                        Row(children: [
                          Expanded(
                            flex: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: MaterialButton(
                                color: Colors.brown[100],
                                onPressed: () {selectDate(context, isStartDate: true, recur: widget.isRecurring);},
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        oneStartDate == null ? "Date" : DateFormat.yMMMd().format(oneStartDate!),
                                        style: GoogleFonts.montserrat(fontSize: 14)
                                      ),
                                    ],
                                  ),
                                )
                              ),
                            ),
                          ), 
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child:MaterialButton(
                              padding: const EdgeInsets.all(5),
                                color: Colors.brown[100],
                                onPressed: () {selectTime(context, isStartTime: false);}, 
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                    Text(
                                      oneEndTime == null ? widget.docData['end_time'] : oneEndTime!.format(context),
                                      style: GoogleFonts.montserrat(fontSize: 14)
                                    )
                                  ],),
                                )),
                          )
                        ]),
                      ],
                    )
                  ),
                if (widget.isRecurring) ...[
                  Text("Schedule", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500),),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text("How long will the activity last?", style: GoogleFonts.montserrat(fontSize: 14), softWrap: true,),
                      mandatory(14),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: MaterialButton(
                          color: Colors.brown[100],
                          onPressed: () => selectDate(context, isStartDate: true, recur: widget.isRecurring),
                          child: Text(
                            selectedStartDate == null ? 'Start Date' : DateFormat.yMMMd().format(selectedStartDate!),
                            style: GoogleFonts.montserrat(),),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MaterialButton(
                          color: Colors.brown[100],
                          onPressed: () => selectDate(context, isStartDate: false, recur: widget.isRecurring),
                          child: Text(
                            selectedEndDate == null ? 'End Date' : DateFormat.yMMMd().format(selectedEndDate!),
                            style: GoogleFonts.montserrat(),),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Flexible Schedule', 
                          style: GoogleFonts.montserrat(fontSize: 16), 
                          softWrap: true,
                          overflow: TextOverflow.visible, 
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: flexibleSchedule,
                        onChanged: (value) {
                          setState(() {
                            flexibleSchedule = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (!flexibleSchedule)...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'The activity has the same time every day it is done', 
                          style: GoogleFonts.montserrat(fontSize: 14), 
                          softWrap: true,
                          overflow: TextOverflow.visible, 
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: sameTimes,
                        onChanged: (value) {
                          setState(() {
                            sameTimes = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Select Days and Time", style: GoogleFonts.montserrat(fontSize: 14)),
                      mandatory(14)
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: schedule.keys.map((day) {
                              return Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: SizedBox(
                                              width: MediaQuery.of(context).size.width * 0.35,
                                              child: FilterChip(
                                                label: SizedBox(
                                                  width: 150,
                                                  child: Center(child: Text(day))
                                                  ),
                                                labelStyle: GoogleFonts.montserrat(fontSize: 16),
                                                selected: selectedDays.contains(day),
                                                onSelected: (bool selected) {
                                                  setState(() {
                                                    if (selected) {
                                                      setState(() {
                                                        selectedDays.add(day);
                                                      });
                                                    } else {
                                                      setState(() {
                                                        selectedDays.remove(day);
                                                        schedule[day]![0] = null;
                                                        schedule[day]![1] = null;
                                                      });
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!sameTimes)
                                    if (selectedDays.contains(day))
                                      Expanded(
                                        flex: 1,
                                        child: Row(children: [
                                          Expanded(
                                            flex: 1,
                                            child: MaterialButton(
                                              onPressed: () => selectTime(isStartTime: true, day: day, context),
                                              child: schedule[day]![0] == null ? const Text("Start Time") : Text(schedule[day]![0]!.format(context)),
                                            ),
                                          ),
                                          const Text(" - "),
                                          Expanded(
                                            flex: 1,
                                            child: MaterialButton(
                                              onPressed: () => selectTime(isStartTime: false, day: day, context),
                                              child: schedule[day]![1] == null ? const Text("End Time") : Text(schedule[day]![1]!.format(context)),
                                            ),
                                          )
                                        ]
                                        ),
                                      ),
                                  
                                  if (!sameTimes)
                                    if (!selectedDays.contains(day))
                                      const Expanded(
                                        flex: 1,
                                        child: Row(),
                                      )
                                ],
                              );
                              }).toList(),
                            
                          ),
                        ),
                        
                        if (sameTimes)
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                MaterialButton(
                                  onPressed: () => selectTime(context, isStartTime: true),
                                  child: selectedStartTime == null ? const Text("Start Time") : Text(selectedStartTime!.format(context),
                                  style: GoogleFonts.montserrat(fontSize: 16),)
                                ),
                                const SizedBox(height: 12),
                                Text("-", style: GoogleFonts.montserrat()),
                                const SizedBox(height: 12,),
                                MaterialButton(
                                  onPressed: () => selectTime(context, isStartTime: false),
                                  child: selectedEndTime == null ? const Text("End Time") : Text(selectedEndTime!.format(context), 
                                  style: GoogleFonts.montserrat(fontSize: 16),)
                                ),                            
                              ],
                            ))
                      ]
                    ),
                  ),
                ],
                ], 
                if (flexibleSchedule)
                  Row(children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        child: Text(
                          "* This means that the schedule for each volunteer will be determined later based on differing circumstances." 
                          "You will need to separately determine a schedule with the volunteers", 
                          style: GoogleFonts.montserrat(fontSize: 10), softWrap: true,),
                      ),
                    )
                  ],),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text("Requirements", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 20),
                      Text(
                        '(${requirementsControllers.length} out of 5)', 
                        style: GoogleFonts.montserrat(fontSize: 14, color: const Color.fromARGB(255, 137, 137, 137)))
                    ],
                  ),
                  const SizedBox(height: 6),
                  Column(children: [
                    const SizedBox(height: 6),
                    Column(children: 
                    requirementsControllers.map((controller) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                          Expanded(child: buildTextField("Place requirement here", controller, 100, false)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () {removeController(controller);},)
                        ],),
                      );
                    }).toList(),
                    ),
                    if (requirementsControllers.length < 5)
                      Row(children: [
                        IconButton(icon: const Icon(Icons.add_box_rounded), onPressed: addRequirements)
                      ],)
                  ],),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text("Location", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500)),
                      mandatory(18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                      width: double.infinity,
                      child: TextField(
                        maxLines: null,
                        controller: locationController,
                        decoration: InputDecoration(
                          constraints: const BoxConstraints(
                            minHeight: 50,
                          ),
                          hintText: 'Enter a location',
                          suffix: const Text("*", style: TextStyle(color: Colors.red)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
                          filled: true,
                          fillColor: Colors.grey[200],
                          suffixIcon: locationController.text.isNotEmpty ? IconButton(onPressed: () {
                            setState(() {
                              predictions = [];
                              locationController.clear();
                            });
                          }, icon: const Icon(Icons.clear_rounded)) : null,
                        ),
                        onChanged: (text) {
                          if(debounce?.isActive ?? false) debounce!.cancel();
                          debounce = Timer(const Duration(milliseconds: 1000), () {
                            if (text.isNotEmpty) {
                              showAutocomplete(text);
                            } else {
                              setState(() {
                                predictions = [];
                                selectedLocation = null;
                              });
                            }
                          });

                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  SizedBox(
                    child: ListView.builder(shrinkWrap: true, itemCount: predictions.length, itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.pin_drop_outlined)
                            ),
                            title: Text(predictions[index].description.toString()),
                            onTap: () async {
                              final placeId = predictions[index].placeId;
                              final details = await googlePlace.details.get(placeId!);
                              if (details != null && details.result != null && mounted) {
                                setState(() {
                                  selectedLocation = details.result;
                                  locationController.text = details.result!.formattedAddress!;
                                  predictions = [];
                                });
                              }
                            },
                          ),
                          const Divider(
                            height: 4,
                            indent: 10,
                            endIndent: 10,
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Number of volunteers: ", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 18),
                      Expanded(
                        child: TextField(
                          controller: numberController,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          keyboardType: const TextInputType.numberWithOptions(),
                          maxLength: 4,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            isDense: true,
                            counterText: '',
                            hintText: 'Enter',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const SizedBox(width: 20),
                      Expanded(
                        child: SizedBox(
                          child: Text(
                            "* Number of people is not required, but it is highly recommended to provide an estimate of the people accepted for the volunteers",
                            style: GoogleFonts.montserrat(fontSize: 10), softWrap: true,),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Contact Information', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500)),
                      mandatory(18)
                    ],
                  ),
                  const SizedBox(height: 8),
                  buildTextField('Contact\'s Name', contactNameController, 50, true),
                  const SizedBox(height: 8),
                  buildTextField('Contact\'s Email or Phone Number', contactInfoController, 100, true),
                  const SizedBox(height: 16),
                  Text("Additional Information", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  buildTextField('Additional Info', additionalInfoController, 100, false),
                  const SizedBox(height: 16),
                  Row(children: [
                    Text("When should the post close?", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w500)),
                    mandatory(18),
                    const SizedBox(width: 10,),
                  ],),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: MaterialButton(
                        onPressed: () {selectDate(isStartDate: false, recur: false, closingTime: true, context);},
                        color: Colors.brown[100],
                        child: Text(
                          dateClosed == null ? "Select date" : DateFormat.yMMMd().format(dateClosed!), 
                          style: GoogleFonts.montserrat()
                        ),
                        ),
                    )
                  ],),
                  const SizedBox(height: 8),
                  Row(children: [
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        child: Text(
                          "* If you don't have an application deadline, set the date the same as the start date of the activity",
                          style: GoogleFonts.montserrat(fontSize: 10), softWrap: true,
                        ),
                      ),
                    )
                  ],),
                  const SizedBox(height: 20),
                ]
              )
            ),
          ),
          const Divider(thickness: 2,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.all(5),
                child: ElevatedButton(
                  onPressed: editPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                  ),
                  child: const Text('Save & Continue'),
                ),
              ),
            ],
          )
        ],
      ),)
    );
  }
}