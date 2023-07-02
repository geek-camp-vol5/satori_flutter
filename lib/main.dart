import 'dart:async';
import 'dart:convert';

import 'package:external_path/external_path.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
// import 'package:audioplayers/audioplayers.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
// import 'package:ffmpeg_kit_flutter/return_code.dart';

import 'package:logger/logger.dart';
import 'package:record/record.dart';

void main() {
  runApp(const Recorder());
}

// var logger = Logger(
//   printer: PrettyPrinter(
//     errorMethodCount: 2, // number of method calls to be displayed
//     colors: true, // Colorful log messages
//     printEmojis: true, // Print an emoji for each log message
//   ),
// );

class Recorder extends StatelessWidget {
  const Recorder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satori_',
      theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFF203549),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFFdcc7b3)),
            bodyMedium:
                TextStyle(color: Color(0xFFdcc7b3)), // この色がアプリ全体の背景色になります
          )),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Satori'),
          backgroundColor: const Color(0xFF203549),
        ),
        body: const Center(
          child: WindowBody(),
        ),
      ),
    );
  }
}

class WindowBody extends StatefulWidget {
  const WindowBody({super.key});

  @override
  _WindowBodyState createState() => _WindowBodyState();
}

class _WindowBodyState extends State<WindowBody> {
  bool _status = false;
  bool _flag = false;
  final record = Record();
  String? pathToWrite;
  final logger = Logger();

  // API response holder
  Map<String, dynamic> apiResponse = {
    "calm": 30,
    "anger": 30,
    "joy": 30,
    "sorrow": 30,
    "energy": 30,
  };

  Future<Map<String, dynamic>> _getAPI(String filePath) async {
    const url = 'https://api.webempath.net/v2/analyzeWav';
    const apikey = "-Z7Pukop4oayllGf5lovrOsVg7fUTwLdJuaWaWFTkNM";
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll({
      'apikey': apikey,
    });
    request.files.add(await http.MultipartFile.fromPath('wav', filePath));
    var response = await request.send();
    if (response.statusCode == 200) {
      logger.i("Get Responce...");
      var result = await http.Response.fromStream(response);
      return jsonDecode(result.body);
    } else {
      logger.w("Failed");
      throw Exception('Failed to load data');
    }
  }

  Future<void> _convertToWav() async {
    var tempDir = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    String newPath = '$tempDir/converted.wav';

    var flutterSoundHelper = FlutterSoundHelper();

    await flutterSoundHelper.convertFile(
      pathToWrite,
      Codec.aacADTS,
      newPath,
      Codec.pcm16WAV,
    );

    // Do what you want with the newPath here
    //logger.i("Converted file path: $newPath");
  }

  void _startRecording() async {
    // 録音を開始する
    logger.i("Start recording $_flag");
    await record.hasPermission();
    //final directory = await getApplicationDocumentsDirectory();
    final directory = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    pathToWrite = '$directory/kari.m4a';
    await record.start(
      path: pathToWrite,
      encoder: AudioEncoder.aacLc,
      bitRate: 256000,
      samplingRate: 11025,
    );
  }

  void _stopRecording() async {
    // 録音を停止する
    var tempDir = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS);
    String newPath = '$tempDir/converted.wav';
    logger.w("Stop recording PATH:$pathToWrite");
    await record.stop();
    await _convertToWav();
    var response = await _getAPI(newPath);
    setState(() {
      apiResponse = response;
    });
    logger.i(apiResponse); // or do whatever you want with the response
  }

  // void _startPlaying() async {
  //   // 再生する
  //   final logger = Logger();
  //   AudioPlayer audioPlayer = AudioPlayer();
  //   final directory = await getApplicationDocumentsDirectory();
  //   String pathToWrite = '${directory.path}/kari.wav';
  //   logger.i('Start Play!!');
  //   await audioPlayer.play(DeviceFileSource(pathToWrite));
  //   logger.i('Finish Play!!');
  // }

  void _recordSwitch() async {
    _status = !_status;
    if (_status) {
      _startRecording();
    } else {
      _stopRecording();
      //_startPlaying();
    }
    setState(() {});
  }

  Timer? _timer;
  void _startTimer() async {
    final logger = Logger();
    setState(() {
      _flag = !_flag;
      if (_flag) {
        _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
          _recordSwitch();
        });
      } else {
        logger.e("Canceled Timer!! flag:$_flag");
        _stopTimer();
        _stopRecording();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Text((_flag ? "今の私の感情は..." : " "),
                style: const TextStyle(
                  fontSize: 40.0,
                  fontWeight: FontWeight.w600,
                  fontFamily: "RondeB",
                )),
            Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 10.0), // 上下に10.0のパディングを追加
              child: TextButton(
                  onPressed: _startTimer,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    backgroundColor: Colors.grey,
                    shadowColor: Colors.teal,
                    elevation: 5,
                  ),
                  child: Text((_flag ? "停止" : "開始"),
                      style: const TextStyle(
                          color: Colors.black, fontSize: 40.0))),
            ),
            Padding(
                padding: const EdgeInsets.all(20.0),
                child: AspectRatio(
                    aspectRatio: 1.3,
                    child: Stack(alignment: Alignment.center, children: [
                      Container(
                        width: 200,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFdcc7b3),
                            width: 2,
                          ),
                        ),
                      ),
                      RadarChart(
                        RadarChartData(
                          dataSets: [
                            RadarDataSet(
                              // dataEntriesはRadarEntryのリストで、それぞれがチャート上の点を表します。
                              // RadarEntryのvalueプロパティは、チャートの中心からの距離を決定します。
                              dataEntries: [
                                RadarEntry(
                                    value: apiResponse["calm"].toDouble()),
                                RadarEntry(
                                    value: apiResponse["anger"].toDouble()),
                                RadarEntry(
                                    value: apiResponse["joy"].toDouble()),
                                RadarEntry(
                                    value: apiResponse["sorrow"].toDouble()),
                                RadarEntry(
                                    value: apiResponse["energy"].toDouble()),
                              ],

                              fillColor: const Color.fromARGB(255, 226, 241, 14)
                                  .withOpacity(0.2), // set the fill color
                              borderColor: const Color.fromARGB(
                                  255, 226, 241, 14), // set the border color
                              borderWidth: 2.0, // set the border width
                            ),
                          ],
                          radarBackgroundColor:
                              const Color.fromARGB(0, 240, 62, 62),
                          borderData: FlBorderData(show: false),
                          radarBorderData: const BorderSide(
                              color: Color.fromARGB(0, 250, 17, 17)),
                          titlePositionPercentageOffset: 0.2,
                          titleTextStyle: const TextStyle(fontSize: 16),
                          getTitle: (index) {
                            switch (index) {
                              case 0:
                                return "リラックス";
                              case 1:
                                return "怒り";
                              case 2:
                                return "楽しみ";
                              case 3:
                                return "悲しみ";
                              case 4:
                                return "元気";
                              default:
                                return "";
                            }
                          },
                          tickCount: 1,
                          ticksTextStyle: const TextStyle(
                              color: Colors.transparent, fontSize: 10),
                          tickBorderData:
                              const BorderSide(color: Colors.transparent),
                          gridBorderData: const BorderSide(
                              color: Color(0xFFdcc7b3), width: 2),
                        ),
                        swapAnimationDuration:
                            const Duration(milliseconds: 200),
                        swapAnimationCurve: Curves.linear,
                      )
                    ])))
          ],
        ));
  }
}
