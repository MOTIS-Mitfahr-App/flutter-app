import 'package:flutter_app/util/supabase.dart';

import '../../util/model.dart';

class Ride extends Model {
  final String start;
  final DateTime startTime;
  final String end;
  final DateTime endTime;

  final int seats;
  final double? price;
  final bool approved;

  final int driveId;
  final int riderId;

  Ride({
    super.id,
    super.createdAt,
    required this.start,
    required this.startTime,
    required this.end,
    required this.endTime,
    required this.seats,
    this.price,
    required this.approved,
    required this.driveId,
    required this.riderId,
  });

  @override
  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      start: json['start'],
      startTime: DateTime.parse(json['start_time']),
      end: json['end'],
      endTime: DateTime.parse(json['end_time']),
      seats: json['seats'],
      price: json['price'],
      approved: json['approved'],
      driveId: json['drive_id'],
      riderId: json['rider_id'],
    );
  }

  static List<Ride> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => Ride.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'start_time': startTime.toString(),
      'end': end,
      'end_time': endTime.toString(),
      'seats': seats,
      'price': price,
      'approved': approved,
      'drive_id': driveId,
      'rider_id': riderId,
    };
  }

  List<Map<String, dynamic>> toJsonList(List<Ride> rides) {
    return rides.map((ride) => ride.toJson()).toList();
  }

  @override
  String toString() {
    return 'Ride{id: $id, in: $driveId, from: $start at $startTime, to: $end at $endTime, by: $riderId}';
  }

  static Future<Ride?> rideOfUserAtTime(
      DateTime start, DateTime end, int userId) async {
    //get all rides of user
    final List<Ride> rides = Ride.fromJsonList(
        await supabaseClient.from('rides').select().eq('rider_id', userId));
    //check if ride overlaps with start and end
    for (Ride ride in rides) {
      if (ride.startTime.isBefore(end) && ride.endTime.isAfter(start)) {
        return ride;
      }
    }
    return null;
  }
}
