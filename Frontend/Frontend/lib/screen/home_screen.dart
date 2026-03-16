import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:typed_data';
import 'bus_information.dart';
import 'login.dart'; // Trang đăng nhập
import 'search_screen.dart';
import 'get_direction.dart';
import 'bus_stop_detail_screen.dart';
import 'package:collection/collection.dart'; // For listEquals
import 'favorite_routes_screen.dart';
import 'entertainment_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _mapController;
  static const CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(21.0054933764515, 105.84567100681808), zoom: 14);
  final List<Marker> _markers = <Marker>[];
  List _busStations = []; // Danh sách các điểm dừng bus
  String _selectedOption = "";
  bool _loggedIn = false;
  String _email = '';
  String _name = '';
  String _photoUrl = ''; // Ảnh đại diện người dùng
  Map<PolylineId, Polyline> _polylines = {};

  double _currentZoom = 14; // To store current zoom level
  CameraPosition? _latestCameraPosition; // To store the latest camera position
  Timer? _debounceTimer;
  Map<String, dynamic>? _selectedStation; // Thêm biến để lưu trạm được chọn

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    loadData(); // This loads user location marker
    _loadBusStations(); // Load bus stations data
    _latestCameraPosition = _kGooglePlex; // Initialize with initial camera position
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Kiểm tra trạng thái đăng nhập
  Future<void> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _loggedIn = true;
        _email = user.email ?? '';
        _name = user.displayName ?? 'Unknown User';
        _photoUrl = user.photoURL ?? ''; // Lấy ảnh đại diện từ Firebase
      });
    } else {
      setState(() {
        _loggedIn = false;
      });
    }
  }

  // Đăng xuất người dùng
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _loggedIn = false;
      _email = '';
      _name = '';
      _photoUrl = ''; // Đặt lại ảnh đại diện khi đăng xuất
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Tải dữ liệu bản đồ và vị trí người dùng
  loadData() {
    getUserCurrentLocation().then((value) async {
      _markers.add(Marker(
          markerId: MarkerId('2'),
          position: LatLng(value.latitude, value.longitude),
          infoWindow: InfoWindow(title: 'My current location')));

      CameraPosition cameraPosition = CameraPosition(
          zoom: 14, target: LatLng(value.latitude, value.longitude));
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      setState(() {
        _selectedOption = "X";
      });
    });
  }

  // Lấy vị trí hiện tại của người dùng
  Future<Position> getUserCurrentLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      return await Geolocator.getCurrentPosition();
    } else {
      throw Exception('Location permission denied');
    }
  }

  // Tải các điểm dừng xe buýt từ API hoặc SharedPreferences
  Future<void> _loadBusStations() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? busStationsData = prefs.getString('busStations');

    if (busStationsData != null) {
      setState(() {
        _busStations = json.decode(busStationsData);
        // Don't add markers immediately, wait for map controller and camera idle
        _updateVisibleMarkers(); // Attempt to update markers if map controller is ready
      });
    } else {
      await _fetchBusStations();
    }
  }

  // Gọi API để lấy danh sách các điểm dừng xe buýt
  Future<void> _fetchBusStations() async {
    String base_url = 'http://192.160.16.100:8080';
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
            _busStations = result['data'] ?? []; // Handle potential null
          });
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('busStations', json.encode(_busStations));
          _updateVisibleMarkers(); // Update markers after fetching and if map controller is ready
        } else {
          print('Failed to load bus stations: ${result['message']}');
          // Optionally show a snackbar or error message to the user
        }
      } else {
        print('Failed to load bus stations with status code: ${response.statusCode}');
         // Optionally show a snackbar or error message to the user
      }
    } catch (e) {
       print('Error fetching bus stations: $e');
       // Optionally show a snackbar or error message to the user
    }
  }

  // Add markers based on zoom level and map center
  void _updateVisibleMarkers() async {
    if (_mapController == null || _busStations.isEmpty || _latestCameraPosition == null) {
      print('Map controller not ready, no stations loaded, or no camera position.');
      return;
    }

    try {
      // Use the latest stored camera position
      _currentZoom = _latestCameraPosition!.zoom; // Get zoom from stored position
      final LatLng mapCenter = _latestCameraPosition!.target; // Get center from stored position

      // Define zoom threshold and radius (adjust these values as needed)
      const double zoomThreshold = 14.0; // Giảm ngưỡng zoom xuống để hiển thị sớm hơn
      const double radiusInMeters = 1000; // Tăng bán kính lên để hiển thị nhiều điểm hơn

      // Create a new temporary list to hold markers for the current view
      List<Marker> currentViewMarkers = [];

       // Find the user's current location marker if it exists in the current _markers list
      final userLocationMarker = _markers.firstWhereOrNull(
        (marker) => marker.markerId.value == '2',
      );

      // Add the user marker to the temporary list if it was found
       if (userLocationMarker != null) {
         currentViewMarkers.add(userLocationMarker);
       }

      // Logic to add bus station markers based on zoom level and radius
      if (_currentZoom >= zoomThreshold) {
         // If zoomed in enough, find and add markers within the defined radius
         for (var station in _busStations) {
          final double? latitude = (station['latitude'] as num?)?.toDouble();
          final double? longitude = (station['longitude'] as num?)?.toDouble();

          if (latitude != null && longitude != null) {
            final LatLng stationLocation = LatLng(latitude, longitude);

            // Calculate distance from map center to station
            final double distance = Geolocator.distanceBetween(
              mapCenter.latitude,
              mapCenter.longitude,
              stationLocation.latitude,
              stationLocation.longitude,
            );

            // Add marker only if the station is within the defined radius
            if (distance <= radiusInMeters) {
               final markerIcon = await _getMarkerIcon(Icons.directions_bus, Colors.blue, 48);

                // Safely access list of bus numbers and create snippet text
                final List<String> busNumbersGo = List<String>.from(station['bus_number_list_go'] ?? []);
                final List<String> busNumbersReturn = List<String>.from(station['bus_number_list_return'] ?? []);

                String snippetText = '';
                if (busNumbersGo.isNotEmpty) {
                  snippetText += 'Lượt đi: ${busNumbersGo.join(', ')}';
                }
                if (busNumbersReturn.isNotEmpty) {
                  if (snippetText.isNotEmpty) snippetText += '; ';
                  snippetText += 'Lượt về: ${busNumbersReturn.join(', ')}';
                }

                final marker = Marker(
                  markerId: MarkerId(station['bus_station_id']?.toString() ?? DateTime.now().toIso8601String()),
                  position: stationLocation,
                  icon: markerIcon,
                  onTap: () {
                    setState(() {
                      _selectedStation = station;
                    });
                  },
                );
                currentViewMarkers.add(marker);
            }
          }
        }
      } // If zoomed out (zoom < zoomThreshold), no bus station markers are added to currentViewMarkers

      // Update the _markers list by clearing and adding markers from the temporary list
      // This is the correct way to modify a final list and trigger UI update
       setState(() {
          _markers.clear(); // Clear the final list
          _markers.addAll(currentViewMarkers); // Add markers from the temporary list
          print('Current Zoom: $_currentZoom'); // Log current zoom
          print('Markers updated. Count: ${_markers.length}'); // Log marker count
        });

    } catch (e) {
       print('Error updating visible markers: $e');
    }
  }

  // Lấy icon cho marker
  Future<BitmapDescriptor> _getMarkerIcon(IconData iconData, Color color, double size) async {
    try {
      final PictureRecorder pictureRecorder = PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final Paint paint = Paint()..color = color;
      final double radius = size / 2;

      // Vẽ hình tròn nền
      canvas.drawCircle(Offset(radius, radius), radius, paint);

      // Vẽ icon xe buýt
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

      final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
      final ByteData? data = await img.toByteData(format: ImageByteFormat.png);
      if (data != null) {
        return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
      }
      // Return a default marker if data is null
      print('Marker data is null, returning default marker.');
      return BitmapDescriptor.defaultMarker;
    } catch (e) {
      print('Error creating marker icon: $e');
      // Return a default marker in case of any error during icon creation
      return BitmapDescriptor.defaultMarker;
    }
  }

  // Hiển thị chi tiết điểm dừng xe buýt
  void _showBusStationDetails(station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusStopDetailScreen(
          name: station['name']?.toString() ?? 'Unknown Station',
          busNumber: station['bus_number']?.toString() ?? '',
          direction: station['direction']?.toInt() ?? 0,
        ),
      ),
    );
  }

  // Đăng nhập với Google
  Future<void> _loginWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    setState(() {
      _loggedIn = true;
      _email = user?.email ?? '';
      _name = user?.displayName ?? 'Unknown User';
      _photoUrl = user?.photoURL ?? '';
    });
  }

  // Đăng nhập với Facebook
  Future<void> _loginWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? user = userCredential.user;

    setState(() {
      _loggedIn = true;
      _email = user?.email ?? '';
      _name = user?.displayName ?? 'Unknown User';
      _photoUrl = user?.photoURL ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buýt Xanh',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: _loggedIn
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(_photoUrl),
                        ),
                        SizedBox(height: 10),
                        Text(
                          _name,
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        Text(
                          _email,
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    )
                  : Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                        child: Text(
                          'Đăng Nhập',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
            _loggedIn
                ? ListTile(
              leading: Icon(Icons.logout),
              title: Text('Đăng xuất'),
              onTap: _logout,
            )
                : Container(),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Trang chủ'),
              onTap: () {
                // Xử lý khi chọn Trang chủ
              },
            ),
        
            ListTile(
              leading: Icon(Icons.favorite),
              title: Text('Tuyến đường yêu thích'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FavoriteRoutesScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.celebration, color: Colors.purple),
              title: Text('Giải trí'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EntertainmentScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedOption = "X";
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackBusScreen(),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: _selectedOption == "X"
                              ? Border(
                              bottom: BorderSide(color: Colors.orange, width: 3))
                              : null,
                        ),
                        child: ListTile(
                          leading: Icon(Icons.directions_bus),
                          title: Text('Thông tin xe'),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 50,
                    child: VerticalDivider(
                      color: Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedOption = "Y";
                        });
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GetDirectionScreen()),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: _selectedOption == "Y"
                              ? Border(
                              bottom: BorderSide(color: Colors.orange, width: 3))
                              : null,
                        ),
                        child: ListTile(
                          leading: Icon(Icons.directions),
                          title: Text('Tìm đường'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _kGooglePlex,
                      markers: Set<Marker>.of(_markers),
                      polylines: Set<Polyline>.of(_polylines.values),
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                        _mapController = controller;
                        _latestCameraPosition = _kGooglePlex;
                        _updateVisibleMarkers();
                      },
                      onCameraMove: (position) {
                        _latestCameraPosition = position;
                        _currentZoom = position.zoom;
                        
                        // Cancel any existing timer
                        _debounceTimer?.cancel();
                        
                        // Set a new timer to update markers after camera movement stops
                        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                          _updateVisibleMarkers();
                        });
                      },
                      zoomControlsEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                    Positioned(
                      top: 10,
                      left: 20,
                      right: 20,
                      child: Visibility(
                        visible: _selectedOption == "X" ? true : false,
                        child: SizedBox(
                            height: 40,
                            child: GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SearchScreen(
                                        title: "Tìm kiếm điểm dừng",
                                      )),
                                );
                                
                                if (result != null) {
                                  // Lấy thông tin điểm dừng từ kết quả trả về
                                  final station = result['station'];
                                  final latitude = result['latitude'];
                                  final longitude = result['longitude'];
                                  
                                  if (latitude != null && longitude != null && _mapController != null) {
                                    // Di chuyển camera đến vị trí điểm dừng
                                    final cameraPosition = CameraPosition(
                                      target: LatLng(latitude, longitude),
                                      zoom: 16, // Zoom gần hơn để dễ nhìn
                                    );
                                    
                                    await _mapController!.animateCamera(
                                      CameraUpdate.newCameraPosition(cameraPosition)
                                    );
                                    
                                    // Cập nhật trạm được chọn
                                    setState(() {
                                      _selectedStation = station;
                                    });
                                  }
                                }
                              },
                              child: AbsorbPointer(
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: 'Tìm kiếm điểm dừng',
                                    fillColor: Colors.white,
                                    filled: true,
                                    prefixIcon: Icon(Icons.search),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 4.0, horizontal: 8.0),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(16)),
                                    ),
                                  ),
                                  readOnly: true,
                                ),
                              ),
                            )),
                      ),
                    ),
                    if (_selectedStation != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            _showBusStationDetails(_selectedStation!);
                          },
                          child: Container(
                            margin: EdgeInsets.all(16),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.directions_bus, color: Colors.blue),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedStation!['name']?.toString() ?? 'Unknown Station',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                      Text(
                                        'Nhấn để xem chi tiết',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontFamily: 'Roboto',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
           // Animate to user's current location
          getUserCurrentLocation().then((value) async {
             if (_mapController != null) {
              CameraPosition cameraPosition = CameraPosition(
                  zoom: 14, target: LatLng(value.latitude, value.longitude));
               _mapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
               // onCameraIdle will be called after animation stops to update markers
            }
          });
        },
        child: Icon(Icons.location_searching_sharp),
        mini: true,
      ),
    );
  }
}
