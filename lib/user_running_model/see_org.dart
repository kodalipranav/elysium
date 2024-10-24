import 'package:elysium/widgets/posts_by_organization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SeeOrg extends StatefulWidget {
  const SeeOrg({super.key, required this.orgName});

  final String orgName;

  @override
  State<SeeOrg> createState() => _SeeOrgState();
}

class _SeeOrgState extends State<SeeOrg> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.orgName,
          style: GoogleFonts.montserrat(),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Non-Recurring Posts'),
            Tab(text: 'Recurring Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PostsByOrganization(orgName: widget.orgName, recurring: false, role: "user",),
          PostsByOrganization(orgName: widget.orgName, recurring: true, role: "user",),
        ],
      ),
    );
  }
}
