import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart' as hp;
import 'package:mime/mime.dart' as mime;
import 'package:path_provider/path_provider.dart';
import 'package:pathprovc/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as r;
import 'package:shelf_virtual_directory/shelf_virtual_directory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabase();

  final Directory? docDir = await getExternalStorageDirectory();

  var app = r.Router();


  // var address = '192.168.231.159';
  // var address = '10.0.2.16';
  var address = 'localhost';
  // this needed for static and api type respone
  final virDirCascade = ShelfVirtualDirectory(docDir!.path).cascade;
  var server =
      await shelf_io.serve(virDirCascade.add(app).handler, address, 8081);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');
  app.get('/home', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/index.html");
    File fi = await writeToFile(imageBytes, "index.html");
    final headers = await _defaultFileheaderParser(fi);
    return Response(200, body: fi.openRead(), headers: headers);
  });
  app.get('/bim', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/bim.html");
    File fi = await writeToFile(imageBytes, "bim.html");
    final headers = await _defaultFileheaderParser(fi);
    return Response(200, body: fi.openRead(), headers: headers);
  });
  app.get('/i', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/img.png");
    File fi = await writeToFile(imageBytes, "img.png");
    final headers = await _defaultFileheaderParser(fi);
    return Response(200, body: fi.openRead(), headers: headers);
  });
  app.get('/bootstrap', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/self.html");
    File fi = await writeToFile(imageBytes, "self.html");
    final headers = await _defaultFileheaderParser(fi);
    return Response(200, body: fi.openRead(), headers: headers);
  });
  app.get('/n404', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/404.html");
    File fi = await writeToFile(imageBytes, "404.html");
    final headers = await _defaultFileheaderParser(fi);
    return Response(200, body: fi.openRead(), headers: headers);
  });
  app.get('/api/hello', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/self.html");
    File fi = await writeToFile(imageBytes, "self.html");
    final headers = await _defaultFileheaderParser(fi);
    return Response.ok('hello Api ${request.requestedUri}');
  });

  app.get('/user/<user>', (Request request, String user) {
    return Response.ok('hello $user');
  });
  app.get('/u', (Request request, String user) {
    return Response(200,
        body: test.htmls,
        headers: {HttpHeaders.contentTypeHeader: 'text/html'});
  });
  runApp(MyApp());
}

Future<Map<String, Object>> _defaultFileheaderParser(File file) async {
  final fileType = mime.lookupMimeType(file.path);

  // collect file data
  final fileStat = await file.stat();

  // check file permission
  if (fileStat.modeString()[0] != 'r') return {};

  return {
    HttpHeaders.contentTypeHeader: fileType ?? 'application/octet-stream',
    HttpHeaders.contentLengthHeader: fileStat.size.toString(),
    HttpHeaders.lastModifiedHeader: hp.formatHttpDate(fileStat.modified),
    HttpHeaders.acceptRangesHeader: 'bytes'
  };
}

Response _echoRequest(Request request) =>
    Response.ok('Request for Kunchol "${request.url}"');

Future<void> initializeDatabase() async {
  // copy db file from Assets folder to Documents folder (only if not already there...)
  // if (FileSystemEntity.typeSync(dbPath) == FileSystemEntityType.notFound) {
  var data = await rootBundle.load("example/files/index.html");
  var datab = await rootBundle.load("example/files/img.png");
  var datas = await rootBundle.load("example/files/self.html");
  var databi = await rootBundle.load("example/files/bim.html");
  writeToFile(data, "index.html");
  writeToFile(datab, "img.png");
  writeToFile(datas, "self.html");
  writeToFile(databi, "bim.html");

  // }
}

//=======================
Future<File> writeToFiles(ByteData data) async {
  final buffer = data.buffer;
  Directory? tempDir = await getExternalStorageDirectory();
  String? tempPath = tempDir?.path;

  var filePath =
      tempPath! + '/img.png'; // file_01.tmp is dump file, can be anything
  return new File(filePath)
      .writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}
//======================

// HERE IS WHERE THE CODE CRASHES (WHEN TRYING TO WRITE THE LOADED BYTES)
Future<File> writeToFile(ByteData data, String file) async {
  final buffer = data.buffer;
  Directory? tempDir = await getExternalStorageDirectory();
  String? tempPath = tempDir?.path;
  var filePath =
      tempPath! + '/' + file; // file_01.tmp is dump file, can be anything
  return new File(filePath)
      .writeAsBytes(buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
}

class MyApp extends StatelessWidget {
  var type;

  var internal;

  var external;

  MyApp();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: "Host Static and Api"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
