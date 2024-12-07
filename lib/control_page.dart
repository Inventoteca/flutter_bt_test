import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'res/custom_colors.dart';
import '/widgets/day_number_grid.dart';
import 'package:intl/intl.dart';

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
  final String dataUUID =
      "5f6d4f53-5f52-5043-5f64-6174615f5f5f"; // UUID correcto

  String receivedData = ""; // Almacena la respuesta procesada
  String fechaHora = "";
  int fechaDia = 31;
  //int fechaMes = 12;
  //int fechaAnio = 24;
  String buffer = ""; // Almacena datos fragmentados
  bool isLoading = false;
  List<int> events = List<int>.filled(32, 0);

  //var decodedContent;
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
        debugPrint('Service UUID: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          debugPrint('  Characteristic UUID: ${characteristic.uuid}');
          if (characteristic.uuid.toString() == txCtlUUID) {
            txCtlCharacteristic = characteristic;
          } else if (characteristic.uuid.toString() == rxCtlUUID) {
            rxCtlCharacteristic = characteristic;

            // Habilita notificaciones
            await rxCtlCharacteristic!.setNotifyValue(true);
            rxSubscription =
                rxCtlCharacteristic!.lastValueStream.listen((data) {
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
        return;
      }

      // Una vez conectados y descubiertas las características, enviar el comando config.get
      if (widget.device.platformName.startsWith('cruz_')) {
        await sendCommand('{"id":1,"method":"Sys.GetTime"}');

        await sendCommand(
            '{"id":1,"method":"FS.Get","params":{"filename":"events.txt"}}');
      } else {
        await sendCommand(
            '{"id":2,"method":"Config.Get","params":{"key":"app"}}');
      }

      // if(widget.platformName.startsWith('panel_'))
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

      debugPrint("Longitud del mensaje recibida: $messageLength bytes");

      if (messageLength > 0) {
        // Lee los datos reales desde dataCharacteristic
        await readFrame(messageLength);
      }
    }
  }

  Future<void> readFrame(int length) async {
    try {
      // Lee los datos reales desde dataCharacteristic
      List<int> frameData = await dataCharacteristic!.read();

      // Decodifica el contenido recibido
      String frameContent = utf8.decode(frameData);
      DateTime dateTime = DateTime.now();
      debugPrint("BT in: $frameContent");

      try {
        // Convierte los datos recibidos en una cadena
        String jsonString = frameContent;
        debugPrint("Datos recibidos: $jsonString");

        // Intenta parsear el JSON
        var jsonResponse = jsonDecode(jsonString);

        // Verifica si `result` contiene `time`
        if (jsonResponse['result'] != null &&
            jsonResponse['result']['time'] != null) {
          int unixTime = jsonResponse['result']['time'];

          // Convierte UNIX time a DateTime
          dateTime = DateTime.fromMillisecondsSinceEpoch(unixTime * 1000);

          debugPrint("Fecha y hora recibidas: $dateTime");

          setState(() {
            fechaHora = DateFormat('MM-yy').format(dateTime);
            fechaDia = dateTime.day;
            //fechaMes = dateTime.month;
            //fechaAnio = dateTime.year;
          });
        }

        // Verifica si `result` contiene `data`
        else if (jsonResponse['result'] != null &&
            jsonResponse['result']['data'] != null) {
          // Obtiene el contenido codificado en Base64
          String base64Data = jsonResponse['result']['data'];

          // Decodifica el contenido Base64 a texto
          String decodedText = utf8.decode(base64Decode(base64Data));

          // Decodifica el texto a un arreglo JSON o un mapa
          var decodedContent = jsonDecode(decodedText);

          if (decodedContent is List) {
            // Si es una lista
            debugPrint("Contenido decodificado (lista): $decodedContent");
          } else if (decodedContent is Map) {
            // Si es un mapa
            debugPrint("Contenido decodificado (mapa): $decodedContent");
            //List<int> events =
            //    List<int>.filled(32, 0); // Lista predeterminada de ceros
            if (decodedContent.containsKey('events')) {
              final rawEvents = decodedContent['events'];
              if (rawEvents is List) {
                // Conversión explícita a List<int>
                setState(() {
                  receivedData = decodedContent
                      .toString(); // Actualiza la interfaz con los datos reales
                  events = List<int>.from(rawEvents.map((e) => e as int));
                  //debugPrint("Eventos: $events");
                });
              }
            }
          } else {
            debugPrint("Contenido inesperado decodificado: $decodedContent");
          }
        }
      } catch (e) {
        debugPrint("Error al procesar los datos recibidos: $e");
      }
    } catch (e) {
      debugPrint("Error al leer el frame: $e");
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

  // Función que se llamará desde DayNumberGrid
  void updateEvent(int day, int value) {
    setState(() {
      events[day] = value; // Actualiza el evento para el día seleccionado
    });

    // Genera el JSON para simular su envío o guardado
    Map<String, dynamic> jsonData = {"events": events};
    String jsonString = jsonEncode(jsonData);

    debugPrint("NEW JSON generado: $jsonString");
    sendUpdatedEventsCommand();
  }

  void sendUpdatedEventsCommand() {
    // Genera el mapa de datos
    Map<String, dynamic> jsonData = {"events": events};

    // Convierte a JSON
    String jsonString = jsonEncode(jsonData);

    // Codifica el JSON a Base64
    String base64Data = base64Encode(utf8.encode(jsonString));

    // Genera el comando completo
    String command = '''
  {
    "id":5,
    "method":"FS.Put",
    "params":{
      "filename":"events.txt",
      "append":false,
      "data":"$base64Data"
    }
  }
  ''';

    // Envía el comando
    sendCommand(command);
    debugPrint("Comando enviado: $command");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Configuracion'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Card(
                color: CustomColors.panel,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.device.platformName.startsWith('cruz_'))
                      DayNumberGrid(
                        diaHoy: fechaDia,
                        events: events,
                        fechaHora: fechaHora,
                        onEventUpdate: updateEvent,
                      ),
                    /*Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(15.0),
                            child: Text(
                              "Cruz de Seguridad",
                              style: TextStyle(
                                  fontWeight: FontWeight.normal, fontSize: 24),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                            width: 400,
                          ),
                          
                          Text(
                            fechaHora,
                            style: const TextStyle(
                                fontWeight: FontWeight.normal, fontSize: 18),
                          ),
                        ],
                      ),*/

                    //const SizedBox(height: 10),

                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: txCtlCharacteristic != null &&
                              dataCharacteristic != null
                          ? () =>
                              sendCommand('{"id":1999,"method":"Wifi.Scan"}')
                          : null,
                      child: const Text("WiFi"),
                    ),
                    ElevatedButton(
                      onPressed: txCtlCharacteristic != null &&
                              dataCharacteristic != null
                          ? () => sendCommand(
                              '{"id":2,"method":"SetLast","params":{"year":2024,"month":1,"day":1}}')
                          : null,
                      child: const Text("Ajustar Fecha y Hora"),
                    ),
                    //ElevatedButton(
                    //  onPressed: txCtlCharacteristic != null &&
                    //          dataCharacteristic != null
                    //      ? () => sendCommand(
                    //          '{"id":3,"method":"FS.Put","params":{"filename":"events.txt","append":false,"data":"eyJldmVudHMiOiBbMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMCwgMF19"}}')
                    //
                    //      : null,
                    //  child: const Text("Eventos.txt"),
                    //),
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        widget.device.platformName,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
              ));
  }
}
