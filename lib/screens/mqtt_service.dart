import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String clientId;
  final String token;
  final String secret;

  final Function(Map<String, dynamic>) onSensorUpdate;

  late MqttServerClient _client;

  // topics
  final String sensorTopic = '@msg/lab_ict_kps/sensor_data';
  final String controlTopic = '@msg/lab_ict_kps/dashboard_control';

  MqttService({
    required this.clientId,
    required this.token,
    required this.secret,
    required this.onSensorUpdate,
  });

  Future<void> connect() async {
    _client = MqttServerClient('broker.netpie.io', clientId);

    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;

    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;

    _client.connectionMessage =
        MqttConnectMessage()
            .withClientIdentifier(clientId)
            .authenticateAs(token, secret)
            .startClean();

    try {
      await _client.connect();
    } catch (e) {
      print("MQTT connection error: $e");
      _client.disconnect();
      return;
    }

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      print("MQTT Connected");

      _client.subscribe(sensorTopic, MqttQos.atMostOnce);

      _client.updates?.listen(_onMessage);
    } else {
      print("MQTT connection failed");
      _client.disconnect();
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> events) {
    final recMsg = events[0].payload as MqttPublishMessage;

    final payload = MqttPublishPayload.bytesToStringAsString(
      recMsg.payload.message,
    );

    print("MQTT Payload: $payload");

    try {
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        onSensorUpdate(decoded);
      }
    } catch (e) {
      print("JSON decode error: $e");
    }
  }

  void _onConnected() {
    print('MQTT Connected');
  }

  void _onDisconnected() {
    print('MQTT Disconnected');
  }

  // ===== Toggle System ON =====
  void systemOn() {
    final builder = MqttClientPayloadBuilder();
    builder.addString("SYSTEM_ON");

    _client.publishMessage(controlTopic, MqttQos.atMostOnce, builder.payload!);
  }

  // ===== Toggle System OFF =====
  void systemOff() {
    final builder = MqttClientPayloadBuilder();
    builder.addString("SYSTEM_OFF");

    _client.publishMessage(controlTopic, MqttQos.atMostOnce, builder.payload!);
  }

  void disconnect() {
    _client.disconnect();
  }
}
