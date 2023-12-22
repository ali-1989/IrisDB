import 'package:g_json/g_json.dart';

class Conditions {
  final List<Condition> _andList = [];
  final List<List<Condition>> _orList = [];
  bool exceptionSafe = true;

  bool get isEmpty {
    return _andList.isEmpty && _orList.isEmpty;
  }

  void clearConditions(){
    _andList.clear();
  }

  void clearOr(){
    _orList.clear();
  }

  Conditions add(Condition condition) {
    _andList.add(condition);
    return this;
  }

  Conditions addOr(List<Condition> or) {
    _orList.add(or);
    return this;
  }

  List<Condition> get andConditions => _andList;
  List<List<Condition>> get orConditions => _orList;

  @override
  String toString() {
    var res = '[Conditions]\n';
    res += ' - AND:\n';

    for(final i in _andList){
      res += ' -- (${i.type}) ${i.key} : ${i.value},  path:${i.path}\n';
    }

    res += ' - OR:\n';

    for(final i in _orList){
      for(final j in i){
        res += ' -- (${j.type}) ${j.key} : ${j.value},  path:${j.path}\n';
      }
      res += ' ----------\n';
    }

    res += ' --------- END ----------\n';

    return res;
  }
}
///=============================================================================
enum ConditionType {
  EQUAL,
  DefinedIsNull,
  DefinedNotNull,
  NotDefinedKey,
  DefinedKey,
  NotEqual,
  IN,
  NotIn,
  GT, /// for numbers
  GTE, /// for numbers
  LT, /// for numbers
  LTE, /// for numbers
  TestFn,
  RegExp,
  IsEmpty,
  IsNotEmpty,
  IsTrue,
  IsFalse,
  IsBeforeTs,
  IsAfterTs,
}
///=============================================================================
class Condition {
  ConditionType type = ConditionType.EQUAL;
  String? key;
  dynamic value;
  List? path;
  bool Function(dynamic value)? testFn;

  Condition([ConditionType? type]){
    if(type != null){
      this.type = type;
    }
  }

  @override
  String toString() {
    return '[Condition] -> ($type)  $key : $value,   path:$path';
  }
}
///=============================================================================
bool hasCondition(dynamic value, Conditions condition, bool debug){
  if(debug){
    var txt = '☼☼☼☼☼☼ IsisDB [conditions check]\n';
    txt += 'AND condition count: ${condition.andConditions.length}\n';
    txt += 'OR condition count: ${condition.orConditions.length}\n';
    txt += 'value type: ${value.runtimeType}\n';
    txt += '@---------------------------------\n';

    print(txt);
  }


  var allRes = true;

  if(condition.andConditions.isNotEmpty) {
    allRes &= _check(condition.andConditions, value, true, debug);
  }

  if(allRes) {
    for(final consList in condition.orConditions){
      allRes &= _check(consList, value,false, debug);
    }
  }

  return allRes;
}

bool _check(List<Condition> conditions, dynamic value, bool isAnd, bool debug) {
  bool res = true;
  dynamic curValue = value;
  var debugTxt = '☼☼☼☼☼☼ IsisDB [check]\n';

  for(var i = 0; i < conditions.length; i++) {
    var con = conditions.elementAt(i);

    if (con.path != null && con.path!.isNotEmpty) {
      debugTxt += 'with path: ${con.path}\n';

      var j = JSON(value);
      j = j[con.path];

      if (j.error == null) {
        curValue = j.value;
      }
      else {
        debugTxt += '::path error:: ${j.error}\n\n';

        if(isAnd || i == conditions.length-1) {
          res = false;
          break;
        }
        else {
          continue;
        }
      }
    }

    var checkWith;

    if (curValue is Map && con.key != null) {
      checkWith = curValue[con.key];
    }
    else{
      checkWith = curValue;
    }

    debugTxt += 'condition type: ${con.type.name}\n';
    debugTxt += 'data type: ${checkWith.runtimeType}\n';

    switch (con.type) {
      case ConditionType.EQUAL:
        if(con.value is BigInt){
          res &= BigInt.parse(checkWith.toString()) == con.value;
        }
        else {
          res &= checkWith == con.value;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.NotEqual:
        if(con.value is BigInt){
          res &= BigInt.parse(checkWith.toString()) == con.value;
        }
        else {
          res &= checkWith != con.value;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.NotDefinedKey:
        if (curValue is Map && con.key != null) {
          res &= !curValue.containsKey(con.key);
        }
        else
          res &= false;

        break;
    //---------------------------------------------------------
      case ConditionType.DefinedKey:
        if (curValue is Map && con.key != null) {
          res &= curValue.containsKey(con.key);
        }
        else
          res &= false;

        break;
    //---------------------------------------------------------
      case ConditionType.DefinedIsNull:
        if (curValue is Map && con.key != null) {
          res &= curValue.containsKey(con.key) && curValue[con.key] == null;
        }
        else //because is not defined key
          res &= false;

        break;
    //---------------------------------------------------------
      case ConditionType.DefinedNotNull:
        if (curValue is Map && con.key != null) {
          if(con.value == null) {
            res &= curValue.containsKey(con.key) && curValue[con.key] != null;
          }
          else {
            res &= curValue.containsKey(con.key) && curValue[con.key] == con.value;
          }
        }
        else { //because is not defined key
          res &= false;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.IN:
        if(con.value is List){
          if((con.value as List) is List<BigInt>){
            res &= (con.value as List).contains(BigInt.parse(checkWith.toString()));
          }
          else {
            res &= (con.value as List).contains(checkWith);
          }
        }

        break;
    //---------------------------------------------------------
      case ConditionType.NotIn:
        if(con.value is List){
          if((con.value as List) is List<BigInt>){
            res &= !(con.value as List).contains(BigInt.parse(checkWith.toString()));
          }
          else {
            res &= !(con.value as List).contains(checkWith);
            debugTxt += 'NotIn result: $res\n';
          }
        }

        break;
    //---------------------------------------------------------
      case ConditionType.GT:
        if(con.value is BigInt){
          res &= (con.value < BigInt.parse(checkWith.toString()));
        }
        else {
          res &= (con.value as num) < checkWith;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.GTE:
        if(con.value is BigInt){
          res &= (con.value <= BigInt.parse(checkWith.toString()));
        }
        else {
          res &= (con.value as num) <= checkWith;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.LT:
        if(con.value is BigInt){
          res &= (con.value > BigInt.parse(checkWith.toString()));
        }
        else {
          res &= (con.value as num) > checkWith;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.LTE:
        if(con.value is BigInt){
          res &= (con.value >= BigInt.parse(checkWith.toString()));
        }
        else {
          res &= (con.value as num) >= checkWith;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.TestFn:
        res &= con.testFn!(checkWith);

        break;
    //---------------------------------------------------------
      case ConditionType.RegExp:
        res &= (con.value as RegExp).hasMatch(checkWith);

        break;
    //---------------------------------------------------------
      case ConditionType.IsEmpty:
        if(checkWith is String)
          res &= checkWith.isEmpty;
        else if(checkWith is List)
          res &= checkWith.isEmpty;
        else if(checkWith is Map)
          res &= checkWith.isEmpty;
        else
          res &= false;

        break;
    //---------------------------------------------------------
      case ConditionType.IsNotEmpty:
        if(checkWith is String)
          res &= checkWith.isNotEmpty;
        else if(checkWith is List)
          res &= checkWith.isNotEmpty;
        else if(checkWith is Map)
          res &= checkWith.isNotEmpty;
        else
          res &= false;

        break;
    //---------------------------------------------------------
      case ConditionType.IsTrue:
        if(checkWith is bool) {
          res &= checkWith;
        }
        else {
          res &= false;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.IsFalse:
        if(checkWith is bool) {
          res &= !checkWith;
        }
        else {
          res &= false;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.IsBeforeTs:
        if(checkWith is String){
          checkWith = tsToSystemDate(checkWith);
        }

        DateTime v;
        if(con.value is String){
          v = tsToSystemDate(con.value)!;
        }
        else {
          v = con.value;
        }

        if(checkWith is DateTime) {
          res &= checkWith.isBefore(v);
        }
        else {
          res &= false;
        }

        break;
    //---------------------------------------------------------
      case ConditionType.IsAfterTs:
        if(checkWith is String){
          checkWith = tsToSystemDate(checkWith);
        }

        DateTime v;
        if(con.value is String){
          v = tsToSystemDate(con.value)!;
        }
        else {
          v = con.value;
        }


        if(checkWith is DateTime) {
          res &= checkWith.isAfter(v);
        }
        else {
          res &= false;
        }

        break;
    //---------------------------------------------------------
      default:
        res &= false;
    }

    if(debug){
      print(debugTxt);
    }

    if(!res){
      if(isAnd || i == conditions.length-1){
        return false;
      }
      else {
        res = true;
      }
    }
    else {
      if(!isAnd){
        return true;
      }
    }
  }

  return res;
}

///=============================================================================
DateTime? tsToSystemDate(String? ts){
  if(ts == null){
    return null;
  }

  try {
    return DateTime.parse(ts);
  }
  catch(e){
    return null;
  }
}
