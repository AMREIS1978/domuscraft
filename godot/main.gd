extends Node3D
# DOMUSCRAFT: base nativa Godot, sem API paga.
const GRID := 18
var chosen := "Parede"
var objects: Dictionary = {}
var camera: Camera3D
var pivot: Node3D
var status: Label
var budget := 0
var drag_start := Vector2.ZERO
var moved := false
var materials := {}
const COST = {"Fundação": 400, "Pavimento": 120, "Parede": 350, "Porta": 700, "Janela": 550, "Remover": 0}
func _ready() -> void:
    _make_materials()
    _make_world()
    _make_ui()
    _update_status()
func _make_materials() -> void:
    var colors = {"ground": Color("#719a66"), "foundation": Color("#a0a3a0"), "floor": Color("#d3ad80"), "wall": Color("#eee8da"), "door": Color("#805437"), "window": Color("#65b9d5")}
    for key in colors:
        var mat := StandardMaterial3D.new()
        mat.albedo_color = colors[key]
        mat.roughness = 0.78
        materials[key] = mat
func _make_world() -> void:
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -30, 0)
    sun.light_energy = 1.6
    add_child(sun)
    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("#a5c6db")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.environment.ambient_light_color = Color("#e0e8e9")
    env.environment.ambient_light_energy = 0.7
    add_child(env)
    _cube(self, Vector3(0,-0.18,0), Vector3(GRID,0.35,GRID), "ground")
    for i in GRID+1:
        _line(Vector3(i-GRID/2,0.02,-GRID/2),Vector3(i-GRID/2,0.02,GRID/2))
        _line(Vector3(-GRID/2,0.02,i-GRID/2),Vector3(GRID/2,0.02,i-GRID/2))
    pivot = Node3D.new()
    add_child(pivot)
    camera = Camera3D.new()
    camera.position = Vector3(17,21,23)
    camera.look_at(Vector3.ZERO)
    camera.current = true
    pivot.add_child(camera)
func _line(a: Vector3,b: Vector3) -> void:
    var mesh := ImmediateMesh.new()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    mesh.surface_set_color(Color(1,1,1,0.3))
    mesh.surface_add_vertex(a)
    mesh.surface_add_vertex(b)
    mesh.surface_end()
    var m := MeshInstance3D.new()
    m.mesh=mesh
    add_child(m)
func _cube(parent: Node3D, pos: Vector3, size: Vector3, mat: String) -> Node3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var item := MeshInstance3D.new()
    item.mesh = mesh
    item.material_override = materials[mat]
    item.position = pos
    parent.add_child(item)
    return item
func _make_ui() -> void:
    var canvas := CanvasLayer.new()
    add_child(canvas)
    var panel := PanelContainer.new()
    panel.position = Vector2(12,12)
    panel.custom_minimum_size = Vector2(240,0)
    canvas.add_child(panel)
    var column := VBoxContainer.new()
    panel.add_child(column)
    var title := Label.new()
    title.text="DOMUSCRAFT 3D"
    column.add_child(title)
    for name in COST:
        var btn := Button.new()
        btn.text=name
        btn.pressed.connect(_choose.bind(name))
        column.add_child(btn)
    var home := Button.new()
    home.text="Construir casa inicial"
    home.pressed.connect(_build_house)
    column.add_child(home)
    var save := Button.new()
    save.text="Guardar projeto"
    save.pressed.connect(_save)
    column.add_child(save)
    status=Label.new()
    column.add_child(status)
    var hint := Label.new()
    hint.text="Toque no terreno para construir\nArraste para rodar a câmara\nRoda do rato: zoom"
    column.add_child(hint)
func _choose(name: String) -> void:
    chosen=name
    _update_status()
func _update_status() -> void:
    status.text="Ferramenta: %s\nCusto total: %d €\nPeças: %d" % [chosen,budget,objects.size()]
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index==MOUSE_BUTTON_WHEEL_UP and event.pressed:
            camera.position *= 0.9
        elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            camera.position *= 1.1
        elif event.button_index==MOUSE_BUTTON_LEFT:
            if event.pressed:
                drag_start=event.position
                moved=false
            elif not moved:
                _place_from_screen(event.position)
    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        if event.position.distance_to(drag_start)>12:
            moved=true
            pivot.rotate_y(-event.relative.x*0.007)
func _place_from_screen(screen: Vector2) -> void:
    var origin := camera.project_ray_origin(screen)
    var direction := camera.project_ray_normal(screen)
    if abs(direction.y)<0.0001: return
    var t := -origin.y/direction.y
    if t<=0: return
    var hit := origin+direction*t
    var x := floori(hit.x+GRID/2)
    var z := floori(hit.z+GRID/2)
    if x<0 or z<0 or x>=GRID or z>=GRID: return
    _place(x,z,chosen)
func _place(x:int,z:int,kind:String) -> void:
    var key := Vector2i(x,z)
    if objects.has(key):
        var old=objects[key]
        budget-=COST[old["kind"]]
        old["node"].queue_free()
        objects.erase(key)
    if kind=="Remover":
        _update_status()
        return
    var group := Node3D.new()
    add_child(group)
    group.position=Vector3(x-GRID/2+0.5,0,z-GRID/2+0.5)
    match kind:
        "Fundação": _cube(group,Vector3(0,0.13,0),Vector3(0.98,0.26,0.98),"foundation")
        "Pavimento": _cube(group,Vector3(0,0.08,0),Vector3(0.98,0.16,0.98),"floor")
        "Parede": _cube(group,Vector3(0,1.35,0),Vector3(0.98,2.7,0.22),"wall")
        "Porta":
            _cube(group,Vector3(-0.38,1.35,0),Vector3(0.2,2.7,0.22),"wall")
            _cube(group,Vector3(0.38,1.35,0),Vector3(0.2,2.7,0.22),"wall")
            _cube(group,Vector3(0,2.45,0),Vector3(0.98,0.5,0.22),"wall")
            _cube(group,Vector3(0,1.02,0),Vector3(0.58,2.04,0.12),"door")
        "Janela":
            _cube(group,Vector3(0,0.45,0),Vector3(0.98,0.9,0.22),"wall")
            _cube(group,Vector3(0,2.35,0),Vector3(0.98,0.7,0.22),"wall")
            _cube(group,Vector3(0,1.45,0),Vector3(0.76,1.1,0.12),"window")
    objects[key]={"node":group,"kind":kind}
    budget+=COST[kind]
    _update_status()
func _build_house() -> void:
    for x in range(5,13):
        for z in range(6,12):
            var kind := "Parede" if x==5 or x==12 or z==6 or z==11 else "Pavimento"
            if z==11 and x==8: kind="Porta"
            elif z==11 and x==10: kind="Janela"
            _place(x,z,kind)
func _save() -> void:
    var data=[]
    for key in objects:
        data.append({"x":key.x,"z":key.y,"kind":objects[key]["kind"]})
    var file:=FileAccess.open("user://domuscraft.json",FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.close()
        status.text="Projeto guardado!\n"+status.text
