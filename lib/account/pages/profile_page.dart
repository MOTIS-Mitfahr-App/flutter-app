import 'package:flutter/material.dart';
import 'package:flutter_app/account/widgets/editable_row.dart';
import 'package:flutter_app/account/widgets/features_column.dart';
import 'package:flutter_app/account/widgets/reviews_preview.dart';
import 'package:flutter_app/util/big_button.dart';
import 'package:flutter_app/util/locale_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../util/supabase.dart';
import '../models/profile.dart';
import '../widgets/avatar.dart';

class ProfilePage extends StatefulWidget {
  final int profileId;
  final Profile? profile;

  const ProfilePage(this.profileId, {super.key}) : profile = null;
  ProfilePage.fromProfile(this.profile, {super.key}) : profileId = profile!.id!;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Profile? _profile;
  bool _fullyLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) _profile = widget.profile!;
    loadProfile();
  }

  Future<void> loadProfile() async {
    Map<String, dynamic> data = await supabaseClient.from('profiles').select('''
      *,
      profile_features (*),
      reviews_received: reviews!reviews_receiver_id_fkey(
        *,
        writer: writer_id(*)
      )
    ''').eq('id', widget.profileId).single();
    setState(() {
      _profile = Profile.fromJson(data);
      _fullyLoaded = true;
    });
  }

  Widget buildAvatar() {
    return Avatar(
      _profile!,
      size: 64,
      onUpload: loadProfile,
      isTappable: true,
    );
  }

  Widget buildUsername() {
    Widget username = Text(
      _profile!.username,
      style: Theme.of(context).textTheme.headline5,
    );
    if (_profile!.isCurrentUser) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Container()),
          username,
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
            ),
          ),
        ],
      );
    } else {
      return username;
    }
  }

  Widget buildEmail() {
    return Text(
      _profile!.email,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
    );
  }

  Widget buildDescription() {
    Widget description = _profile!.description?.isNotEmpty ?? false
        ? Text(
            _profile!.description!,
            style: Theme.of(context).textTheme.bodyText1,
          )
        : buildNoInfoText("<No description yet>");
    return EditableRow(
      title: 'Description',
      innerWidget: description,
      isEditable: _profile!.isCurrentUser,
      onPressed: () {},
    );
  }

  Widget buildFullName() {
    Widget fullName = _profile!.fullName.isNotEmpty
        ? Text(
            _profile!.fullName,
            style: Theme.of(context).textTheme.headline6,
          )
        : buildNoInfoText("<No full name>");
    return EditableRow(
        title: 'Full Name', innerWidget: fullName, isEditable: _profile!.isCurrentUser, onPressed: () {});
  }

  Widget buildBirthDate() {
    Widget birthDate = _profile!.birthDate != null
        ? Text(
            localeManager.formatDate(_profile!.birthDate!),
            style: Theme.of(context).textTheme.headline6,
          )
        : buildNoInfoText("<No birth date>");
    return EditableRow(
      title: 'Birth Date',
      innerWidget: birthDate,
      isEditable: _profile!.isCurrentUser,
      onPressed: () {},
    );
  }

  Widget buildGender() {
    Widget gender = _profile!.gender != null
        ? Text(
            _profile!.gender!.getName(context),
            style: Theme.of(context).textTheme.headline6,
          )
        : buildNoInfoText("<No gender>");

    return EditableRow(
      title: 'Gender',
      innerWidget: gender,
      isEditable: _profile!.isCurrentUser,
      onPressed: () {},
    );
  }

  Widget buildFeatures() {
    Widget features = _profile!.profileFeatures!.isNotEmpty
        ? FeaturesColumn(_profile!.profileFeatures!)
        : buildNoInfoText("<No features>");
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Features',
              style: Theme.of(context).textTheme.headline6,
            ),
            if (_profile!.isCurrentUser)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {},
                  ),
                ),
              ),
          ],
        ),
        features,
      ],
    );
  }

  Widget buildReviews() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Reviews',
        style: Theme.of(context).textTheme.headline6,
      ),
      const SizedBox(height: 8),
      ReviewsPreview(_profile!)
    ]);
  }

  Widget buildNoInfoText(String noInfoText) {
    return Text(
      noInfoText,
      style: Theme.of(context).textTheme.bodyText1?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      buildAvatar(),
      const SizedBox(height: 8),
      buildUsername(),
      if (_profile!.isCurrentUser) ...[
        buildEmail(),
      ],
      const SizedBox(height: 8),
      const Divider(),
      const SizedBox(height: 8),
    ];
    if (_profile!.isCurrentUser || _profile!.fullName.isNotEmpty) {
      widgets.addAll([
        buildFullName(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || (_profile!.description?.isNotEmpty ?? false)) {
      widgets.addAll([
        buildDescription(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || _profile!.birthDate != null) {
      widgets.addAll([
        buildBirthDate(),
        const SizedBox(height: 16),
      ]);
    }
    if (_profile!.isCurrentUser || _profile!.gender != null) {
      widgets.addAll([
        buildGender(),
        const SizedBox(height: 16),
      ]);
    }
    if (_fullyLoaded) {
      if (_profile!.isCurrentUser || _profile!.profileFeatures!.isNotEmpty) {
        widgets.addAll([buildFeatures(), const SizedBox(height: 16)]);
      }
      widgets.add(buildReviews());
    } else {
      widgets.add(const Center(child: CircularProgressIndicator()));
    }
    if (!_profile!.isCurrentUser) {
      widgets.addAll([
        const SizedBox(height: 32),
        BigButton(text: 'Report user', onPressed: () {}, color: Colors.red),
      ]);
    }
    final content = Column(
      children: widgets,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.username ?? ''),
      ),
      body: _profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(padding: const EdgeInsets.all(12), child: content),
              ),
            ),
    );
  }
}