import 'package:elysium/user_running_model/see_org.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class OrgSearchDelegate extends SearchDelegate{
  final Box orgBox = Hive.box('orgBox');

  List<String> orgNames = [];

  OrgSearchDelegate() : orgNames = Hive.box('orgBox').values.map((value) => value['name'] as String).toList();

  @override
  Widget buildSuggestions(BuildContext context) {
    
    final List queriedNames = orgNames.where((org) => org.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: queriedNames.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(queriedNames[index], style: GoogleFonts.montserrat()),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SeeOrg(orgName: queriedNames[index])));
          },
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override List<Widget>? buildActions(BuildContext context) {
    return [IconButton(onPressed: () {query = '';}, icon: const Icon(Icons.clear))];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(onPressed: () {close(context, '');}, icon: const Icon(Icons.arrow_back));
  }
}