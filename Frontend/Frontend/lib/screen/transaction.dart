import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserDetailForm extends StatefulWidget {
  final String fare;
  final String busListString;
  final List ticketStationData;

  UserDetailForm({
    Key? key,
    required this.fare,
    required this.busListString,
    required this.ticketStationData,
  }) : super(key: key);

  @override
  _UserDetailFormState createState() => _UserDetailFormState();
}

class _UserDetailFormState extends State<UserDetailForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getUserInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('Không thể lấy thông tin người dùng. Vui lòng thử lại.'));
        }

        final userData = snapshot.data!;
        String userEmail = userData['email'];
        String userBalance = userData['balance'];
        int userId = userData['user_id'];

        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.phone),
                title: Text('Gmail'),
                subtitle: Text(userEmail),
              ),
              ListTile(
                leading: Icon(Icons.wallet),
                title: Text('Số dư tài khoản'),
                subtitle: Text(userBalance),
              ),
              ListTile(
                leading: Icon(Icons.attach_money),
                title: Text('Giá vé'),
                subtitle: Text(widget.fare),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Xử lý logic khác khi bấm nút, ví dụ lưu thông tin người dùng hoặc làm gì đó
                    try {
                      // Logic xử lý cho dự án của bạn ở đây
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Thông tin đã được xử lý thành công.'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(20.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã có lỗi xảy ra. Vui lòng thử lại.'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(20.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.check),
                  label: Text('Xử lý thông tin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final String baseUrl = '';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    final response = await http.get(
      Uri.parse('${baseUrl}/user'), // URL giả lập
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = jsonDecode(response.body);
      String email = responseBody['email'];
      int userId = responseBody['id'];
      double balance = 0;
      final response2 = await http.get(
        Uri.parse('${baseUrl}/deposit?user_id=$userId'), // URL giả lập
      );
      if (response2.statusCode == 200) {
        final Map<String, dynamic> responseBody2 = jsonDecode(response2.body);
        balance = responseBody2['amount'];
      }
      String balanceString = balance.toString();

      Object userData = {
        'email': email,
        'balance': balanceString,
        "user_id": userId,
      };
      return userData as Map<String, dynamic>;
    } else {
      throw Exception('Không thể lấy thông tin người dùng. Vui lòng thử lại.');
    }
  }

  int extractNumericValue(String fare) {
    final regex = RegExp(r'\d+'); // Tìm tất cả các chữ số
    final matches = regex.allMatches(fare); // Lấy tất cả các khớp
    final numericString = matches
        .map((match) => match.group(0))
        .join(''); // Nối tất cả các khớp lại với nhau
    return int.parse(numericString); // Chuyển đổi thành số nguyên
  }
}
