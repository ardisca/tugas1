import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart';
import 'history_attendance_page.dart';
import 'package:geocoding/geocoding.dart' as geo_location;

import 'image_view_page.dart';
import 'master_office_page.dart';

class HomePage extends HookWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = useState(false);
    final isStatusLoading = useState('');
    final attendanceCount = useState<int>(0);
    final officeData = useState<Map>({});

    useEffect(() {
      Future<void> fetchAttendanceCount() async {
        isLoading.value = true;
        try {
          DateTime now = DateTime.now();
          DateTime startOfDay = DateTime(now.year, now.month, now.day);
          DateTime endOfDay = DateTime(now.year, now.month, now.day + 1);
          QuerySnapshot querySnapshot = await FirebaseFirestore.instance
              .collection('attendance')
              .where('time', isGreaterThanOrEqualTo: startOfDay)
              .where('time', isLessThan: endOfDay)
              .get();

          attendanceCount.value = querySnapshot.docs.length;
        } catch (e) {
          debugPrint('$e');
        } finally {
          isLoading.value = false;
        }
      }

      fetchAttendanceCount();
      return null;
    }, []);

    return Scaffold(
      body: SafeArea(
          child: Stack(
        children: [
          _renderBody(
              context, isLoading, attendanceCount, officeData, isStatusLoading),
          if (isLoading.value)
            Container(
              padding: const EdgeInsets.all(150),
              color: Colors.grey.withOpacity(.5),
              child: Center(
                  child: Column(
                // crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text(isStatusLoading.value)
                ],
              )),
            )
        ],
      )),
    );
  }

  Widget _renderBody(
    BuildContext context,
    ValueNotifier<bool> isLoading,
    ValueNotifier<int> attendanceCount,
    ValueNotifier<Map> officeData,
    ValueNotifier<String> isStatusLoading,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: [
        _renderCountAttendance(attendanceCount.value),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${officeData.value['name'] ?? 'Kantor'}'),
            InkWell(
              onTap: () async {
                var result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MasterOfficePage(),
                    ));
                officeData.value = result;
              },
              child: Container(
                decoration: const BoxDecoration(color: Colors.blue),
                padding: const EdgeInsets.all(8),
                child: const Text(
                  'Pilih Kantor',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
        const SizedBox(height: 16),
        const Text('Menu',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
        const SizedBox(height: 16),
        _renderMenu(isLoading, officeData, isStatusLoading)
      ],
    );
  }

  Widget _renderCountAttendance(int count) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 75,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              )
            ], color: Colors.blue, borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Attendance Today',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w400),
                ),
                Text(
                  '$count attendance',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Radius bumi dalam meter

    // Konversi derajat ke radian
    double lat1Rad = _toRadians(lat1);
    double lon1Rad = _toRadians(lon1);
    double lat2Rad = _toRadians(lat2);
    double lon2Rad = _toRadians(lon2);

    // Selisih latitude dan longitude
    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;

    // Rumus Haversine
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    // Jarak dalam meter
    return earthRadius * c;
  }

  /// Mengonversi derajat ke radian
  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  Widget _renderMenu(
    ValueNotifier<bool> isLoading,
    ValueNotifier<Map> officeData,
    ValueNotifier<String> isStatusLoading,
  ) {
    List menu = [
      {'title': 'Attendance', 'icon': Icons.access_time, 'page': ''},
      {
        'title': 'History Attendance',
        'icon': Icons.playlist_add_check_outlined,
        'page': const HistoryAttendancePage()
      },
    ];

    return SizedBox(
      height: 100,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        padding: const EdgeInsets.all(10),
        itemCount: menu.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () async {
              if (index == 0) {
                if (officeData.value.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pilih Kantor Dulu',
                          style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                isLoading.value = true;

                var result = await _getImageAndLocation(isStatusLoading);
                isLoading.value = false;
                isStatusLoading.value = 'calculate Distance';

                var resultCalculate = calculateDistance(
                    result['position']['lat'],
                    result['position']['long'],
                    double.parse(officeData.value['location']['lat']),
                    double.parse(officeData.value['location']['long']));
                if (resultCalculate > 50) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Column(
                        children: [
                          const Text('Jarak Terlalu Jauh',
                              style: TextStyle(color: Colors.white)),
                          Text('${resultCalculate.toStringAsFixed(2)} M'),
                          Text(
                              'Lokasi Anda ${result['position']['lat']} ${result['position']['long']}'),
                          Text(
                              'Lokasi Kantor ${double.parse(officeData.value['location']['lat'])} ${double.parse(officeData.value['location']['long'])}')
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  isStatusLoading.value = '';

                  isLoading.value = false;

                  return;
                }

                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewPage(
                        imageFile: result['image'],
                        location: result['position'],
                      ),
                    ));
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => menu[index]['page'],
                    ));
              }
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.amber,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]),
                  child:
                      Icon(menu[index]['icon'], color: Colors.white, size: 34),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    menu[index]['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future _getImageAndLocation(ValueNotifier<String> isStatusLoading) async {
    await _requestPermissions();
    isStatusLoading.value = 'requestPermissions';
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    isStatusLoading.value = 'Prossess image';

    if (image != null) {
      Location location = Location();
      isStatusLoading.value = 'get Location';
      LocationData locationData = await location.getLocation();
      List<geo_location.Placemark> placemarks =
          await geo_location.placemarkFromCoordinates(
              locationData.latitude ?? 0.0, locationData.longitude ?? 0.0);
      Map tempData = {
        'position': {
          'lat': locationData.latitude,
          'long': locationData.longitude,
          'address':
              '${placemarks[0].street} ${placemarks[0].subLocality},${placemarks[0].subAdministrativeArea}, ${placemarks[0].postalCode}'
        },
        'image': File(image.path),
      };

      return tempData;
    }
    return;
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }

    var cameraStatus = await Permission.camera.status;

    if (!cameraStatus.isGranted) {
      await Permission.camera.request();
    }

    var storageStatus = await Permission.storage.status;

    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }
  }
}
