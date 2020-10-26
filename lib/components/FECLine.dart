import 'package:dslstats/models/modemClients/LineStatsCollection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mp_chart/mp/chart/line_chart.dart';
import 'package:mp_chart/mp/controller/line_chart_controller.dart';
import 'package:mp_chart/mp/core/data/line_data.dart';
import 'package:mp_chart/mp/core/data_set/line_data_set.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/enums/mode.dart';
import 'package:mp_chart/mp/core/enums/x_axis_position.dart';

import 'MyLineMarker.dart';
import 'XDateFormatter.dart';

class FECLine extends StatefulWidget {
  List<LineStatsCollection> collection;
  Duration showPeriod;

  FECLine({this.collection, this.showPeriod});

  @override
  _SNRMState createState() => _SNRMState();
}

class _SNRMState extends State<FECLine> {
  LineChartController _controller;

  void initState() {
    _initController();
    _initLineData(widget.collection);
  }

  // Initialize controller
  void _initController() {
    _controller = LineChartController(
        axisLeftSettingFunction: (axisLeft, controller) {
          axisLeft
            ..drawGridLines = true
            ..gridColor = Colors.blueGrey[50]
            ..drawAxisLine = false
            ..setAxisMinValue(0)
            // ..setAxisMaxValue(22)
            ..spacePercentTop = 40
            ..drawGridLinesBehindData = true;
        },
        axisRightSettingFunction: (axisRight, controller) {
          axisRight
            ..enabled = true
            ..drawGridLines = false
            ..setAxisMinValue(0)
            // ..setAxisMaxValue(22)
            ..spacePercentTop = 40
            ..drawAxisLine = false;
        },
        legendSettingFunction: (legend, controller) {
          legend.enabled = true;
        },
        xAxisSettingFunction: (xAxis, controller) {
          xAxis
            ..drawGridLines = true
            ..gridColor = Colors.blueGrey[50]
            ..drawAxisLine = false
            ..position = XAxisPosition.BOTTOM
            ..setValueFormatter(XDateFormater());
          if (widget.showPeriod != null) {
            xAxis.setAxisMinValue(widget
                    .collection.last.dateTime.millisecondsSinceEpoch
                    .toDouble() -
                widget.showPeriod.inMilliseconds);
          }
        },
        drawGridBackground: false,
        dragXEnabled: true,
        dragYEnabled: true,
        scaleXEnabled: true,
        scaleYEnabled: false,
        pinchZoomEnabled: false,
        highLightPerTapEnabled: true,
        drawBorders: false,
        noDataText: 'loading',
        marker:
            MyLineMarker(textColor: Colors.white, backColor: Colors.blueGrey),
        highlightPerDragEnabled: true);
  }

  // Precompute datasets in Isolate
  static LineData _computeData(List<LineStatsCollection> collection) {
    // Calc positive difference beetween last and current value

    List<Map> diff = [];
    for (var i = 1; i < collection.length; i++) {
      if (collection[i - 1].isErrored) {
        continue;
      }
      DateTime time = collection[i].dateTime;

      int upCurr = collection[i].upFEC ?? 0;
      int downCurr = collection[i].downFEC ?? 0;
      int upPrev = collection[i - 1].upFEC ?? 0;
      int downPrev = collection[i - 1].downFEC ?? 0;

      int up = upCurr - upPrev;
      int down = downCurr - downPrev;

      diff.add({
        'dateTime': time,
        'downFEC': (down <= 0) ? 0 : down,
        'upFEC': (up <= 0) ? 0 : up
      });
    }

    // Prepare download FEC set

    List<Entry> downFECValues = List();

    diff.forEach((element) {
      downFECValues.add(new Entry(
          x: element['dateTime'].millisecondsSinceEpoch.toDouble(),
          y: element['downFEC'].toDouble()));
    });

    // Create a dataset
    LineDataSet downFECSet = new LineDataSet(downFECValues, "FEC Down");

    // Apply setiings
    downFECSet
      // ..setLineWidth(1)
      ..setColor1(Colors.blueGrey[600])
      ..setMode(Mode.STEPPED)
      ..setDrawValues(false)
      ..setDrawFilled(true)
      ..setFillAlpha(200)
      ..setLineWidth(0)
      ..setGradientColor(Colors.yellow[600], Colors.yellow[200])
      ..setDrawCircles(false);

    // Prepare upload FEC set

    List<Entry> upFECValues = List();

    diff.forEach((element) {
      upFECValues.add(new Entry(
          x: element['dateTime'].millisecondsSinceEpoch.toDouble(),
          y: element['upFEC'].toDouble()));
    });

    // Create a dataset
    LineDataSet upFECSet = new LineDataSet(upFECValues, "FEC Up");

    // Apply settings
    upFECSet
      // ..setLineWidth(1)
      ..setColor1(Colors.yellow[600])
      ..setMode(Mode.STEPPED)
      ..setDrawValues(false)
      ..setDrawFilled(true)
      ..setLineWidth(0)
      ..setFillAlpha(200)
      ..setGradientColor(Colors.blueGrey[600], Colors.blueGrey[200])
      ..setDrawCircles(false);

    // Add sets to line data and return
    LineData lineData =
        LineData.fromList(List()..add(downFECSet)..add(upFECSet));
    return lineData;
  }

  // Initialize linedata
  void _initLineData(List<LineStatsCollection> collection) async {
    LineData lineData = await compute(_computeData, collection);
    _controller.data = lineData;
    _controller.state?.setStateIfNotDispose();
  }

  // Render
  @override
  Widget build(BuildContext context) {
    print('render viewer');
    return Container(
        height: 200,
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: 260,
          child: Column(
            children: [
              Container(
                  color: Colors.amber,
                  height: 200,
                  child: LineChart(_controller)),
              Transform.translate(
                offset: const Offset(0, -190),
                child: Text('Speed rates'),
              ),
            ],
          ),
        ));
  }
}
