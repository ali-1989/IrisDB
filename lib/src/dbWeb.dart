import 'package:iris_db/src/cookieManager.dart';
//import 'dart:indexed_db';

Future<String> openDoc(String path) async {
  // window.indexedDB  >  not supported in some browsers
  // window.localStorage  > it is remove by close session

  return CookieManager.getCookie(path);
}

Future<bool> writeDoc(String path, String data, bool backup){
  if(backup){
    final oldBk = '$path.bk';

    final cur = CookieManager.getCookie(path);
    //CookieManager.clear(oldBk);
    CookieManager.addCookie(oldBk, cur);
  }

  CookieManager.addCookie(path, data);

  return Future.value(true);
}

Future<bool> appendDoc(String path, String data, bool backup){
  final cur = CookieManager.getCookie(path);
  final newData = cur + data;

  if(backup){
    final oldBk = '$path.bk';

    //CookieManager.clear(oldBk);
    CookieManager.addCookie(oldBk, cur);
  }

  CookieManager.addCookie(path, newData);

  return Future.value(true);
}

Future<String> deleteDoc(String path) async {
  CookieManager.clear(path);

  return path;
}