import 'dart:convert';
import 'package:g_json/g_json.dart';
import 'package:iris_db/src/condition.dart';
import 'package:iris_db/src/enums.dart';
import 'package:iris_db/src/pathHelper.dart';
import 'package:iris_db/src/resourceHolder.dart';

import 'dbStub.dart'
  if (dart.library.io) 'dbMobile.dart'
  if (dart.library.html) 'dbWeb.dart' as cross;


//------------------------------------------------------------------------------------------------
typedef OrderBy = int Function(JSON e1, JSON e2);
//------------------------------------------------------------------------------------------------
class IrisDB {
  String _version = '1.3';
  String _dirPath = '';
  bool _debug = false;
  List<ResourceHolder> _openedDoc = [];

  IrisDB({String? filesPath}){
    if(filesPath != null){
      _dirPath = filesPath;
    }
    else {
      _dirPath = PathHelper.getCurrentPath();
    }
  }

  void setDatabasePath(String address){
    _dirPath = address;
  }

  bool _hasPath(String docName){
    return docName.contains(RegExp(r'(/|\\)'));
  }

  bool _existDocByPath(String path){
    return _openedDoc.any((elm) => elm.filePath == path);
  }

  bool _existDocByRN(String rawName){
    return _openedDoc.any((elm) => elm.rawName == rawName);
  }

  String _genPath(String docName){
    String p = PathHelper.normalize(_dirPath + PathHelper.getSeparator() + docName)!;
    return PathHelper.resolvePath(p)!;
  }

  ResourceHolder _genNewResourceHolder(String docName){
    if(_debug){
      print('☼☼☼☼☼☼ IsisDB [start Generate Resource]: $docName');
    }

    ResourceHolder rh = ResourceHolder();
    rh.rawName = docName;

    if(_hasPath(docName)){
      rh.filePath = docName;
      rh.name = PathHelper.getFileName(docName);
    }
    else {
      rh.name = docName;
      rh.filePath = _genPath(docName);
    }

    if(_debug){
      print('☼☼☼☼☼☼ IsisDB [End Generate Resource]: $docName | ${rh.name}, ${rh.filePath}');
    }
    return rh;
  }

  ResourceHolder? _getDoc(String docName) {
    try {
      return _openedDoc.firstWhere((element) => element.rawName == docName);
    }
    catch (e){
      if(_debug){
        print('☼☼☼☼☼☼ IsisDB [getDoc A]: $e');
      }
      try {
        return _openedDoc.firstWhere((element) => element.name == docName);
      }
      catch (e){
        if(_debug){
          print('☼☼☼☼☼☼ IsisDB [getDoc B]: $e');
        }
        return null;
      }
    }
  }

  String? _fetchVersion(String line){
    final regExp = RegExp(r"version:\s*(.*?)(\s*,|\s+.*|$)",
      caseSensitive: false,
      multiLine: false,
    );

    if(!regExp.hasMatch(line)){
      return null;
    }

    return regExp.firstMatch(line)!.group(1);
  }

  String? _fetchDate(String line){
    var regExp = RegExp(r"date:\s*(.*?)(\s*,|$)",
      caseSensitive: false,
      multiLine: false,
    );

    if(!regExp.hasMatch(line)){
      return null;
    }

    return regExp.firstMatch(line)!.group(1);
  }

  Future<bool> openDoc(String docName) async {
    final rh = _genNewResourceHolder(docName);

    if(_existDocByPath(rh.filePath)) {
      return Future.value(true);
    }

    if(_debug){
      print('☼☼☼☼☼☼ IsisDB [start read doc]: ${rh.name}');
    }

    var data = await cross.openDoc(rh.filePath);
    //rh.json = json.decode(rh.dataStr);
    if(_debug){
      print('☼☼☼☼☼☼ IsisDB [data is]: ${rh.name}\n > $data');
      print('@-------------END of Data----------------');
    }

    try{
      return convert(rh, data);
    }
    catch (e){
      if(_debug) {
        print('☼☼☼☼☼☼ IsisDB [start OpenBackup]: ${rh.name}: | because >> $e');
      }

      data = await cross.openDoc('${rh.filePath}.bk');

      if(_debug) {
        print('☼☼☼☼☼☼ IsisDB [Backup]: ${rh.name}\n > $data');
      }

      return convert(rh, data);
    }
  }

  bool convert(ResourceHolder rh, String data){
    LineSplitter ls = LineSplitter();
    List<String> temp = ls.convert(data);

    for(var line in temp){
      if(_isJson(line)) {
        rh.records.add(JSON.parse(line));
      }
    }

    if(temp.isEmpty){
      rh.isEmptyFile = true;
    } else {
      rh.fileVersion = _fetchVersion(temp[0]);
      rh.fileDate = _fetchDate(temp[0]);
    }

    if(rh.fileVersion == null){
      rh.fileVersion = _version;
    }

    if(rh.fileDate == null){
      rh.fileDate = DateTime.now().toUtc().toString();
    }

    _openedDoc.add(rh);

    return true;
  }

  bool isOpen(String docName){
    return _existDocByRN(docName);
  }

  void closeDoc(String docName){
    _openedDoc.removeWhere((elm) => elm.rawName == docName);
  }

  Future<String> deleteDocFile(String docName) async {
    var rh = _getDoc(docName);

    if(rh != null){
      rh.records.clear();
    }

    closeDoc(docName);
    rh = _genNewResourceHolder(docName);

    return cross.deleteDoc(rh.filePath);
  }

  Future<String> docFileAsText(String docName) async {
    ResourceHolder? rh = _genNewResourceHolder(docName);

    return cross.openDoc(rh.filePath);
  }

  Future<bool> truncateDoc(String docName) async {
    var rh = _getDoc(docName);

    if(rh != null){
      rh.records.clear();
    }
    else {
      rh = _genNewResourceHolder(docName);
    }

    await _write(rh.filePath, rh.cloneWithoutRecords());
    return true;
  }

  String? getDocFilePath(String name) {
    ResourceHolder rh;

    try {
      rh = _openedDoc.firstWhere((element) => element.name == name || element.rawName == name);
      return rh.filePath;
    }
    catch (e){
      return null;
    }
  }

  List<dynamic> find(String docName, Conditions? conditions, {
    List path = const [],
    int? limit,
    int? offset,
    OutType outType = OutType.MapOrDynamic,
    OrderBy? orderBy,
    }) {
    ResourceHolder rh = _getDoc(docName)!;

    List res = [];
    int skip = 0;

    /*var sourceList = rh.records;

    if(orderBy != null) {
      sourceList = List.from(rh.records.map((e) => e.value));
      sourceList.sort(orderBy);
    }*/

    if(orderBy != null) {
      rh.records.sort(orderBy);
    }

    for(var row in rh.records){
      if(limit != null && res.length >= limit){
        break;
      }

      var v = row[path];

      if(v.error != null){
        continue;
      }

      if(conditions == null || conditions.isEmpty){
        if(offset != null && skip < offset){
          skip++;
          continue;
        }

        if(outType == OutType.JSON)
          res.add(v);
        else
          res.add(json.decode(v.rawString()));
      }
      else {
        bool passConditions = false;

        try{
          //passConditions = hasCondition(v.value, conditions);
          passConditions = hasCondition(row.value, conditions);
        }
        catch (e){
          if(!conditions.exceptionSafe){
            rethrow;
          }
        }

        if(passConditions){
          if(offset != null && skip < offset){
            skip++;
            continue;
          }

          if(outType == OutType.JSON)
            res.add(v);
          else
            res.add(json.decode(v.rawString()));
        }
      }
    }

    return res;
  }

  dynamic first(String docName, Conditions? conditions, {
    List path = const [],
    int? offset,
    OutType outType = OutType.MapOrDynamic,
    OrderBy? orderBy,
    }) {
    var findRes = find(
      docName,
        conditions,
        path: path,
        limit: 1,
        offset: offset,
        outType: outType,
        orderBy: orderBy,
    );

    if(findRes.isEmpty)
      return null;

    return findRes.first;
  }

  Future<int> insert(String docName, Map value) async {
    ResourceHolder rh = _getDoc(docName)!;
    var j = JSON(value);
    rh.records.add(j);

    if(rh.isEmptyFile){
      var isOk = await _write(rh.filePath, rh);
      return isOk? 1: 0;
    }
    else {
      var isOk = await _append(rh.filePath, rh, j.rawString());
      return isOk ? 1 : 0;
    }
  }

  Future<int> update(String docName, dynamic value, Conditions? conditions, {List path = const []}) async {
    ResourceHolder rh = _getDoc(docName)!;
    int count = 0;

    for(var i=0; i< rh.records.length; i++){
      var row = rh.records.elementAt(i);
      var cell = row;

      if(path.isNotEmpty) {
        cell = row[path];
      }

      if(cell.rawJSONType == Type.unknown){
        continue;
      }

      bool passConditions = true;

      try{
        if(conditions != null && !conditions.isEmpty) {
          passConditions = hasCondition(row.value, conditions);
        }
      }
      catch (e){
        if(!conditions!.exceptionSafe){
          rethrow;
        }
        else {
          passConditions = false;
        }
      }

      if(passConditions){
        if(path.isEmpty){
          if(value is Map){
            for(var me in value.entries){
              /// if [me.value] == null, this command remove key
              row[me.key] = me.value;
              //row.value[me.key] = me.value;
            }
          }
          else {
            rh.records[i] = JSON(value);
          }
        }
        else {
          if(value is Map){
            for(var me in value.entries){
              cell[me.key] = me.value; //row[path][me.key] = me.value;
            }
          }
          else {
            row[path] = value;
          }
        }

        count++;
      }
    }

    if(count > 0) {
      await _write(rh.filePath, rh);
    }

    return count;
  }

  Future<int> replace(String docName, dynamic value, Conditions? conditions, {List path = const []}) async {
    ResourceHolder rh = _getDoc(docName)!;
    List<int> mustDeleteRow = [];
    List<JSON> newRecords = [];
    int editCount = 0;

    for(var i=0; i< rh.records.length; i++){
      var row = rh.records.elementAt(i);
      var v = row[path];

      if(v.error != null){
        continue;
      }

      if(conditions == null || conditions.isEmpty){
        if(path.isEmpty){
          mustDeleteRow.add(i);
          newRecords.add(JSON(value));
        }
        else {
          row[path] = value;
          editCount++;
        }
      }
      else {
        bool passConditions = false;

        try{
          passConditions = hasCondition(row.value, conditions);
        }
        catch (e){
          if(!conditions.exceptionSafe){
            rethrow;
          }
        }

        if(passConditions){
          if(path.isEmpty){
            mustDeleteRow.add(i);
            newRecords.add(JSON(value));
          }
          else {
            row[path] = value;
            editCount++;
          }
        }
      }
    }

    var r = 0;
    for(int idx in mustDeleteRow){
      rh.records.removeAt(idx-r);
      r++;
    }

    rh.records.addAll(newRecords);

    if(mustDeleteRow.length + editCount > 0) {
      await _write(rh.filePath, rh);
    }

    return mustDeleteRow.length + editCount;
  }

  Future<int> delete(String docName, Conditions? conditions, {List path = const []}) async {
    ResourceHolder rh = _getDoc(docName)!;
    List<int> mustDelete = [];
    int count = 0;

    for(var i=0; i< rh.records.length; i++){
      var row = rh.records.elementAt(i);
      var v = row[path];

      if(v.error != null){
        continue;
      }

      if(conditions == null || conditions.isEmpty){
        if(path.isEmpty){
          mustDelete.add(i);
        }
        else {
          var last = path.last;
          List newPath = path.getRange(0, path.length-1).toList();

          if(last is String){
            if(newPath.length > 0){
              row[newPath].remove(last);
            }
            else {
              row.remove(last);
            }
          }
          else {
            List items;

            if(newPath.length > 0){
              items = List.from(row[newPath].list!);
            }
            else {
              items = List.from(row.list!);
            }

            items.removeAt(last);
            row[newPath] = items;
          }

          count++;
        }
      }
      else {
        bool passConditions = false;

        try{
          //passConditions = hasCondition(v.value, conditions);
          passConditions = hasCondition(row.value, conditions);
        }
        catch (e){
          if(!conditions.exceptionSafe){
            rethrow;
          }
        }

        if(passConditions){
          if(path.isEmpty){
            mustDelete.add(i);
          }
          else {
            var last = path.last;
            List newPath = path.getRange(0, path.length-1).toList();

            if(last is String){
              if(newPath.length > 0){
                row[newPath].remove(last);
              }
              else {
                row.remove(last);
              }
            }
            else {
              List items;

              if(newPath.length > 0){
                items = List.from(row[newPath].list!);
              }
              else {
                items = List.from(row.list!);
              }

              items.removeAt(last);
              row[newPath] = items;
            }

            count++;
          }
        }
      }
    }

    int removed = 0;
    for(int idx in mustDelete){
      rh.records.removeAt(idx-removed);
      removed++;
    }

    if(mustDelete.length + count > 0) {
      await _write(rh.filePath, rh);
    }

    return mustDelete.length + count;
  }

  Future<int> deleteKey(String docName, Conditions? conditions, String key) async {
    return delete(docName, conditions, path: [key]);
  }

  bool exist(String docName, Conditions conditions, {List path = const []}) {
    return find(docName, conditions, path: path, limit: 1).isNotEmpty;
  }

  void setDebug(bool state){
    _debug = state;
  }

  Future<bool> _write(String path, ResourceHolder rh) {
    String w = 'Version: ${rh.fileVersion}, date: ${rh.fileDate}';

    for(var r in rh.records){
      w += "\n" + r.rawString();
    }

    if(_debug) {
      print('@@@ Write @ ${rh.name}:\n$w');
      print('@---------------------------');
    }

    rh.isEmptyFile = false;
    return cross.writeDoc(path, w, true);
  }

  Future<bool> _append(String path, ResourceHolder rh, String data) {
    if(_debug) {
      print('@@@ Append @ ${rh.name}:\n$data');
      print('@---------------------------');
    }

    rh.isEmptyFile = false;
    return cross.appendDoc(path, '\n$data', true);
  }

  bool _isJson(String? data) {
    if(data == null) {
      return false;
    }

    var pat = r'^\s*(\{|\[.{0,4}\{).*?(\}|\}.{0,4}\])\s*$';
    var regExp = RegExp(pat, multiLine: true, dotAll: true);
    return regExp.hasMatch(data);
  }
}