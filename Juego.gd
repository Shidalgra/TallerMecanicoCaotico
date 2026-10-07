extends Control

# 1. PRECARGA DE TEXTURAS
const TEXTURA_LLANTA = preload("res://images/Llanta.png")
const TEXTURA_ARO = preload("res://images/Aro.png")
const TEXTURA_MAQUINA_INACTIVA = preload("res://images/MaquinaHidraulica.png")
const TEXTURA_MAQUINA_PROCESO = preload("res://images/MaquinaHidraulicaFuncionando.png")
const TEXTURA_RUEDA_ARMADA = preload("res://images/AroLlantaMontados.png")

# 2. REFERENCIAS DE INTERFAZ DE USUARIO
@onready var mesa_repuestos: Control = $VBoxContainer/ContenedorFlotante/FondoGrisHerramientas/EstacionesTrabajo/MesaRepuestos
@onready var boton_repuesto: TextureButton = $VBoxContainer/ContenedorFlotante/FondoGrisHerramientas/EstacionesTrabajo/MesaRepuestos/BotonRepuesto
@onready var maquina_hidraulica: TextureButton = $VBoxContainer/ContenedorFlotante/FondoGrisHerramientas/EstacionesTrabajo/MaquinaHidraulica

# 3. VARIABLES DE ESTADO INTERNO
var repuesto_en_mesa: String = "Vacio"         # Estados: "Vacio", "Llanta", "Aro"
var estado_maquina: String = "Inactiva"       # Estados: "Inactiva", "ListaParaOperar", "RuedaArmada"
var tiene_llanta_adentro: bool = false
var tiene_aro_adentro: bool = false

# 4. CONFIGURACIÓN DEL SISTEMA DE ENSAMBLE
var toques_actuales: int = 0
const TOQUES_REQUERIDOS: int = 7

func _ready() -> void:
	# Ajuste de tamaño al 50% y centrado automático
	if boton_repuesto:
		_configurar_boton_centrado_y_mediano()
		
		if not boton_repuesto.pressed.is_connected(_on_mesa_repuestos_pressed):
			boton_repuesto.pressed.connect(_on_mesa_repuestos_pressed)
			
	if maquina_hidraulica and not maquina_hidraulica.pressed.is_connected(_on_maquina_hidraulica_pressed):
		maquina_hidraulica.pressed.connect(_on_maquina_hidraulica_pressed)
		
	print("🚨 [Taller]: Conexión establecida. ¡Sistema listo!")
	_actualizar_interfaz_visual()

# Configura el botón para que ocupe el centro y tenga la mitad del tamaño de la mesa
func _configurar_boton_centrado_y_mediano() -> void:
	boton_repuesto.anchor_left = 0.25
	boton_repuesto.anchor_top = 0.25
	boton_repuesto.anchor_right = 0.75
	boton_repuesto.anchor_bottom = 0.75
	
	boton_repuesto.offset_left = 0
	boton_repuesto.offset_top = 0
	boton_repuesto.offset_right = 0
	boton_repuesto.offset_bottom = 0
	
	boton_repuesto.ignore_texture_size = true
	boton_repuesto.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

# --- 1. CICLO DE CLICS EN LA MESA DE REPUESTOS ---
func _on_mesa_repuestos_pressed() -> void:
	_rotar_repuesto_en_mesa()

func _rotar_repuesto_en_mesa() -> void:
	match repuesto_en_mesa:
		"Vacio":
			repuesto_en_mesa = "Llanta"
		"Llanta":
			repuesto_en_mesa = "Aro"
		"Aro":
			repuesto_en_mesa = "Vacio"
			
	_actualizar_interfaz_visual()

# --- 2. SISTEMA DRAG & DROP (ARRASTRAR Y SOLTAR) ---
func _get_drag_data(_at_position: Vector2) -> Variant:
	if repuesto_en_mesa == "Vacio":
		return null
		
	var drag_data = {"tipo": repuesto_en_mesa}
	
	# Vista previa del tamaño de la pieza al arrastrar
	var preview = TextureRect.new()
	preview.texture = TEXTURA_LLANTA if repuesto_en_mesa == "Llanta" else TEXTURA_ARO
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(80, 80) # Tamaño medio de la vista previa flotante
	
	var control_container = Control.new()
	control_container.add_child(preview)
	preview.position = -preview.custom_minimum_size / 2
	
	set_drag_preview(control_container)
	return drag_data

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not maquina_hidraulica or typeof(data) != TYPE_DICTIONARY or not data.has("tipo"):
		return false

	var tipo: String = data["tipo"]
	if estado_maquina != "Inactiva":
		return false
		
	# REGLA: No admite componentes duplicados
	if tipo == "Llanta" and not tiene_llanta_adentro:
		return true
	elif tipo == "Aro" and not tiene_aro_adentro:
		return true
		
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var tipo: String = data["tipo"]
	if tipo == "Llanta":
		tiene_llanta_adentro = true
		print("⚙️ [Máquina]: Llanta acoplada.")
	elif tipo == "Aro":
		tiene_aro_adentro = true
		print("⚙️ [Máquina]: Aro acoplado.")
		
	repuesto_en_mesa = "Vacio"
	_verificar_condicion_ensamble()

# --- 3. ACCIÓN Y ENSAMBLE EN LA MÁQUINA HIDRÁULICA ---
func _on_maquina_hidraulica_pressed() -> void:
	match estado_maquina:
		"ListaParaOperar":
			toques_actuales += 1
			_aplicar_efecto_progreso()
			print("⚙️ [Máquina]: Tap de ensamblado (", toques_actuales, "/", TOQUES_REQUERIDOS, ")")
			
			if toques_actuales >= TOQUES_REQUERIDOS:
				estado_maquina = "RuedaArmada"
				maquina_hidraulica.self_modulate = Color.WHITE
				_actualizar_interfaz_visual()
				
		"RuedaArmada":
			print("📦 [Taller]: Rueda despachada con éxito.")
			estado_maquina = "Inactiva"
			tiene_llanta_adentro = false
			tiene_aro_adentro = false
			maquina_hidraulica.self_modulate = Color.WHITE
			_actualizar_interfaz_visual()

func _verificar_condicion_ensamble() -> void:
	if tiene_llanta_adentro and tiene_aro_adentro:
		print("⚙️ [Máquina]: Componentes completos. Lista para operar.")
		estado_maquina = "ListaParaOperar"
		toques_actuales = 0
	_actualizar_interfaz_visual()

func _aplicar_efecto_progreso() -> void:
	var progreso: float = float(toques_actuales) / float(TOQUES_REQUERIDOS)
	maquina_hidraulica.self_modulate = Color(1.0 - progreso, 1.0, 1.0 - progreso, 1.0)

# --- 4. CONTROLADOR VISUAL ---
func _actualizar_interfaz_visual() -> void:
	if not boton_repuesto or not maquina_hidraulica:
		return
		
	match repuesto_en_mesa:
		"Vacio":
			boton_repuesto.texture_normal = null
		"Llanta":
			boton_repuesto.texture_normal = TEXTURA_LLANTA
		"Aro":
			boton_repuesto.texture_normal = TEXTURA_ARO
			
	match estado_maquina:
		"Inactiva":
			maquina_hidraulica.texture_normal = TEXTURA_MAQUINA_INACTIVA
		"ListaParaOperar":
			maquina_hidraulica.texture_normal = TEXTURA_MAQUINA_PROCESO
		"RuedaArmada":
			maquina_hidraulica.texture_normal = TEXTURA_RUEDA_ARMADA
