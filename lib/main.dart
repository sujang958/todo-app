// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:reorderables/reorderables.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        brightness: Brightness.light,
        fontFamily: "Pretendard",
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.black,
              displayColor: Colors.black,
            ),
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
        brightness: Brightness.dark,
        fontFamily: "Pretendard",
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {'/': (context) => HomeScreen()},
      locale: Locale("en"),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _prefListKey = "__todos_sujang";
  final List<Todo> _todos = [];

  bool _isInitializing = true;
  Map<int, bool> _todosEditingMap = {};

  final editingTodoController = TextEditingController();
  final addingTodoController = TextEditingController();
  final addingTodoFocusNode = FocusNode();

  @override
  void dispose() {
    addingTodoController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setTodosFromPrefList();
  }

  void _setTodosFromPrefList() async {
    setState(() {
      _isInitializing = true;
    });
    final todosFromPref = await _getTodoFromPrefList();
    setState(() {
      _todos.addAll(todosFromPref);
      _setTodosEditingMap();
      _isInitializing = false;
    });
  }

  void _setTodosEditingMap() {
    setState(() {
      _todos.asMap().entries.map((e) {
        _todosEditingMap[e.key] = false;
      });
    });
  }

  void _addTodo(String todoContent) async {
    if (todoContent.trim().isEmpty) return;
    addingTodoController.text = '';
    addingTodoFocusNode.requestFocus();
    Todo addedTodo = Todo(todoContent, false);
    setState(() {
      _todos.add(addedTodo);
      _setTodosEditingMap();
    });
    _addTodoToPrefList(addedTodo);
  }

  void _removeTodo(int index) async {
    setState(() {
      _todos.removeAt(index);
      _setTodosEditingMap();
      _assignPrefToTodos(_todos);
    });
  }

  void _updateTodo(int index, String newTodo) async {
    // setState(() {
      final prev = _todos.removeAt(index);
      _todos.insert(index, Todo(newTodo, prev.checked));
    _setTodosEditingMap();
      _assignPrefToTodos(_todos);
    // });
  }

  void _assignPrefToTodos(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefListKey, todos.map((todo) => json.encode(todo.toJson())).toList());
  }

  Future<List<Todo>> _getTodoFromPrefList() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedTodos = prefs.getStringList(_prefListKey);
    if (encodedTodos == null) return <Todo>[];
    return encodedTodos
        .map((encodedTodo) => json.decode(encodedTodo))
        .map((decodedTodo) => Todo(decodedTodo['todo'], decodedTodo['checked']))
        .toList();
  }

  void _addTodoToPrefList(Todo todo) async {
    final prevs = await _getTodoFromPrefList();
    prevs.add(todo);
    _assignPrefToTodos(prevs);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: CircularProgressIndicator(
          color: Colors.white,
          backgroundColor: Colors.black,
        )),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CupertinoTextField(
                controller: addingTodoController,
                placeholder: "Add your to-dos",
                padding: const EdgeInsets.symmetric(
                    vertical: 12.0, horizontal: 10.0),
                suffix: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: const Icon(CupertinoIcons.add),
                    onTap: () => (_addTodo(addingTodoController.text))),
                onSubmitted: (_) => (_addTodo(addingTodoController.text)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
              ),
              Expanded(
                  child: ReorderableListView.builder(
                      onReorder: ((oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _todos.removeAt(oldIndex);
                          _todos.insert(newIndex, item);
                          _assignPrefToTodos(_todos);
                        });
                      }),
                      itemCount: _todos.length,
                      physics: BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final todo = _todos.elementAt(index);
                        final textController =
                            TextEditingController(text: todo.todo);

                        textController.addListener(() {
                          _updateTodo(index, textController.text);
                        });

                        return Padding(
                            key: Key(index.toString()),
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Slidable(
                                startActionPane: ActionPane(
                                  motion: BehindMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        setState(() {
                                          todo.setChecked(!todo.checked);
                                          _assignPrefToTodos(_todos);
                                        });
                                      },
                                      icon: todo.checked
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      backgroundColor: todo.checked
                                          ? Color.fromARGB(255, 47, 235, 84)
                                          : Color.fromARGB(255, 173, 177, 182),
                                      foregroundColor: Colors.white,
                                    )
                                  ],
                                ),
                                endActionPane: ActionPane(
                                  motion: BehindMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (context) {
                                        showCupertinoModalPopup(
                                            context: context,
                                            builder: (context) =>
                                                CupertinoAlertDialog(
                                                  title: Text("For sure?"),
                                                  actions: [
                                                    CupertinoDialogAction(
                                                        onPressed: () {
                                                          _removeTodo(index);
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        isDestructiveAction:
                                                            true,
                                                        child: Text("Yup")),
                                                    CupertinoDialogAction(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                        child: Text("Nah")),
                                                  ],
                                                ));
                                      },
                                      icon: CupertinoIcons.delete_left,
                                      backgroundColor: Colors.red.shade700,
                                      foregroundColor: Colors.white,
                                    )
                                  ],
                                ),
                            child: CupertinoTextField(
                              enabled: _todosEditingMap[index] ?? true,
                                  style: TextStyle(
                                decoration: todo.checked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                              onTap: () {
                                print("tap");
                                final editingState = _todosEditingMap[index];
                                if (editingState == null) return;
                                setState(() {
                                  _todosEditingMap[index] = !editingState;
                                });
                              },
                              controller: textController,
                              textDirection: TextDirection.ltr,
                                  minLines: 1,
                                  maxLines: 4,
                                  padding: EdgeInsets.symmetric(
                                      vertical: 14.0, horizontal: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(13.0),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 1.2),
                              ),
                            ),
                          ),
                        );
                        // return ListTile(
                        //   shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(30)),
                        //   horizontalTitleGap: 4.0,
                        //   contentPadding: const EdgeInsets.symmetric(
                        //       horizontal: 0.0, vertical: 1.0),
                        //   leading: Container(
                        //       height: double.infinity,
                        //       child: Checkbox(
                        //     shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(4.0)),
                        //     value: todo.checked,
                        //     onChanged: (checked) => setState(() {
                        //       todo.setChecked(checked ?? !todo.checked);
                        //     }),
                        //   )),
                        //   // title: Text(
                        //   //   todo.todo,
                        //   //   style: TextStyle(
                        //   //       decoration: todo.checked
                        //   //           ? TextDecoration.lineThrough
                        //   //           : TextDecoration.none),
                        //   // ),
                        //   title: CupertinoTextField(
                        //     minLines: 1,
                        //     maxLines: 4,
                        //     controller:
                        //         TextEditingController(text: "hello\nhello"),
                        //   ),
                        //   key: Key(todo.hashCode.toString()),
                        // );
                      })),
            ],
          ),
        ),
      ),
    );
  }
}

class Todo {
  String todo;
  bool checked;

  Todo(this.todo, this.checked);

  setChecked(bool checked) {
    this.checked = checked;
  }

  toggleChecked() {
    checked = !checked;
  }

  Map<String, dynamic> toJson() => {"todo": todo, "checked": checked};
}
