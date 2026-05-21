import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spin_craze/extension/ext_localization.dart';

class ConnectivityService {
  /// Returns true if the device is connected to any network (WiFi, Mobile, etc.)
  static Future<bool> hasInternet() async {
    final List<ConnectivityResult> connectivityResult =
    await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return false;
    }
    return true;
  }
}