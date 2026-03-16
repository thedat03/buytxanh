import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/favorite_route.dart';

class FavoriteRouteService {
  static const String _storageKey = 'favorite_routes';

  // Lưu tuyến đường yêu thích
  static Future<void> saveFavoriteRoute(FavoriteRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> routes = prefs.getStringList(_storageKey) ?? [];
    
    // Kiểm tra xem tuyến đường đã tồn tại chưa
    bool exists = routes.any((r) {
      final routeData = json.decode(r);
      return routeData['startLocation'] == route.startLocation && 
             routeData['endLocation'] == route.endLocation;
    });

    if (!exists) {
      routes.add(json.encode(route.toJson()));
      await prefs.setStringList(_storageKey, routes);
    }
  }

  // Lấy danh sách tuyến đường yêu thích
  static Future<List<FavoriteRoute>> getFavoriteRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> routes = prefs.getStringList(_storageKey) ?? [];
    
    return routes.map((r) {
      final routeData = json.decode(r);
      return FavoriteRoute.fromJson(routeData);
    }).toList();
  }

  // Xóa tuyến đường yêu thích
  static Future<void> removeFavoriteRoute(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> routes = prefs.getStringList(_storageKey) ?? [];
    
    routes.removeWhere((r) {
      final routeData = json.decode(r);
      return routeData['id'] == id;
    });

    await prefs.setStringList(_storageKey, routes);
  }

  // Kiểm tra xem tuyến đường có trong danh sách yêu thích không
  static Future<bool> isRouteFavorite(String startLocation, String endLocation, List<dynamic> transitSteps) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> routes = prefs.getStringList(_storageKey) ?? [];
    
    return routes.any((r) {
      final routeData = json.decode(r);
      // Kiểm tra điểm đi và điểm đến
      if (routeData['startLocation'] != startLocation || 
          routeData['endLocation'] != endLocation) {
        return false;
      }
      
      // Kiểm tra các tuyến xe buýt
      List<dynamic> savedTransitSteps = routeData['transitSteps'];
      if (savedTransitSteps.length != transitSteps.length) {
        return false;
      }
      
      // So sánh từng bước di chuyển
      for (int i = 0; i < transitSteps.length; i++) {
        if (savedTransitSteps[i]['travelMode'] != transitSteps[i]['travelMode'] ||
            savedTransitSteps[i]['name'] != transitSteps[i]['name']) {
          return false;
        }
      }
      
      return true;
    });
  }
} 