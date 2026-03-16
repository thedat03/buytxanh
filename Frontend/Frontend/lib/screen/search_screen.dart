import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  final String title;
  const SearchScreen({Key? key, required this.title}) : super(key: key);

  @override
  _SearchScreen createState() => _SearchScreen();
}

class _SearchScreen extends State<SearchScreen> {
  TextEditingController _controller = TextEditingController();
  List<dynamic> _busStations = [];
  List<dynamic> _filteredStations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBusStations();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadBusStations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? busStationsData = prefs.getString('busStations');

      if (busStationsData != null) {
        setState(() {
          _busStations = json.decode(busStationsData);
          _filteredStations = _busStations;
          _isLoading = false;
        });
      } else {
        await _fetchBusStations();
      }
    } catch (e) {
      print('Error loading bus stations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchBusStations() async {
    String base_url = 'http://192.168.88.145:8080';
    final String apiUrl = '$base_url/get_all_bus_station';
    
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(utf8.decode(response.bodyBytes));
        if (result['status'] == 200) {
          setState(() {
            _busStations = result['data'] ?? [];
            _filteredStations = _busStations;
            _isLoading = false;
          });
          
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('busStations', json.encode(_busStations));
        }
      }
    } catch (e) {
      print('Error fetching bus stations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _controller.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredStations = _busStations;
      });
    } else {
      setState(() {
        _filteredStations = _busStations.where((station) {
          final name = station['name']?.toString().toLowerCase() ?? '';
          final address = station['address']?.toString().toLowerCase() ?? '';
          return name.contains(query) || address.contains(query);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey.withOpacity(0.3),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Tìm điểm dừng",
                hintText: "Nhập tên điểm dừng hoặc địa chỉ",
                fillColor: Colors.white,
                filled: true,
                prefixIcon: Icon(Icons.search, color: Colors.blue),
                contentPadding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredStations.isEmpty
                    ? Center(
                        child: Text(
                          'Không tìm thấy điểm dừng nào',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredStations.length,
                        itemBuilder: (context, index) {
                          final station = _filteredStations[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: Icon(Icons.directions_bus, color: Colors.blue),
                              title: Text(
                                station['name']?.toString() ?? 'Unknown Station',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station['station_name']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context, {
                                  'station': station,
                                  'latitude': station['latitude']?.toDouble(),
                                  'longitude': station['longitude']?.toDouble(),
                                });
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
