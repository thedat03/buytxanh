import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../database/database_helper.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'route_detail_screen.dart';
import 'map_detail_screen.dart';

class TrackBusScreen extends StatefulWidget {
  @override
  _TrackBusScreenState createState() => _TrackBusScreenState();
}

class _TrackBusScreenState extends State<TrackBusScreen> {
  List<Map<String, dynamic>> _busList = [];
  List<Map<String, dynamic>> _busInfo = [];
  final TextEditingController _busNumberController = TextEditingController();
  bool _busSelected = false;
  bool _isLoading = false;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Map related variables
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];
  String _fare = '0 VND';
  String _routeName = '';
  String _busName = '';

  Future<void> _fetchBusList(String busNumber) async {
    if (busNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập mã tuyến xe buýt')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String baseUrl = 'http://192.160.16.100:8080';
      final response = await http.get(
        Uri.parse('$baseUrl/get_list_bus_bus_number').replace(queryParameters: {
          'bus_number': busNumber,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        setState(() {
          _busList = List<Map<String, dynamic>>.from(data);
          _busInfo = [];
          _busSelected = false;
        });

        // Lưu dữ liệu vào database local
        for (var bus in _busList) {
          try {
            await _dbHelper.insertOrUpdateBus(bus);
          } catch (e) {
            print('Lỗi khi lưu dữ liệu bus: $e');
          }
        }
      } else {
        throw Exception('Không thể lấy dữ liệu từ server');
      }
    } catch (e) {
      print('Lỗi kết nối: $e');
      // Nếu không có kết nối, lấy dữ liệu từ database local
      try {
        final localBuses = await _dbHelper.getBusByNumber(busNumber);
        setState(() {
          _busList = localBuses;
          _busInfo = [];
          _busSelected = false;
        });

        if (localBuses.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không tìm thấy dữ liệu xe buýt')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đọc dữ liệu local: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBusInfo(String busNumber) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get data from local database
      final localBusInfo = await _dbHelper.getBusByNumber(busNumber);
      setState(() {
        _busInfo = localBusInfo;
        _busSelected = true;
        if (_busInfo.isNotEmpty) {
          _fare = _busInfo[0]['fare'] ?? '0 VND';
          _routeName = _busInfo[0]['route_name'] ?? '';
          _busName = _busInfo[0]['bus_name'] ?? '';
        }
      });

      // Fetch route points from local database
      await _fetchRoutePoints(busNumber);

      if (localBusInfo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy thông tin chi tiết xe buýt')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đọc dữ liệu local: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRoutePoints(String busNumber) async {
    try {
      final String baseUrl = 'http://192.160.16.100:8080';
      final response = await http.get(
        Uri.parse('$baseUrl/get_bus_route_points')
            .replace(queryParameters: {
          'bus_number': busNumber,
        }),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))['data'];
        List<LatLng> points = [];
        for (var point in data) {
          points.add(LatLng(point['latitude'], point['longitude']));
        }

        setState(() {
          _routePoints = points;
          _updateMapRoute();
        });
      } else {
        throw Exception('Không thể lấy thông tin tuyến đường');
      }
    } catch (e) {
      print('Error fetching route points: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy thông tin tuyến đường')),
      );
    }
  }

  void _updateMapRoute() {
    if (_routePoints.isEmpty) return;

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );

      _markers.clear();
      // Add start marker
      _markers.add(
        Marker(
          markerId: MarkerId('start'),
          position: _routePoints.first,
          infoWindow: InfoWindow(title: 'Điểm bắt đầu'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      // Add end marker
      _markers.add(
        Marker(
          markerId: MarkerId('end'),
          position: _routePoints.last,
          infoWindow: InfoWindow(title: 'Điểm kết thúc'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    });

    // Fit map to show entire route
    if (_mapController != null && _routePoints.isNotEmpty) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          _getBounds(_routePoints),
          50.0,
        ),
      );
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin Xe buýt'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _busNumberController,
                        decoration: InputDecoration(
                          labelText: 'Nhập mã tuyến xe buýt',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[200],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        _fetchBusList(_busNumberController.text);
                      },
                      child: Text('Tìm kiếm'),
                    ),
                  ],
                ),
              ),
              if (!_busSelected && _busList.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _busList.length,
                    itemBuilder: (context, index) {
                      final bus = _busList[index];
                      final direction = bus['direction'] ?? 0;
                      final isDirectionGo = direction == 0;
                      
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDirectionGo ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(FontAwesomeIcons.bus,
                                size: 30, color: isDirectionGo ? Colors.blue : Colors.orange),
                          ),
                          title: Row(
                            children: [
                              Text(
                                'Tuyến ${bus['bus_number']}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDirectionGo ? Colors.blue[800] : Colors.orange[800],
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  bus['bus_number_name'] ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDirectionGo ? Colors.blue : Colors.orange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 2,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                ),
                                child: Text(
                                  isDirectionGo ? 'Lượt đi' : 'Lượt về',
                                  style: TextStyle(
                                    color: isDirectionGo ? Colors.blue[900] : Colors.orange[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            final busId = (bus['bus_id'] is int)
                                ? bus['bus_id']
                                : int.tryParse(bus['bus_id']?.toString() ?? '') ?? 0;
                            final direction = (bus['direction'] is int)
                                ? bus['direction']
                                : int.tryParse(bus['direction']?.toString() ?? '') ?? 0;
                            final routeName = bus['bus_number_name'] ?? '';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RouteDetailScreen(
                                  busId: busId,
                                  routeName: routeName,
                                  direction: direction,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (_busSelected && _busInfo.isNotEmpty)
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        child: GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                            _updateMapRoute();
                          },
                          initialCameraPosition: CameraPosition(
                            target: _routePoints.isNotEmpty
                                ? _routePoints.first
                                : LatLng(10.762622, 106.660172), // Default to HCMC
                            zoom: 12,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _busInfo.length,
                          itemBuilder: (context, index) {
                            final bus = _busInfo[index];
                            return Card(
                              margin: const EdgeInsets.all(8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      leading: Icon(FontAwesomeIcons.bus,
                                          size: 30, color: Colors.blue),
                                      title: Text('Mã xe buýt: ${bus['bus_number']}'),
                                      subtitle: Text('Tên xe: $_busName'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.route,
                                          size: 30, color: Colors.green),
                                      title: Text('Tuyến đường: $_routeName'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.speed,
                                          size: 30, color: Colors.green),
                                      title: Text('Tốc độ: ${bus['speed']} km/h'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.people,
                                          size: 30, color: Colors.orange),
                                      title: Text(
                                          'Số lượng hành khách: ${bus['current_passenger_amount']}/${bus['max_passenger_amount']}'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.attach_money,
                                          size: 30, color: Colors.green),
                                      title: Text('Giá vé: $_fare'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
