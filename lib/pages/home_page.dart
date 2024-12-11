import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:molecule_scan/network/api.dart';

class HomePage extends StatefulWidget {
  final String authToken;

  HomePage({required this.authToken});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String scannedCode = '';
  bool isLoading = false;
  String? errorMessage;
  Map<String, dynamic>? userData;
  bool isTokenValid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkTokenValidity(); // Validasi token
      if (isTokenValid) {
        await fetchLogo(); // Hanya fetch logo jika token valid
      }
    });
  }

  // Fungsi untuk memindai QR code
  // Fungsi untuk memindai QR code
  Future<void> scanQRCode() async {
    // Cek apakah QR code masih dalam proses pemindaian
    if (isLoading) return;

    String result = await FlutterBarcodeScanner.scanBarcode(
      '#00FF00', // Warna garis scan
      'Cancel', // Teks tombol Cancel
      true, // Gunakan kamera
      ScanMode.QR, // Mode pemindaian QR
    );

    if (result != '-1') {
      setState(() {
        scannedCode = result.replaceFirst('Invitation Code: ', '').trim();
        isLoading = true; // Set loading state agar UI menunggu
        errorMessage = null;
      });

      // Ambil data berdasarkan QR code
      await fetchUserData(scannedCode);

      // Pastikan isLoading diubah kembali menjadi false setelah selesai
      setState(() {
        isLoading = false;
      });
    }
  }

// Fungsi untuk mengambil data dari API
  Future<void> fetchUserData(String qrCode) async {
    final String url = '${Api.baseUrl}/registrations/$qrCode';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ${widget.authToken}',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        setState(() {
          userData = json.decode(response.body);
          isLoading = false; // Reset loading setelah data berhasil diambil
          isTokenValid = true; // Token valid
        });

        // Perbarui status 'telah_scan'
        await updateScanStatus(qrCode);
      } else if (response.statusCode == 401) {
        setState(() {
          isLoading = false;
          isTokenValid = false; // Token tidak valid
          errorMessage = 'Token tidak valid. Harap login kembali.';
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal mengambil data: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> updateScanStatus(String qrCode) async {
    final String url = '${Api.baseUrl}/registrations/$qrCode';

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Berhasil'),
              content: Text('Status telah_scan berhasil diperbarui'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        setState(() {
          errorMessage = 'Gagal memperbarui status: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat memperbarui status: $e';
      });
    }
  }

  // Fungsi untuk logout
  Future<void> logout() async {
    final String url = '${Api.baseUrl}/logout';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (mounted) {
        if (response.statusCode == 200) {
          // Kembali ke halaman login dan hapus semua rute sebelumnya
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        } else {
          setState(() {
            errorMessage = 'Gagal logout: ${response.body}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Terjadi kesalahan saat logout: $e';
        });
      }
    }
  }

  Future<void> checkTokenValidity() async {
    final String url = '${Api.baseUrl}/check-token';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isTokenValid = true;
        });
      } else {
        handleInvalidToken('Token tidak valid. Harap login kembali.');
      }
    } catch (e) {
      handleInvalidToken('Terjadi kesalahan saat memeriksa token: $e');
    }
  }

// Tangani token tidak valid atau error
  void handleInvalidToken(String error) {
    if (mounted) {
      setState(() {
        isTokenValid = false;
        errorMessage = error;
      });
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  // Fungsi untuk mengambil logo pertama
  Future<void> fetchLogo() async {
    final String url = '${Api.baseUrl}/logo'; // Ganti dengan URL API Anda

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse response untuk mendapatkan nama gambar
        final Map<String, dynamic> logoData = json.decode(response.body);
        setState(() {
          logoUrl = logoData['img']; // Simpan nama gambar yang diterima
        });
      } else {
        print('Failed to load logo: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildUserInfo(String title, dynamic value,
      {required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor, // Gunakan textColor untuk title
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 16,
                color: textColor, // Gunakan textColor untuk value
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String? logoUrl; // Variabel untuk menyimpan nama file logo

  @override
  Widget build(BuildContext context) {
    if (!isTokenValid && errorMessage == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(), // Menampilkan indikator loading
        ),
      );
    }

    if (!isTokenValid) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 100,
                ),
                SizedBox(height: 20),
                Text(
                  errorMessage ?? 'Token tidak valid. Harap login kembali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'Login Ulang',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 8.0,
        shadowColor: Colors.black.withOpacity(0.5),
        title: Row(
          children: [
            Image.asset(
              'img/logo.png',
              height: 40,
              width: 40,
            ),
            SizedBox(width: 10),
            Text(
              'Molecule',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: FaIcon(FontAwesomeIcons.rightFromBracket),
            tooltip: 'Logout',
            color: Colors.white,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 20),

              // Menampilkan logo dengan bentuk bulat
              logoUrl == null
                  ? CircularProgressIndicator()
                  : ClipOval(
                      child: Image.asset(
                        'img/$logoUrl',
                        height: 150,
                        width: 150,
                      ),
                    ),

              SizedBox(height: 20),

              // Divider sebagai garis pemisah
              Divider(
                thickness: 2,
                color: Colors.blue, // Warna garis
              ),

              SizedBox(height: 10),

              // Menampilkan pesan error jika ada
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Menampilkan data user
              if (userData != null)
                Column(
                  children: [
                    SizedBox(height: 20),

                    // Membuat teks Data Peserta bulat
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Data Peserta',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Card untuk menampilkan data dengan warna AppBar
                    Card(
                      elevation: 5,
                      margin:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.blue, // Menyesuaikan warna dengan AppBar
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildUserInfo('Nama ', userData!['nama'],
                                textColor: Colors.white),
                            SizedBox(height: 8),
                            _buildUserInfo('Email ', userData!['email'],
                                textColor: Colors.white),
                            SizedBox(height: 8),
                            _buildUserInfo('No HP ', userData!['no_hp'],
                                textColor: Colors.white),
                            SizedBox(height: 8),
                            _buildUserInfo('Domisili Perusahaan ',
                                userData!['domisili_perusahaan'],
                                textColor: Colors.white),
                            SizedBox(height: 8),
                            _buildUserInfo('Peserta ', userData!['peserta'],
                                textColor: Colors.white),
                            SizedBox(height: 8),
                            _buildUserInfo('Jabatan ', userData!['jabatan'],
                                textColor: Colors.white),
                            SizedBox(height: 8),
                            _buildUserInfo(
                                'Akan Hadir ', userData!['akan_hadir'],
                                textColor: Colors.white),
                            SizedBox(height: 8),
                            _buildUserInfo(
                                'Telah Scan ', userData!['telah_scan'],
                                textColor: Colors.white),
                            SizedBox(height: 8),
                            _buildUserInfo('Kode ', userData!['kode'],
                                textColor: Colors.white),
                            SizedBox(height: 8),

                            // Menampilkan QR Code
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'QR Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  userData!['qr'] != null
                                      ? Image.asset(
                                          'img/qr/${userData!['qr']}',
                                          height: 150,
                                        )
                                      : Container(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Jika userData null, tampilkan pesan
              if (userData == null)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Silakan scan QR peserta terlebih dahulu untuk menampilkan data-data peserta.',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20, right: 20),
        child: FloatingActionButton(
          onPressed: scanQRCode,
          backgroundColor: Colors.blue,
          shape: CircleBorder(),
          child: FaIcon(
            FontAwesomeIcons.qrcode,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
