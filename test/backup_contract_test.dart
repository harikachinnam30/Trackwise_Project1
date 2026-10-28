import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_league/smart_helper.dart';
void main(){
  test('tie at 80 is high',()=>expect(recommendTarget([80],50).target,55));
  test('tie at 40 remains same',()=>expect(recommendTarget([40],50).target,50));
  test('recent three excludes old outlier',()=>expect(recommendTarget([90,90,90,0],50).target,55));
  test('baseline is independent of history',()=>expect(baselineTarget(50),50));
}
