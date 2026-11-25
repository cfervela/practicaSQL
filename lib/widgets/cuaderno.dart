import 'package:flutter/material.dart';

class ColoresCuaderno {
  static const papel = Color(0xFFEFD3CB);
  static const linea = Color(0xFFDDA8A5);
  static const margen = Color(0xFFBE6A79);
  static const encabezado = Color(0xFFBE6A79);
  static const franja = Color(0xFFDDA8A5);
  static const tinta = Color(0xFF5B2E38);
  static const tintaSuave = Color(0x995B2E38);
}

const double altoLinea = 52;

const double xMargen = 52;

const double sangria = 66;

class MargenDoble extends StatelessWidget {
  const MargenDoble({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final x in [xMargen, xMargen + 5])
            Positioned(
              left: x,
              top: 0,
              bottom: 0,
              child: Container(width: 1.5, color: ColoresCuaderno.margen),
            ),
        ],
      ),
    );
  }
}

class FilaRayada extends StatelessWidget {
  const FilaRayada({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: altoLinea,
      padding: const EdgeInsets.only(left: sangria, right: 8),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColoresCuaderno.linea, width: 1.5),
        ),
      ),
      child: child,
    );
  }
}