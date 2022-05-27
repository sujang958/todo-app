// ignore_for_file: prefer_const_constructors

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(fontFamily: "Pretendard"),
      initialRoute: '/',
      routes: {'/': (context) => HomeScreen()},
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
      _isInitializing = false;
    });
  }

  void _addTodo(String todoContent) async {
    if (todoContent.trim().isEmpty) return;
    addingTodoController.text = '';
    addingTodoFocusNode.requestFocus();
    Todo addedTodo = Todo(todoContent, false);
    setState(() {
      _todos.add(addedTodo);
    });
    _addTodoToPrefList(addedTodo);
  }

  void _removeTodo(int index) async {
    setState(() {
      _todos.removeAt(index);
      _assignPrefToTodos(_todos);
    });
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

    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 42.0, horizontal: 24.0),
                child: TextField(
                  focusNode: addingTodoFocusNode,
                  keyboardType: TextInputType.text,
                  onSubmitted: (value) => setState(() {
                    _addTodo(addingTodoController.value.text);
                  }),
                  controller: addingTodoController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14.0)),
                        borderSide: BorderSide(style: BorderStyle.none)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14.0)),
                        borderSide: BorderSide(style: BorderStyle.none)),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _addTodo(addingTodoController.value.text);
                        });
                      },
                      icon: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 26.0,
                      ),
                      enableFeedback: true,
                      splashColor: Colors.transparent,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
                    hintText: "Add some to-dos!",
                    hintStyle: TextStyle(color: Colors.grey[300]),
                    filled: true,
                    fillColor: Colors.grey[900],
                  ),
                ),
              ),
              Expanded(
                  child: ListView.builder(
                      padding:
                          EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
                      itemCount: _todos.length,
                      itemBuilder: (context, index) {
                        final todo = _todos.elementAt(index);
                        return AnimatedContainer(
                            curve: Curves.easeInOut,
                            duration: Duration(milliseconds: 400),
                            margin: EdgeInsets.only(bottom: 16.0),
                            padding: EdgeInsets.symmetric(
                                vertical: 1.1, horizontal: 1.5),
                            foregroundDecoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(24.0)),
                              backgroundBlendMode: BlendMode.exclusion,
                              color: todo.checked
                                  ? Colors.grey[900]
                                  : Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Transform.scale(
                                      scale: 1.08,
                                      child: Checkbox(
                                        activeColor: Colors.white,
                                        checkColor: Colors.black,
                                        side: BorderSide(
                                          color: Colors.white,
                                          style: BorderStyle.solid,
                                          width: 1.5,
                                        ),
                                        shape: CircleBorder(),
                                        value: todo.checked,
                                        onChanged: (checkboxChecked) {
                                          if (checkboxChecked == null) return;
                                          setState(() {
                                            todo.setChecked(checkboxChecked);
                                          });
                                        },
                                      ),
                                    ),
                                    Text(
                                      todo.todo,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.0,
                                          decoration: todo.checked
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none),
                                    )
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _removeTodo(index);
                                    });
                                  },
                                  icon: Icon(
                                    Icons.delete_forever_rounded,
                                    color: Colors.white,
                                    size: 24.0,
                                  ),
                                  splashColor: Colors.transparent,
                                )
                              ],
                            ));
                      }))
            ],
          )),
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
