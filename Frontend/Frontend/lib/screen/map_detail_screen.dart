import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:mapbus/widgets/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbus/services/favorite_route_service.dart';
import 'package:mapbus/models/favorite_route.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MapDetailScreen extends StatefulWidget {
  final String encodedPolyline;
  final List<dynamic> transitStepsDetail;
  final String combinedTimeString;
  final String travelTimeInMinutes;
  final String busStopDepartureTime;
  final String startStationInstruction;
  final List<dynamic> transitSteps;
  final String fare;
  final int walkDuration;
  final List<dynamic> ticketStationData;
  final String startLocation;
  final String endLocation;

  MapDetailScreen({
    Key? key,
    required this.encodedPolyline,
    required this.transitStepsDetail,
    required this.combinedTimeString,
    required this.travelTimeInMinutes,
    required this.busStopDepartureTime,
    required this.startStationInstruction,
    required this.transitSteps,
    required this.fare,
    required this.walkDuration,
    required this.ticketStationData,
    required this.startLocation,
    required this.endLocation,
  }) : super(key: key);

  @override
  _MapDetailScreenState createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends State<MapDetailScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  List _busStations = [];
  final List<Marker> _markers = <Marker>[];
  late StreamSubscription<Position> _positionStream;
  late StreamSubscription<Position> _headingStream;
  LatLng _currentPosition = LatLng(0, 0);
  BitmapDescriptor? _currentLocationMarker;
  double _heading = 0.0;
  bool _shouldMoveCamera = false;
  bool _isFavorite = false;

  final FlutterTts flutterTts = FlutterTts();
  bool _notifiedOfDestination = false;
  bool _isSpeaking = false;
  
  // Thêm các biến để quản lý thông báo tốt hơn
  bool _hasNotifiedNearDestination = false;
  bool _hasNotifiedVeryNearDestination = false;
  bool _hasNotifiedArrival = false;
  Timer? _notificationTimer;
  double _lastNotificationDistance = double.infinity;

  @override
  void initState() {
    super.initState();
    _initTts();
    decodePolyline(widget.encodedPolyline);
    _loadBusStations();
    _initCurrentLocationMarker();
    _trackUserLocation();
    _checkIfFavorite();
  }

  @override
  void dispose() {
    _positionStream.cancel();
    _headingStream.cancel();
    _notificationTimer?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  void decodePolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encodedPolyline);

    if (result.isNotEmpty) {
      result.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    setState(() {
      Polyline polyline = Polyline(
        polylineId: PolylineId('route'),
        points: polylineCoordinates,
        color: Colors.orange,
        width: 5,
      );
      polylines.add(polyline);

      _markers.add(Marker(
        markerId: MarkerId('start'),
        position: polylineCoordinates.first,
        infoWindow: InfoWindow(title: widget.startLocation),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));

      _markers.add(Marker(
        markerId: MarkerId('end'),
        position: polylineCoordinates.last,
        infoWindow: InfoWindow(title: widget.endLocation),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    });
  }

  Future<void> _loadBusStations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? busStationsData = prefs.getString('busStations');

    if (busStationsData != null) {
      // Dữ liệu đã được lưu trữ trong SharedPreferences
      setState(() {
        _busStations = json.decode(busStationsData);
        _addBusStationMarkers();
      });
    }
  }

  void _addBusStationMarkers() async {
    for (var station in _busStations) {
      final markerIcon =
          await _getMarkerIcon(Icons.directions_bus, Colors.blue, 48);

      _markers.add(Marker(
        markerId: MarkerId(station['bus_station_id'].toString()),
        position: LatLng(station['latitude'], station['longitude']),
        infoWindow: InfoWindow(
          title: station['name'],
          snippet:
              'Lượt đi: ${station["bus_number_list_go"]}; lượt về: ${station["bus_number_list_return"]}',
          onTap: () {},
        ),
        icon: markerIcon,
      ));
    }
    setState(() {});
  }

  Future<BitmapDescriptor> _getMarkerIcon(
      IconData iconData, Color color, double size) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = size / 2;

    canvas.drawCircle(Offset(radius, radius), radius, paint);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: iconData.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final img = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? data = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _initCurrentLocationMarker() async {
    _currentLocationMarker =
        await _getMarkerIcon(Icons.navigation, Colors.red, 48);
  }

  void _trackUserLocation() {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,  // Đảm bảo rằng độ chính xác được thiết lập
      distanceFilter: 10,  // Cập nhật vị trí sau mỗi 10 mét
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);

        _markers.removeWhere(
                (marker) => marker.markerId.value == 'currentLocation');
        _markers.add(Marker(
          markerId: MarkerId('currentLocation'),
          position: _currentPosition,
          infoWindow: InfoWindow(title: 'Vị trí hiện tại của bạn'),
          icon: _currentLocationMarker ?? BitmapDescriptor.defaultMarker,
          rotation: _heading, // Cập nhật xoay theo hướng di chuyển
        ));
      });

      if (_shouldMoveCamera) {
        _moveCameraToCurrentLocation();
      }
      
      // Kiểm tra khoảng cách đến đích mỗi khi vị trí thay đổi
      _checkDistanceToDestination();
    });

    _headingStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      setState(() {
        _heading = position.heading!;
      });
    });
  }

  Future<void> _moveCameraToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: 14, bearing: _heading),
      ),
    );
  }

  Future<void> _checkIfFavorite() async {
    final isFavorite = await FavoriteRouteService.isRouteFavorite(
      widget.startLocation,
      widget.endLocation,
      widget.transitSteps,
    );
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      // Xóa khỏi danh sách yêu thích
      await FavoriteRouteService.removeFavoriteRoute(
        '${widget.startLocation}_${widget.endLocation}_${widget.transitSteps.map((step) => step['name']).join('_')}',
      );
    } else {
      // Thêm vào danh sách yêu thích
      final route = FavoriteRoute(
        id: '${widget.startLocation}_${widget.endLocation}_${widget.transitSteps.map((step) => step['name']).join('_')}',
        startLocation: widget.startLocation,
        endLocation: widget.endLocation,
        encodedPolyline: widget.encodedPolyline,
        combinedTimeString: widget.combinedTimeString,
        travelTimeInMinutes: widget.travelTimeInMinutes,
        busStopDepartureTime: widget.busStopDepartureTime,
        startStationInstruction: widget.startStationInstruction,
        transitSteps: widget.transitSteps,
        fare: widget.fare,
        walkDuration: widget.walkDuration,
        transitStepsDetail: widget.transitStepsDetail,
        createdAt: DateTime.now(),
      );
      await FavoriteRouteService.saveFavoriteRoute(route);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite 
          ? 'Đã thêm vào tuyến đường yêu thích' 
          : 'Đã xóa khỏi tuyến đường yêu thích'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget buildHeader() {
    return routeDetailHeader(
      context,
      widget.combinedTimeString,
      widget.travelTimeInMinutes,
      widget.busStopDepartureTime,
      widget.startStationInstruction,
      widget.transitSteps,
      widget.fare,
      widget.walkDuration,
      widget.ticketStationData,
    );
  }

  Widget buildTransitStepDetail(int index) {
    var step = widget.transitStepsDetail[index];
    if (index == 0) {
      return timeLineTileStart(step['time'], step['location']);
    } else if (step['travelMode'] == 'WALK') {
      return timeLineTileWalk(step['walkTime'], step['distance']);
    } else if (step['travelMode'] == 'TRANSIT') {
      return timeLineTileTransit(
        step['departureTime'],
        step['arrivalTime'],
        step['departureStop'],
        step['arrivalStop'],
        step['busNumber'],
        step['headsign'],
        step['timeMinites'],
        step['stopCount'],
      );
    } else if (index == widget.transitStepsDetail.length - 1) {
      return timeLineTileDestination(
          step['time'], step['location'], step['fare']);
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đường đi trên bản đồ'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: polylineCoordinates.isNotEmpty
                  ? polylineCoordinates[0]
                  : LatLng(0, 0),
              zoom: 14,
            ),
            markers: Set<Marker>.of(_markers),
            polylines: polylines,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.1,
            maxChildSize: 1.0,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    buildHeader(),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: widget.transitStepsDetail.length,
                        itemBuilder: (BuildContext context, int index) {
                          return buildTransitStepDetail(index);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _shouldMoveCamera = true;
                });
                _moveCameraToCurrentLocation();
              },
              child: Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  Widget timeLineTileStart(String time, String location) {
    String locationHeader = location.split(',')[0];
    int commaIndex = location.indexOf(',');
    String locationDetail = location.substring(commaIndex + 1).trim();

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 50,
                child: Column(
                  children: <Widget>[
                    Text(time,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 2,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3.0),
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              for (int i = 0; i < 2; i++)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3.0),
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationHeader,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      locationDetail,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget timeLineTileWalk(int time, int distance) {
    String travelModeVN = "Đi bộ";
    int timeMinites = (time / 60).round();

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 50,
            child: Column(
              children: <Widget>[
                SizedBox(height: 28),
                Icon(Icons.directions_walk, color: Colors.blue, size: 20),
              ],
            ),
          ),
          SizedBox(width: 14.5),
          Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: Column(
                        children: [
                          for (int i = 0; i < 9; i++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3.0),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  travelModeVN,
                  style: TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Khoảng ${timeMinites} p, ${distance} m',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget timeLineTileTransit(
      String departureTime,
      String arrivalTime,
      String departureStop,
      String arrivalStop,
      String busNumber,
      String headsign,
      int timeMinites,
      int stopCount) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 50,
            child: Column(
              children: <Widget>[
                Text(departureTime,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 28),
                Icon(Icons.directions_bus, color: Colors.blue, size: 20),
                SizedBox(height: 54),
                Text(arrivalTime,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 2,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: Colors.black, width: 2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.0),
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: Colors.black, width: 2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  departureStop,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(3.0),
                      ),
                      child: Text(
                        '${busNumber}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        '${headsign}',
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Khoảng ${timeMinites} p, ${stopCount} điểm dừng",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Text(
                  arrivalStop,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget timeLineTileDestination(String time, String location, String fare) {
    String locationHeader = location.split(',')[0];
    int commaIndex = location.indexOf(',');
    String locationDetail = location.substring(commaIndex + 1).trim();

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 50,
                child: Column(
                  children: <Widget>[
                    Text(time,
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 0),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 2,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 3.0),
                                child: Container(
                                  width: 11,
                                  height: 11,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locationHeader,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      locationDetail,
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w300),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
                right: 8.0, left: 8.0, top: 16.0, bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('Chi phí: ${fare}'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget routeDetailHeader(
      BuildContext context,
      String combinedTimeString,
      String travelTimeInMinutes,
      String busStopDepartureTime,
      String startStationInstruction,
      List<dynamic> transitSteps,
      String fare,
      int walkDuration,
      List ticketStationData) {
    // get current time and directionDetail["duration"] to calculate the arrival time, convert to string
    walkDuration = (walkDuration / 60).round();
    List<dynamic> list_bus = [];
    for (int i = 0; i < transitSteps.length; i++) {
      var step = transitSteps[i];
      if (step['travelMode'] == 'TRANSIT') {
        list_bus.add(step['name']);
      }
    }
    String busListString = list_bus.join(', ');

    return Padding(
      padding: EdgeInsets.all(0),
      child: Card(
        // elevation: 4.0, // Độ cao của shadow
        color: Colors.white, // Màu nền của thẻ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Bo tròn các góc
        ),
        child: Container(
          width: 400, // max size of the card
          padding: EdgeInsets.only(
              top: 16.0,
              right: 16.0,
              left: 16.0,
              bottom: 0), // Padding bên trong thẻ
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Đảm bảo column chiếm không gian tối thiểu
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Căn lề các phần tử ở hai bên
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        combinedTimeString,
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        travelTimeInMinutes,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_walk, size: 20), // Biểu tượng xe
                      SizedBox(width: 5), // Khoảng cách giữa các icon
                      Icon(Icons.directions_bus, size: 20), // Biểu tượng bus
                    ],
                  ),
                ],
              ),
              getDirectionSummaryWidget(transitSteps),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        '${busStopDepartureTime} từ ${startStationInstruction}',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w300)),
                  ),
                ],
              ),
              SizedBox(height: 4), // Khoảng cách nhỏ hơn
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // Căn chỉnh các phần tử ở hai bên
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(fare,
                          style:
                              TextStyle(fontSize: 14, color: Colors.black54)),
                      SizedBox(width: 24),
                      Icon(Icons.directions_walk, size: 40),
                      Text(
                        '${walkDuration} p',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8), // Khoảng cách nhỏ hơn
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    
    // Set up completion handler
    flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) return; // Prevent multiple simultaneous speech
    
    setState(() {
      _isSpeaking = true;
    });

    try {
      await flutterTts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  void _showNotification(String message) {
    // Hủy timer cũ nếu có
    _notificationTimer?.cancel();
    
    // Hiển thị thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.location_on, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.blue[600],
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
    
    // Tự động ẩn thông báo sau 4 giây
    _notificationTimer = Timer(Duration(seconds: 4), () {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  void _checkDistanceToDestination() async {
    if (polylineCoordinates.isEmpty) return;

    LatLng destination = polylineCoordinates.last;
    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      destination.latitude,
      destination.longitude,
    );

    // Định nghĩa các ngưỡng thông báo khác nhau
    double farThreshold = 500.0; // 500 mét - thông báo xa
    double nearThreshold = 200.0; // 200 mét - thông báo gần
    double veryNearThreshold = 100.0; // 100 mét - thông báo rất gần
    double arrivalThreshold = 50.0; // 50 mét - thông báo đã đến

    // Kiểm tra xem có đang di chuyển về phía đích không (khoảng cách giảm)
    bool isMovingTowardsDestination = distanceInMeters < _lastNotificationDistance;
    _lastNotificationDistance = distanceInMeters;

    // Chỉ thông báo nếu đang di chuyển về phía đích hoặc đã rất gần
    if (!isMovingTowardsDestination && distanceInMeters > veryNearThreshold) {
      return;
    }

    // Thông báo khi còn xa (500m)
    if (distanceInMeters <= farThreshold && distanceInMeters > nearThreshold && !_hasNotifiedNearDestination) {
      String message = "Bạn còn khoảng ${distanceInMeters.round()} mét nữa sẽ đến điểm đến";
      _showNotification(message);
      await _speak(message);
      _hasNotifiedNearDestination = true;
    }
    // Thông báo khi gần (200m)
    else if (distanceInMeters <= nearThreshold && distanceInMeters > veryNearThreshold && !_hasNotifiedVeryNearDestination) {
      String message = "Bạn sắp đến điểm đến! Còn khoảng ${distanceInMeters.round()} mét";
      _showNotification(message);
      await _speak(message);
      _hasNotifiedVeryNearDestination = true;
    }
    // Thông báo khi rất gần (100m)
    else if (distanceInMeters <= veryNearThreshold && distanceInMeters > arrivalThreshold && !_hasNotifiedArrival) {
      String message = "Bạn đã rất gần điểm đến! Còn khoảng ${distanceInMeters.round()} mét";
      _showNotification(message);
      await _speak(message);
      _hasNotifiedArrival = true;
    }
    // Thông báo khi đã đến (50m)
    else if (distanceInMeters <= arrivalThreshold && !_notifiedOfDestination) {
      String message = "Chúc mừng! Bạn đã đến điểm đến!";
      _showNotification(message);
      await _speak(message);
      
      setState(() {
        _notifiedOfDestination = true;
      });
      
      // Dừng theo dõi vị trí sau khi đã đến
      _positionStream.cancel();
      _headingStream.cancel();
    }
  }
}
