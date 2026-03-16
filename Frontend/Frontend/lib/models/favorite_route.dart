import 'dart:convert';

class FavoriteRoute {
  final String id;
  final String startLocation;
  final String endLocation;
  final String encodedPolyline;
  final String combinedTimeString;
  final String travelTimeInMinutes;
  final String busStopDepartureTime;
  final String startStationInstruction;
  final List<dynamic> transitSteps;
  final String fare;
  final int walkDuration;
  final List<dynamic> transitStepsDetail;
  final DateTime createdAt;

  FavoriteRoute({
    required this.id,
    required this.startLocation,
    required this.endLocation,
    required this.encodedPolyline,
    required this.combinedTimeString,
    required this.travelTimeInMinutes,
    required this.busStopDepartureTime,
    required this.startStationInstruction,
    required this.transitSteps,
    required this.fare,
    required this.walkDuration,
    required this.transitStepsDetail,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'encodedPolyline': encodedPolyline,
      'combinedTimeString': combinedTimeString,
      'travelTimeInMinutes': travelTimeInMinutes,
      'busStopDepartureTime': busStopDepartureTime,
      'startStationInstruction': startStationInstruction,
      'transitSteps': transitSteps,
      'fare': fare,
      'walkDuration': walkDuration,
      'transitStepsDetail': transitStepsDetail,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FavoriteRoute.fromJson(Map<String, dynamic> json) {
    return FavoriteRoute(
      id: json['id'],
      startLocation: json['startLocation'],
      endLocation: json['endLocation'],
      encodedPolyline: json['encodedPolyline'],
      combinedTimeString: json['combinedTimeString'],
      travelTimeInMinutes: json['travelTimeInMinutes'],
      busStopDepartureTime: json['busStopDepartureTime'],
      startStationInstruction: json['startStationInstruction'],
      transitSteps: json['transitSteps'],
      fare: json['fare'],
      walkDuration: json['walkDuration'],
      transitStepsDetail: json['transitStepsDetail'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 