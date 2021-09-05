import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as hp;
import 'package:mime/mime.dart' as mime;
import 'package:path_provider/path_provider.dart';
import 'package:pathprovc/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as r;
import 'package:shelf_static/shelf_static.dart';
import 'package:url_launcher/url_launcher.dart';

var address = "";

var url_ = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDatabase();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  address = '25.86.151.26';
  address = prefs.getString("id") ?? "localhost";
  final Directory? docDir = await getExternalStorageDirectory();

  var app = Routers();

  app.mount("/", createStaticHandler(docDir!.path));

  // var address = '192.168.231.159';
  // var address = '10.0.2.16';
  // var address = 'localhost';
  // address = '25.86.151.26';
  url_ = 'http://$address:8081';
  // this needed for static and api type respone
  // final virDirCascade = ShelfVirtualDirectory(docDir!.path).cascade;
  // var handler2 = virDirCascade.add(app).handler;
  var server = await shelf_io.serve(Cascade().add(app).handler, address, 8081);

  // Enable content compression
  server.autoCompress = true;

  print('Serving at http://${server.address.host}:${server.port}');

  runApp(MyApp());
}

r.Router Routers() {
  var app = r.Router();
  app.get('/home', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/index.html");
    File fi = await writeToFile(imageBytes, "index.html");
    final headers = await _defaultFileheaderParser(fi);
    return Response(200, body: fi.openRead(), headers: headers);
  });
  app.get('/', (Request request) async {
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
  app.get('/upload', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/upload.html");
    File fi = await writeToFile(imageBytes, "upload.html");
    final headers = await _defaultFileheaderParser(fi);
    return Response(200, body: fi.openRead(), headers: headers);
  });
  app.get('/api/uploadtest', (Request request) async {
    final imageBytes = await rootBundle.load("example/img_2.png");
    File fi = await writeToFile(imageBytes, "img_2.png");
    var request =
    http.MultipartRequest('POST', Uri.parse('$address:8081/api/upload'));
    request.files.add(await http.MultipartFile.fromPath('image', fi.path));

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      print(await response.stream.bytesToString());
      Response.ok("File Uploaded");
    } else {
      print(response.reasonPhrase);
      Response.notFound(response.reasonPhrase);
    }
    await Response.ok("File Uploaded");
  });
  app.post('/api/upload', (Request request) async {
    // second(request);

    return await third(request);
    // await fst(request);
  });
  app.get('/i', (Request request) async {
    final imageBytes = await rootBundle.load("example/files/img.png");
    File fi = await writeToFile(imageBytes, "img.png");
    final headers = await _defaultFileheaderParser(fi);
    return Response(200, body: fi.openRead(), headers: headers);
  });
  app.get('/files', (Request request) async {
    final Directory? docDir = await getExternalStorageDirectory();
    List<FileSystemEntity> files = docDir!.listSync(recursive: true);
    String data = "";
    files.forEach((element) {
      var s = element.statSync();
      var filename =
          element.resolveSymbolicLinksSync().toString().split("/").last;
      var size = s.size.toDigital;
      data +=
      '       <div class="col-md-4 col-sm-4 col-lg-3 col-6 m-2" align="center"> <div class="card" style="width: 18rem;"> <div class="card-body"> <p style="font-size: 13px;color: #1b6d85" class="card-title">${filename}</p> <p class="card-text">${s.modified.toString()}</p> <p class="card-text">${size}</p> <a href="/${filename}" class="btn btn-primary">Download</a> </div> </div> </div>';
      // data += filename + s.size.toString() + s.type.toString() + "\n";
    });
    // return Response.ok('\n $data');
    final imageBytes = await rootBundle.loadString("example/files/files.html");
    var datas = imageBytes.replaceAll("<!--        content-->", data);

    File fi = await writeToFile2(datas, "files.html");
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
  app.get('/api/set/<name>', (Request request, String name) async {
    final imageBytes = await rootBundle.load("example/files/self.html");
    File fi = await writeToFile(imageBytes, "self.html");
    final headers = await _defaultFileheaderParser(fi);
    return Response.ok('$name hello Api ${request.requestedUri}');
  });

  app.get('/u', (Request request, String user) {
    return Response(200,
        body: test.htmls,
        headers: {HttpHeaders.contentTypeHeader: 'text/html'});
  });
  return app;
}

writeToFile2(String imageBytes, String file) async {
  Directory? tempDir = await getExternalStorageDirectory();
  String? tempPath = tempDir?.path;
  var filePath =
      tempPath! + '/' + file; // file_01.tmp is dump file, can be anything
  return new File(filePath).writeAsString(imageBytes);
}

Future<Response> third(Request request) async {
  List<int> dataBytes = [];
  await for (var data in request.read()) {
    dataBytes.addAll(data);
  }

  String fileExtension = '';
  late File file;
  var header2 = request.headers['content-type'];
  var header = HeaderValue.parse(header2!);
  final transformer =
  new mime.MimeMultipartTransformer(header.parameters['boundary']!);
  final bodyStream = Stream.fromIterable([dataBytes]);
  try {
    final parts = await transformer.bind(bodyStream).toList();
    final part = parts[0];
    if (part.headers.containsKey('content-disposition')) {
      header = HeaderValue.parse(part.headers['content-disposition']!);
      String? filename = header.parameters['filename'] ?? "pic.png";
      final content = await part.toList();
      convert(content[0], filename);
      // originalfilename = header.parameters['filename'];
      // print('originalfilename:' + originalfilename!);
      // fileExtension = p.extension(originalfilename);
      // file = await File('/destination/filename.mp4').create(
      //     recursive:
      //         true); //Up two levels and then down into ServerFiles directory

      // await file.writeAsBytes(content[0]);
      return Response.ok("File Sucesfully Uploaded $filename");
    }
  } catch (e) {
    print(e);
    return Response.notFound(e.toString() + "\n Empty File");
  }
  return Response.notFound("Empty File");
}

Future<void> five(Request args) async {
  // final maybeMultipart = args.parts;
  // if (maybeMultipart.isNone)
  //   return const ResponseBodyString("bad POST request: not multipart")
  //       .toResponse(statusCode: HttpStatus.badRequest);
  // final multipart = maybeMultipart.getOrThrow.map(HttpMultipartFormData.parse);
  // final formData = (await multipart.toList())[0];
  // if (!formData.isBinary)
  //   const ResponseBodyString("bad POST request: expected binary data")
  //       .toResponse(statusCode: HttpStatus.badRequest);
  // // ignore: avoid_as
  // final untypedData =
  //     await formData.map((dynamic d) => d as Uint8List).toList();
  // final data = Uint8List.fromList(untypedData.flatten().toList());
  // final either =
  //     EventLog.rw.deserialize(data.asByteData, 0).map((di) => di.value);
  // return respondHtml(renderParseLogFile(Some(either)));
}

Future<void> four(Request request) async {
  List<int> dataBytes = [];
  await for (var data in request.read()) {
    dataBytes.addAll(data);
  }

  String fileExtension = '';
  late File file;
  var header2 = request.headers['content-type'];
  var header = HeaderValue.parse(header2!);
  final transformer =
  new mime.MimeMultipartTransformer(header.parameters['boundary']!);
  transformer.bind(request.read());
  final bodyStream = Stream.fromIterable([dataBytes]);
  final parts = await transformer.bind(bodyStream).toList();
  final part = parts[0];
  if (part.headers.containsKey('content-disposition')) {
    header = HeaderValue.parse(part.headers['content-disposition']!);
    String? filename = header.parameters['filename'] ?? "pic.png";
    final content = await part.toList();

    convert(content, filename);
    // originalfilename = header.parameters['filename'];
    // print('originalfilename:' + originalfilename!);
    // fileExtension = p.extension(originalfilename);
    // file = await File('/destination/filename.mp4').create(
    //     recursive:
    //         true); //Up two levels and then down into ServerFiles directory

    // await file.writeAsBytes(content[0]);
  }
}

void second(Request request) {
  gzip.decoder.bind(request.read()).drain();
  // if (!request.isMultipart)
  //   return Response(400);
  //  // var single = await request.read();
  //
  // await  for (final part in request.parts) {
  //    // var s= Uint8List.fromList(part.);
  //    // writeToFile(s.buffer.asByteData(),"pic.png");
  //
  //    // Deal with the part
  //  }
  //  return Response(200);

  // var boundary = request.headers;
  // String? value = request.headers['content-type'];
  // var header = HeaderValue.parse(value!);
  // String fileExtension = '';
  // late File file;
  // final transformer =
  //     new mime.MimeMultipartTransformer(header.parameters['boundary']!);
  // final bodyStream = Stream.fromIterable([dataBytes]);
  // final parts = await transformer.bind(bodyStream).toList();
  // final part = parts[0];
  // var content = await part.toList();
  // convert();

  // if (part.headers.containsKey('content-disposition')) {
  //   header = HeaderValue.parse(part.headers['content-disposition']!);
  //   originalfilename = header.parameters['filename'];
  //   print('originalfilename:' + originalfilename!);
  //   fileExtension = p.extension(originalfilename);
  //   file = await File('/destination/filename.mp4')
  //       .create(recursive: true); //Up two levels and then down into ServerFiles directory
  //   final content = await part.toList();
  //   await file.writeAsBytes(content[0]);
  // }
}

void convert(dataBytes, String filename) {
  var s = Uint8List.fromList(dataBytes);
  writeToFile(s.buffer.asByteData(), filename);
}

Future<void> fst(Request request) async {
  List<int> dataBytes = [];
  String? value = request.headers['content-type'];
  var header = HeaderValue.parse(value!);
  var boundary = header.parameters['boundary']!;
  await for (var part in request
      .read()
      .transform(new mime.MimeMultipartTransformer(boundary))) {
    if (part.headers.containsKey('content-disposition')) {
      String? header2 = part.headers['content-disposition'];
      header = HeaderValue.parse(header2!);
      Directory? tempDir = await getExternalStorageDirectory();
      String? tempPath = tempDir?.path;
      var filename = tempPath! + '/' + "pics.png";
      final file = new File(filename);
      IOSink fileSink = file.openWrite();
      await part.pipe(fileSink);
      fileSink.close();
    }
    // dataBytes.addAll(data);
  }
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
      debugShowCheckedModeBanner: false,
      title: 'Dart Http Web server',
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

  var _textcontroller = new TextEditingController(text: url_);

  onPressed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("id",
        _textcontroller.text.isEmpty ? "localhost" : _textcontroller.text);
  }

  void _launchURL() async => await canLaunch(url_)
      ? await launch(url_)
      : throw 'Could not launch $url_';

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

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
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
              TextField(
                controller: _textcontroller,
              ),
              RaisedButton(
                color: Colors.blue,
                onPressed: () async {
                  SharedPreferences prefs =
                  await SharedPreferences.getInstance();
                  await prefs.setString(
                      "id",
                      _textcontroller.text.isEmpty
                          ? "localhost"
                          : _textcontroller.text);
                  print(prefs.getString("id"));
                },
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _launchURL,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

extension Digitalsize on int {
  String get toDigital => this < 100000
      ? "${(.001 * this).roundToDouble()}" + "kB"
      : "${(.000001 * this).roundToDouble()}" + "MB";
}
