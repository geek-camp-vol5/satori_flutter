import 'package:flutter/material.dart';
import 'package:radar_chart/radar_chart.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RadarChartExample(title: 'Flutter Demo Home Page'),
    );
  }
}

class RadarChartExample extends StatefulWidget {
  const RadarChartExample({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _RadarChartExampleState createState() => _RadarChartExampleState();
}

class _RadarChartExampleState extends State<RadarChartExample> {
  int _counter = 3;
  List<double> values1 = [0.4, 0.8, 0.65];
  List<double> values2 = [0.5, 0.3, 0.85];
  late List<PreferredSizeWidget> vertices2;
  late PreferredSizeWidget _vertex;

  @override
  void initState() {
    super.initState();
    const double radius = 5;
    _vertex = PreferredSize(
      preferredSize: const Size.square(2 * radius),
      child: CircleAvatar(
        backgroundColor: Colors.red,
        radius: radius,
      ),
    );

    vertices2 = [_vertex, _vertex, _vertex];
  }

  void _incrementCounter() {
    final random = Random.secure();
    setState(() {
      _counter++;
      values1.add(random.nextDouble());
      values2.add(random.nextDouble());
      vertices2.add(_vertex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.grey.shade200,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text(
                "There are ${values1.length} values for each radar chart!",
                style: const TextStyle(fontSize: 30),
              ),
            ),
            RadarChart(
              length: _counter,
              radius: 150,
              initialAngle: 0,
              backgroundColor: Colors.white,
              borderStroke: 2,
              borderColor: Colors.grey.shade300,
              radialStroke: 2,
              radialColor: Colors.grey.shade300,
              radars: [
                RadarTile(
                  values: values1,
                  borderStroke: 2,
                  borderColor: Colors.yellow,
                  backgroundColor: Colors.yellow.withOpacity(0.4),
                ),
                RadarTile(
                  values: values2,
                  borderStroke: 2,
                  borderColor: Colors.blue,
                  backgroundColor: Colors.blue.withOpacity(0.4),
                  vertices: vertices2,
                ),
              ],
            ),
            // RadarChart(
            //   length: 3,
            //   radius: 100,
            //   initialAngle: 0,
            //   backgroundColor: Colors.white,
            //   borderStroke: 2,
            //   borderColor: Colors.grey.shade300,
            //   radialStroke: 1,
            //   radialColor: Colors.grey.shade300,
            //   vertices: [
            //     for (int i = 0; i < 3; i++)
            //       RadarVertex(
            //         radius: 15,
            //         textOffset: Offset(0, 0),
            //         text: Text('$i'),
            //       ),
            //   ],
            //   radars: [
            //     RadarTile(
            //       radialColor: Colors.red,
            //       values: values1,
            //       borderStroke: 2,
            //       borderColor: Colors.yellow,
            //       backgroundColor: Colors.yellow.withOpacity(0.4),
            //     ),
            //     RadarTile(
            //       radialColor: Colors.red,
            //       values: values1,
            //       borderStroke: 2,
            //       borderColor: Colors.yellow,
            //       backgroundColor: Colors.yellow.withOpacity(0.4),
            //     ),
            //     RadarTile(
            //       radialColor: Colors.red,
            //       values: values1,
            //       borderStroke: 2,
            //       borderColor: Colors.yellow,
            //       backgroundColor: Colors.yellow.withOpacity(0.4),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

class RadarVertex extends StatelessWidget implements PreferredSizeWidget {
  const RadarVertex({
    required this.radius,
    this.text,
    this.textOffset,
  });

  final double radius;
  final Widget? text;
  final Offset? textOffset;

  @override
  Size get preferredSize => Size.fromRadius(radius);

  @override
  Widget build(BuildContext context) {
    Widget tree = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.green,
    );
    if (text != null) {
      tree = Stack(
        children: [
          tree,
          Center(
            child: text,
          )
        ],
      );
    }
    return tree;
  }
}
