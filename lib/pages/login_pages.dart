import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'home_page.dart';
import 'package:molecule_scan/network/api.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: Api.baseUrl,
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  bool isLoading = false;

  Future<void> login(BuildContext context) async {
    // Validasi input
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showErrorDialog(context, 'Email dan password tidak boleh kosong.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await dio.post(
        '/login',
        data: {
          'email': emailController.text,
          'password': passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;

        // Cek token dari respons
        final String? token = data['token'];
        if (token == null || token.isEmpty) {
          _showErrorDialog(
              context, 'Token tidak ditemukan. Periksa respons API.');
          return;
        }

        // Simpan token ke Hive
        try {
          var box = await Hive.openBox('sessionBox');
          print('Token diterima: $token');
          await box.put('authToken', token);
        } catch (e) {
          _showErrorDialog(context, 'Kesalahan menyimpan token: $e');
          return;
        }

        // Navigasi ke halaman Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(authToken: token),
          ),
        );
      } else {
        final Map<String, dynamic>? data = response.data;
        final errorMessage = data?['message'] ?? 'Login gagal';
        _showErrorDialog(context, errorMessage);
      }
    } on DioError catch (e) {
      String errorMessage = 'Terjadi kesalahan saat login.';
      if (e.response?.data is Map<String, dynamic>) {
        final Map<String, dynamic> data = e.response?.data;
        errorMessage = data['message'] ?? 'Kesalahan tidak diketahui.';
      } else if (e.response != null) {
        errorMessage = 'HTTP Error: ${e.response?.statusCode}';
      } else {
        errorMessage = 'Koneksi error: ${e.message}';
      }
      _showErrorDialog(context, errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image with blur effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('img/bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          // Login Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                margin: EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 20),
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Selamat datang di aplikasi Molecule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.blueAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      // Email Input
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(FontAwesomeIcons.envelope),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 20),
                      // Password Input
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(FontAwesomeIcons.key),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: () => login(context),
                              child: Text('Login'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 15),
                                textStyle: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
