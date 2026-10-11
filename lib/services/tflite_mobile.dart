import 'package:tflite_flutter/tflite_flutter.dart';

Future<Interpreter> loadInterpreter(String modelPath) async {
  return await Interpreter.fromAsset(modelPath);
}
