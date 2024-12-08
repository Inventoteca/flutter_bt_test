import 'package:flutter/material.dart';

class DayCounter extends StatefulWidget {
  final int diaHoy;
  final String fechaHora;
  final List<int> events;
  final Function(int day, int value) onEventUpdate;
  final Function(DateTime dateTime) onDateUpdate;

  const DayCounter({
    super.key,
    required this.diaHoy,
    required this.events,
    required this.fechaHora,
    required this.onEventUpdate,
    required this.onDateUpdate,
  });

  @override
  State<DayCounter> createState() => _DayCounterState();
}

class _DayCounterState extends State<DayCounter> {
  late String fechaHora;

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
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
        initialDate.hour,
        initialDate.minute,
        initialDate.second,
      );

      // Llama a la función de actualización con la fecha ajustada
      widget.onDateUpdate(adjustedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int diaActual = widget.diaHoy;

    return Column(
      mainAxisSize: MainAxisSize.min, // Previene expandirse infinitamente
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Dias sin accidentes",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => _selectDate(context), // Selector para el mes
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Mes:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    //color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  widget.fechaHora.split('-')[0],
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
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => _selectDate(context), // Selector para el anio
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Año:",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    //color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 20),
                Text(
                  widget.fechaHora.split('-')[1],
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
