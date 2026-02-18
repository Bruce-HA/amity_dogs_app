import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'dogs_page.dart';
import 'people_page.dart';
import 'litters_page.dart';
import 'calendar_page.dart';
import 'vehicle_log_page.dart';
import 'vehicle_reports_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 90,
          automaticallyImplyLeading: false,

          title: Row(
            children: [
              const Spacer(),

              Row(
                children: [
                  Image.asset('assets/images/amity_logo.png', height: 60),

                  const SizedBox(width: 16),

                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amity Labradoodles',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        'Management System v3',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
              ),
            ],
          ),

          bottom: const TabBar(
            isScrollable: false,
            tabs: [
              Tab(icon: Icon(Icons.pets), text: 'Dogs'),

              Tab(icon: Icon(Icons.people), text: 'People'),

              Tab(icon: Icon(Icons.child_care), text: 'Litters'),

              Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),

              Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),

              Tab(icon: Icon(Icons.bar_chart), text: 'Reports'),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            DogsPage(),
            PeoplePage(),
            LittersPage(),
            CalendarPage(),
            VehicleLogPage(),
            VehicleReportsPage(),
          ],
        ),
      ),
    );
  }
}
