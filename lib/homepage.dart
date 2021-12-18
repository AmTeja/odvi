import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'main.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {

  String result="";
  CameraController? cameraController;
  CameraImage? imageCamera;
  bool speak = false;
  bool onceDone = false;

  FlutterTts flutterTts = FlutterTts();

  Timer? timer;

  initCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.veryHigh);
    cameraController!.initialize().then((value) {
      if(!mounted){
        return;
      }
      setState(() {
        cameraController!.startImageStream((image) => {
            imageCamera = image,
        });
      });
    });
    setState(() {
    });
  }
  runModelOnStreamFile() async {
    if(imageCamera != null)
      {
        var recognitions = await Tflite.runModelOnFrame(
          bytesList: imageCamera!.planes.map((plane) {
            return plane.bytes;
          }).toList(),
          imageHeight: imageCamera!.height,
          imageWidth:  imageCamera!.width,
          imageMean:  127.5,
          rotation:  90,
          numResults: 2,
          threshold: 0.1,
          asynch: true,
        );
        result = '${recognitions![0]['label']} ${ recognitions[0]['confidence']}' ;
        setState(() {

        });
        if(recognitions[0]['confidence'] >= 0.80){
            await _speak(recognitions[0]['label'].toString());
        }
        // for (var response in recognitions!) {
        //   setState(() async {
        //     result = response['label'];
        //
        //   });
        // }
      }
  }

Future _speak(String text) async{
  var result = await flutterTts.speak(text);
}

  loadModel() async {
    Tflite.close( );
    try {
      await Tflite.loadModel(
          model: "assets/model.tflite",
          labels: "assets/labels.txt"
      );
    } on PlatformException {
      print('Failed to load the model');
    }
  }

  @override
  void initState() {
    initCamera();
    loadModel();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    Tflite.close();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                Expanded(
                    flex: 3,
                    child: Container(
                      color: Colors.red,
                      child: cameraController!.value.isInitialized ? AspectRatio(
                        aspectRatio: cameraController!.value.aspectRatio,
                       child: CameraPreview(cameraController!),
                       ) : Container(),)),
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text("Result: $result", textAlign: TextAlign.start ,style: TextStyle(fontSize: 22),),
                        ),

                        Expanded(
                          child: MaterialButton(
                            onPressed: () {
                              if(!onceDone) {
                                speak ? flutterTts.speak('Stop Dictating') :flutterTts.speak("Start Dictating");
                                onceDone = true;
                              } else {
                                speak = !speak;
                                print("speak: $speak");
                                if(speak){
                                  timer = Timer.periodic(Duration(seconds: 2), (timer) => runModelOnStreamFile());
                                }else{
                                  timer?.cancel();
                                }
                                onceDone = false;
                                setState(() {

                                });
                              }
                            },
                            minWidth: 200,
                            color: Colors.blue,
                            child: Container(
                              height: 100,
                              width: MediaQuery.of(context).size.width,
                              child: Text(
                                speak ? "Stop Dictating" : "Start Dictating",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: MaterialButton(
                            onPressed: () async {
                              await runModelOnStreamFile();
                            },
                            minWidth: 200,
                            color: Colors.blue,
                            child: Container(
                              height: 100,
                              width: MediaQuery.of(context).size.width,
                              child: const Text(
                                'Detect',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                        ),

                      ],
                    )
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
