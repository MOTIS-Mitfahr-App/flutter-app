import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';

class ProfileWidget extends StatelessWidget {
  final Profile profile;
  final double size;
  final bool showDescription;
  final Widget? actionWidget;
  final bool isTappable;

  const ProfileWidget(
    this.profile, {
    super.key,
    this.size = 20,
    this.showDescription = false,
    this.actionWidget,
    this.isTappable = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget profileRow = Row(
      children: [
        // TODO: Use profile picture
        CircleAvatar(
          minRadius: size,
          child: Text(profile.username[0], style: TextStyle(fontSize: size)),
        ),
        const SizedBox(width: 5),
        Text(profile.username, style: TextStyle(fontSize: size)),
      ],
    );
    if (actionWidget != null) {
      profileRow = Stack(
        children: [profileRow, Positioned(right: 0, child: actionWidget!)],
      );
    }
    if (showDescription && (profile.description?.isNotEmpty ?? false)) {
      profileRow = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileRow,
          const SizedBox(height: 10),
          Text(profile.description!),
        ],
      );
    }
    return isTappable
        ? InkWell(
            onTap: () {
              //TODO Profile page
            },
            child: profileRow,
          )
        : profileRow;
  }
}
