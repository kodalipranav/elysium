import 'package:elysium/org_running_model/add_post.dart';
import 'package:elysium/widgets/posts_by_organization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class OrgPosts extends StatefulWidget{
  const OrgPosts({required this.back, super.key});

  final Function() back;

  @override
  State<OrgPosts> createState() => _OrgPostsState();
}

class _OrgPostsState extends State<OrgPosts> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  bool currentlyRecurring = false;
  String orgID = FirebaseAuth.instance.currentUser!.uid;
  String orgName = Hive.box('orgBox').get(FirebaseAuth.instance.currentUser!.uid)['name'];

  void switchToRecur() {
    setState(() {
      currentlyRecurring = true;
    });
  }

  void switchBack() {
    setState(() {
      currentlyRecurring = false;
    });
  }

  void addPost() {
    showModalBottomSheet(
      useSafeArea: true,
      isDismissible: false,
      context: context, 
      isScrollControlled: true,
      shape: const LinearBorder(),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom),
          child: AddPost(orgName: orgName)
        );
      }
      );
    
  }

  @override
  Widget build (context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.back),
        title: const Text("See Posts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add), onPressed: addPost,
          )
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: MaterialButton(                 
                    elevation: 4,   
                    minWidth: double.infinity,
                    onPressed: switchBack,
                    color: !currentlyRecurring ?  Colors.brown : Colors.grey[400], 
                    child: Text(
                      "Non-Recurring Posts", 
                      style: GoogleFonts.montserrat(color: !currentlyRecurring ? Colors.white : Colors.black, fontWeight: FontWeight.w700))

                  )
                ),
                Expanded(
                  flex: 1,
                  child: MaterialButton(
                    elevation: 4,
                    minWidth: double.infinity,
                    onPressed: switchToRecur,
                    color: currentlyRecurring ?  Colors.brown : Colors.grey[400], 
                    child: Text(
                      "Recurring Posts", 
                      style: GoogleFonts.montserrat(color: currentlyRecurring ? Colors.white : Colors.black, fontWeight: FontWeight.w700))
                  )
                ),
              ]
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PostsByOrganization(key: ValueKey(currentlyRecurring), orgName: orgName, recurring: currentlyRecurring, role: "organization")
          )
        ],
      )
    );
  }
}