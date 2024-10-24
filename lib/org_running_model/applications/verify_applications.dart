import 'package:elysium/org_running_model/applications/verification_applications.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyApplications extends StatefulWidget {
  const VerifyApplications({super.key, required this.back});

  final Function() back;

  @override
  State<VerifyApplications> createState() => _VerifyApplicationsState();
}

class _VerifyApplicationsState extends State<VerifyApplications> {
  bool currentlyRecurring = false;
  
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.back),
        title: const Text("Verify Applications"),
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
                      style: GoogleFonts.montserrat(color: !currentlyRecurring ? Colors.white : Colors.black, fontWeight: FontWeight.w800))

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
                      style: GoogleFonts.montserrat(color: currentlyRecurring ? Colors.white : Colors.black, fontWeight: FontWeight.w800))
                  )
                ),
              ]
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: VerificationApplications(key: ValueKey(currentlyRecurring), recurring: currentlyRecurring)
          )
        ],
      )
    );
  }
}