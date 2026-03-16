import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'route_detail_screen.dart';
import 'bus_map_screen.dart';

class BusStopDetailScreen extends StatefulWidget {
  final String name;
  final String busNumber;
  final int direction;

  BusStopDetailScreen({
    required this.name,
    required this.busNumber,
    required this.direction,
  });

  @override
  _BusStopDetailScreenState createState() => _BusStopDetailScreenState();
}

class _BusStopDetailScreenState extends State<BusStopDetailScreen> {
  List<dynamic> _busRoutes = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBusRoutes();
  }

  Future<void> _fetchBusRoutes() async {
    String baseUrl = 'http://192.160.16.100:8080';
    final url = '$baseUrl/get_bus_station_by_name?name=${Uri.encodeComponent(widget.name)}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 200) {
          setState(() {
            _busRoutes = data['data'] ?? []; // Handle potential null
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Không có thông tin tuyến bus.'; // Use message from API or default
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Không có thông tin tuyến bus.'; // Default message for non-200 status
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối đến server: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showRouteDetail(BuildContext context, int? busId, String routeName, int direction) {
    if (busId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không có thông tin tuyến xe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết trạm xe buýt',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _busRoutes.isEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: TextStyle(fontFamily: 'Roboto'),
                  ),
                )
              : ListView.builder(
                  itemCount: _busRoutes.length,
                  itemBuilder: (context, index) {
                    final busRoute = _busRoutes[index];
                    return GestureDetector(
                      onTap: () => _showRouteDetail(
                        context,
                        busRoute['bus_id'] as int?,
                        busRoute['bus_number_name'] ?? '',
                        busRoute['direction'] ?? 0,
                      ),
                      child: RouteInfoCard(
                        routeNumber: busRoute['bus_number'] ?? '',
                        routeName: busRoute['bus_number_name'] ?? '',
                        direction: (busRoute['direction'] ?? 0) == 0 ? 'Lượt đi' : 'Lượt về',
                      ),
                    );
                  },
                ),
    );
  }
}

class RouteInfoCard extends StatelessWidget {
  final String routeNumber;
  final String routeName;
  final String direction;

  RouteInfoCard({
    required this.routeNumber,
    required this.routeName,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue,
              child: Text(
                routeNumber,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Roboto'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeName,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                        fontFamily: 'Roboto'),
                  ),
                  Text(direction,
                      style: TextStyle(
                          color: direction == 'Lượt đi'
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 14,
                          fontFamily: 'Roboto')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
