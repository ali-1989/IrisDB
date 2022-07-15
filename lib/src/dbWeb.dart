import 'dart:html';
//import 'dart:indexed_db';

Future<String> openDoc(String path) async {
  print('☼☼☼☼☼☼ IsisDB [web-openDoc]: $path');
  /*if (IdbFactory.supported){
    window.indexedDB!.open(path, version: 1)
  }*/

  if (window.localStorage.containsKey(path)){
    return window.localStorage[path]!;
  }

  print('☼☼☼☼☼☼ IsisDB [web-openDoc] C');
  return '';
}

Future<bool> writeDoc(String path, String data, bool backup){
  if (window.localStorage.containsKey(path)){
    if(backup){
      final oldBk = '$path.bk';

      try {
        window.localStorage.remove(oldBk);
        window.localStorage[oldBk] = window.localStorage[path]!;
      }
      catch (e){/**/}
    }
  }

  window.localStorage[path] = data;

  return Future.value(true);
}

Future<bool> appendDoc(String path, String data, bool backup){
  if (window.localStorage.containsKey(path)){
    if(backup){
      final oldBk = '$path.bk';

      try {
        window.localStorage.remove(oldBk);
        window.localStorage[oldBk] = window.localStorage[path]!;
      }
      catch (e){/**/}
    }

    window.localStorage[path] = window.localStorage[path]! + data;
  }
  else {
    window.localStorage[path] = data;
  }

  return Future.value(true);
}

Future<String> deleteDoc(String path) async {
  if (window.localStorage.containsKey(path)){
    window.localStorage.remove(path);
  }

  return path;
}