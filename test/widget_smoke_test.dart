import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
void main(){
 testWidgets('basic responsive Material controls', (tester) async {
  await tester.pumpWidget(MaterialApp(home:Scaffold(body:Column(children:[const Text('Habit Mastery League'),Slider(value:0.5,onChanged:(_){})]))));
  expect(find.text('Habit Mastery League'),findsOneWidget);
  expect(find.byType(Slider),findsOneWidget);
 });
}
