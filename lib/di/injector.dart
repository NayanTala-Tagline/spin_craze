import 'package:spin_craze/di/inject_services.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:get_it/get_it.dart';

/// App Dependencies Injection using GetIt
@immutable
class Injector {
  const Injector._();

  static final GetIt _injector = GetIt.instance;

  /// GetIt Instance
  static GetIt get instance => _injector;

  /// init all dependencies module wise
  static void initModules() {
    ServicesInjector(instance);
  }
}
