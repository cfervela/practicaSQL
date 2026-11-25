import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/utils/validacion.dart';

void main() {
  test('rechaza nulo, vacío y solo espacios', () {
    expect(validarTitulo(null), isNotNull);
    expect(validarTitulo(''), isNotNull);
    expect(validarTitulo('   \t  '), isNotNull);
  });

  test('acepta un título normal', () {
    expect(validarTitulo('Comprar leche'), isNull);
  });

  test('acepta exactamente el máximo y rechaza uno más', () {
    expect(validarTitulo('a' * longitudMaximaTitulo), isNull);
    expect(validarTitulo('a' * (longitudMaximaTitulo + 1)), isNotNull);
  });

  test('los espacios de los extremos no cuentan para la longitud', () {
    expect(validarTitulo('  ${'a' * longitudMaximaTitulo}  '), isNull);
  });
}