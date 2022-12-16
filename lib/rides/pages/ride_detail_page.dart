import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/account/models/review.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/util/custom_banner.dart';
import 'package:flutter_app/util/profiles/custom_rating_bar_indicator.dart';
import 'package:flutter_app/util/profiles/profile_row.dart';
import 'package:flutter_app/util/profiles/profile_wrap_list.dart';
import 'package:flutter_app/util/review_detail.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/trip/trip_overview.dart';
import 'package:intl/intl.dart';

class RideDetailPage extends StatefulWidget {
  final int id;
  final Ride? ride;

  const RideDetailPage({super.key, required this.id}) : ride = null;
  RideDetailPage.fromRide(this.ride, {super.key}) : id = ride!.id!;

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  Ride? _ride;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      _ride = widget.ride;
    });

    loadRide();
  }

  Future<void> loadRide() async {
    Map<String, dynamic> data = await supabaseClient.from('rides').select('''
      *,
      drive: drive_id(
        *,
        driver: driver_id(
          *,
          reviews_received: reviews!reviews_receiver_id_fkey(
            *,
            writer: writer_id(*)
          )
        ),
        rides(
          *,
          rider: rider_id(*)
        )
      )
    ''').eq('id', widget.id).single();

    setState(() {
      _ride = Ride.fromJson(data);
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];
    bool currentlyWaitingForApproval = Random().nextBool(); // TODO: Get this from the database
    bool isCancelled = Random().nextBool(); // TODO: Get this from the database

    if (_ride != null) {
      if (true) {}

      Widget overview = TripOverview(_ride!);
      widgets.add(overview);
    }

    if (_fullyLoaded) {
      widgets.add(const Divider(
        thickness: 1,
      ));

      Profile driver = _ride!.drive!.driver!;
      Widget driverColumn = InkWell(
        onTap: () {
          // TODO: Navigate to driver profile
        },
        child: Column(
          children: [
            ProfileRow(driver),
            const SizedBox(height: 10),
            if (driver.description != null && driver.description!.isNotEmpty) Text(driver.description!),
          ],
        ),
      );
      widgets.add(driverColumn);

      widgets.add(const Divider(
        thickness: 1,
      ));

      widgets.add(_buildReviewsColumn(driver));

      widgets.add(const Divider(
        thickness: 1,
      ));

      Set<Profile> riders =
          _ride!.drive!.rides!.where((otherRide) => _ride!.overlapsWith(otherRide)).map((ride) => ride.rider!).toSet();

      widgets.add(ProfileWrapList(riders, title: "Riders"));

      if (_ride!.approved) {
        Widget cancelButton = BigButton(text: "DELETE", onPressed: _showDeleteDialog, color: Colors.red);
        widgets.add(const Divider(
          thickness: 1,
        ));
        widgets.add(cancelButton);
      } else if (_ride!.id == null) {
        Widget requestButton = BigButton(text: "REQUEST RIDE", onPressed: () {}, color: Theme.of(context).primaryColor);
        widgets.add(const Divider(
          thickness: 1,
        ));
        widgets.add(requestButton);
      } else if (currentlyWaitingForApproval) {
        Widget requestButton = const BigButton(text: "RIDE REQUESTED", color: Colors.grey);
        widgets.add(const Divider(
          thickness: 1,
        ));
        widgets.add(requestButton);
      }
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    Widget content = Column(
      children: [
        if (currentlyWaitingForApproval)
          const CustomBanner(backgroundColor: Colors.orange, text: "You have requested this ride.")
        else if (isCancelled)
          CustomBanner(
            color: Theme.of(context).colorScheme.onError,
            backgroundColor: Theme.of(context).errorColor,
            text: "This ride has been cancelled.",
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widgets,
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Detail'),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat),
          )
        ],
      ),
      body: _ride == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadRide,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: content,
              ),
            ),
    );
  }

  Widget _buildReviewsColumn(Profile driver) {
    List<Review> reviews = (driver.reviewsReceived ?? [])..sort((a, b) => a.compareTo(b));
    AggregateReview aggregateReview = AggregateReview.fromReviews(reviews);

    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                Text(aggregateReview.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                CustomRatingBarIndicator(rating: aggregateReview.rating, size: CustomRatingBarIndicatorSize.large),
                Expanded(
                  child: Text(
                    "${reviews.length} ${Intl.plural(reviews.length, one: 'review', other: 'reviews')}",
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Comfort"),
                      const SizedBox(width: 10),
                      CustomRatingBarIndicator(rating: aggregateReview.comfortRating),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Safety"),
                      const SizedBox(width: 10),
                      CustomRatingBarIndicator(rating: aggregateReview.safetyRating)
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Reliability"),
                      const SizedBox(width: 10),
                      CustomRatingBarIndicator(rating: aggregateReview.reliabilityRating)
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Hospitality"),
                      const SizedBox(width: 10),
                      CustomRatingBarIndicator(rating: aggregateReview.hospitalityRating)
                    ],
                  ),
                ],
              ),
            ),
            if (reviews.isNotEmpty)
              Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                    ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height)),
                    blendMode: BlendMode.dstIn,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ClipRect(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              min(reviews.length, 2),
                              (index) => ReviewDetail(review: reviews[index]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
          ],
        ),
        if (reviews.isNotEmpty)
          Positioned(
            bottom: 2,
            right: 2,
            child: Text(
              "More",
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Navigate to reviews page
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this ride?"),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              _ride!.cancel();
              Navigator.of(context).pop();
              Navigator.of(context).maybePop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ride deleted"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
