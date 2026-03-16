import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteDetailScreen extends StatefulWidget {
  final int busId;
  final String routeName;
  final int direction;
  const RouteDetailScreen({Key? key, required this.busId, required this.routeName, required this.direction}) : super(key: key);

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? data;
  bool isLoading = true;
  String error = '';
  late TabController _tabController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _initialCameraTarget;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() { isLoading = true; error = ''; });
    try {
      final url = 'http://192.160.16.100:8080/api/bus-routing/${widget.busId}';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          data = jsonData;
          isLoading = false;
        });
        if (jsonData['polyline'] != null && jsonData['polyline'].toString().isNotEmpty) {
          _decodeAndSetPolyline(jsonData['polyline']);
        }
      } else {
        setState(() { error = 'Không tìm thấy thông tin tuyến xe.'; isLoading = false; });
      }
    } catch (e) {
      setState(() { error = 'Lỗi kết nối: $e'; isLoading = false; });
    }
  }

  void _decodeAndSetPolyline(String polylineString) {
    List<LatLng> points = [];
    for (var pair in polylineString.split(';')) {
      var latlng = pair.split(',');
      if (latlng.length == 2) {
        double? lat = double.tryParse(latlng[0].trim());
        double? lng = double.tryParse(latlng[1].trim());
        if (lat != null && lng != null) {
          points.add(LatLng(lat, lng));
        }
      }
    }
    if (points.isEmpty) return;
    Set<Marker> markers = {
      Marker(
        markerId: MarkerId('start'),
        position: points.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Điểm bắt đầu'),
      ),
      Marker(
        markerId: MarkerId('end'),
        position: points.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Điểm kết thúc'),
      ),
    };
    setState(() {
      _polylines = {
        Polyline(
          polylineId: PolylineId('route_polyline'),
          points: points,
          color: Colors.blue,
          width: 5,
        ),
      };
      _markers = markers;
      _initialCameraTarget = points.first;
    });
  }

  Widget _buildTimesTimeline() {
    if (isLoading) return Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));
    final times = (data?['departureTimes'] ?? '').toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (times.isEmpty) return Center(child: Text('Không có giờ xuất bến.'));
    return ListView.builder(
      itemCount: times.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Column(
                children: [
                  if (index != 0) Container(width: 2, height: 20, color: Colors.blue),
                  Icon(Icons.access_time, color: Colors.blue),
                  if (index != times.length - 1) Container(width: 2, height: 20, color: Colors.blue),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(child: Align(alignment: Alignment.centerLeft, child: Text(times[index]))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopsTimeline() {
    if (isLoading) return Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));
    final stops = (data?['routeDescription'] ?? '').toString().split(RegExp(r'\s*-\s*|\s*–\s*')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (stops.isEmpty) return Center(child: Text('Không có điểm dừng.'));
    return ListView.builder(
      itemCount: stops.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Column(
                children: [
                  if (index != 0) Container(width: 2, height: 20, color: Colors.blue),
                  Icon(Icons.directions_bus, color: Colors.blue),
                  if (index != stops.length - 1) Container(width: 2, height: 20, color: Colors.blue),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(child: Align(alignment: Alignment.centerLeft, child: Text(stops[index]))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab() {
    if (isLoading) return Center(child: CircularProgressIndicator());
    if (error.isNotEmpty) return Center(child: Text(error));
    final info = data;
    if (info == null) return Center(child: Text('Không có dữ liệu.'));
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đơn vị chủ quản:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(info['operator'] ?? 'N/A'),
            SizedBox(height: 8),
            Text('Giãn cách chạy xe:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(info['frequency'] ?? 'N/A'),
            SizedBox(height: 8),
            Text('Giá vé:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(info['price'] ?? 'N/A'),
            SizedBox(height: 8),
            Text('Thời gian hoạt động:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(info['operatingHoursWeekday'] ?? ''),
            Text(info['operatingHoursWeekend'] ?? ''),
            SizedBox(height: 8),
            Text('Chiều đi:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            Text(info['routeDescription'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeName = data?['bus']?['busNumberName'] ?? widget.routeName;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Tuyến: ${data?['bus']?['busNumber'] ?? widget.busId.toString().padLeft(2, '0')}'),
      ),
      body: Column(
        children: [
          Container(
            height: 220,
            child: _initialCameraTarget == null
                ? Center(child: Text('Đang tải bản đồ...'))
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialCameraTarget!,
                      zoom: 13,
                    ),
                    polylines: _polylines,
                    markers: _markers,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: true,
                  ),
          ),
          Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(routeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                SizedBox(height: 4),
                Row(
children: [
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.direction == 0 ? Colors.blue : Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 2,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      child: Text(
                        widget.direction == 0 ? 'Lượt đi' : 'Lượt về',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          
                        ),                  
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.deepPurple,
                  unselectedLabelColor: Colors.black,
                  indicatorColor: Colors.deepPurple,
                  tabs: [
                    Tab(text: 'Giờ xuất bến'),
                    Tab(text: 'Điểm dừng'),
                    Tab(text: 'Thông tin'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTimesTimeline(),
                      _buildStopsTimeline(),
                      _buildInfoTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
