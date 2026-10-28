import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/database/database_helper.dart';
import 'smart_helper.dart';
import 'streaks.dart';

final appProvider = ChangeNotifierProvider<AppState>((ref) => AppState()..load());

class AppState extends ChangeNotifier {
  final db = DatabaseHelper.instance;
  List<Map<String, Object?>> habits = [], activities = [];
  bool dark = false, busy = true;
  String? error;
  Future<void> load() async {
    busy = true; notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      dark = prefs.getBool('dark') ?? false;
      habits = await db.habits(); activities = await db.activities(); error = null;
    } catch (e) { error = '$e'; }
    busy = false; notifyListeners();
  }
  Future<void> setDark(bool value) async { dark = value; notifyListeners(); await (await SharedPreferences.getInstance()).setBool('dark', value); }
  Future<void> execute(Future<void> Function() action) async {
    try { await action(); await load(); } catch (e) { error = '$e'; notifyListeners(); rethrow; }
  }
}
void main() => runApp(const ProviderScope(child: HabitApp()));
class HabitApp extends ConsumerWidget {
  const HabitApp({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    return MaterialApp(debugShowCheckedModeBanner: false, title: 'TrackWise', theme: trackTheme(Brightness.light), darkTheme: trackTheme(Brightness.dark), themeMode: state.dark ? ThemeMode.dark : ThemeMode.light, home: const Home());
  }
}
class Home extends ConsumerStatefulWidget { const Home({super.key}); @override ConsumerState<Home> createState() => _HomeState(); }
class _HomeState extends ConsumerState<Home> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final pages = [const Dashboard(), const HabitEditor(), const ActivityPage(), const InsightsPage(), const SettingsPage()];
    return Scaffold(appBar: AppBar(title: const Text('TrackWise', style: TextStyle(fontWeight: FontWeight.w800)), centerTitle: false), body: state.busy ? const Center(child: CircularProgressIndicator()) : Column(children: [if(state.error != null) MaterialBanner(content: Text(state.error!), actions: [TextButton(onPressed: () => ref.read(appProvider).load(), child: const Text('Retry'))]), Expanded(child: pages[tab])]), bottomNavigationBar: NavigationBar(selectedIndex: tab, onDestinationSelected: (i) => setState(() => tab = i), destinations: const [NavigationDestination(icon: Icon(Icons.dashboard), label: 'Habits'), NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Editor'), NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'Activity'), NavigationDestination(icon: Icon(Icons.insights), label: 'Insights'), NavigationDestination(icon: Icon(Icons.settings), label: 'Settings')]));
  }
}
Future<bool> confirm(BuildContext context, String title) async => await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text(title), content: const Text('This cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(c,false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c,true), child: const Text('Delete'))])) ?? false;
void showError(BuildContext context, Object error) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error'))); }
bool isCompletedOnDay(Map<String, Object?> activity, String day) {
  final date = DateTime.tryParse('${activity['created_at']}')?.toLocal();
  return date != null && dayKey(date) == day;
}

const twIndigo = Color(0xFF5865E8);
const twTeal = Color(0xFF14A88A);
const twAmber = Color(0xFFF3A437);
const twPurple = Color(0xFF9470DE);

ThemeData trackTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: twIndigo, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF111629) : const Color(0xFFF5F7FF),
    appBarTheme: AppBarTheme(backgroundColor: dark ? const Color(0xFF181F34) : const Color(0xFFF5F7FF), elevation: 0),
    cardTheme: CardThemeData(elevation: 0, color: dark ? const Color(0xFF1E2940) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    inputDecorationTheme: InputDecorationTheme(filled: true,
      fillColor: dark ? const Color(0xFF1E2940) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      backgroundColor: twIndigo, foregroundColor: Colors.white, minimumSize: const Size(0, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: dark ? const Color(0xFF181F34) : Colors.white,
      indicatorColor: dark ? const Color(0xFF3C4788) : const Color(0xFFE5E9FF), height: 76),
  );
}

class MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const MetricCard({super.key, required this.label, required this.value, required this.icon, required this.color});
  @override Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 26), const SizedBox(height: 10),
      Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ])));
}

class WeeklyStreak extends StatelessWidget {
  final StreakStats stats;
  const WeeklyStreak({super.key, required this.stats});
  @override Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    const labels = ['M','T','W','T','F','S','S'];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your weekly consistency', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
          final date = monday.add(Duration(days: i));
          final checked = stats.completedDays.contains(dayKey(date));
          return Column(children: [Text(labels[i]), const SizedBox(height: 7),
            Container(width: 35, height: 35, decoration: BoxDecoration(
              color: checked ? twIndigo : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle), alignment: Alignment.center,
              child: checked ? const Icon(Icons.check, color: Colors.white, size: 19)
                : Text('${date.day}', style: const TextStyle(fontSize: 12))) ]);
        })),
      ])));
  }
}

class Dashboard extends ConsumerStatefulWidget { const Dashboard({super.key}); @override ConsumerState<Dashboard> createState()=>_DashboardState(); }
class _DashboardState extends ConsumerState<Dashboard> {
  String query=''; String category='All';
  @override Widget build(BuildContext context) {
    final s=ref.watch(appProvider);
    final stats = calculateStreak(s.activities);
    final today = dayKey(DateTime.now());
    final completedToday = s.activities.where((a) => a['completed'] == 1 &&
      isCompletedOnDay(a, today)).map((a) => a['habit_id']).toSet();
    final filtered=s.habits.where((h)=>'${h['title']}'.toLowerCase().contains(query.toLowerCase()) && (category=='All'||h['category']==category)).toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF5865E8), Color(0xFF9678EA)]),
        borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Welcome to TrackWise', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6), const Text('Small steps. Big progress.', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 14), Row(children: [const Icon(Icons.local_fire_department, color: Color(0xFFFFD98B)),
            const SizedBox(width: 8), Text('${stats.current} day streak', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
        ])),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: MetricCard(label: 'Active habits', value: '${s.habits.length}', icon: Icons.track_changes, color: twIndigo)),
        Expanded(child: MetricCard(label: 'Best streak', value: '${stats.longest} days', icon: Icons.emoji_events, color: twAmber))]),
      Row(children: [Expanded(child: MetricCard(label: 'Done today', value: '${completedToday.length}/${s.habits.length}', icon: Icons.check_circle, color: twTeal)),
        Expanded(child: MetricCard(label: 'Activity logs', value: '${s.activities.length}', icon: Icons.insights, color: twPurple))]),
      WeeklyStreak(stats: stats), const SizedBox(height: 14),
      Text('Your habits', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search habits'), onChanged:(v)=>setState(()=>query=v)),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'Category'),
        items: ['All','Study','Health','Creative','Other'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),
        onChanged:(v)=>setState(()=>category=v??'All')),
      const SizedBox(height: 12),
      if (s.habits.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        const Icon(Icons.auto_awesome, color: twIndigo, size: 42), const SizedBox(height: 10),
        const Text('Start your first habit', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5), const Text('Open the Editor tab to create a habit.', textAlign: TextAlign.center),
      ])))
      else if (filtered.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text('No matching habits')),
      for (final h in filtered) Builder(builder: (context) {
        final id = h['id'] as int;
        final habitStreak = calculateStreak(s.activities, habitId: id);
        final done = completedToday.contains(id);
        return Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: ListTile(
          leading: CircleAvatar(backgroundColor: done ? const Color(0xFFDDF7EE) : const Color(0xFFE8EBFF),
            child: Icon(done ? Icons.check : Icons.track_changes, color: done ? twTeal : twIndigo)),
          title: Text('${h['title']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${h['category']}  •  ${habitStreak.current} day streak  •  Target ${h['target']}%'),
          trailing: PopupMenuButton<String>(tooltip: 'Habit actions', onSelected: (action) async {
            if (action == 'edit') {
              if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Edit habit')), body: HabitEditor(existing: h))));
            } else if (action == 'delete') {
              if (await confirm(context, 'Delete habit and its history?') && context.mounted) {
                try { await ref.read(appProvider).execute(() => s.db.deleteHabit(id)); }
                catch (e) { if (context.mounted) showError(context, e); }
              }
            } else if (action == 'complete') {
              try { await ref.read(appProvider).execute(() => s.db.saveActivity(
                habitId: id, note: 'Quick completion', progress: 100, completed: true).then((_) {})); }
              catch (e) { if (context.mounted) showError(context, e); }
            }
          }, itemBuilder: (_) => [
            if (!done) const PopupMenuItem(value: 'complete', child: Text('✓ Complete today')),
            const PopupMenuItem(value: 'edit', child: Text('Edit habit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete habit')),
          ]),
        )));
      }),
      const SizedBox(height: 20),
    ]);
  }
}
class HabitEditor extends ConsumerStatefulWidget { final Map<String,Object?>? existing; const HabitEditor({super.key,this.existing}); @override ConsumerState<HabitEditor> createState() => _HabitEditorState(); }
class _HabitEditorState extends ConsumerState<HabitEditor> {
  final form = GlobalKey<FormState>(); late final TextEditingController title; String category='Study'; double target=60;
  @override void initState(){super.initState(); title=TextEditingController(text: '${widget.existing?['title'] ?? ''}'); category='${widget.existing?['category'] ?? 'Study'}'; target=((widget.existing?['target'] as int?) ?? 60).toDouble();}
  @override void dispose(){title.dispose();super.dispose();}
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [Text(widget.existing == null ? 'Create a habit' : 'Edit habit', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 16), Form(key: form, child: TextFormField(controller: title, decoration: const InputDecoration(labelText: 'Habit title', border: OutlineInputBorder()), maxLength: 60, validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null)), const SizedBox(height: 12), DropdownButtonFormField<String>(initialValue: category, decoration: const InputDecoration(labelText: 'Category'), items: ['Study','Health','Creative','Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => category = v ?? category)), const SizedBox(height: 12), Text('Target: ${target.round()}%'), Slider(value: target, min: 1, max: 100, divisions: 99, label: '${target.round()}%', onChanged: (v) => setState(() => target=v)), FilledButton.icon(icon: const Icon(Icons.save), label: const Text('Save habit'), onPressed: () async {if(!form.currentState!.validate())return; try {await ref.read(appProvider).execute(() async {await ref.read(appProvider).db.saveHabit(id: widget.existing?['id'] as int?, title: title.text, category: category, target: target.round());}); if(context.mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Habit saved'))); if(widget.existing != null) Navigator.pop(context); else {title.clear();}}} catch(e){if(context.mounted)showError(context,e);} })]);
}
class ActivityPage extends ConsumerStatefulWidget { const ActivityPage({super.key}); @override ConsumerState<ActivityPage> createState() => _ActivityPageState(); }
class _ActivityPageState extends ConsumerState<ActivityPage> {
  int? selected; double progress=0; final note=TextEditingController(); bool completed=false; int? editing;
  @override void dispose(){note.dispose();super.dispose();}
  @override Widget build(BuildContext context){ final s=ref.watch(appProvider); if(s.habits.isEmpty)return const Center(child: Text('Create a habit first.'));
    if(selected != null && !s.habits.any((h)=>h['id']==selected)) selected=null;
    selected ??= s.habits.first['id'] as int;
    final records=s.activities.where((a)=>a['habit_id']==selected).toList();
    final past=records.map((a)=>a['progress'] as int).toList();
    final current=s.habits.firstWhere((h)=>h['id']==selected);
    final suggestion=recommendTarget(past,current['target'] as int);
    return ListView(padding: const EdgeInsets.all(16), children: [DropdownButtonFormField<int>(key: ValueKey(selected), initialValue:selected, decoration: const InputDecoration(labelText: 'Choose habit'), items:s.habits.map((h)=>DropdownMenuItem(value:h['id'] as int,child:Text('${h['title']}'))).toList(), onChanged:(v)=>setState((){selected=v;editing=null;progress=0;note.clear();completed=false;})), const SizedBox(height:12), Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Local smart helper',style:TextStyle(fontWeight:FontWeight.bold)),Text('Suggested target: ${suggestion.target}%'),Text(suggestion.reason), const Text('Suggested, not guaranteed.'),Wrap(children:[TextButton(onPressed:()=>setState(()=>progress=suggestion.target.toDouble()),child:const Text('Apply to progress')),TextButton(onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Suggestion dismissed'))),child:const Text('Not now'))])]))),Text('Progress: ${progress.round()}%'),Slider(value:progress,min:0,max:100,divisions:100,onChanged:(v)=>setState(()=>progress=v)),TextField(controller:note,decoration:const InputDecoration(labelText:'Activity note (optional)')),CheckboxListTile(value:completed,title:const Text('Mark complete'),onChanged:(v)=>setState(()=>completed=v??false)),FilledButton(onPressed:()async{try{await ref.read(appProvider).execute(() async {await s.db.saveActivity(id:editing,habitId:selected!,note:note.text,progress:progress.round(),completed:completed);});setState((){editing=null;note.clear();progress=0;completed=false;});}catch(e){if(context.mounted)showError(context,e);}},child:Text(editing==null?'Save activity':'Update activity')),TextButton(onPressed:()=>setState((){editing=null;note.clear();progress=0;completed=false;}),child:const Text('Reset form')),const Divider(),Text('Activity history (${records.length})',style:Theme.of(context).textTheme.titleMedium),for(final a in records) Card(child:ListTile(title:Text('${a['progress']}% ${a['completed']==1?'• Finished':'• In progress'}'),subtitle:Text('${a['note']}'),onTap:()=>setState((){editing=a['id'] as int;progress=(a['progress'] as int).toDouble();completed=a['completed']==1;note.text='${a['note']}';}),trailing:IconButton(icon:const Icon(Icons.delete_outline),tooltip:'Delete activity',onPressed:()async{if(await confirm(context,'Delete activity?') && context.mounted){try{await ref.read(appProvider).execute(()=>s.db.deleteActivity(a['id'] as int));}catch(e){if(context.mounted)showError(context,e);}}}))) ]);
  }
}
class InsightsPage extends ConsumerStatefulWidget {const InsightsPage({super.key});@override ConsumerState<InsightsPage> createState()=>_InsightsPageState();}
class _InsightsPageState extends ConsumerState<InsightsPage>{bool completedOnly=false;@override Widget build(BuildContext context){final s=ref.watch(appProvider);final filtered=s.activities.where((a)=>!completedOnly||a['completed']==1).toList();final done=s.activities.where((a)=>a['completed']==1).length;return ListView(padding:const EdgeInsets.all(16),children:[Text('Total habits: ${s.habits.length}',style:Theme.of(context).textTheme.titleLarge),Text('Activities: ${s.activities.length} • Completed: $done'),Text('Completion rate: ${s.activities.isEmpty?'0':(done*100/s.activities.length).toStringAsFixed(1)}%'),const SizedBox(height:16),const Text('Progress visualization (last 10 activities)'),for(final a in s.activities.take(10)) Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[SizedBox(width:42,child:Text('${a['progress']}%')),Expanded(child:LinearProgressIndicator(value:(a['progress'] as int)/100,minHeight:12))])),SwitchListTile(title:const Text('Completed activities only'),value:completedOnly,onChanged:(v)=>setState(()=>completedOnly=v)),if(filtered.isEmpty)const Text('No matching activity yet.'),for(final a in filtered)ListTile(title:Text('${a['progress']}% • ${a['completed']==1?'Complete':'In progress'}'),subtitle:Text('${a['note']}'))]);}}
class SettingsPage extends ConsumerStatefulWidget { const SettingsPage({super.key}); @override ConsumerState<SettingsPage> createState()=>_SettingsPageState(); }
class _SettingsPageState extends ConsumerState<SettingsPage> {
  String message='';
  Future<File> backupFile() async { final directory=await getApplicationDocumentsDirectory(); return File('${directory.path}/habit_mastery_backup.json'); }
  Future<void> exportBackup() async {
    try { final snapshot=await ref.read(appProvider).db.exportSnapshot(); final file=await backupFile(); await file.writeAsString(const JsonEncoder.withIndent('  ').convert(snapshot),flush:true); if(mounted)setState(()=>message='Exported to ${file.path}'); }
    catch(e){if(mounted)showError(context,e);}
  }
  Future<void> importBackup() async {
    if(!await confirm(context,'Replace ALL current data with the local backup?') || !mounted)return;
    try { final file=await backupFile(); if(!await file.exists())throw const FormatException('No local backup found. Export first.'); final data=jsonDecode(await file.readAsString()); if(data is! Map<String,dynamic>)throw const FormatException('Invalid JSON backup'); await ref.read(appProvider).db.importSnapshot(data); await ref.read(appProvider).load(); if(mounted)setState(()=>message='Backup restored successfully'); }
    catch(e){if(mounted)showError(context,e);}
  }
  @override Widget build(BuildContext context){ final s=ref.watch(appProvider);return ListView(padding:const EdgeInsets.all(12),children:[SwitchListTile(title:const Text('Dark mode'),subtitle:const Text('Saved on this device'),value:s.dark,onChanged:(v)=>ref.read(appProvider).setDark(v)),const ListTile(title:Text('Privacy'),subtitle:Text('Habits and activities are stored locally in SQLite. No cloud backend.')),const Divider(),const ListTile(title:Text('Local JSON backup'),subtitle:Text('Export/import to the app documents directory. Import replaces current records after confirmation.')),FilledButton.icon(onPressed:exportBackup,icon:const Icon(Icons.file_download),label:const Text('Export JSON backup')),OutlinedButton.icon(onPressed:importBackup,icon:const Icon(Icons.file_upload),label:const Text('Restore local JSON backup')),if(message.isNotEmpty)SelectableText(message),ListTile(title:const Text('Refresh local data'),trailing:const Icon(Icons.refresh),onTap:()=>ref.read(appProvider).load())]); }
}
