class_name TextosIntercambio
extends Resource

## {entregada} y {recibida} se sustituyen por los nombres de las piezas.
@export_multiline var titulo: String = "UN TRATO ENTRE AMIGOS"
@export_multiline var instrucciones: String = "Elige una de mis piezas y una sin equipar de tu SHIFT."
@export_multiline var titulo_inventario: String = "TU PARTE DEL TRATO · piezas sin equipar"
@export_multiline var seleccion_pendiente: String = "Selecciona ambas piezas para confirmar el intercambio."
@export_multiline var aceptar: String = "Aceptar intercambio"
@export_multiline var cancelar: String = "Cancelar y salir"
@export_multiline var salir: String = "Salir al piso cero"
@export_multiline var sin_ofertas: String = "Ahora mismo no tengo piezas para ofrecerte."
@export_multiline var sin_piezas: String = "No llevas piezas sin equipar. Puedes volver cuando tengas alguna."
@export_multiline var resumen: String = "Entregas: {entregada}\nRecibes: {recibida}"
@export_multiline var no_disponible: String = "El intercambio ya no está disponible. Sal y vuelve a hablar conmigo."
@export_multiline var trato_hecho: String = "Trato hecho. {recibida} ya está en tu SHIFT."
@export_multiline var despedida: String = "Me vendrá bien esa pieza. ¡Cuídate ahí fuera!"
@export_multiline var error_salida: String = "No se pudo volver al piso cero. Inténtalo de nuevo."
@export_multiline var espera: String = "Encárgate antes de las alimañas de este piso, y te buscaré algo para tí"
@export_multiline var titulo_dialogo: String = "Un trato pendiente"
@export_multiline var volver: String = "Volver"
@export var categorias: Array[String] = ["TORSO", "BRAZO", "CABEZA", "PIERNAS"]
