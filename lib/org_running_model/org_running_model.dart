import 'package:elysium/org_running_model/completed_posts.dart';
import 'package:elysium/org_running_model/org_home.dart';
import 'package:elysium/org_running_model/org_posts.dart';
import 'package:elysium/org_running_model/applications/verify_applications.dart';
import 'package:elysium/org_running_model/verify_hours.dart';
import 'package:flutter/material.dart';

class OrgRunningModel extends StatefulWidget{
  const OrgRunningModel({required this.signOut, super.key});

  final Function() signOut;

  @override
  State<OrgRunningModel> createState() => _OrgRunningModelState();
}

class _OrgRunningModelState extends State<OrgRunningModel> {
  
  Widget? page;

  void homePage() {
    setState(() {
      page = OrgHome(logOut: widget.signOut, postPage: postPage, verifyApplicationsPage: verifyApplications, verifyHoursPage: verifyHours, completedPostsPage: completedPosts,);
    });
  }

  void postPage() {
    setState(() {
      page = OrgPosts(back: homePage);
    });
  }

  void completedPosts() {
    setState(() {
      page = CompletedOrgPosts(back: homePage);
    });
  }

  void verifyApplications() {
    setState(() {
      page = VerifyApplications(back: homePage);
    });
  }

  void verifyHours() {
    setState(() {
      page = VerifyHours(back: homePage);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    page ??= OrgHome(logOut: widget.signOut, postPage: postPage, verifyApplicationsPage: verifyApplications, verifyHoursPage: verifyHours, completedPostsPage: completedPosts,);
    return page!;
  }
}