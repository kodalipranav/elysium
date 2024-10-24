import 'package:hive_flutter/hive_flutter.dart';

Future<int> countTotalApplications (String orgName) async {

  Future<int> countPostApplications(bool recurring) async {
    Box postBox = recurring ? Hive.box('recurringBox') : Hive.box('nonRecurringBox');
    int count = 0;
    postBox.toMap().forEach((key, value) {
      if (value['org_name'] == orgName) {
        count += value['applied_volunteers'].length as int;
      }
    });
    return count;
  }

  int recur = await countPostApplications(true);
  int nonRecur = await countPostApplications(false);

  return recur + nonRecur;
}