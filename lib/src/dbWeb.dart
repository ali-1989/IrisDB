import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'dart:html';
//import 'dart:io';

Future<String> openDoc(String path){
  print('☼☼☼☼☼☼ IsisDB [web-openDoc]: $path');
  final f = MemoryFileSystem().file(path);
  print('☼☼☼☼☼☼ IsisDB [web-openDoc] B');
  //if(!f.existsSync()) {
    f.createSync(recursive: true);
  //}
  print('☼☼☼☼☼☼ IsisDB [web-openDoc] C');
  return f.readAsString();
}

Future<bool> writeDoc(String path, String data, bool backup){
  final f = MemoryFileSystem().file(path);

  if(!f.existsSync()) {
    f.createSync(recursive: true);
  }

  return f.writeAsString(data, mode: FileMode.writeOnly, flush: true)
      .then((value) => true);
}

Future<bool> appendDoc(String path, String data, bool backup){
  File f = MemoryFileSystem().file(path);

  if(!f.existsSync()) {
    f.createSync(recursive: true);
  }

  return f.writeAsString(data, mode: FileMode.writeOnlyAppend, flush: true)
      .then((value) => true);
  //throw UnsupportedError('Cannot append DB file.');
}

Future<String> deleteDoc(String path) async {
  await MemoryFileSystem().file(path).delete();
  return path;
}