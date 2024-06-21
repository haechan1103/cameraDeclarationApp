import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cameraapp/alerterror.dart';
import 'package:cameraapp/Camera/CameraScreen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart' show rootBundle;

import 'package:path_provider/path_provider.dart'; // 추가

class ReportPage extends StatefulWidget {
  final String reportTopic;
  const ReportPage({required this.reportTopic, super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  TextEditingController contentController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  double? gyroX, gyroY, gyroZ;
  double? accelX, accelY, accelZ;
  double? pitch, roll, yaw;
  double? latitude, longitude, altitude;
  double? x, y, z;

  String? photo;
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _requestLocationPermission();
    // _loadDefaultPhoto();
  }

  // Future<void> _loadDefaultPhoto() async {
  //   x=0; y=0;z=0;
  //   pitch = 0; roll = 0; yaw = 0;
  //   accelX = 0; accelY =0; accelZ = 0;
  //   final byteData = await rootBundle.load('assets/images/default_photo.jpg');
  //   final file = File('${(await getTemporaryDirectory()).path}/default_photo.jpg');
  //   await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  //   setState(() {
  //     photo = file.path;
  //   });
  // }

  Future<void> _requestLocationPermission() async {
    await [
      Permission.camera,
      Permission.location,
    ].request();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.high);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    contentController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> applyReport() async {
    if (photo == null) {
      OverlaySetting().showErrorAlert(context, '사진/영상을 촬영해주세요');
    } else if (contentController.text == '') {
      OverlaySetting().showErrorAlert(context, '내용을 입력해주세요');
    } else if (phoneController.text == '') {
      OverlaySetting().showErrorAlert(context, '휴대전화를 입력해주세요');
    } else {
      Navigator.pop(context);
      OverlaySetting().showErrorAlert(context, '신청됐습니다!');
      await _uploadDataToServer();
    }
  }

  Future<void> _uploadDataToServer() async {
    try {
      final fileName = '내용:' + contentController.text + ' 휴대전화번호:' + phoneController.text + ' 신고종목:' + widget.reportTopic+'.jpg';
      final urlResponse = await http.get(Uri.parse('http://54.180.108.115/api/generate-presigned-url?fileName=$fileName'));
      final presignedUrl = json.decode(urlResponse.body)['url'];

      final imageFile = File(photo!);
      final uploadResponse = await http.put(Uri.parse(presignedUrl),
          headers: {
            'Content-Type': 'multipart/form-data',
          },
          body: imageFile.readAsBytesSync());

      if (uploadResponse.statusCode == 200) {
       DateTime dt = DateTime.now();
        print('Image uploaded successfully');
        final content_text = '신고종목:'
        +widget.reportTopic +' 시간:' +dt.toString() + ' 내용:' + contentController.text;
        const photoUrl = '준비중입니다.';
        const serverUrl = 'http://54.180.108.115/api/upload';
        final response = await http.post(
          Uri.parse(serverUrl),
          body: {
            'x': x.toString(),
            'y': y.toString(),
            'z': z.toString(),
            'yaw': yaw.toString(),
            'pitch': pitch.toString(),
            'roll': roll.toString(),
            'ax': accelX.toString(),
            'ay': accelY.toString(),
            'az': accelZ.toString(),
            'content': content_text,
            'phone_number': phoneController.text,
            'photo_url': photoUrl,
          },
        );
// 내껀 볼게 없어.
        if (response.statusCode == 200) {
          print('Data sent successfully');
        } else {
          print('Failed to send data: ${response.body}');
        }
      } else {
        print('Failed to upload image: ${uploadResponse.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void clickPhotoOk() {
    if (_isCameraInitialized && _cameras.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(
            onCapture: (data) {
              setState(() {
                photo = data['photo'];
                gyroX = data['gyroX'];
                gyroY = data['gyroY'];
                gyroZ = data['gyroZ'];
                accelX = data['accelX'];
                accelY = data['accelY'];
                accelZ = data['accelZ'];
                pitch = data['pitch'];
                roll = data['roll'];
                yaw = data['yaw'];
                latitude = data['latitude'];
                longitude = data['longitude'];
                altitude = data['altitude'];
                x = data['x'];
                y = data['y'];
                z = data['z'];
              });
            },
          ),
        ),
      );
    } else {
      OverlaySetting().showErrorAlert(context, '카메라를 초기화하는 중입니다. 잠시만 기다려주세요.');
    }
  }

  void clickPhoto(double screenWidth) async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '촬영 시 모바일의 센서＊정보가\n 취득 됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: screenWidth * 0.043),
                  ),
                  Text(
                    '센서＊:GPS(위치정보),INS(자세정보)',
                    style: TextStyle(fontSize: screenWidth * 0.034),
                  ),
                ],
              ),
              actionsPadding: EdgeInsets.zero,
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                TextButton(
                    onPressed: () {
                      clickPhotoOk();
                    },
                    style: const ButtonStyle(
                        overlayColor:
                            MaterialStatePropertyAll(Colors.transparent),
                        padding: MaterialStatePropertyAll(
                            EdgeInsets.only(bottom: 20))),
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(5),
                          color: const Color.fromARGB(255, 206, 224, 251)),
                      padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.054,
                          vertical: screenWidth * 0.025),
                      child: Text(
                        '계속',
                        style: TextStyle(
                            color: Colors.black, fontSize: screenWidth * 0.06),
                      ),
                    ))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            title: Text('${widget.reportTopic} 신고'),
            actions: [
              TextButton(
                  onPressed: () async {
                    showDialog(
                        context: context,
                        builder: (context) => const Scaffold(
                              backgroundColor: Colors.black26,
                              body: Center(child: CircularProgressIndicator()),
                            ));
                    await applyReport();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: const ButtonStyle(
                      overlayColor: MaterialStatePropertyAll(Colors.black12),
                      padding: MaterialStatePropertyAll(EdgeInsets.zero)),
                  child: Text(
                    '신청',
                    style: TextStyle(
                        color: Colors.black, fontSize: screenWidth * 0.043),
                  ))
            ],
          ),
          body: SafeArea(
              child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: screenWidth,
                      height: 10,
                    ),
                  
                    informationPurpose(screenWidth),
                    SizedBox(
                      height: screenWidth * 0.05,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '  ⦁ 사진/영상, 센서정보',
                          style: TextStyle(fontSize: screenWidth * 0.05),
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: screenWidth * 0.03),
                          child: TextButton(
                              onPressed: () {
                                clickPhoto(screenWidth);
                              },
                              style: const ButtonStyle(
                                overlayColor:
                                    MaterialStatePropertyAll(Colors.black12),
                                padding:
                                    MaterialStatePropertyAll(EdgeInsets.zero),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(5)),
                                padding: EdgeInsets.symmetric(
                                    vertical: screenWidth * 0.03,
                                    horizontal: screenWidth * 0.08),
                                child: Text(
                                  '촬영',
                                  style: TextStyle(
                                      fontSize: screenWidth * 0.043,
                                      color: Colors.black),
                                ),
                              )),
                        )
                      ],
                    ),

  if (photo != null)
                      Column(
                        children: [
                          SizedBox(height: screenWidth * 0.05,),
                          Image.file(File(photo!)),
                          Text('GyroX: $gyroX, GyroY: $gyroY, GyroZ: $gyroZ'),
                          Text('AccelX: $accelX, AccelY: $accelY, AccelZ: $accelZ'),
                          Text('Pitch: $pitch, Roll: $roll, Yaw: $yaw'),
                          Text('Latitude: $latitude, Longitude: $longitude, Altitude: $altitude'),
                          Text('X: $x, Y: $y, Z: $z'),
                        ],
                      ),

                    SizedBox(
                      height: screenWidth * 0.05,
                    ),
                    Text(
                      '  ⦁ 내용',
                      style: TextStyle(fontSize: screenWidth * 0.05),
                    ),
                    SizedBox(
                      height: screenWidth * 0.05,
                    ),
                    TextFormField(
                      controller: contentController,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 300,
                      decoration: const InputDecoration(
                          hintText: '신고할 재난에 대한 상황 및 위험요인, 피해상황을 신고해주세요.',
                          border: OutlineInputBorder()),
                    ),
                    SizedBox(
                      height: screenWidth * 0.02,
                    ),
                    Text(
                      '  ⦁ 휴대전화',
                      style: TextStyle(fontSize: screenWidth * 0.05),
                    ),
                    SizedBox(
                      height: screenWidth * 0.05,
                    ),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                          hintText: '전화번호 입력 (010-XXXX-XXXX)',
                          hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                          border: const OutlineInputBorder()),
                    ),
                    SizedBox(height: screenWidth * 0.05,)
                  ]),
            ),
          )),
        ));
  }

  Container informationPurpose(double screenWidth) {
    return Container(
      width: screenWidth * 0.9,
      decoration: BoxDecoration(
          border: Border.all(), borderRadius: BorderRadius.circular(5)),
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '개인정보 수집 및 이용',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Text(
            '1. 개인정보 수집 목적 : 재난 상황 관리',
          ),
          const Text(
            '2. 개인정보 수집 항목 : 위치정보, 모바일 센서 정보',
          ),
          const Text('3. 보유 및 이용기간'),
          const Text('보유기간 : 00'),
          const Text('이용기간 : 00'),
          SizedBox(
              width: screenWidth * 0.84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('* '),
                  SizedBox(
                    width: screenWidth * 0.8,
                    child: const Text(
                        '수집한 개인정보는 수집 및 이용 목적이 달성된 후에는 해당 정보를 지체 없이 파기합니다.'),
                  )
                ],
              ))
        ],
      ),
    );
  }
}
