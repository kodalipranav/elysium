import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elysium/hive/geopoint_adapter.dart';
import 'package:elysium/hive/timestamp_adapter.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> initializeHive() async {
  Hive.registerAdapter(TimestampAdapter());
  Hive.registerAdapter(GeoPointAdapter());

  if (!Hive.isBoxOpen('orgBox')) {
    await Hive.openBox('orgBox');
  }
  if (!Hive.isBoxOpen('nonRecurringBox')) {
    await Hive.openBox('nonRecurringBox');
  }
  if (!Hive.isBoxOpen('recurringBox')) {
    await Hive.openBox('recurringBox');
  }
  
  if (Hive.box('orgBox').isEmpty || Hive.box('nonRecurringBox').isEmpty || Hive.box('recurringBox').isEmpty) {
    await downloadAllData(Hive.box('orgBox'), Hive.box('nonRecurringBox'), Hive.box('recurringBox'));
  }

  listenToUpdates(Hive.box('orgBox'), 'organizations');
  listenToUpdates(Hive.box('nonRecurringBox'), 'non_recurring');
  listenToUpdates(Hive.box('recurringBox'), 'recurring');
}

Future<void> downloadAllData(Box orgBox, Box nonRecurring, Box recurring) async {
  try {
    QuerySnapshot orgSnap = await FirebaseFirestore.instance.collection('organizations').get();
    for (var orgDoc in orgSnap.docs) {
      await orgBox.put(orgDoc.id, orgDoc.data());
    }

    QuerySnapshot nonRecurringSnap = await FirebaseFirestore.instance.collection("non_recurring").get();
    for (var nonRecurringDoc in nonRecurringSnap.docs) {
      await nonRecurring.put(nonRecurringDoc.id, nonRecurringDoc.data());
    }

    QuerySnapshot recurringSnap = await FirebaseFirestore.instance.collection("recurring").get();
    for (var recurringDoc in recurringSnap.docs) {
      await recurring.put(recurringDoc.id, recurringDoc.data());
    }

    print("All data downloaded locally!");
  } catch (e) {
    print('Error during downloads: $e');
  }
}

void listenToUpdates(Box changedBox, String collectionName) {
  FirebaseFirestore.instance.collection(collectionName).snapshots().listen((snapshot) {
    for (var change in snapshot.docChanges) {
      var doc = change.doc;
      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        changedBox.put(doc.id, doc.data());
      } else if (change.type == DocumentChangeType.removed) {
        changedBox.delete(doc.id);
      }
    }
    print("All listeners have been set up!");
  });
}