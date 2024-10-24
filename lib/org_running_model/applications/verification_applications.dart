import 'package:elysium/org_running_model/applications/verification_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class VerificationApplications extends StatefulWidget {
  const VerificationApplications({required this.recurring, super.key});

  final bool recurring;

  @override
  State<VerificationApplications> createState() => _VerificationApplicationsState();
}

class _VerificationApplicationsState extends State<VerificationApplications> {
  String orgName = '';
  bool isLoading = true;

  Future<void> getOrgName () async {
    final user = FirebaseAuth.instance.currentUser;
    final orgBox = Hive.box('orgBox');
    final orgData = orgBox.get(user!.uid);
    setState(() {
      orgName = orgData['name'];
    });
  }
  Map<String, Map<dynamic, dynamic>> postsWithApplications = {};

  Future<void> getPostsWithApplications() async {
    await getOrgName();

    Box usingBox = widget.recurring ? Hive.box('recurringBox') : Hive.box('nonRecurringBox');
    usingBox.toMap().forEach((key, value) {
      if (value['org_name'] == orgName) {
        Map allUsersApplied = value['applied_volunteers'];
        if (allUsersApplied.isNotEmpty) {
          postsWithApplications[key] = allUsersApplied;
        }
      }
    });

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadData() async {
    await getPostsWithApplications();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  List<Widget> buildCard(bool recurring) {
    List<Widget> cards = [];
    postsWithApplications.forEach((postID, applicantData) {
      Widget newAddition = VerificationCard(
        recurring: recurring, postID: postID, applicantData: applicantData, remove: () {
          setState(() {
            postsWithApplications.remove(postID);
          });
        }
      );
      cards.add(newAddition);
    });
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading ? const Center(child: CircularProgressIndicator()) : 
    ListView(
      children: buildCard(widget.recurring)
    );
  }
}