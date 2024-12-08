import 'package:flutter/material.dart';

class DayNumberGrid extends StatefulWidget {
  final int diaHoy;
  final String fechaHora;
  final List<int> events;
  final Function(int day, int value) onEventUpdate;
  final Function(DateTime dateTime) onDateUpdate;

  const DayNumberGrid({
    super.key,
    required this.diaHoy,
    required this.events,
    required this.fechaHora,
    required this.onEventUpdate,
    required this.onDateUpdate,
  });

  @override
  State<DayNumberGrid> createState() => _DayNumberGridState();
}

class _DayNumberGridState extends State<DayNumberGrid> {
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
            "Cruz de Seguridad",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Flexible(
          // Permite al GridView ajustarse
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true, // Ajusta el tamaño del GridView al contenido
              crossAxisCount: 7,
              children: List.generate(49, (index) {
                int dayNumber = index + 1;
                final List<int> ignoredIndices = [
                  1,
                  2,
                  6,
                  7,
                  8,
                  9,
                  13,
                  14,
                  36,
                  37,
                  41,
                  42,
                  43,
                  44,
                  48,
                  49
                ];

                final bool isIgnored = ignoredIndices.contains(dayNumber);

                if (isIgnored) {
                  return Container();
                }

                if (index >= 2 && index <= 5) {
                  dayNumber = index - 1;
                } else if (index >= 9 && index <= 12) {
                  dayNumber = index - 5;
                } else if (index >= 14 && index <= 35) {
                  dayNumber = index - 7;
                } else if (index >= 37 && index <= 40) {
                  dayNumber = index - 9;
                } else if (index >= 44 && index <= 47) {
                  dayNumber = index - 13;
                }

                Color finalDayColor = Colors.transparent;

                if (dayNumber <= diaActual) {
                  final int eventDay = widget.events[dayNumber];
                  finalDayColor = _getDayColor(eventDay);
                }

                return GestureDetector(
                  onTap: dayNumber <= diaActual
                      ? () {
                          _showEventDialog(context, dayNumber);
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 0.5),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(fontSize: 18, color: finalDayColor),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            //onTap: () => _selectDate(context), // Selector para el mes
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
            //onTap: () => _selectDate(context), // Selector para el anio
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

  Color _getDayColor(int eventDay) {
    switch (eventDay) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  void _showEventDialog(BuildContext context, int dayNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Seleccionar Evento para el Día $dayNumber"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogOption(
                  context, dayNumber, "Sin accidente", Colors.green, 0),
              _buildDialogOption(
                  context, dayNumber, "Casi accidente", Colors.orange, 1),
              _buildDialogOption(
                  context, dayNumber, "No incapacitante", Colors.blue, 2),
              _buildDialogOption(
                  context, dayNumber, "Primer auxilio", Colors.yellow, 3),
              _buildDialogOption(
                  context, dayNumber, "Accidente incapacitante", Colors.red, 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogOption(BuildContext context, int dayNumber, String label,
      Color color, int eventValue) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        radius: 10,
      ),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        widget.onEventUpdate(dayNumber, eventValue);
      },
    );
  }
}
