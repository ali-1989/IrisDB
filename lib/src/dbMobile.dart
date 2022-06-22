import 'dart:io';

Future<String> openDoc(String path) async {
  final f = File(path);

  if(!await f.exists()) {
    f.createSync(recursive: true);
    return '';
  }

  return f.readAsString();
}

Future<bool> writeDoc(String path, String data, bool backup){
  var f = File(path);

  if(f.existsSync()) {
    if(backup){
      final oldBk = File('$path.bk');

      try {
        oldBk.deleteSync();
        f.renameSync('$path.bk');
      }
      catch (e){}

      f = File(path);
      //f.createSync(recursive: true);
    }
  }
  else {
    f.createSync(recursive: true);
  }

  f.writeAsStringSync(data, mode: FileMode.writeOnly, flush: true);
  return Future.value(true);
}

Future<bool> appendDoc(String path, String data, bool backup){
  final f = File(path);

  if(f.existsSync()) {
    if(backup){
      final oldBk = File('$path.bk');

      try {
        oldBk.deleteSync();
        f.copySync('$path.bk');
      }
      catch (e){}
    }
  }
  else {
    f.createSync(recursive: true);
  }

  f.writeAsStringSync(data, mode: FileMode.writeOnlyAppend, flush: true);
  return Future.value(true);
}

Future<String> deleteDoc(String path) {
  File f = File(path);
  f.deleteSync();

  return Future.value(path);
}