
Future<String> openDoc(String path){
  throw UnsupportedError('Cannot open DB file.');
}

Future<bool> writeDoc(String path, String data, bool backup){
  throw UnsupportedError('Cannot write DB file.');
}

Future<bool> appendDoc(String path, String data, bool backup){
  throw UnsupportedError('Cannot append DB file.');
}

Future<String> deleteDoc(String path){
  throw UnsupportedError('Cannot delete DB file.');
}