import 'package:flutter/material.dart';
import 'screen/home_screen.dart';  // Đảm bảo đường dẫn đúng đến tệp login.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
void main() async {

  WidgetsFlutterBinding.ensureInitialized(); // Thêm dòng này
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),  // Màn hình đăng nhập khi khởi chạy ứng dụng
    );
  }
}
