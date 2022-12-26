import 'package:flutter/material.dart';

import '../../account/models/profile.dart';
import '../../rides/models/ride.dart';
import '../../util/trip/pending_ride_card.dart';
import '../../util/supabase.dart';
import '../models/drive.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DriveChatPage extends StatefulWidget {
  final Drive drive;
  const DriveChatPage({required this.drive, super.key});

  @override
  State<DriveChatPage> createState() => _DriveChatPageState();
}

class _DriveChatPageState extends State<DriveChatPage> {
  Drive? _drive;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      _drive = widget.drive;
    });
    loadDrive();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    if (_fullyLoaded) {
      Set<Profile> riders = _drive!.approvedRides!.map((ride) => ride.rider!).toSet();
      List<Ride> pendingRides = _drive!.pendingRides!.toList();
      if (riders.isEmpty && pendingRides.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.driveChatPageTitle),
          ),
          body: Center(
            child: Text(AppLocalizations.of(context)!.driveChatPageEmptyMessage),
          ),
        );
      } else {
        if (riders.isNotEmpty) {
          List<Widget> riderColumn = [
            const SizedBox(height: 5.0),
            Text(AppLocalizations.of(context)!.driveChatPageRiderHeadline,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10.0),
            _riderList(riders),
          ];
          widgets.addAll(riderColumn);
        }
        widgets.add(const SizedBox(height: 10.0));
        if (pendingRides.isNotEmpty) {
          List<Widget> pendingRidesColumn = [
            const SizedBox(height: 5.0),
            Text(AppLocalizations.of(context)!.driveChatPageRequestsHeadline,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10.0),
          ];
          pendingRidesColumn.addAll(_pendingRidesList(pendingRides));
          widgets.addAll(pendingRidesColumn);
        }
      }
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.driveChatPageTitle),
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
          drive: _drive!,
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
      _fullyLoaded = true;
    });
  }
}
