import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/trip/pending_ride_card.dart';
import '../../util/supabase.dart';
import '../models/drive.dart';

class DriveChatPage extends StatefulWidget {
  final Drive drive;
  const DriveChatPage({required this.drive, super.key});

  @override
  State<DriveChatPage> createState() => _DriveChatPageState();
}

class _DriveChatPageState extends State<DriveChatPage> {
  late Drive _drive;

  @override
  void initState() {
    super.initState();
    _drive = widget.drive;
  }

  @override
  Widget build(BuildContext context) {
    Set<Profile> riders = _drive.approvedRides!.map((ride) => ride.rider!).toSet();
    List<Ride> pendingRides = _drive.pendingRides!.toList();
    List<Widget> widgets = [];
    if (riders.isEmpty && pendingRides.isEmpty) {
      widgets.add(const Center(
        child: Text("No riders or pending rides"),
      ));
    } else {
      if (riders.isNotEmpty) {
        List<Widget> riderColumn = [
          Text(
            "Riders",
            style: Theme.of(context).textTheme.headline4,
          ),
          const SizedBox(height: 10.0),
          _riderList(riders),
        ];
        widgets.addAll(riderColumn);
      }
      widgets.add(const SizedBox(height: 10.0));
      if (pendingRides.isNotEmpty) {
        List<Widget> pendingRidesColumn = [
          Text(
            "Pending Rides",
            style: Theme.of(context).textTheme.headline4,
          ),
          const SizedBox(height: 10.0),
        ];
        pendingRidesColumn.addAll(_pendingRidesList(pendingRides));
        widgets.addAll(pendingRidesColumn);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Chat'),
      ),
      body: RefreshIndicator(
        onRefresh: loadDrive,
        child: ListView.separated(
          itemCount: widgets.length,
          itemBuilder: (context, index) {
            return widgets[index];
          },
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 10);
          },
        ),
      ),
    );
  }

  List<Widget> _pendingRidesList(List<Ride> pendingRides) {
    List<Widget> pendingRidesColumn = [];
    if (pendingRides.isNotEmpty) {
      pendingRidesColumn = List.generate(
        pendingRides.length,
        (index) => PendingRideCard(
          pendingRides.elementAt(index),
          reloadPage: loadDrive,
          drive: _drive,
        ),
      );
    }
    return pendingRidesColumn;
  }

  Row profileRow(Profile profile) {
    return Row(
      children: [
        CircleAvatar(
          child: Text(profile.username[0]),
        ),
        const SizedBox(width: 5),
        Text(profile.username),
      ],
    );
  }

  Widget _riderList(Set<Profile> riders) {
    Widget ridersColumn = Container();
    if (riders.isNotEmpty) {
      ridersColumn = Column(
        children: List.generate(
          riders.length,
          (index) => InkWell(
            onTap: () => print("Hey"),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  profileRow(riders.elementAt(index)),
                  const Icon(
                    Icons.chat,
                    color: Colors.black,
                    size: 36.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ridersColumn;
  }

  Future<void> loadDrive() async {
    Map<String, dynamic> data = await supabaseClient.from('drives').select('''
      *,
      rides(
        *,
        rider: rider_id(*)
      )
    ''').eq('id', widget.drive.id).single();
    setState(() {
      _drive = Drive.fromJson(data);
    });
  }
}
