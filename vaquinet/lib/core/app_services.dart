import 'package:cattle_monitoring/managers/mqtt_manager.dart';
import 'app_config.dart';

class AppServices {
  static late final MQTTManager mqttManager;

  static Future<void> init() async {
    mqttManager = MQTTManager(
      serverUri: AppConfig.mqttUri,
      clientId: AppConfig.clientId,
      username: AppConfig.username,
      password: AppConfig.password,
    );

    await mqttManager.initialize();
    mqttManager.subscribe('cows/');
  }
}
