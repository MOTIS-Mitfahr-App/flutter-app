import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/account/models/profile_feature.dart';
import 'package:flutter_app/account/models/review.dart';
import 'package:flutter_app/account/pages/write_review_page.dart';
import 'package:flutter_app/drives/models/drive.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/util/custom_banner.dart';
import 'package:flutter_app/util/profiles/reviews/custom_rating_bar_indicator.dart';
import 'package:flutter_app/util/profiles/profile_widget.dart';
import 'package:flutter_app/util/profiles/profile_wrap_list.dart';
import 'package:flutter_app/util/profiles/reviews/custom_rating_bar_size.dart';
import 'package:flutter_app/util/review_detail.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/trip/trip_overview.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../welcome/pages/login_page.dart';
import '../../welcome/pages/register_page.dart';

class RideDetailPage extends StatefulWidget {
  // One of these two must be set
  final int? id;
  final Ride? ride;

  const RideDetailPage({super.key, required this.id}) : ride = null;
  RideDetailPage.fromRide(this.ride, {super.key}) : id = ride!.id;

  @override
  State<RideDetailPage> createState() => _RideDetailPageState();
}

class _RideDetailPageState extends State<RideDetailPage> {
  static const String _driveQuery = '''
    *,
    driver: driver_id(
      *,
      reviews_received: reviews!reviews_receiver_id_fkey(
        *,
        writer: writer_id(*)
      ),
      profile_features(*)
    ),
    rides(
      *,
      rider: rider_id(*)
    )
  ''';
  static const String _rideQuery = '''
        *,
        drive: drive_id(
          $_driveQuery
        )
      ''';

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
    Ride ride;
    if (_ride?.status == RideStatus.preview) {
      ride = _ride!;

      Map<String, dynamic> data =
          await supabaseClient.from('drives').select(_driveQuery).eq('id', ride.driveId).single();

      ride.drive = Drive.fromJson(data);
    } else {
      Map<String, dynamic> data = await supabaseClient.from('rides').select(_rideQuery).eq('id', widget.id!).single();
      ride = Ride.fromJson(data);
    }

    setState(() {
      _ride = ride;
      _fullyLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [];

    if (_ride != null) {
      widgets.add(TripOverview(_ride!));
      widgets.add(const Divider(thickness: 1));
    }

    if (_fullyLoaded) {
      Ride ride = _ride!;

      Profile driver = ride.drive!.driver!;
      Widget driverColumn = InkWell(
        onTap: () {
          // TODO: Navigate to driver profile
        },
        child: Column(
          children: [
            ProfileWidget(driver),
            const SizedBox(height: 10),
            if (driver.description != null && driver.description!.isNotEmpty) Text(driver.description!),
          ],
        ),
      );
      widgets.add(driverColumn);
      widgets.add(const Divider(thickness: 1));

      widgets.add(_buildReviewsColumn(driver));

      if (driver.profileFeatures!.isNotEmpty) widgets.add(const Divider(thickness: 1));
      widgets.add(_buildFeaturesColumn(driver));

      if (ride.status != RideStatus.preview && ride.status != RideStatus.pending) {
        widgets.add(const Divider(thickness: 1));

        Set<Profile> riders =
            ride.drive!.rides!.where((otherRide) => ride.overlapsWith(otherRide)).map((ride) => ride.rider!).toSet();
        widgets.add(ProfileWrapList(riders, title: "Riders"));
      }

      Widget? primaryButton = _buildPrimaryButton(driver);
      if (primaryButton != null) {
        widgets.add(const SizedBox(height: 10));
        widgets.add(primaryButton);
        widgets.add(const SizedBox(height: 5));
      }
    } else {
      widgets.add(const SizedBox(height: 10));
      widgets.add(const Center(child: CircularProgressIndicator()));
    }

    Widget content = Column(
      children: [
        if (_ride != null && _ride!.status == RideStatus.pending)
          const CustomBanner(kind: CustomBannerKind.warning, text: "You have requested this ride.")
        else if (_ride != null && _ride!.status == RideStatus.rejected)
          const CustomBanner(kind: CustomBannerKind.error, text: "This ride has been rejected.")
        else if (_ride?.status.isCancelled() ?? false)
          CustomBanner(
            kind: CustomBannerKind.error,
            text: _ride!.status == RideStatus.cancelledByDriver
                ? "This ride has been cancelled."
                : "You have cancelled this ride.",
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
    List<Review> reviews = driver.reviewsReceived!..sort((a, b) => a.compareTo(b));
    AggregateReview aggregateReview = AggregateReview.fromReviews(reviews);

    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                Text(aggregateReview.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                CustomRatingBarIndicator(rating: aggregateReview.rating, size: CustomRatingBarSize.large),
                Expanded(
                  child: Text(
                    "${reviews.length} ${Intl.plural(reviews.length, one: 'review', other: 'reviews')}",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
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

  Widget _buildFeaturesColumn(Profile driver) {
    List<ProfileFeature> profileFeatures = driver.profileFeatures!;

    return ListView.builder(
      itemBuilder: ((context, index) {
        Feature feature = profileFeatures[index].feature;
        return ListTile(
          leading: feature.getIcon(context),
          title: Text(feature.getDescription(context)),
        );
      }),
      itemCount: profileFeatures.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget? _buildPrimaryButton(Profile driver) {
    switch (_ride!.status) {
      case RideStatus.preview:
        return BigButton(
          text: "REQUEST RIDE",
          onPressed: SupabaseManager.getCurrentProfile() == null ? _showLoginDialog : _showRequestDialog,
          color: Theme.of(context).primaryColor,
        );
      case RideStatus.approved:
        return _ride!.isFinished
            ? BigButton(
                text: "RATE DRIVER",
                onPressed: () => _navigateToRatePage(driver),
                color: Theme.of(context).primaryColor,
              )
            : BigButton(text: "CANCEL RIDE", onPressed: _showCancelDialog, color: Theme.of(context).errorColor);
      case RideStatus.pending:
        return BigButton(text: "RIDE REQUESTED", color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5));
      default:
        return null;
    }
  }

  void _navigateToRatePage(Profile driver) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => WriteReviewPage(driver)),
        )
        .then((value) => loadRide());
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.pageRideDetailCancelDialogTitle),
        content: Text(AppLocalizations.of(context)!.pageRideDetailCancelDialogContent),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.confirm),
            onPressed: () {
              _cancelRide();

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.pageRideDetailCancelDialogSuccessSnackbar),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _cancelRide() async {
    await _ride?.cancel();
    setState(() {});
  }

  _showRequestDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.pageRideDetailRequestlDialogTitle),
        content: Text(AppLocalizations.of(context)!.pageRideDetailRequestlDialogContent),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.confirm),
            onPressed: () {
              confirmRequest(_ride!);
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }

  void confirmRequest(Ride ride) async {
    ride.status = RideStatus.pending;
    final data = await supabaseClient.from('rides').insert(ride.toJson()).select(_rideQuery).single();
    setState(() {
      _ride = Ride.fromJson(data);
    });
    //todo: send notification to driver
  }

  _showLoginDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.pageRideDetailLoginlDialogTitle),
        content: Text(AppLocalizations.of(context)!.pageRideDetailLoginlDialogContent),
        actions: <Widget>[
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
              child: Text(AppLocalizations.of(context)!.login),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.popUntil(context, (route) => route.isFirst);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
              }),
          TextButton(
            child: Text(AppLocalizations.of(context)!.register),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
            },
          ),
        ],
      ),
    );
  }
}
