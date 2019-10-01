import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import './consts.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:async/async.dart';
import 'package:audio_service/audio_service.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: appTitle,
      theme: ThemeData.dark(),
      /*theme: ThemeData(
        primarySwatch: Colors.blue,
      ),*/
      home: HomePage(title: appTitle),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AssetsAudioPlayer aap;
  bool randomSound = true;
  String selectedSound;
  List<String> _assetPaths = [];
  RestartableTimer t;
  int maxRandMins = 2;

  @override
  initState() {
    super.initState();
    _getAssetPaths();

    /*AudioService.connect(); // When UI becomes visible
    AudioService.start(
      // When user clicks button to start playback
      backgroundTask: myBackgroundTask,
      androidNotificationChannelName: 'Music Player',
      androidNotificationIcon: "mipmap/ic_launcher",
    );
    AudioService.pause(); // When user clicks button to pause playback
    AudioService.play(); // When user clicks button to resume playback*/
  }

  void _startAudioService() {
    print('startAudioService');
    AudioService.connect(); // When UI becomes visible
    AudioService.start(
      // When user clicks button to start playback
      backgroundTask: _myBackgroundTask,
      androidNotificationChannelName: 'Music Player',
      androidNotificationIcon: "mipmap/ic_launcher",
    );
  }

  void _myBackgroundTask() {
    AudioServiceBackground.run(
      onStart: () async {
        print('onStart');
        // Your custom dart code to start audio playback.
        // NOTE: The background audio task will shut down
        // as soon as this async function completes.
        _start();
      },
      onPlay: () {
        print('onPlay');
        // Your custom dart code to resume audio playback.
        _start();
      },
      onPause: () {
        print('onPause');
        // Your custom dart code to pause audio playback.
        aap.pause();
      },
      onStop: () {
        print('onStop');
        // Your custom dart code to stop audio playback.
        _reset();
      },
      onClick: (MediaButton button) {
        print('onClick');
        // Your custom dart code to handle a media button click.
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style:
              TextStyle(fontSize: appFontSizeHuge, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: appMargin),
          children: _showConfig(),
        ),
      ),
    );
  }

  Future<void> _getAssetPaths() async {
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    //print('bbb $manifestContent');
    final Map<String, dynamic> manifestMap = await json.decode(manifestContent);
    //print('ccc $manifestMap');
    final paths = manifestMap.keys
        .where((String key) => key.contains('assets/'))
        .where((String key) => key.contains('.mp3'))
        .toList();

    for (int i = 0; i < paths.length; i++) {
      paths[i] = paths[i].substring(7);
    }
    //print('ddd $paths');

    setState(() {
      _assetPaths = paths;
    });
  }

  List<Widget> _showConfig() {
    return <Widget>[
      Container(height: appMargin),
      Text(
        'Options',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: appFontSizeBig,
          fontWeight: FontWeight.bold,
        ),
      ),
      CheckboxListTile(
        activeColor: Colors.blueGrey,
        title: Text(
          'Random sound effect:',
          style: TextStyle(
              fontSize: appFontSizeNormal, fontWeight: FontWeight.normal),
        ),
        value: randomSound,
        onChanged: ((val) {
          setState(() {
            randomSound = val;
          });
        }),
      ),
      DropdownButton<String>(
        hint: Text(
          'Select Sound',
          style: TextStyle(
              fontSize: appFontSizeNormal, fontWeight: FontWeight.normal),
        ),
        items: _assetPaths
            .map(
              (value) => DropdownMenuItem<String>(
                child: Text(
                  value,
                  style: TextStyle(
                      fontSize: appFontSizeNormal,
                      fontWeight: FontWeight.normal),
                ),
                value: value,
              ),
            )
            .toList(),
        onChanged: (val) {
          setState(() {
            selectedSound = val;
          });
        },
        value: selectedSound,
      ),
      TextField(
        decoration: InputDecoration(
            labelText: 'Enter max random number of minutes (>=2):'),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          maxRandMins = (int.parse(val) < 2) ? 2 : int.parse(val);
        },
      ),
      Container(
        height: appMargin,
      ),
      RaisedButton(
        shape: RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(appButBorderRad)),
        color: Color(appStartButCol),
        padding: EdgeInsets.symmetric(
            vertical: appMargin, horizontal: appButMargin - 10),
        child: Text(
          'Start',
          style:
              TextStyle(fontSize: appFontSizeHuge, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          _startAudioService();
          _start();
        },
      ),
      Container(
        height: appMargin,
      ),
      RaisedButton(
        shape: RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(appButBorderRad)),
        color: Color(appResetButCol),
        padding: EdgeInsets.symmetric(
            vertical: appMargin, horizontal: appButMargin - 14),
        child: Text(
          'Stop',
          style:
              TextStyle(fontSize: appFontSizeHuge, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          //_reset();
          AudioService.stop();
          _reset();
        },
      ),
    ];
  }

  int _getRandomMinutes() {
    Random rnd = Random();
    int min = 1;
    int max = maxRandMins;
    int toret = min + rnd.nextInt(max - min);
    return toret;
  }

  String _getRandomBeep() {
    Random rnd = Random();
    int min = 0;
    int max = _assetPaths.length - 1;
    return _assetPaths[min + rnd.nextInt(max - min)];
  }

  void _start() async {
    print('_start()');
    t = RestartableTimer(Duration(minutes: _getRandomMinutes()), () {
      aap = AssetsAudioPlayer();
      aap.open(AssetsAudio(
        asset: !randomSound && selectedSound.isNotEmpty
            ? selectedSound
            : _getRandomBeep(),
        folder: "assets/",
      ));
      t.cancel();
      _start();
    });
  }

  void _stopAudio() {
    print('_stopAudio()');
    if (aap != null) {
      aap.stop();
      aap.dispose();
      aap = null;
    }
  }

  void _reset() {
    print('_reset()');
    t.cancel();
    _stopAudio();
  }

  @override
  void dispose() {
    print('dispose()');
    t.cancel();
    _stopAudio();
    AudioService.disconnect(); // When UI is gone
    super.dispose();
  }
}
