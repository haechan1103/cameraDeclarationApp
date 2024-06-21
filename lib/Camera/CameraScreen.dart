import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

import 'package:cameraapp/alerterror.dart';

class CameraScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onCapture;

  const CameraScreen({required this.onCapture, Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraAvailable = false;
  double _gyroX = 0, _gyroY = 0, _gyroZ = 0;
  double _accelX = 0, _accelY = 0, _accelZ = 0;
  double _pitch = 0, _roll = 0, _yaw = 0;
  double _latitude = 0, _longitude = 0, _altitude = 0;
  double _x = 0, _y = 0, _z = 0;

  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  StreamSubscription<Position>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _initializeCamera();
      _initializeLocation();
    } else {
      setState(() {
        _isCameraAvailable = false;
      });
    }

    _accelSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (!mounted) return;
      setState(() {
        _accelX = event.x;
        _accelY = event.y;
        _accelZ = event.z;
        _calculateOrientation();
      });
    });

    _gyroSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (!mounted) return;
      setState(() {
        _gyroX = event.x;
        _gyroY = event.y;
        _gyroZ = event.z;
        _calculateOrientation();
      });
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras[0], ResolutionPreset.high);
        await _cameraController.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
            _isCameraAvailable = true;
          });
        }
      } else {
        OverlaySetting().showErrorAlert(context, '카메라를 찾을 수 없습니다.');
      }
    } catch (e) {
      OverlaySetting().showErrorAlert(context, '카메라 초기화 실패: $e');
      print('카메라 초기화 실패: $e');
    }
  }

  void _initializeLocation() {
    _positionSubscription = Geolocator.getPositionStream().listen((Position position) {
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _altitude = position.altitude;
        _convertToXYZ(_latitude, _longitude, _altitude);
      });
    });
  }

  void _convertToXYZ(double lat, double lon, double alt) {
    const double a = 6378137.0; // Earth's semi-major axis in meters
    const double f = 1 / 298.257223563; // Earth's flattening
    const double e2 = 2 * f - f * f; // Square of eccentricity

    double latRad = lat * math.pi / 180.0;
    double lonRad = lon * math.pi / 180.0;

    double N = a / math.sqrt(1 - e2 * math.sin(latRad) * math.sin(latRad));

    double x = (N + alt) * math.cos(latRad) * math.cos(lonRad);
    double y = (N + alt) * math.cos(latRad) * math.sin(lonRad);
    double z = ((1 - e2) * N + alt) * math.sin(latRad);

    setState(() {
      _x = x;
      _y = y;
      _z = z;
    });
  }

 

  void _calculateOrientation() {
    double pitch = math.atan2(_accelY, math.sqrt(_accelX * _accelX + _accelZ * _accelZ)) * 180 / math.pi;
    double roll = math.atan2(-_accelX, _accelZ) * 180 / math.pi;
    _yaw += _gyroZ * 0.1;

    if (mounted) {
      setState(() {
        _pitch = pitch;
        _roll = roll;
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      if (_isCameraInitialized) {
        final XFile file = await _cameraController.takePicture();
        Map<String, dynamic> data = {
          'photo': file.path,
          'gyroX': _gyroX,
          'gyroY': _gyroY,
          'gyroZ': _gyroZ,
          'accelX': _accelX,
          'accelY': _accelY,
          'accelZ': _accelZ,
          'pitch': _pitch,
          'roll': _roll,
          'yaw': _yaw,
          'latitude': _latitude,
          'longitude': _longitude,
          'altitude': _altitude,
          'x': _x,
          'y': _y,
          'z': _z,
        };
        widget.onCapture(data);
        Navigator.pop(context);
      }
    } catch (e) {
      OverlaySetting().showErrorAlert(context, '사진 촬영에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraAvailable) {
      return Scaffold(
        body: Center(
          child: Text('카메라가 이 플랫폼에서 지원되지 않습니다.'),
        ),
      );
    }

    return Scaffold(
      body: _isCameraInitialized
          ? Stack(
              children: [
                Positioned.fill(
                  child: CameraPreview(_cameraController),
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 10,
                  bottom: MediaQuery.of(context).size.height / 2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    height: 100,
                    color: Color.fromARGB(255, 105, 104, 104).withOpacity(0.5),
                    child: Center(
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: FloatingActionButton(
                          onPressed: _takePicture,
                          child: const Icon(Icons.camera),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Pitch: $_pitch, Roll: $_roll, Yaw: $_yaw, X: $_x, Y: $_y, Z: $_z'),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
