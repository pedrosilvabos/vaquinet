import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum MqttConnectionState {
  idle,
  connecting,
  connected,
  disconnected,
  error,
}

class MQTTManager {
  final String serverUri;
  final String clientId;
  final String username;
  final String password;
  final int port;

  late MqttServerClient _client;
  MqttConnectionState connectionState = MqttConnectionState.idle;

  MQTTManager({
    required this.serverUri,
    required this.clientId,
    required this.username,
    required this.password,
    this.port = 8883, // default secure MQTT port
  });

  Future<void> initialize() async {
    _setupClient();
    await connect();
  }

  void _setupClient() {
    _client = MqttServerClient.withPort(serverUri, clientId, port);
    _client.secure = true;
    _client.securityContext = SecurityContext.defaultContext;
    _client.keepAlivePeriod = 20;
    _client.logging(on: false);

    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.onSubscribed = _onSubscribed;

    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;
  }

  Future<void> connect() async {
    try {
      connectionState = MqttConnectionState.connecting;
      print('Connecting to MQTT broker...');
      await _client.connect(username, password);
    } catch (e) {
      print('MQTT client connection failed: $e');
      connectionState = MqttConnectionState.error;
      //_client.disconnect();
      return;
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttConnectionState.connected;
      print('MQTT client connected');
    } else {
      print('MQTT connection failed - status: ${_client.connectionStatus}');
      // connectionState = MqttConnectionState.error;
      // _client.disconnect();
    }
  }

  void subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    if (connectionState != MqttConnectionState.connected) {
      print('Cannot subscribe, client not connected.');
      return;
    }

    print('Subscribing to topic: $topic');
    _client.subscribe(topic, qos);

    // No need to add another listener here because you already listen in _onConnected,
    // or if you want you can remove the listener here to avoid duplicates
  }

  void publish(String topic, String message, {MqttQos qos = MqttQos.exactlyOnce, bool retain = false}) {
    if (connectionState != MqttConnectionState.connected) {
      print('Cannot publish, client not connected.');
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message: $message to topic: $topic');
    _client.publishMessage(topic, qos, builder.payload!, retain: retain);
  }

  void disconnect() {
    _client.disconnect();
  }

  final StreamController<MqttMessageEvent> _messageController = StreamController.broadcast();
  Stream<MqttMessageEvent> get messageStream => _messageController.stream;

  // Callbacks
  void _onConnected() {
    connectionState = MqttConnectionState.connected;
    print('✅ MQTT connected successfully');

    // Subscribe once connected
    subscribe('cows/#');

    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final recMess = messages[0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      final topic = messages[0].topic;

      print('📥 Message received: "$payload" from topic: "$topic"');

      // Add message to stream for listeners
      _messageController.add(MqttMessageEvent(topic, payload));
    });
  }

  void _onDisconnected() {
    connectionState = MqttConnectionState.disconnected;
    print('MQTT disconnected');
  }

  void _onSubscribed(String topic) {
    print('Subscription confirmed for topic: $topic');
  }
}

// Helper class to wrap topic + message
class MqttMessageEvent {
  final String topic;
  final String payload;

  MqttMessageEvent(this.topic, this.payload);
}
