import 'dart:convert';
import 'package:g_json/g_json.dart';
import 'package:iris_db/src/condition.dart';
import 'package:iris_db/src/enums.dart';

class JsonQuery {
  JsonQuery._();

  static dynamic find(Map jsonMap, Conditions? conditions, {
    List path = const [],
    OutType outType = OutType.MapOrDynamic,
  }) {

    final row = JSON(jsonMap);
    var v = row[path];

    if(v.error != null){
      return null;
    }

    if(conditions == null || conditions.isEmpty){
      if(outType == OutType.JSON)
        return v;
      else
        return json.decode(v.rawString());
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
        if(outType == OutType.JSON)
          return v;
        else
          return json.decode(v.rawString());
      }
    }

    return null;
  }

  static dynamic updateAs(Map jsonMap, dynamic value, Conditions? conditions, {List path = const []}) {
    final row = JSON(jsonMap);
    var rowPath = row[path];

    if(rowPath.error != null){
      return jsonMap;
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
          for(final me in value.entries){
            row[me.key] = me.value;
          }
        }
        else {
          return json.decode(row.rawString());
        }
      }
      else {
        if(value is Map){
          for(final me in value.entries){
            rowPath[me.key] = me.value; //row[path][me.key] = me.value;
          }
        }
        else {
          row[path] = value;
        }
      }
    }

    return json.decode(row.rawString());
  }

  static dynamic deleteAs(Map jsonMap, List path, Conditions? conditions) {
    final row = JSON(jsonMap);
    var v = row[path];

    if(path.isEmpty || v.error != null){
      return jsonMap;
    }

    if(conditions == null || conditions.isEmpty){
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
      }
    }

    return json.decode(row.rawString());
  }
}