import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/rides/pages/ride_detail_page.dart';
import 'package:motis_mitfahr_app/util/custom_timeline_theme.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:timelines/timelines.dart';

import '../../account/widgets/avatar.dart';

class SearchCard extends TripCard<Ride> {
  const SearchCard(super.trip, {super.key});

  FixedTimeline buildRoute(context) {
    return FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: [
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${localeManager.formatTime(trip.startTime)}  ${trip.start}'),
              ],
            ),
          ),
          node: const TimelineNode(
            indicator: CustomOutlinedDotIndicator(),
            endConnector: CustomSolidLineConnector(),
          ),
        ),
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${localeManager.formatTime(trip.endTime)}  ${trip.end}'),
              ],
            ),
          ),
          node: const TimelineNode(
            indicator: CustomOutlinedDotIndicator(),
            startConnector: CustomSolidLineConnector(),
          ),
        )
      ],
    );
  }

  Widget buildDate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(localeManager.formatDate(trip.startTime)),
        Text("${trip.price}€"),
      ],
    );
  }

  Widget buildProfile(driver) {
    return Row(
      children: [
        Avatar(driver),
        const SizedBox(width: 5),
        Text(driver.username),
      ],
    );
  }

  Widget buildRanking() {
    return Row(
      children: const [
        Text("3"),
        Icon(
          Icons.star,
          color: Colors.amberAccent,
        ),
      ],
    );
  }

  Widget buildCardInfo(context, driver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: buildDate(),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: buildRoute(context),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildProfile(driver),
              buildRanking(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Profile driver = trip.drive!.driver!;

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RideDetailPage.fromRide(trip),
          ),
        ),
        child: buildCardInfo(context, driver),
      ),
    );
  }
}
