import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ControlPage extends StatefulWidget {
  final BluetoothDevice device;

  const ControlPage({Key? key, required this.device}) : super(key: key);

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  BluetoothCharacteristic? txCtlCharacteristic;
  BluetoothCharacteristic? rxCtlCharacteristic;
  BluetoothCharacteristic? dataCharacteristic;

  final String txCtlUUID = "5f6d4f53-5f52-5043-5f74-785f63746c5f";
  final String rxCtlUUID = "5f6d4f53-5f52-5043-5f72-785f63746c5f";
  final String dataUUID = "5f6d4f53-5f52-5043-5f64-6174615f5f5f"; // UUID correcto

  String receivedData = ""; // Almacena la respuesta procesada
  String buffer = ""; // Almacena datos fragmentados
  bool isLoading = false;
  StreamSubscription<List<int>>? rxSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionSubscription;

  @override
  void initState() {
    super.initState();
    connectToDevice();
  }

  @override
  void dispose() {
    rxSubscription?.cancel();
    connectionSubscription?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  Future<void> connectToDevice() async {
    try {
      setState(() => isLoading = true);

      // Escucha el estado de conexión
      connectionSubscription = widget.device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          showError("Dispositivo desconectado.");
        }
      });

      // Conecta al dispositivo
      await widget.device.connect();

      // Descubre las características después de conectar
      await discoverCharacteristics();
    } catch (e) {
      showError("Error al conectar: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> discoverCharacteristics() async {
    try {
      List<BluetoothService> services = await widget.device.discoverServices();

      for (var service in services) {
        print('Service UUID: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          print('  Characteristic UUID: ${characteristic.uuid}');
          if (characteristic.uuid.toString() == txCtlUUID) {
            txCtlCharacteristic = characteristic;
          } else if (characteristic.uuid.toString() == rxCtlUUID) {
            rxCtlCharacteristic = characteristic;

            // Habilita notificaciones
            await rxCtlCharacteristic!.setNotifyValue(true);
            rxSubscription = rxCtlCharacteristic!.value.listen((data) {
              processReceivedData(data); // Procesa fragmentos
            });
          } else if (characteristic.uuid.toString() == dataUUID) {
            dataCharacteristic = characteristic;
          }
        }
      }

      if (txCtlCharacteristic == null ||
          dataCharacteristic == null ||
          rxCtlCharacteristic == null) {
        showError("No se encontraron todas las características necesarias.");
      }
    } catch (e) {
      showError("Error al descubrir características: $e");
    }
  }

void processReceivedData(List<int> data) async {
  // Verifica si el dato es la longitud del mensaje
  if (data.length == 4) {
    // Convierte los 4 bytes en un número entero (Big-Endian)
    int messageLength = ByteData.sublistView(Uint8List.fromList(data))
        .getUint32(0, Endian.big);

    print("Longitud del mensaje recibida: $messageLength bytes");

    if (messageLength > 0) {
      // Lee los datos reales desde dataCharacteristic
      await readFrame(messageLength);
    }
  } else {
    print("Datos inesperados recibidos: ${utf8.decode(data)}");
  }
}

Future<void> readFrame(int length) async {
  try {
    // Lee los datos reales desde dataCharacteristic
    List<int> frameData = await dataCharacteristic!.read();

    // Decodifica el contenido recibido
    String frameContent = utf8.decode(frameData);
    print("Contenido del mensaje recibido: $frameContent");

    setState(() {
      receivedData = frameContent; // Actualiza la interfaz con los datos reales
    });
  } catch (e) {
    print("Error al leer el frame: $e");
    showError("Error al leer el mensaje.");
  }
}

  Future<void> sendCommand(String command) async {
    if (txCtlCharacteristic == null || dataCharacteristic == null) {
      showError("Características BLE no encontradas.");
      return;
    }

    final commandBytes =
        utf8.encode(command); // Codifica el comando en bytes UTF-8
    final commandLength = commandBytes.length;

    // Convierte la longitud del comando a un array de 4 bytes (Little Endian)
    final lengthBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, commandLength, Endian.big);

    try {
      setState(() => isLoading = true);

      // 1. Enviar la longitud del comando a txCtlCharacteristic
      await txCtlCharacteristic!.write(lengthBytes, withoutResponse: false);

      // 2. Enviar el comando real a dataCharacteristic
      await dataCharacteristic!.write(commandBytes, withoutResponse: false);

      showSuccess("Comando enviado correctamente.");
    } catch (e) {
      showError("Error al enviar el comando: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.red,
    ));
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Control ${widget.device.name}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Received Data:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    receivedData.isEmpty
                        ? "No se ha recibido respuesta."
                        : receivedData,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: txCtlCharacteristic != null &&
                          dataCharacteristic != null
                      ? () => sendCommand('{"id":1999,"method":"Wifi.Scan"}')
                      : null,
                  child: const Text("Enviar Comando RPC"),
                ),
              ],
            ),
    );
  }
}
