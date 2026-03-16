import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'home_screen.dart'; // Link tới màn hình chính của ứng dụng

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Biến kiểm tra trạng thái đồng ý với điều khoản
  bool _agreeToTerms = false;

  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    // Start the animation after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Hàm đăng nhập với Google
  Future<void> _signInWithGoogle() async {
    if (!_agreeToTerms) {
      _showErrorDialog('Bạn cần đồng ý với điều khoản và chính sách của ứng dụng.');
      return;
    }

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in process
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      // Navigate to home screen on successful login
      if (!mounted) return; // Check if the widget is still in the widget tree
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      // Handle specific errors or show a generic message
      print('Google Sign-In Error: $e'); // Log the error for debugging
      _showErrorDialog('Đăng nhập Google không thành công. Vui lòng thử lại.\nChi tiết: ${e.toString()}');
    }
  }

  // Hàm đăng nhập với Facebook
  Future<void> _signInWithFacebook() async {
    if (!_agreeToTerms) {
      _showErrorDialog('Bạn cần đồng ý với điều khoản và chính sách của ứng dụng.');
      return;
    }

    try {
      final LoginResult result = await FacebookAuth.i.login();

      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.tokenString);

        await _auth.signInWithCredential(credential);

        // Navigate to home screen on successful login
        if (!mounted) return; // Check if the widget is still in the widget tree
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else if (result.status != LoginStatus.cancelled) {
        _showErrorDialog('Đăng nhập Facebook không thành công. Vui lòng thử lại.');
      }
    } catch (e) {
      // Handle specific errors or show a generic message
      print('Facebook Sign-In Error: $e'); // Log the error for debugging
      _showErrorDialog('Đăng nhập Facebook không thành công. Vui lòng thử lại.\nChi tiết: ${e.toString()}');
    }
  }


  // Hiển thị hộp thoại lỗi
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Use Navigator.pop to close dialog
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background Illustration with fade effect

              SingleChildScrollView(
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 100),
                          // Logo with shadow
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/bus_login.png',
                              height: 120,
                            ),
                          ),
                          SizedBox(height: 20),
                          // Title with gradient
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [Colors.blue.shade900, Colors.blue.shade700],
                            ).createShader(bounds),
                            child: Text(
                              'Buýt Xanh',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            'Phụng sự từ trái tim',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 60),
                          // Login Buttons with enhanced styling
                          _buildSocialButton(
                            onPressed: _signInWithFacebook,
                            icon: Icon(Icons.facebook, size: 30, color: Colors.white),
                            label: 'Đăng nhập bằng Facebook',
                            backgroundColor: Color(0xFF3b5998),
                            textColor: Colors.white,
                          ),
                          SizedBox(height: 15),
                          _buildSocialButton(
                            onPressed: _signInWithGoogle,
                            icon: Image.asset('assets/google_logo.webp', width: 30, height: 30),
                            label: 'Đăng nhập bằng Google',
                            backgroundColor: Colors.white,
                            textColor: Colors.black87,
                            isGoogle: true,
                          ),
                          SizedBox(height: 20),
                          // Terms and conditions with improved styling
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Transform.scale(
                                  scale: 0.9,
                                  child: Checkbox(
                                    value: _agreeToTerms,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _agreeToTerms = value!;
                                      });
                                    },
                                    activeColor: Colors.blue.shade700,
                                    checkColor: Colors.white,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      print("Mở điều khoản và chính sách");
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: RichText(
                                        text: TextSpan(
                                          text: 'Bằng cách cung cấp thông tin của mình, tôi chấp nhận ',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Chính sách về quyền riêng tư',
                                              style: TextStyle(
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            TextSpan(
                                              text: ' khi sử dụng ứng dụng này.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required Widget icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    bool isGoogle = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          minimumSize: Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isGoogle ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
