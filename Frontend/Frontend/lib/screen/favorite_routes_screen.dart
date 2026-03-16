import 'package:flutter/material.dart';
import '../models/favorite_route.dart';
import '../services/favorite_route_service.dart';
import 'map_detail_screen.dart';

class FavoriteRoutesScreen extends StatefulWidget {
  @override
  _FavoriteRoutesScreenState createState() => _FavoriteRoutesScreenState();
}

class _FavoriteRoutesScreenState extends State<FavoriteRoutesScreen> {
  List<FavoriteRoute> _favoriteRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteRoutes();
  }

  Future<void> _loadFavoriteRoutes() async {
    setState(() {
      _isLoading = true;
    });

    final routes = await FavoriteRouteService.getFavoriteRoutes();
    setState(() {
      _favoriteRoutes = routes;
      _isLoading = false;
    });
  }

  Future<void> _removeFavoriteRoute(String id) async {
    await FavoriteRouteService.removeFavoriteRoute(id);
    await _loadFavoriteRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tuyến đường yêu thích'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _favoriteRoutes.isEmpty
              ? Center(
                  child: Text(
                    'Chưa có tuyến đường yêu thích nào',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _favoriteRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _favoriteRoutes[index];
                    return Dismissible(
                      key: Key(route.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _removeFavoriteRoute(route.id);
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          title: Text(
                            '${route.startLocation} → ${route.endLocation}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(route.combinedTimeString),
                              Text('Chi phí: ${route.fare}'),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapDetailScreen(
                                  encodedPolyline: route.encodedPolyline,
                                  transitStepsDetail: route.transitStepsDetail,
                                  combinedTimeString: route.combinedTimeString,
                                  travelTimeInMinutes: route.travelTimeInMinutes,
                                  busStopDepartureTime: route.busStopDepartureTime,
                                  startStationInstruction: route.startStationInstruction,
                                  transitSteps: route.transitSteps,
                                  fare: route.fare,
                                  walkDuration: route.walkDuration,
                                  ticketStationData: [],
                                  startLocation: route.startLocation,
                                  endLocation: route.endLocation,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 