// ignore_for_file: prefer_const_constructors

import 'dart:collection';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
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
  final List<Todo> _todos = [Todo("not done", false), Todo("done", true)];

  final addingTodoController = TextEditingController();

  @override
  void dispose() {
    addingTodoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          backgroundColor: Colors.black,
          body: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 42.0, horizontal: 24.0),
                child: TextField(
                  onSubmitted: (value) => setState(() {
                    _todos.add(Todo(value, false));
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
                          _todos.add(
                              Todo(addingTodoController.value.text, false));
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
                                vertical: 3.0, horizontal: 1.5),
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
                                      scale: 1.1,
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
                                      _todos.removeAt(index);
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
  String uid;

  Todo(this.todo, this.checked, this.uid);

  setChecked(bool checked) {
    this.checked = checked;
  }
}

class TodoList {
  final String StorageKey = "__todos_sujang";
  final uuid = Uuid();

  final List<Todo> todos = [];
  final Queue<Todo> todosWaitingToBeAdded = Queue();

  bool unabledToEditTodos = true;

  TodoList() {
    loadTodosFromStorage();
  }

  loadTodosFromStorage() async {
    unabledToEditTodos = true;
    final list = await getListFromStorage();
    todos.addAll(list.map((todo) => json.decode(todo) as Todo));
    addWaitedTodosToStorage();
    unabledToEditTodos = false;
  }

  addWaitedTodosToStorage() {
    setPrefsToList(todosWaitingToBeAdded
        .toList()
        .map((waitedTodo) => json.encode(waitedTodo))
        .toList());
  }

  add(String todo) async {
    Todo addedTodo = Todo(todo, false);
    todos.add(addedTodo);
    final prevs = await getListFromStorage();
    final encodedAddedTodo = json.encode(addedTodo);
    prevs.add(encodedAddedTodo);
    setPrefsToList(prevs);
  }

  remove(int index) {
    todos.removeAt(index);
  }

  Future<List<String>> getListFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(StorageKey) ?? <String>[];
  }

  setPrefsToList(List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(StorageKey, list);
  }
}
