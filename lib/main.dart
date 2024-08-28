//DEBUG : 現状の再確認と今後の方針
// [ ]  : wav変換部分の実装 - ffmpeg関連の設定を確認する
// [ ]  : 録音部分のプログラムを整理
// [ ]  : アプリのデザインを調整
// [ ]  : レーダーチャートのデザインを調整（legend等）

//TODO : ffmpegの調整
//TODO : グラフ更新部分の作成

import 'dart:async';
import 'dart:convert';
// import 'package:path/path.dart' as p;
// import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:record/record.dart';
// import 'package:radar_chart/radar_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:multi_charts/multi_charts.dart';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_audio/return_code.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satori',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF203549),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFdcc7b3)),
          bodyMedium: TextStyle(color: Color(0xFFdcc7b3)),
        ),
      ),
      home: const Satori(title: 'Satori'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Satori extends StatefulWidget {
  const Satori({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _SatoriState createState() => _SatoriState();
}

class _SatoriState extends State<Satori> {
  final _record = AudioRecorder();
  final logger = Logger();
  bool _isRecording = false;
  // bool _cancel = false;
  bool _flag = false;
  String? _pathToWrite;
  Timer? _timer;

  // API response holder
  List<double> chartValues = [0.0, 0.0, 0.0, 0.0, 0.0];
  Map<String, dynamic> apiResponse = {
    "calm": 30,
    "anger": 30,
    "joy": 30,
    "sorrow": 30,
    "energy": 30,
  };

  // 録音ファイルをWAVに変換
  // Future<String> _convertToWav(String filePath) async {
  //   logger.i("Converting to WAV...");
  //   final tempDir = await getApplicationDocumentsDirectory();
  //   String outputPath = '$tempDir/converted.wav';

  //   // var flutterSoundHelper = FlutterSoundHelper();
  //   // await flutterSoundHelper.convertFile(
  //   //   filePath,
  //   //   Codec.aacADTS,
  //   //   newPath,
  //   //   Codec.pcm16WAV,
  //   // );

  //   // FlutterSoundHelper flutterSoundHelper = FlutterSoundHelper();

  //   // final ffmpegCommand =
  //   //     '-i $filePath -codec:a libmp3lame -qscale:a 2 $outputPath';
  //   final ffmpegCommand =
  //       '-i $filePath -codec:a pcm_s16le -ac 1 -ar 44100 $outputPath';

  //   // await FFmpegKit.execute(ffmpegCommand);

  //   return outputPath;
  // }

  // APIリクエストを送信し、レスポンスを取得
  Future<Map<String, dynamic>> _getAPI(String filePath) async {
    const url = 'https://api.webempath.net/v2/analyzeWav';
    const apikey = "NThas5RjM1hPAM4Qs1SPN5ekCrSShqVaoa_XK9Yo28o";

    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields['apikey'] = apikey;
    request.files.add(await http.MultipartFile.fromPath('wav', filePath));

    var response = await request.send();
    if (response.statusCode == 200) {
      logger.i("Get Response...");
      var result = await http.Response.fromStream(response);
      return jsonDecode(result.body);
    } else {
      logger.w("Failed to get response");
      throw Exception('Failed to load data');
    }
  }

  // レーダーチャートを更新
  void _updateRadarChart(Map<String, dynamic> apiResponse) {
    setState(() {
      chartValues = [
        apiResponse['calm'].toDouble() + 10,
        apiResponse['anger'].toDouble() + 10,
        apiResponse['joy'].toDouble() + 10,
        apiResponse['sorrow'].toDouble() + 10,
        apiResponse['energy'].toDouble() + 10,
      ];
    });
    logger.i("Update Radar Chart... : $chartValues");
  }

  // レコーディングの開始
  Future<void> _startRecording() async {
    logger.i("_startRecording : recording...");
    if (await _record.hasPermission()) {
      // ExternalPath.getExternalStoragePublicDirectory(
      //     ExternalPath.DIRECTORY_DOWNLOADS);
      final directory = await getApplicationDocumentsDirectory();
      String _tmppath = directory.path;
      _pathToWrite = '$_tmppath/kari.wav';
      // _pathToWrite = p.join(directory.path, 'kari.wav');
      logger.i("_startRecording : get directory : $_pathToWrite");
      // await _record.start(
      //   path: _pathToWrite,
      //   // encoder: AudioEncoder.aacLc,
      //   encoder: AudioEncoder.pcm16bit,
      //   bitRate: 1411000, //あとで1411000も試す
      //   samplingRate: 11025,
      // );

      await _record.start(const RecordConfig(), path: _pathToWrite!);
      // await _record.start(
      //   path: _pathToWrite,
      //   encoder: AudioEncoder.aacLc,
      //   bitRate: 256000,
      //   samplingRate: 11025,
      // );
      // setState(() {
      //   _isRecording = true;
      // });
    } else {
      logger.e("Recording permission denied");
    }
  }

  // レコーディングの終了
  Future<void> _stopRecording() async {
    if (_isRecording && _pathToWrite != null) {
      logger.w(" _stopRecording : Stop recording, path: $_pathToWrite");
      await _record.stop();

      //録音されたファイルのコーデックを確認
      //final info = await FFmpegKitConfig.getMediaInformation(_pathToWrite!);
      File checkfile = File(_pathToWrite!);
      List<int> bytes = checkfile.readAsBytesSync();

      //最初の4バイトがRIFFであることを確認
      logger.i("RIFF : ${bytes[0]} ${bytes[1]} ${bytes[2]} ${bytes[3]}");
      int codec = bytes[20] | (bytes[21] << 8);
      logger.i("Codec : $codec"); // Codec : 1 なら PCM 16-bit

      // WAVに変換し、APIリクエストを送信
      // String newPath = await _convertToWav(_pathToWrite!);
      // logger.i(" _stopRecording : getwavefile : $_pathToWrite");
      Map<String, dynamic> response = await _getAPI(_pathToWrite!);
      logger.i(" _stopRecording : getAPIres : $response");

      setState(() {
        apiResponse = response;
        // _isRecording = false;
        _updateRadarChart(response);
      });

      logger.i(apiResponse);
    } else {
      logger.w(" _stopRecording : path : $_pathToWrite");
      logger.w(" _stopRecording : _isRecording : $_isRecording");
    }
  }

  // 録音のオン/オフを切り替え
  void _recordSwitch() async {
    logger.i("Record switch : $_isRecording");
    if (_isRecording) {
      logger.i("switch : Stop recording!");
      await _stopRecording();
    } else {
      logger.i("switch : Start recording!");
      await _startRecording();
    }
    _isRecording = !_isRecording;
  }

  // タイマーを使って録音のスイッチを管理
  void _recTimer() {
    // logger.i("_starttimer : Start Timer...");
    setState(() {
      logger.i("_recTimer : 3 sec recording...");
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _recordSwitch();
      });
      // logger.i("Stop Timer!");
      // _stopTimer();
      // stoptimer内ですでに録音停止
      // _stopRecording();
    });
  }

  // タイマーの停止
  void _stopTimer() {
    _timer?.cancel();
    if (_isRecording) {
      _stopRecording();
    }
    setState(() {
      _isRecording = false;
    });
    logger.i("Timer stopped and recording stopped");
  }

  // 最大10分動かす
  void _run() async {
    // _flag = !_flag;

    //一旦お試しテスト
    // logger.w("try load D:\\User\\zigza\\Documents\\kari.wav");
    // File checkfile = File('D:\\User\\zigza\\Documents\\kari.wav');
    // List<int> bytes = checkfile.readAsBytesSync();
    // int Codec = bytes[20] | (bytes[21] << 8);

    //普通のテキストファイルが保存できるかテスト
    var tmpdir = await getApplicationDocumentsDirectory();
    logger.w("try write $tmpdir/test.txt");
    String text = "This is a test file.";
    File file = File('${tmpdir.path}/test.txt');
    file.writeAsStringSync(text);
    //書き込み完了
    logger.w("write completed");

    //test.txtの読み込みができるかテスト
    logger.w("try read $tmpdir/test.txt");
    try {
      String contents = file.readAsStringSync();
      logger.w("read completed : $contents");
    } catch (e) {
      logger.e("read failed : $e");
    }

    logger.w("Codec : $Codec");
    if (_flag) {
      logger.i("_run : Start running...");
      // 10分間タイマーを動かす
      _recTimer();
      await Future.delayed(const Duration(minutes: 10));
      // 10分後にタイマーを停止
      _stopTimer();
      logger.w("_run : Completed 10 minutes");
    } else {
      logger.w("_run : Cancel running!");
      _stopTimer();
    }
  }

  //----------------------------------------------------------------
  // 描画
  //----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final labels = ["リラックス", "怒り", "楽しみ", "悲しみ", "元気"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFFdcc7b3),
          ),
        ),
        backgroundColor: const Color(0xFF203549),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: Text(
                "今のあなたの感情は...",
                style: TextStyle(
                  fontSize: 35.0, // フォントサイズを35に変更
                  fontWeight: FontWeight.w600,
                  fontFamily: "RondeB",
                ),
              ),
            ),
            Expanded(
              child: RadarChart(
                values: chartValues,
                labels: labels,
                maxValue: 60,
                fillColor: Colors.red,
                strokeColor: Colors.red,
                labelColor: const Color.fromARGB(255, 220, 220, 220),
                curve: Curves.linear,
                animationDuration: const Duration(milliseconds: 500),
                chartRadiusFactor: 0.9, // チャートサイズを大きくするために0.9に変更
                textScaleFactor: 0.03,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _flag = !_flag;
          });
          _run();
        },
        child: Icon(_flag ? Icons.stop : Icons.mic),
      ),
    );
  }
}
