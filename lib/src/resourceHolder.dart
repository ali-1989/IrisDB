import 'package:g_json/g_json.dart';

class ResourceHolder {
  String? fileVersion;
  String? fileDate;
  late String rawName;
  late String name;
  late String filePath;
  bool isEmptyFile = false;
  List<JSON> records = [];

  ResourceHolder cloneWithoutRecords(){
    var res = ResourceHolder();
    res.name = name;
    res.filePath = filePath;
    res.fileVersion = fileVersion;
    res.fileDate = fileDate;
    res.isEmptyFile = isEmptyFile;

    return res;
  }
}