import 'package:iris_db/iris_db.dart';
import 'package:iris_db/json_query.dart';

typedef ff = Function();

void main() async {
  await test();
  //db();
  //json();
}
///========================================================================================
void db() async {
  IrisDB db = IrisDB();
  //await db.openDoc('myDb');
  await db.openDoc('Users');

  //-------insert --------------------------------------------------------
  //await db.insert('myDb', {"k1":  'aa', "k2":  'bb', 'k3': {'s1': 'ali', 's2': [1,2]}});
  //------ update ---------------------------------------------------------
  //var newVal = 'newVal';
  //var newVal = {'k1': 'v100'};

  //var upCon = Conditions();
  //await db.update('kv', newVal, upCon);
  //await db.replace('kv', newVal, upCon,);
  //------ replace ---------------------------------------------------------
  /*var repCon = Conditions();
  repCon.add(Condition()..key = 'k1'..value = 'aa2');

  var newVal = {'k1': 'newA2'};

  await db.replace('myDb', newVal, repCon, );*/
  //----- read ----------------------------------------------------------
  var con = Conditions();
  //con.add(Condition()..key = 'k1'..value ='v1');

  /*con.addOr([
    Condition()..key = 'k2'..value ='v2',
    Condition()..key = 'k2'..value ='iris',
  ]);

  con.addOr([
    Condition(ConditionType.DefinedNotNull)..key = 'k4',
    Condition(ConditionType.DefinedIsNull)..key = 'k2',
  ]);*/

  var read = db.find('Users', con);

  for(var r in read) {
    print('$r ');
  }
}
///========================================================================================
void json(){
  Map m = {};
  m['k1'] = 'v1';
  m['k2'] = 'v2';
  m['k3'] = [1, 2, 3];
  m['k4'] = {'s1': 's1', 's2': [5,6,7], 's3': {'ss1': 'ok'}};


  print('-------- update ------------');
  var con = Conditions();
  //var up = JsonQuery.updateAs(m, ['k3'], [5,5], con);
  //var up = JsonQuery.updateAs(m, ['k3', 0], 100, con);
  //var up = JsonQuery.updateAs(m, ['k4', 's3', 'ss1'], 100, con);
  var up = JsonQuery.updateAs(m, 100, con, path: ['k4', 's2', 1]);
  print(up);
  print('----- find ---------------');
  var con2 = Conditions();
  con2.add(Condition()..key = 'k1'..value = 'v1');
  //con2.add(Condition()..path = ['k3', 0]..value = 1);

  var find = JsonQuery.find(m, con2);
  print(find);
  print('-------- delete ------------');
  var con3 = Conditions();
  //con3.add(Condition()..key = 'k1'..value = 'v1');
  //con3.add(Condition()..path = ['k3', 0]..value = 1);

  //var del = JsonQuery.delete(m, ['k3'], con3);
  var del = JsonQuery.deleteAs(m, ['k3', 0], con3);
  print(del);
}
///========================================================================================
Future test() async {
  IrisDB db = IrisDB();
  await db.openDoc('testTb');

  await db.insert('testTb', {"k1":  'aa', "k2":  'bb', 'k3': 'mustDelete'});

  var res = await db.find ('testTb', Conditions());
  print(res);
  //--------------------------------
  final con = Conditions();
  con.add(Condition(ConditionType.DefinedKey)..key = 'k3');

  //await db.delete('testTb', Conditions(), path: ['k3']);
  await db.deleteKey('testTb', Conditions(), 'k3');
  
  res = await db.find('testTb', Conditions());
  print(res);
}