import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'control_page.dart';
import 'res/custom_colors.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final List<ScanResult> devicesList = [];
  bool isScanning = false;
  bool isConnecting = false; // Para mostrar el estado de conexión

  @override
  void initState() {
    super.initState();
    startScan();
  }

  void startScan() {
    setState(() {
      devicesList.clear();
      isScanning = true;
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5)).then((_) {
      setState(() {
        isScanning = false;
      });
    });

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult result in results) {
        if (!devicesList.any(
            (device) => device.device.remoteId == result.device.remoteId)) {
          setState(() {
            devicesList.add(result);
          });
        }
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    setState(() => isConnecting = true);

    try {
      // Intenta conectar al dispositivo
      await device.connect();
      setState(() => isConnecting = false);

      // Navega a la página de control
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ControlPage(device: device),
        ),
      );
    } catch (e) {
      setState(() => isConnecting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error al conectar: $e"),
        backgroundColor: CustomColors.firebaseOrange,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Dispositivos'),
          actions: [
            IconButton(
              icon: Icon(isScanning ? Icons.stop : Icons.refresh),
              onPressed: isScanning ? null : startScan,
            ),
          ],
        ),
        body: isConnecting
            ? const Center(child: CircularProgressIndicator())
            : devicesList.isEmpty
                ? Center(
                    child: isScanning
                        ? const CircularProgressIndicator()
                        : const Text('No hay dispositivos.'),
                  )
                : ListView.builder(
                    itemCount: devicesList.length,
                    itemBuilder: (context, index) {
                      final device = devicesList[index].device;

                      // Verificar si el nombre del dispositivo comienza con los prefijos deseados
                      if (device.platformName.startsWith('panel_') ||
                          device.platformName.startsWith('ergo_') ||
                          device.platformName.startsWith('dias_') ||
                          device.platformName.startsWith('cruz_')) {
                        if (device.platformName.startsWith('dias_')) {
                          return GestureDetector(
                            //subtitle: Text(device.remoteId.toString()),
                            onTap: () => connectToDevice(
                                device), // Lleva al control del dispositivo
                            child: Card(
                              color: CustomColors.panel,
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Días sin Accidentes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      '1234', // Reemplaza con el valor dinámico si está disponible
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: CustomColors.sinAccidente,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      device.remoteId
                                          .toString(), // Muestra el ID en pequeño
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else if (device.platformName.startsWith('cruz_')) {
                          return GestureDetector(
                            onTap: () => connectToDevice(
                                device), // Lleva al control del dispositivo
                            child: Card(
                              color: CustomColors.panel,
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Cruz de Seguridad',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    GridView.count(
                                      crossAxisCount: 3,
                                      shrinkWrap: true,
                                      crossAxisSpacing: 4.0,
                                      mainAxisSpacing: 4.0,
                                      children: List.generate(9, (index) {
                                        // Crear una cruz de cuadros
                                        bool isCross = (index == 1 ||
                                            index == 3 ||
                                            index == 4 ||
                                            index == 5 ||
                                            index == 7);
                                        return Container(
                                          color: isCross
                                              ? CustomColors.sinAccidente
                                              : CustomColors.panel,
                                          height: 20,
                                          width: 20,
                                        );
                                      }),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      device.remoteId
                                          .toString(), // Muestra el ID en pequeño
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              title: Text(
                                device.platformName.isNotEmpty
                                    ? device.platformName
                                    : 'Unknown',
                              ),
                              subtitle: Text(device.remoteId.toString()),
                              onTap: () => connectToDevice(
                                  device), // Lleva al control estándar
                            ),
                          );
                        }
                      } else {
                        // Devuelve un espacio vacío para los dispositivos no coincidentes
                        return const SizedBox.shrink();
                      }
                    },
                  ));
  }
}
