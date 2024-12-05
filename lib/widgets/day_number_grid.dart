import 'package:flutter/material.dart';
import 'dart:convert';

class DayNumberGrid extends StatelessWidget {
  final int diaHoy;
  final Color dayColor = Colors.transparent;
  final String jsonValue;

  const DayNumberGrid({
    super.key,
    required this.diaHoy,
    required this.jsonValue,
  });

  //@override
  @override
  Widget build(BuildContext context) {
    final int diaActual = diaHoy;
    debugPrint("Eventos: $jsonValue");

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
        ),
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
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
            List<int> events = [
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0
            ];

            try {
              // Corrige el formato de las claves
              String correctedJson = jsonValue.replaceAllMapped(
                RegExp(r'(\w+):'),
                (Match match) => '"${match[1]}":',
              );

              // Decodifica el JSON corregido
              Map<String, dynamic> decodedData = jsonDecode(correctedJson);

              // Extrae la lista de eventos
              List<int> events = List<int>.from(decodedData['events']);

              // Imprime el resultado
              debugPrint("Lista de eventos: $events");
            } catch (e) {
              debugPrint("Error al decodificar el JSON: $e");
            }

            final bool isIgnored = ignoredIndices.contains(dayNumber);

            // Ignora índices especificados
            if (isIgnored) {
              return Container();
            }

            // Ajusta dayNumber para el diseño del calendario
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

            Color finalDayColor = dayColor;

            // Define el color del día según los eventos y el día actual
            if (dayNumber > diaActual) {
              finalDayColor = Colors.transparent;
            } else {
              //if (jsonValue is List)
              //{
              final int eventDay = events[dayNumber];
              //if (eventDay != null)
              //{
              if (eventDay == 0) {
                finalDayColor = Colors.green;
              } else if (eventDay == 1) {
                finalDayColor = Colors.orange;
              } else if (eventDay == 2) {
                finalDayColor = Colors.blue;
              } else if (eventDay == 3) {
                finalDayColor = Colors.yellow;
              } else if (eventDay == 4) {
                finalDayColor = Colors.red;
              } else {
                finalDayColor = Colors.green;
              }
              //}
              //} //else {
              //finalDayColor = Colors.green;
              //}
            }

            return Container(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.orange, // Cambiar al color que necesites
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 18,
                            color: finalDayColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
