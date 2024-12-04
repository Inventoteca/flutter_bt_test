import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'control_page.dart';

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
        backgroundColor: Colors.red,
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
                        return ListTile(
                          title: Text(
                            device.platformName.isNotEmpty
                                ? device.platformName
                                : 'Unknown',
                          ),
                          subtitle: Text(device.remoteId.toString()),
                          onTap: () => connectToDevice(device),
                        );
                      } else {
                        // Devuelve un espacio vacío para los dispositivos no coincidentes
                        return const SizedBox.shrink();
                      }
                    },
                  ));
  }
}
