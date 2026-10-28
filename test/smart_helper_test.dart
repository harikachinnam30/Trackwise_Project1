import 'package:flutter_test/flutter_test.dart';
import 'package:habit_mastery_league/smart_helper.dart';
void main() {
  test('empty history',()=>expect(recommendTarget([],60).target,60));
  test('high average',()=>expect(recommendTarget([90,90],60).target,65));
  test('low average',()=>expect(recommendTarget([10,20],60).target,55));
  test('middle average',()=>expect(recommendTarget([60],60).target,60));
  test('upper boundary',()=>expect(recommendTarget([100],99).target,100));
  test('lower boundary',()=>expect(recommendTarget([0],1).target,1));
  test('negative history',()=>expect(()=>recommendTarget([-1],50),throwsArgumentError));
  test('oversized history value',()=>expect(()=>recommendTarget([101],50),throwsArgumentError));
  test('invalid target',()=>expect(()=>recommendTarget([],0),throwsArgumentError));
  test('baseline',()=>expect(baselineTarget(75),75));
  test('recent three',()=>expect(recommendTarget([90,90,90,0],60).target,65));
}
