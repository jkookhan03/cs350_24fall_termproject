import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Messaging import
import 'package:url_launcher/url_launcher.dart'; // 전화 앱 실행을 위한 import
import 'user_screen.dart'; // 사용자 화면
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detail_screen.dart'; // 상세정보 화면 (각 사용자 정보)
import 'low_heart_rate_screen.dart'; // 심박수 관련 화면
import 'missed_medicine_screen.dart'; // 약 복용 관련 화면
import 'outdoor_alert_screen.dart'; // 외출 알림 화면

class HomeScreen extends StatefulWidget {
  final String name;
  final bool elderly;
  final String token;

  const HomeScreen({
    Key? key,
    required this.name,
    required this.elderly,
    required this.token,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 1; // 현재 네비게이션 바 인덱스 (1: HomeScreen)
  List<Map<String, dynamic>> elderlyList = []; // Elder 정보를 저장

  @override
  void initState() {
    super.initState();
    setupFCM();
    fetchElderlyInfo();
  }

  void setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 알림 권한 요청
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('알림 권한 상태: ${settings.authorizationStatus}');

    // 포그라운드 알림 처리
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("포그라운드에서 메시지 수신: ${message.notification?.title}");
      _showAlert(message);
    });

    // 백그라운드 알림 클릭 처리
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("백그라운드 알림 클릭: ${message.notification?.title}");
      _navigateToDetailPage(message.data);
    });

    // 앱 종료 상태에서 알림 클릭 처리
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      print("종료 상태에서 알림 클릭: ${initialMessage.notification?.title}");
      _navigateToDetailPage(initialMessage.data);
    }
  }

  Future<void> fetchElderlyInfo() async {
    final Uri url = Uri.parse('http://121.152.208.156:3000/caregiver/elderlyInfo');

    try {
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          elderlyList = List<Map<String, dynamic>>.from(responseData['elderlyInfo']);
        });
      } else {
        print("Failed to fetch elderly info: ${response.body}");
      }
    } catch (e) {
      print("Error fetching elderly info: $e");
    }
  }

  void _showAlert(RemoteMessage message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message.notification?.title ?? '알림'),
          content: Text(message.notification?.body ?? '내용 없음'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToDetailPage(message.data);
              },
              child: const Text("열기"),
            ),
          ],
        );
      },
    );
  }

  void _navigateToDetailPage(Map<String, dynamic> data) {
    final type = data['type']; // 알림 유형
    final personName = data['personName'] ?? 'Unknown'; // 사용자 이름 기본값

    if (type == 'low_heart_rate') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LowHeartRateScreen(personName: personName),
        ),
      );
    } else if (type == 'missed_medicine') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MissedMedicineScreen(personName: personName),
        ),
      );
    } else if (type == 'outdoor_alert') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OutdoorAlertScreen(personName: personName),
        ),
      );
    } else {
      /*Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(personName: personName),
        ),
      );*/
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 30, height: 30), // 로고 이미지
            const SizedBox(width: 10),
            const Text(
              "Smart Health Monitoring",
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, ${widget.name}!",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "User Type: ${widget.elderly ? 'Elderly' : 'Caregiver'}",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              Text(
                "Access Token: ${widget.token}",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text(
                "Elderly List:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...elderlyList.map((elder) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          personName: elder['name'],
                          elderlyID: elder['ID'].toString(),
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/unknown_profile.png', // 기본 이미지
                          width: 100,
                          height: 100,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          elder['name'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            // 전화 앱 열기
            launchDialer();
          } else if (index == 1) {
            // 현재 페이지 (HomeScreen)
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserScreen(
                  name: widget.name,
                  elderly: widget.elderly,
                  token: widget.token,
                ),
              ),
            );
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.phone),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
      ),
    );
  }

  void launchDialer() async {
    final Uri telUri = Uri(scheme: 'tel'); // 전화 앱 URI
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else {
      throw 'Could not launch $telUri';
    }
  }
}
