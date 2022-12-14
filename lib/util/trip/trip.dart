import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/model.dart';
import 'package:motis_mitfahr_app/util/search/position.dart';

abstract class Trip extends Model {
  final String start;
  final Position startPosition;
  final DateTime startTime;
  final String end;
  final Position endPosition;
  final DateTime endTime;

  final int seats;

  Trip({
    super.id,
    super.createdAt,
    required this.start,
    required this.startPosition,
    required this.startTime,
    required this.end,
    required this.endPosition,
    required this.endTime,
    required this.seats,
  });

  bool get isFinished => endTime.isBefore(DateTime.now());
  bool get isOngoing => startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());

  bool overlapsWith(Trip other) {
    return startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime);
  }

  bool overlapsWithTimeRange(DateTimeRange range) {
    return startTime.isBefore(range.end) && endTime.isAfter(range.start);
  }
}
