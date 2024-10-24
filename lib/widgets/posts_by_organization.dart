import 'dart:async';

import 'package:elysium/widgets/non_recurring_post.dart';
import 'package:elysium/widgets/recurring_post.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PostsByOrganization extends StatefulWidget {
  const PostsByOrganization({super.key, required this.orgName, required this.recurring, required this.role});

  final String orgName;
  final bool recurring;
  final String role;

  @override
  State<PostsByOrganization> createState() => _PostsByOrganizationState();
}

class _PostsByOrganizationState extends State<PostsByOrganization> {

  late StreamSubscription boxSubscription;

  @override
  void initState() {
    super.initState();
    bool recurring = widget.recurring;
    returnPostData(recurring);
  }

  @override
  void dispose() {
    boxSubscription.cancel();
    super.dispose();
  }

  Map<String, Map<String, dynamic>> finalNonRecurringPostData = {};
  Map<String, Map<String, dynamic>> finalRecurringPostData = {};

  void returnPostData(bool recurring) async {
    print("the post is currently $recurring");
    Box used;
    if (!Hive.isBoxOpen('recurringBox')) {
      await Hive.openBox('recurringBox');
    }  
    if (!Hive.isBoxOpen('nonRecurringBox')) {
      await Hive.openBox('nonRecurringBox');
    }
    if (recurring) {
      used = Hive.box('recurringBox');
    } else {
      used = Hive.box('nonRecurringBox');
    }
    Map<String, Map<String, dynamic>> postsData = {};

    for (var key in used.keys) {
      var post = used.get(key);
      if (post['org_name'] == widget.orgName && post['current'] == true) {
        postsData[key] = post;
      }
    }

    setState(() {
      if (recurring) {
        finalRecurringPostData = postsData;
      } else {
        finalNonRecurringPostData = postsData;
      }
    });

    boxSubscription = used.watch().listen((event) {
      var updatedPost = event.value;

      if (updatedPost != null && updatedPost['org_name'] == widget.orgName) {
        setState(() {
          if (event.deleted) {
            if (recurring) {
              finalRecurringPostData.remove(event.key);
            } else {
              finalNonRecurringPostData.remove(event.key);
            }
          } else {
            if (recurring) {
              finalRecurringPostData[event.key] = updatedPost;
            } else {
              finalNonRecurringPostData[event.key] = updatedPost;
            }
          }
        });
      }
    });
  }

  List<Widget> buildCards (bool recurring) {
    List<Widget> cards = [];
    if (recurring) {
      finalRecurringPostData.forEach((key, post) {
        cards.add(recurringPost(doc: post, shortened: true, orgName: widget.orgName, role: widget.role, docID: key));
      });
    } else {
      finalNonRecurringPostData.forEach((key, post) {
        cards.add(nonRecurringPost(doc: post, shortened: true, orgName: widget.orgName, role: widget.role, docID: key));
      });
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: buildCards(widget.recurring));
  }
}