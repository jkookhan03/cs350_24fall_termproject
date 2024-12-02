import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HeartGraph extends StatefulWidget {
  final String personName;
  final String elderlyID;
  final String token;

  const HeartGraph({
    Key? key,
    required this.personName,
    required this.elderlyID,
    required this.token,
  }) : super(key: key);

  @override
  _HeartGraphState createState() => _HeartGraphState();
}

class _HeartGraphState extends State<HeartGraph> {
  List<FlSpot> heartRateData = []; // 그래프 데이터
  bool isLoading = true; // 로딩 상태 확인

  @override
  void initState() {
    super.initState();
    fetchHeartRateData();
  }

  Future<void> fetchHeartRateData() async {
    final Uri url = Uri.parse('http://121.152.208.156:3000/caregiver/sensorData');

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.token}",
        },
        body: jsonEncode({
          "elderlyID": int.parse(widget.elderlyID), // String -> int 변환
          "type": "heartRate",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> times = data['time'] ?? [];
        final List<dynamic> values = data['heartRate'] ?? [];
        List<FlSpot> spots = [];

        for (int i = 0; i < times.length; i++) {
          // x축은 시간차 (분), y축은 심박수
          final DateTime time = DateTime.parse(times[i]);
          final double xValue = time.difference(DateTime.now()).inMinutes.toDouble();
          final double yValue = values[i].toDouble();
          spots.add(FlSpot(xValue, yValue));
        }

        setState(() {
          heartRateData = spots;
          isLoading = false;
        });
      } else {
        print("Failed to fetch heart rate data: ${response.body}");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching heart rate data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Heart Rate (BPM)',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : heartRateData.isEmpty
          ? Center(
        child: Text(
          "No heart rate data available.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "${widget.personName} - Heart Rate",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 300,
              width: 350,
              child: LineChart(
                LineChartData(
                  maxY: heartRateData.isEmpty ? 100 : null,
                  minY: heartRateData.isEmpty ? 60 : null,
                  lineBarsData: [
                    LineChartBarData(
                      spots: heartRateData.isEmpty
                          ? [FlSpot(0, 0)] // const 제거
                          : heartRateData,
                      isCurved: true,
                      colors: [Colors.red],
                      barWidth: 4,
                      belowBarData: BarAreaData(show: false),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      margin: 10,
                      getTextStyles: (value) => const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      getTitles: (value) {
                        if (value % 10 == 0) {
                          return '${value.toInt()}m';
                        }
                        return '';
                      },
                    ),
                    leftTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      margin: 10,
                      getTextStyles: (value) => const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      getTitles: (value) {
                        if (value % 10 == 0) {
                          return '${value.toInt()} BPM';
                        }
                        return '';
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.black, width: 1),
                      bottom: BorderSide(color: Colors.black, width: 1),
                    ),
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
