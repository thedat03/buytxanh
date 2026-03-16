import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bus_data.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bus_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bus_number TEXT NOT NULL,
        driver_name TEXT,
        speed REAL,
        current_passenger_amount INTEGER,
        max_passenger_amount INTEGER,
        fare TEXT,
        route_name TEXT,
        bus_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE route_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bus_number TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        point_order INTEGER NOT NULL,
        FOREIGN KEY (bus_number) REFERENCES bus_list (bus_number)
      )
    ''');
  }

  Future<int> insertBus(Map<String, dynamic> bus) async {
    final db = await instance.database;
    return await db.insert('bus_list', bus);
  }

  Future<List<Map<String, dynamic>>> getAllBuses() async {
    final db = await instance.database;
    return await db.query('bus_list');
  }

  Future<List<Map<String, dynamic>>> getBusByNumber(String busNumber) async {
    final db = await instance.database;
    return await db.query(
      'bus_list',
      where: 'bus_number = ?',
      whereArgs: [busNumber],
    );
  }

  Future<int> updateBus(Map<String, dynamic> bus) async {
    final db = await instance.database;
    return await db.update(
      'bus_list',
      bus,
      where: 'bus_number = ?',
      whereArgs: [bus['bus_number']],
    );
  }

  Future<int> deleteBus(String busNumber) async {
    final db = await instance.database;
    return await db.delete(
      'bus_list',
      where: 'bus_number = ?',
      whereArgs: [busNumber],
    );
  }

  Future<int> insertOrUpdateBus(Map<String, dynamic> bus) async {
    final db = await instance.database;
    
    // Kiểm tra xem bus đã tồn tại chưa
    final existingBuses = await db.query(
      'bus_list',
      where: 'bus_number = ?',
      whereArgs: [bus['bus_number']],
    );

    if (existingBuses.isEmpty) {
      // Nếu chưa tồn tại, thêm mới
      return await db.insert('bus_list', bus);
    } else {
      // Nếu đã tồn tại, cập nhật
      return await db.update(
        'bus_list',
        bus,
        where: 'bus_number = ?',
        whereArgs: [bus['bus_number']],
      );
    }
  }

  // Thêm phương thức để lấy các điểm đường đi của xe buýt
  Future<List<Map<String, dynamic>>> getRoutePoints(String busNumber) async {
    final db = await instance.database;
    return await db.query(
      'route_points',
      where: 'bus_number = ?',
      whereArgs: [busNumber],
      orderBy: 'point_order ASC',
    );
  }

  // Thêm phương thức để lưu các điểm đường đi
  Future<int> insertRoutePoint(Map<String, dynamic> point) async {
    final db = await instance.database;
    return await db.insert('route_points', point);
  }

  // Thêm phương thức để xóa các điểm đường đi của một xe buýt
  Future<int> deleteRoutePoints(String busNumber) async {
    final db = await instance.database;
    return await db.delete(
      'route_points',
      where: 'bus_number = ?',
      whereArgs: [busNumber],
    );
  }
} 