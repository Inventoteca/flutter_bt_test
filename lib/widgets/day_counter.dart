import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DayCounter extends StatefulWidget {
  final int dias;
  final DateTime lastFechaHora;
  final List<int> events;
  final Function(int day, int value) onEventUpdate;
  final Function(DateTime dateTime) onLastUpdate;

  const DayCounter({
    super.key,
    required this.dias,
    required this.events,
    required this.lastFechaHora,
    required this.onEventUpdate,
    required this.onLastUpdate,
  });

  @override
  State<DayCounter> createState() => _DayCounterState();
}

class _DayCounterState extends State<DayCounter> {
  //late String fechaHora;

  Future<void> _showDaysInputDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ingresar días sin accidentes"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            //decoration: const InputDecoration(
            //  hintText: "",
            //),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                final int? days = int.tryParse(controller.text);
                if (days != null && days >= 0 && days <= 9999) {
                  Navigator.of(context).pop(days);
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    ).then((days) {
      if (days != null) {
        _processDaysInput(days);
      }
    });
  }

  void _processDaysInput(int days) {
    // Calcula la nueva fecha sumando los días a `lastFechaHora`
    DateTime newDate = widget.lastFechaHora.add(Duration(days: days));

    // Convierte la nueva fecha en Unix timestamp
    //int unixTime = newDate.millisecondsSinceEpoch ~/ 1000;

    // Llama a la función de ajuste con el Unix timestamp
    widget.onLastUpdate(newDate);
  }

  Future<void> _selectDate(BuildContext context) async {
    //DateTime initialDate = DateTime.now();
    DateTime initialDate = widget.lastFechaHora.isBefore(DateTime(2000))
        ? DateTime(2000)
        : widget.lastFechaHora;

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000), // Fecha mínima permitida
      lastDate: DateTime(2100), // Fecha máxima permitida
    );

    if (pickedDate != null) {
      // Ajusta pickedDate para incluir la hora actual
      DateTime adjustedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        0,
        0,
        0,
      );

      // Llama a la función de actualización con la fecha ajustada
      widget.onLastUpdate(adjustedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int diaActual = widget.dias;

    return Column(
      mainAxisSize: MainAxisSize.min, // Previene expandirse infinitamente
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.all(15.0),
          child: Text(
            "Dias sin accidentes",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(15.0),
          child: InkWell(
            onTap: () => _selectDate(context), // Selector para el mes
            child: Text(
              '$diaActual', // Reemplaza con el valor dinámico si está disponible
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(30.0),
          child: InkWell(
            onTap: () => _selectDate(context), // Selector para el mes
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Último accidente:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    //color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  DateFormat().format(widget
                      .lastFechaHora), // DateFormat('MM-yy').format(dateTime);
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
