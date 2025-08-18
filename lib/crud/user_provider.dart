import 'package:flutter/cupertino.dart';
import 'package:app_flutter/crud/user.dart';

class UserProvider extends InheritedWidget {
  final Widget child;
  List<User> user = [];

  UserProvider({required this.child}) : super(child: child);

  static UserProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UserProvider>()!;
  }

  bool updateShouldNotify(UserProvider oldWidget) {
    return true; 
  }
}