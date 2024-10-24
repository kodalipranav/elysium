import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CompletedOrgPosts extends StatefulWidget {
  const CompletedOrgPosts({required this.back, super.key});

  final Function() back;

  @override
  State<CompletedOrgPosts> createState() => CompletedOrgPostsState();
}

class CompletedOrgPostsState extends State<CompletedOrgPosts> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String orgName = '';
  List<Map<String, dynamic>> recurringPosts = [];
  List<Map<String, dynamic>> nonRecurringPosts = [];
  bool isLoading = true;
  late Box<dynamic> recurringBox;
  late Box<dynamic> nonRecurringBox;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    recurringBox = Hive.box('recurringBox');
    nonRecurringBox = Hive.box('nonRecurringBox');
    loadOrgName();
    recurringBox.watch().listen((event) {
      fetchCompletedPosts();
    });
    nonRecurringBox.watch().listen((event) {
      fetchCompletedPosts();
    });
  }

  Future<void> loadOrgName() async {
    final orgBox = Hive.box('orgBox');
    final userId = orgBox.keys.first;
    final orgData = orgBox.get(userId);
    setState(() {
      orgName = orgData['name'];
    });
    await fetchCompletedPosts();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCompletedPosts() async {
    List<Map<String, dynamic>> tempRecurring = [];
    List<Map<String, dynamic>> tempNonRecurring = [];

    for (var entry in recurringBox.toMap().entries) {
      var post = entry.value;
      if (post['org_name'] == orgName && post['current'] == false) {
        tempRecurring.add({
          'title': post['title'] ?? 'No Title',
          'description': post['description'] ?? '',
          'end_date': post['end_date'] ?? '',
        });
      }
    }

    for (var entry in nonRecurringBox.toMap().entries) {
      var post = entry.value;
      if (post['org_name'] == orgName && post['current'] == false) {
        tempNonRecurring.add({
          'title': post['title'] ?? 'No Title',
          'description': post['description'] ?? '',
          'end_date': post['end_date'] ?? '',
        });
      }
    }

    setState(() {
      recurringPosts = tempRecurring;
      nonRecurringPosts = tempNonRecurring;
    });
  }

  Widget buildPostCard(Map<String, dynamic> post) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(post['title'], style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post['description'], style: GoogleFonts.lato(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: widget.back, icon: const Icon(Icons.arrow_back)),
        title: Text('Completed Posts', style: GoogleFonts.josefinSans(fontSize: 24, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Non-Recurring'),
            Tab(text: 'Recurring'),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : TabBarView(
              controller: _tabController,
              children: [
                nonRecurringPosts.isEmpty
                    ? Center(child: Text('No completed non-recurring posts.', style: GoogleFonts.lato(fontSize: 18, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: nonRecurringPosts.length,
                        itemBuilder: (context, index) {
                          return buildPostCard(nonRecurringPosts[index]);
                        },
                      ),
                recurringPosts.isEmpty
                    ? Center(child: Text('No completed recurring posts.', style: GoogleFonts.lato(fontSize: 18, color: Colors.grey)))
                    : ListView.builder(
                        itemCount: recurringPosts.length,
                        itemBuilder: (context, index) {
                          return buildPostCard(recurringPosts[index]);
                        },
                      ),
              ],
            ),
    );
  }
}
