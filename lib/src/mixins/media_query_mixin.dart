import 'package:flutter/cupertino.dart';

mixin MediaQueryMixin<T extends StatefulWidget> on State<T> {
  late Size size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    size = MediaQuery.sizeOf(context);
  }
}