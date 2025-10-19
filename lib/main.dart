import 'package:flutter/material.dart';
import 'database_helper.dart';

final dbHelper = DatabaseHelper();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SQFlite Task List',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: MyHomePage(
        isDarkMode: _isDarkMode,
        toggleTheme: _toggleTheme,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const MyHomePage({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _taskController = TextEditingController();
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    final data = await dbHelper.queryAllRows();
    setState(() => _tasks = data);
  }

  void _insert() async {
    final name = _taskController.text.trim();
    if (name.isEmpty) return;

    Map<String, dynamic> row = {
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnCompleted: 0,
    };
    await dbHelper.insert(row);
    _taskController.clear();
    await _refreshTasks();
  }

  void _delete(int id) async {
    await dbHelper.delete(id);
    await _refreshTasks();
  }

  void _deleteAll() async {
    await dbHelper.deleteAll();
    await _refreshTasks();
  }

  void _toggle(Map<String, dynamic> task) async {
    final updated = {
      DatabaseHelper.columnId: task[DatabaseHelper.columnId],
      DatabaseHelper.columnName: task[DatabaseHelper.columnName],
      DatabaseHelper.columnCompleted:
          (task[DatabaseHelper.columnCompleted] == 1) ? 0 : 1,
    };
    await dbHelper.update(updated);
    await _refreshTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List (SQFLite)'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode
              ? Icons.wb_sunny
              : Icons.dark_mode_outlined
            ),
            onPressed: widget.toggleTheme,
          ),

          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _deleteAll,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Enter new task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  onPressed: _insert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 58, 255, 58),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _tasks.isEmpty
                  ? const Center(child: Text('No tasks added yet.'))
                  : ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: Checkbox(
                              value: task[DatabaseHelper.columnCompleted] == 1,
                              onChanged: (_) => _toggle(task),
                            ),

                            title: Text(
                              task[DatabaseHelper.columnName]
                            ),

                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _delete(task[DatabaseHelper.columnId]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}