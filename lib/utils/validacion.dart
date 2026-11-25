const int longitudMaximaTitulo = 100;

class TituloInvalidoException implements Exception {
  TituloInvalidoException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

String? validarTitulo(String? texto) {
  final titulo = (texto ?? '').trim();
  if (titulo.isEmpty) {
    return 'Escribe un título para la tarea.';
  }
  if (titulo.length > longitudMaximaTitulo) {
    return 'El título no puede tener más de $longitudMaximaTitulo caracteres.';
  }
  return null;
}