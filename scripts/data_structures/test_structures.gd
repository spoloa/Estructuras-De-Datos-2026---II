extends Node
## Pruebas rápidas de las estructuras (pila, cola, cola con prioridad, arreglo dinámico
## y árbol AVL del ranking).
## Uso: crea una escena con un Node, adjúntale este script y ejecútala (F6).
## La salida aparece en el panel "Output" de Godot.

const ScoreManagerScript := preload("res://scripts/managers/ScoreManager.gd")
const PlayerProfileScript := preload("res://scripts/managers/PlayerProfile.gd")

var _passed: int = 0
var _failed: int = 0


func _ready() -> void:
	_test_stack()
	_test_queue()
	_test_priority_queue()
	_test_dynamic_array()
	_test_avl_rotations()
	_test_avl_height()
	_test_avl_random_insert_remove()
	_test_avl_rank_select_top()
	_test_avl_ties()
	_test_avl_preorder_rebuild()
	_test_score_manager()
	_test_player_profile()
	print("--- Resultado: %d OK, %d fallos ---" % [_passed, _failed])


func _check(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		printerr("FALLÓ: " + name)


func _test_stack() -> void:
	var s := Stack.new()
	_check(s.is_empty(), "Stack: nueva está vacía")
	s.push(1)
	s.push(2)
	s.push(3)
	_check(s.peek() == 3, "Stack: peek devuelve el tope")
	_check(s.pop() == 3, "Stack: pop devuelve 3")
	_check(s.pop() == 2, "Stack: pop devuelve 2")
	_check(s.size() == 1, "Stack: size == 1")
	s.pop()
	_check(s.pop() == null, "Stack: pop en vacía devuelve null")


func _test_queue() -> void:
	var q := Queue.new()
	for i in 100:
		q.enqueue(i)
	var en_orden := true
	for i in 60:
		if q.dequeue() != i:
			en_orden = false
	_check(en_orden, "Queue: respeta FIFO (con compactación)")
	_check(q.size() == 40, "Queue: size == 40")
	_check(q.peek() == 60, "Queue: peek == 60")
	q.clear()
	_check(q.is_empty() and q.dequeue() == null, "Queue: clear y vacía")


func _test_priority_queue() -> void:
	var pq := PriorityQueue.new()
	pq.enqueue("baja", 1)
	pq.enqueue("alta", 10)
	pq.enqueue("media", 5)
	pq.enqueue("alta 2", 10)
	_check(pq.dequeue() == "alta", "PQ: sale primero la mayor prioridad")
	_check(pq.dequeue() == "alta 2", "PQ: desempate por orden de llegada")
	_check(pq.dequeue() == "media", "PQ: luego la media")
	_check(pq.dequeue() == "baja", "PQ: al final la baja")
	_check(pq.is_empty(), "PQ: queda vacía")


func _test_dynamic_array() -> void:
	var a := DynamicArray.new()
	for i in 10:
		a.add(i)
	_check(a.size() == 10 and a.capacity() >= 10, "DynArray: crece automáticamente")
	_check(a.get_at(5) == 5, "DynArray: get_at")
	a.insert(0, 99)
	_check(a.get_at(0) == 99 and a.get_at(1) == 0, "DynArray: insert desplaza")
	_check(a.remove_at(0) == 99, "DynArray: remove_at devuelve el eliminado")
	_check(a.index_of(7) == 7 and a.contains(7), "DynArray: index_of / contains")
	for i in 9:
		a.remove_at(0)
	_check(a.size() == 1 and a.capacity() < 16, "DynArray: se reduce al vaciarse")
	_check(a.get_at(50) == null, "DynArray: índice inválido devuelve null")


# ---------------------------------------------------------------------------
# Árbol AVL (ranking)
# ---------------------------------------------------------------------------

## Claves de una lista de entradas, en el mismo orden.
func _keys(entries: Array) -> Array:
	var keys: Array = []
	for e in entries:
		keys.append(e["key"])
	return keys


## Las cuatro rotaciones: tres claves que desbalancean el árbol de cuatro formas
## distintas deben terminar con la misma forma (2 en la raíz, 1 a la izquierda, 3 a la derecha).
func _test_avl_rotations() -> void:
	var casos := {
		"izquierda-izquierda (3, 2, 1)": [3, 2, 1],
		"derecha-derecha (1, 2, 3)": [1, 2, 3],
		"izquierda-derecha (3, 1, 2)": [3, 1, 2],
		"derecha-izquierda (1, 3, 2)": [1, 3, 2],
	}
	for nombre in casos:
		var t := AVLTree.new()
		for k in casos[nombre]:
			t.insert(k)
		_check(_keys(t.to_array_preorder()) == [2, 1, 3], "AVL: rotación " + nombre)
		_check(t.height() == 2 and t.validate(), "AVL: " + nombre + " queda balanceado")


## Con puntajes crecientes (el peor caso de un BST simple) el AVL debe mantenerse
## bajo, mientras que un BST sin balancear se vuelve una lista.
func _test_avl_height() -> void:
	var n := 1000
	var t := AVLTree.new()
	var keys: Array = []
	for i in n:
		t.insert(i)
		keys.append(i)
	_check(t.size() == n, "AVL: size tras 1000 inserciones crecientes")
	_check(t.height() <= 14, "AVL: altura O(log n) con claves crecientes (altura %d)" % t.height())
	_check(_plain_bst_height(keys) == n, "AVL: un BST sin balancear tendría altura %d" % n)
	_check(t.validate(), "AVL: válido tras claves crecientes")

	var d := AVLTree.new()
	for i in n:
		d.insert(n - i)
	_check(d.height() <= 14 and d.validate(), "AVL: altura O(log n) con claves decrecientes")


## Altura de un árbol binario de búsqueda simple (sin rotaciones), solo para comparar.
func _plain_bst_height(keys: Array) -> int:
	var left: Array = []
	var right: Array = []
	var depth: Array = []
	var best := 0
	for i in keys.size():
		left.append(-1)
		right.append(-1)
		depth.append(1)
		if i == 0:
			best = 1
			continue
		var cur := 0
		while true:
			var next: int = left[cur] if keys[i] < keys[cur] else right[cur]
			if next == -1:
				if keys[i] < keys[cur]:
					left[cur] = i
				else:
					right[cur] = i
				depth[i] = depth[cur] + 1
				best = maxi(best, depth[i])
				break
			cur = next
	return best


## Inserciones y borrados al azar: después de cada paso el árbol debe seguir válido.
func _test_avl_random_insert_remove() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var t := AVLTree.new()
	var vivos: Array = []  # [clave, id] de lo que debería haber dentro
	var siempre_valido := true
	for i in 400:
		var k: int = rng.randi_range(0, 60)
		vivos.append([k, t.insert(k)])
		if not t.validate():
			siempre_valido = false
	_check(siempre_valido and t.size() == 400, "AVL: 400 inserciones al azar siempre válidas")

	var borrados_bien := true
	while vivos.size() > 0:
		var idx: int = rng.randi_range(0, vivos.size() - 1)
		var par: Array = vivos[idx]
		vivos.remove_at(idx)
		if not t.remove(par[0], par[1]) or not t.validate() or t.size() != vivos.size():
			borrados_bien = false
			break
	_check(borrados_bien, "AVL: borrar todo en orden aleatorio deja el árbol válido")
	_check(t.is_empty() and t.height() == 0, "AVL: vacío tras borrar todo")
	_check(not t.remove(5, 0), "AVL: remove de algo inexistente devuelve false")
	_check(t.find(5, 0) == null and t.rank(5, 0) == -1 and t.select(1) == null, "AVL: consultas en árbol vacío")


## rank, select y get_top deben coincidir con ordenar todo a mano (puntajes con muchos empates).
func _test_avl_rank_select_top() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var t := AVLTree.new()
	var todos: Array = []
	for i in 200:
		var k: int = rng.randi_range(0, 50)
		todos.append({"key": k, "id": t.insert(k, "p%d" % i)})
	# Referencia: mayor clave primero; a igual clave, el que llegó antes.
	todos.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["key"] != b["key"]:
			return a["key"] > b["key"]
		return a["id"] < b["id"])

	var rank_ok := true
	var select_ok := true
	for i in todos.size():
		if t.rank(todos[i]["key"], todos[i]["id"]) != i + 1:
			rank_ok = false
		var e: Variant = t.select(i + 1)
		if e == null or e["key"] != todos[i]["key"] or e["id"] != todos[i]["id"]:
			select_ok = false
	_check(rank_ok, "AVL: rank coincide con ordenar a mano (200 entradas con empates)")
	_check(select_ok, "AVL: select coincide con ordenar a mano")
	_check(t.select(0) == null and t.select(201) == null, "AVL: select fuera de rango devuelve null")

	var top: Array = t.get_top(10)
	var top_ok := top.size() == 10
	for i in mini(10, top.size()):
		if top[i]["id"] != todos[i]["id"]:
			top_ok = false
	_check(top_ok, "AVL: get_top(10) devuelve los 10 mejores en orden")
	_check(t.get_top(0).is_empty(), "AVL: get_top(0) devuelve vacío")
	_check(t.get_top(1000).size() == 200, "AVL: get_top mayor que el tamaño devuelve todo")


## Con el mismo puntaje queda mejor el que llegó primero.
func _test_avl_ties() -> void:
	var t := AVLTree.new()
	var primero: int = t.insert(500, "primero")
	var segundo: int = t.insert(500, "segundo")
	var mayor: int = t.insert(900, "mayor")
	_check(t.rank(900, mayor) == 1, "AVL empates: el mayor puntaje es 1.º")
	_check(t.rank(500, primero) == 2 and t.rank(500, segundo) == 3, "AVL empates: el que llegó antes queda mejor")
	_check(t.select(2)["value"] == "primero", "AVL empates: select(2) es el primero en llegar")
	_check(t.insert(500, "otra vez", primero) == -1 and t.size() == 3, "AVL: no acepta (clave, id) repetido")


## Guardar en preorden y reinsertar (con los ids originales) reconstruye un árbol con
## las mismas entradas en las mismas posiciones. La forma exacta puede cambiar (al
## cargar, el árbol parcial se desbalancea y rota), pero sigue siendo un AVL válido.
func _test_avl_preorder_rebuild() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var t := AVLTree.new()
	for i in 150:
		t.insert(rng.randi_range(0, 40), {"oleadas": i % 4})
	var guardado: Array = t.to_array_preorder()

	var copia := AVLTree.new()
	for e in guardado:
		copia.insert(e["key"], e["value"], e["id"])
	_check(copia.get_top(copia.size()) == t.get_top(t.size()), "AVL: reinsertar en preorden conserva entradas y posiciones")
	_check(copia.validate() and copia.size() == t.size(), "AVL: la copia cargada es un AVL válido del mismo tamaño")
	_check(copia.rank(guardado[0]["key"], guardado[0]["id"]) == t.rank(guardado[0]["key"], guardado[0]["id"]), "AVL: rank igual en la copia")
	var nuevo_id: int = copia.insert(10)
	_check(nuevo_id > 149, "AVL: un id nuevo no choca con los cargados (id %d)" % nuevo_id)


# ---------------------------------------------------------------------------
# Puntaje y guardado del ranking (ScoreManager)
# ---------------------------------------------------------------------------

## Puntos, posición en el ranking, guardado en disco y archivo dañado.
func _test_score_manager() -> void:
	var path := "user://test_ranking.save"
	var sm: Node = ScoreManagerScript.new()  # sin añadir al árbol: no carga nada ni cuenta tiempo
	sm.save_path = path

	sm.start_run()
	sm.add_kill("chaser")
	sm.add_kill("shooter")
	sm.add_kill("tipo desconocido")
	sm.add_wave_bonus(1)
	_check(sm.score == 100 + 150 + 50 + 200, "Puntaje: enemigos y bono de oleada suman bien")
	sm.run_time = 65.0
	var r1: Dictionary = sm.submit(true)
	_check(r1["score"] == 500 + 1000, "Puntaje: la victoria suma su bono")
	_check(r1["rank"] == 1 and r1["total"] == 1 and not r1["new_record"], "Ranking: primera partida es 1.ª pero no es 'récord'")
	_check(sm.submit(true)["id"] == r1["id"] and sm.ranking.size() == 1, "Ranking: submit dos veces no duplica la partida")
	sm.add_points(999)
	_check(sm.score == 1500, "Puntaje: tras terminar la partida ya no suma")

	sm.start_run()
	sm.add_kill("chaser")
	var r2: Dictionary = sm.submit(false)
	_check(r2["score"] == 100 and r2["rank"] == 2 and r2["total"] == 2, "Ranking: una partida peor queda 2.ª")
	_check(not r2["victory"] and r2["waves"] == 0, "Ranking: la derrota guarda 0 oleadas y victory = false")

	sm.start_run()
	sm.add_points(1500)
	var r3: Dictionary = sm.submit(false)
	_check(r3["rank"] == 2, "Ranking: empate con el 1.º queda detrás (llegó después)")
	sm.start_run()
	sm.add_points(2000)
	var r4: Dictionary = sm.submit(false)
	_check(r4["rank"] == 1 and r4["new_record"], "Ranking: nuevo mejor puntaje es récord")
	_check(sm.format_time(65.0) == "01:05" and sm.format_time(3599.9) == "59:59", "Tiempo: formato mm:ss")

	# Lo guardado en disco se recupera igual.
	_check(FileAccess.file_exists(path), "Guardado: se creó el archivo")
	var sm2: Node = ScoreManagerScript.new()
	_check(sm2.load_from(path), "Guardado: se carga sin error")
	_check(sm2.ranking.size() == 4 and sm2.ranking.validate(), "Guardado: se recuperan las 4 partidas en un AVL válido")
	_check(sm2.ranking.get_top(4) == sm.ranking.get_top(4), "Guardado: mismas partidas en las mismas posiciones")
	var viejo: Variant = sm2.ranking.find(r1["score"], r1["id"])
	_check(viejo != null and viejo["value"]["time"] == 65.0 and viejo["value"]["victory"], "Guardado: conserva tiempo y victoria")
	# Orden final: 2000 (r4), 1500 (r1, llegó antes), 1500 (r3), 100 (r2).
	_check(sm2.ranking.rank(r4["score"], r4["id"]) == 1, "Guardado: el mejor puntaje sigue 1.º")
	_check(sm2.ranking.rank(r1["score"], r1["id"]) == 2 and sm2.ranking.rank(r3["score"], r3["id"]) == 3, "Guardado: el empate conserva su orden de llegada")

	# Archivo dañado: no debe romper el juego.
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("esto no es un ranking {")
	file.close()
	var sm3: Node = ScoreManagerScript.new()
	_check(not sm3.load_from(path) and sm3.ranking.is_empty(), "Guardado: archivo dañado -> ranking vacío, sin romperse")
	_check(sm3.load_from("user://no_existe.save") and sm3.ranking.is_empty(), "Guardado: sin archivo (primera vez) -> ranking vacío")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	sm.free()
	sm2.free()
	sm3.free()


# ---------------------------------------------------------------------------
# Nickname del jugador (PlayerProfile)
# ---------------------------------------------------------------------------

## Limpieza del nombre, guardado entre aperturas del juego y nickname dentro del ranking.
func _test_player_profile() -> void:
	var path := "user://test_profile.save"
	var p: Node = PlayerProfileScript.new()
	p.save_path = path
	_check(p.load_profile() and not p.has_nickname(), "Perfil: sin archivo (primera vez) no hay nickname")
	_check(p.clean("  Gabo   Yo  ") == "Gabo Yo", "Perfil: quita espacios sobrantes")
	_check(p.clean("Ga<b>o;") == "Gabo", "Perfil: quita caracteres raros")
	_check(p.clean("Ñandú_9-x") == "Ñandú_9-x", "Perfil: permite tildes, ñ, números, _ y -")
	_check(p.clean("ABCDEFGHIJKLMNOPQRST").length() == p.MAX_LENGTH, "Perfil: recorta al largo máximo")
	_check(not p.set_nickname("   ") and not p.set_nickname("a") and not p.has_nickname(), "Perfil: vacío o muy corto se rechaza")
	_check(p.set_nickname("  Gabo ") and p.nickname == "Gabo", "Perfil: guarda el nombre limpio")

	# "Cerrar y abrir el juego": otro perfil lee el mismo archivo.
	var p2: Node = PlayerProfileScript.new()
	p2.save_path = path
	_check(p2.load_profile() and p2.nickname == "Gabo", "Perfil: el nickname se recuerda al volver a abrir")

	# Archivo dañado: se pide el nombre de nuevo, sin romperse.
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{esto no es json")
	file.close()
	var p3: Node = PlayerProfileScript.new()
	p3.save_path = path
	_check(not p3.load_profile() and not p3.has_nickname(), "Perfil: archivo dañado -> sin nickname, sin romperse")

	# El nickname viaja con la partida y se recupera del disco.
	var rpath := "user://test_ranking_nick.save"
	var sm: Node = ScoreManagerScript.new()
	sm.save_path = rpath
	sm.start_run()
	sm.add_points(700)
	var r: Dictionary = sm.submit(false, "Gabo")
	_check(r["nickname"] == "Gabo", "Ranking: el resultado trae el nickname")
	var sm2: Node = ScoreManagerScript.new()
	sm2.load_from(rpath)
	var e: Variant = sm2.ranking.find(r["score"], r["id"])
	_check(e != null and e["value"]["nickname"] == "Gabo", "Ranking: el nickname se guarda y se carga")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(rpath))
	for n in [p, p2, p3, sm, sm2]:
		n.free()
