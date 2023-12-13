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
bool hasCondition(dynamic value, Conditions condition){

  bool check(List<Condition> list, bool isAnd) {
    bool res = true;
    dynamic obj = value;

    for(var i = 0; i < list.length; i++) {
      var con = list.elementAt(i);

      if (con.path != null && con.path!.isNotEmpty) {
        var j = JSON(value);
        j = j[con.path];

        if (j.error == null) {
          obj = j.value;
        }
        else {
          if(isAnd || i == list.length-1) {
            res = false;
            break;
          }
          else
            continue;
        }
      }

      var checker;

      if (obj is Map && con.key != null) {
        checker = obj[con.key];
      }
      else{
        checker = obj;
      }

      switch (con.type) {
        case ConditionType.EQUAL:
          if(con.value is BigInt){
            res &= BigInt.parse(checker.toString()) == con.value;
          }
          else {
            res &= checker == con.value;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.NotEqual:
          if(con.value is BigInt){
            res &= BigInt.parse(checker.toString()) == con.value;
          }
          else {
            res &= checker != con.value;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.NotDefinedKey:
          if (obj is Map && con.key != null) {
            res &= !obj.containsKey(con.key);
          }
          else
            res &= false;

          break;
      //---------------------------------------------------------
        case ConditionType.DefinedKey:
          if (obj is Map && con.key != null) {
            res &= obj.containsKey(con.key);
          }
          else
            res &= false;

          break;
      //---------------------------------------------------------
        case ConditionType.DefinedIsNull:
          if (obj is Map && con.key != null) {
            res &= obj.containsKey(con.key) && obj[con.key] == null;
          }
          else //because is not defined key
            res &= false;

          break;
      //---------------------------------------------------------
        case ConditionType.DefinedNotNull:
          if (obj is Map && con.key != null) {
            if(con.value == null) {
              res &= obj.containsKey(con.key) && obj[con.key] != null;
            }
            else {
              res &= obj.containsKey(con.key) && obj[con.key] == con.value;
            }
          }
          else //because is not defined key
            res &= false;

          break;
      //---------------------------------------------------------
        case ConditionType.IN:
          if((con.value as List) is List<BigInt>){
            res &= (con.value as List).contains(BigInt.parse(checker.toString()));
          }
          else {
            res &= (con.value as List).contains(checker);
          }

          break;
      //---------------------------------------------------------
        case ConditionType.NotIn:
          if((con.value as List) is List<BigInt>){
            res &= !(con.value as List).contains(BigInt.parse(checker.toString()));
          }
          else {
            res &= !(con.value as List).contains(checker);
          }

          break;
      //---------------------------------------------------------
        case ConditionType.GT:
          if(con.value is BigInt){
            res &= (con.value < BigInt.parse(checker.toString()));
          }
          else {
            res &= (con.value as num) < checker;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.GTE:
          if(con.value is BigInt){
            res &= (con.value <= BigInt.parse(checker.toString()));
          }
          else {
            res &= (con.value as num) <= checker;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.LT:
          if(con.value is BigInt){
            res &= (con.value > BigInt.parse(checker.toString()));
          }
          else {
            res &= (con.value as num) > checker;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.LTE:
          if(con.value is BigInt){
            res &= (con.value >= BigInt.parse(checker.toString()));
          }
          else {
            res &= (con.value as num) >= checker;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.TestFn:
          res &= con.testFn!(checker);

          break;
      //---------------------------------------------------------
        case ConditionType.RegExp:
          res &= (con.value as RegExp).hasMatch(checker);

          break;
      //---------------------------------------------------------
        case ConditionType.IsEmpty:
          if(checker is String)
            res &= checker.isEmpty;
          else if(checker is List)
            res &= checker.isEmpty;
          else if(checker is Map)
            res &= checker.isEmpty;
          else
            res &= false;

          break;
      //---------------------------------------------------------
        case ConditionType.IsNotEmpty:
          if(checker is String)
            res &= checker.isNotEmpty;
          else if(checker is List)
            res &= checker.isNotEmpty;
          else if(checker is Map)
            res &= checker.isNotEmpty;
          else
            res &= false;

          break;
      //---------------------------------------------------------
        case ConditionType.IsTrue:
          if(checker is bool) {
            res &= checker;
          }
          else {
            res &= false;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.IsFalse:
          if(checker is bool) {
            res &= !checker;
          }
          else {
            res &= false;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.IsBeforeTs:
          if(checker is String){
            checker = tsToSystemDate(checker);
          }

          DateTime v;
          if(con.value is String){
            v = tsToSystemDate(con.value)!;
          }
          else {
            v = con.value;
          }

          if(checker is DateTime) {
            res &= checker.isBefore(v);
          }
          else {
            res &= false;
          }

          break;
      //---------------------------------------------------------
        case ConditionType.IsAfterTs:
          if(checker is String){
            checker = tsToSystemDate(checker);
          }

          DateTime v;
          if(con.value is String){
            v = tsToSystemDate(con.value)!;
          }
          else {
            v = con.value;
          }


          if(checker is DateTime) {
            res &= checker.isAfter(v);
          }
          else {
            res &= false;
          }

          break;
      //---------------------------------------------------------
        default:
          res &= false;
      }

      if(!res){
        if(isAnd || i == list.length-1){
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

  var allRes = true;

  if(condition.andConditions.isNotEmpty) {
    allRes &= check(condition.andConditions, true);
  }

  if(allRes) {
    for(final consList in condition.orConditions){
      allRes &= check(consList, false);
    }
  }

  return allRes;
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
