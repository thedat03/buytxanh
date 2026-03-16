import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'login.dart';
class CustomDrawer extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextStyle _style = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: FutureBuilder<User?>(
              future: _auth.currentUser != null ? Future.value(_auth.currentUser) : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading...");
                } else if (snapshot.hasData) {
                  // Display user's email when logged in
                  return Text(snapshot.data!.email ?? "No Email");
                } else {
                  return Text("Guest");
                }
              },
            ),
            accountEmail: FutureBuilder<User?>(
              future: _auth.currentUser != null ? Future.value(_auth.currentUser) : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading...");
                } else if (snapshot.hasData) {
                  // Display user's email when logged in
                  return Text(snapshot.data!.email ?? "No Email");
                } else {
                  return Text("No Email");
                }
              },
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text("Đăng xuất", style: _style),
            onTap: () async {
              await _signOut(context); // Đăng xuất và điều hướng về màn hình đăng nhập
            },
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Trang chủ", style: _style),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Navigate to home screen
            },
          ),
          ListTile(
            leading: Icon(Icons.search),
            title: Text("Tra cứu", style: _style),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Implement navigation to "Tra cứu" screen
            },
          ),
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Tin buyt", style: _style),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Implement navigation to "Tin buyt" screen
            },
          ),
          ListTile(
            leading: Icon(Icons.help),
            title: Text("Trợ giúp", style: _style),
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              // Implement navigation to "Trợ giúp" screen
            },
          ),
        ],
      ),
    );
  }
  // Hàm đăng xuất và điều hướng về màn hình đăng nhập
  Future<void> _signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await FacebookAuth.i.logOut();

      // Sau khi đăng xuất, điều hướng đến màn hình Đăng Nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()), // Màn hình Đăng Nhập
      );
    } catch (e) {
      print("Lỗi đăng xuất: $e");
    }
  }
}
