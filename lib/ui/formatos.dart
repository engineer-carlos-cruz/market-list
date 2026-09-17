import 'package:intl/intl.dart';

final NumberFormat _formatoMonedaEs = NumberFormat('#,##0.00', 'es_ES');
final DateFormat _formatoFechaEs = DateFormat('d MMM yyyy', 'es_ES');

String formatoMoneda(double valor) {
  return '\$${_formatoMonedaEs.format(valor)}';
}

String formatoFecha(DateTime fecha) {
  return _formatoFechaEs.format(fecha);
}