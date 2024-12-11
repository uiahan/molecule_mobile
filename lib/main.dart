import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import Hive
import 'pages/login_pages.dart';
import 'pages/home_page.dart';

void main() async {
  await Hive.initFlutter(); // Inisialisasi Hive
  await Hive.openBox('sessionBox'); // Membuka box untuk menyimpan data session
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: _getInitialRoute(), // Memeriksa apakah ada session yang valid
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => HomePage(authToken: _getAuthToken()), // Mengambil token dari Hive
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }

  // Cek apakah ada token di Hive
  String _getAuthToken() {
    var box = Hive.box('sessionBox');
    return box.get('authToken', defaultValue: ''); // Ambil token dari Hive
  }

  // Menentukan rute awal berdasarkan apakah ada token
  String _getInitialRoute() {
    var box = Hive.box('sessionBox');
    String? authToken = box.get('authToken');
    if (authToken != null && authToken.isNotEmpty) {
      return '/home'; // Jika ada token, langsung ke halaman home
    }
    return '/login'; // Jika tidak ada token, tampilkan halaman login
  }
}
