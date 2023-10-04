import 'package:cameraapp/Report/reportpage.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<String> disasters = [
    '화재',
    '건물붕괴',
    '풍수해',
    '인명사고',
    '지진',
    '산사태',
    '화학사고',
    '기타'
  ];

  static const List<String> majorDisasters = ['홍수', '지진', '산사태', '화학사고'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            titlePadding: EdgeInsets.zero,
            title: Container(
              height: 80,
              decoration: const BoxDecoration(color: Colors.blue),
              alignment: Alignment.center,
              child: const Text(
                '주요 재난',
                style: TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                ),
              ),
            ),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              for (int i = 0; i < majorDisasters.length; i++)
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  ReportPage(reportTopic: majorDisasters[i])));
                    },
                    style: const ButtonStyle(
                        overlayColor:
                            MaterialStatePropertyAll(Colors.transparent),
                        padding: MaterialStatePropertyAll(
                            EdgeInsets.symmetric(vertical: 10))),
                    child: Container(
                      width: 300,
                      height: 60,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        majorDisasters[i],
                        style:
                            const TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ))
            ]),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < disasters.length / 2; i++) {}
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          Column(children: [
            SizedBox(
              width: screenWidth,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.03),
              child: Container(
                width: screenWidth * 0.9,
                height: screenWidth * 0.2,
                decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(5)),
                alignment: Alignment.center,
                child: Text(
                  '신고 재난 선택',
                  style: TextStyle(fontSize: screenWidth * 0.07),
                ),
              ),
            ),
            SizedBox(
              width: screenWidth * 0.9,
              height: screenHeight * 0.75,
              child: SingleChildScrollView(
                child: Column(children: [
                  for (int i = 0; i < disasters.length / 2; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: screenWidth * 0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          disasterButton(disasters[2 * i], screenWidth),
                          disasterButton(disasters[2 * i + 1], screenWidth)
                        ],
                      ),
                    )
                ]),
              ),
            )
          ])
        ],
      )),
    );
  }

  TextButton disasterButton(String disaster, double screenWidth) {
    return TextButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ReportPage(reportTopic: disaster)));
        },
        style: const ButtonStyle(
            overlayColor: MaterialStatePropertyAll(Colors.transparent),
            padding: MaterialStatePropertyAll(EdgeInsets.zero)),
        child: Container(
          width: screenWidth * 0.43,
          height: screenWidth * 0.35,
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(5)),
          alignment: Alignment.center,
          child: Text(
            disaster,
            style: TextStyle(fontSize: screenWidth * 0.07, color: Colors.black),
          ),
        ));
  }
}
