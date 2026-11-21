; ============================================================
;  Mostrador de Teclas - TECLADO VISUAL para clases (v4)
; ============================================================
;  Dibuja un teclado en pantalla e ILUMINA las teclas que pulsas:
;    - Amarillo = tecla normal (letras, numeros, flechas...)
;    - Rojo     = modificadores (Ctrl, Shift, Alt, Alt Gr, Win)
;  Arriba del teclado aparece la combinacion escrita, p. ej.
;    "Ctrl + C"   o   "Alt Gr + Q  =>  @"   o   "Shift + 2  =>  \""
;  Las teclas siguen iluminadas un momento despues de soltarlas,
;  para que los alumnos alcancen a verlas.
;
;  Distribucion: Latinoamerica (por defecto) o España.
;  Los simbolos en AZUL se escriben con Alt Gr.
;
;  REQUISITO: AutoHotkey v2 (gratis en autohotkey.com)
;  USO: doble clic en este archivo .ahk
;
;  CONTROLES (Ctrl y Alt del lado IZQUIERDO):
;    Ctrl+Alt+L       -> Bloquear / desbloquear (desbloqueado = arrastrar)
;    Ctrl+Alt+RePag   -> Mas grande
;    Ctrl+Alt+AvPag   -> Mas pequeño
;    Ctrl+Alt+K       -> Cambiar entre teclado visual y solo texto
;    Ctrl+Alt+H       -> Siempre visible / ocultarse solo
;    Ctrl+Alt+D       -> Distribucion Latinoamerica / España
;    Ctrl+Alt+R       -> Volver a la esquina inferior derecha
;    Ctrl+Alt+N       -> Minimizar / expandir el mostrador
;    Ctrl+Alt+I       -> Mostrar / ocultar historial (hasta 4 teclas)
;    Ctrl+Alt+B       -> Mostrar / ocultar mouse visual
;    Ctrl+Alt+M       -> Activar / desactivar resplandor del mouse
;    Ctrl+Alt+S       -> Activar / desactivar resaltado de seleccion
;    Ctrl+Alt+A       -> Entrar / salir de anotaciones temporales
;    Ctrl+Alt+X       -> Borrar anotaciones
;    Ctrl+Alt+C       -> Panel de clase
;    Ctrl+Alt+E       -> Activar / desactivar foco del cursor
;    Ctrl+Alt+P       -> Iniciar / pausar el temporizador
;    Ctrl+Alt+Q       -> Cerrar
;  Tambien hay un menu en el icono de la bandeja del sistema.
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent
InstallKeybdHook
InstallMouseHook
DetectHiddenWindows true

; ---------------- CONFIGURACION (se guarda automaticamente) ----------------
global ArchivoConfig  := A_ScriptDir "\overlay-config.ini"
global Distribucion   := IniRead(ArchivoConfig, "Teclado", "Distribucion", "latam")
global Escala         := Float(IniRead(ArchivoConfig, "Teclado", "Escala", "1.0"))
global MostrarTeclado := Integer(IniRead(ArchivoConfig, "Teclado", "MostrarTeclado", "1"))
global AutoOcultar    := Integer(IniRead(ArchivoConfig, "Teclado", "AutoOcultar", "1"))
global DuracionMs     := Integer(IniRead(ArchivoConfig, "Teclado", "DuracionMs", "6000"))
global ResaltadoMs    := Integer(IniRead(ArchivoConfig, "Teclado", "ResaltadoMs", "900"))
global Anclaje        := IniRead(ArchivoConfig, "Teclado", "Anclaje", "BR")
global MargenX        := Integer(IniRead(ArchivoConfig, "Teclado", "MargenX", "20"))
global MargenY        := Integer(IniRead(ArchivoConfig, "Teclado", "MargenY", "20"))

; Colores (RRGGBB)
global Col := {
    fondo: "0F0F0F", tecla: "272727", texto: "F1F1F1", shift: "AAAAAA",
    altgr: "8AB4F8", especial: "D6D6D6",
    normal: "FFC857", normalTxt: "181818",
    mod: "FF334D", modTxt: "FFFFFF",
    barra: "F1F1F1", previo: "909090"
}

global ResplandorMouse := Integer(IniRead(ArchivoConfig, "Mouse", "Resplandor", "1"))
global MostrarMouse := Integer(IniRead(ArchivoConfig, "Mouse", "MostrarVisual", "1"))
global PartesMouse := Map(), EventosMouse := Map()
global HaloMouse := 0, HaloDC := 0, HaloBitmap := 0, HaloAnterior := 0
global HaloTam := Max(40, Min(240, Integer(IniRead(ArchivoConfig, "Mouse", "HaloTam", "88"))))
global HaloColor := ColorMouseValido(IniRead(ArchivoConfig, "Mouse", "HaloColor", "FFD600"), "FFD600")
global HaloOpacidad := Max(5, Min(85, Integer(IniRead(ArchivoConfig, "Mouse", "HaloOpacidad", "35"))))
global MouseCuerpo := LeerColorTema("Mouse", "ColorCuerpo", "B6BEC7", "383838")
global MouseBotones := LeerColorTema("Mouse", "ColorBotones", "E5E9ED", "606060")
global MousePulsado := LeerColorTema("Mouse", "ColorPulsado", "FFD21F", "FF334D")
global MouseRueda := LeerColorTema("Mouse", "ColorRueda", "5AB0FF", "8AB4F8")
global HaloX := "", HaloY := ""

; ---------------- ESTADO ----------------
global DemostracionMouse := Integer(IniRead(ArchivoConfig, "Teclado", "DemostracionMouse", "1")) != 0
global TeclasDemostracion := Map()
global Bloqueado := false, Visible := false
global MostrarHistorial := Integer(IniRead(ArchivoConfig, "Historial", "Mostrar", "1"))
global Historial := [], UltimaTick := 0, AvisoActual := ""
global HistorialPic := 0, HistorialBitmap := 0, HistorialW := 0, HistorialH := 0
global Presionadas := Map(), Soltadas := Map()
global Teclas := Map(), Leyendas := Map(), Especiales := Map(), Posiciones := []
global overlay := 0, txtCombo := 0, txtPrev := 0, U := 40, GuiW := 0, GuiH := 0
global ih := 0, Recursos := [], Fuentes := Map()
global Redimension := 0, HwndTeclado := 0, CerrandoMostrador := false
global Minimizado := false, ControlMinimizar := 0, BotonMinimizar := 0
global IconoMinX := 0, IconoMinY := 0, BotonAjustes := 0, BotonClase := 0
global FrenteOrdenMostrador := [], FrenteReordenandoMostrador := false
global MenuMostradorGui := 0, MenuMostradorControles := []
global ArchivoNota := A_ScriptDir "\overlay-nota.txt"
global NotaTexto := LeerNota()
global NotaMostrar := Integer(IniRead(ArchivoConfig, "Notas", "Mostrar", "0"))
global NotaFuente := IniRead(ArchivoConfig, "Notas", "Fuente", "Consolas")
global NotaTam := Max(10, Min(48, Integer(IniRead(ArchivoConfig, "Notas", "Tamano", "20"))))
global NotaLineas := Max(1, Min(8, Integer(IniRead(ArchivoConfig, "Notas", "Lineas", "3"))))
global NotaNegrita := Integer(IniRead(ArchivoConfig, "Notas", "Negrita", "1"))
global NotaEspacios := Integer(IniRead(ArchivoConfig, "Notas", "Espacios", "0"))
global NotaColor := LeerColorTema("Notas", "Color", "FFF4CC", "F1F1F1")
global NotaFondo := LeerColorTema("Notas", "Fondo", "182438", "181818")
global NotaFondoTeclado := Integer(IniRead(ArchivoConfig, "Notas", "FondoTeclado", "1"))
global NotaContraida := Integer(IniRead(ArchivoConfig, "Notas", "Contraida", "0"))
global PanelNota := 0, NotaEditor := 0, NotaEstado := 0
global NotaAncho := 0, NotaAlto := 0, NotaOffsetX := 0
global NotaEditando := false, NotaGuardada := NotaTexto
global NotasGui := 0, CamposNotas := 0, BotonNotas := 0, BotonAnotaciones := 0
global AjustesMouseGui := 0, CamposMouse := 0, ColoresMousePersonalizados := Buffer(64, 0)
global SeleccionActivo := Integer(IniRead(ArchivoConfig, "Seleccion", "Activo", "0"))
global SeleccionFondo := ColorMouseValido(IniRead(ArchivoConfig, "Seleccion", "Fondo", "FFD600"), "FFD600")
global SeleccionTexto := ColorMouseValido(IniRead(ArchivoConfig, "Seleccion", "Texto", "FFFFFF"), "FFFFFF")
global SeleccionSombra := ColorMouseValido(IniRead(ArchivoConfig, "Seleccion", "Sombra", "000000"), "000000")
global SeleccionGrosor := Max(1, Min(6, Integer(IniRead(ArchivoConfig, "Seleccion", "Grosor", "3"))))
global SeleccionNegrita := Integer(IniRead(ArchivoConfig, "Seleccion", "Negrita", "1"))
global SeleccionPid := 0, AjustesSeleccionGui := 0, CamposSeleccion := 0
; Las sesiones de clase no se reanudan automáticamente al abrir el programa.
global UIImagenesModernas := Map(), UIBotonesModernos := Map(), UIEscalasModernas := Map()
global UIHoverModerno := 0, BotonClaseTam := 0
global ClaseGrupos := [[], [], []], ClaseVista := 1, ClaseArrastre := Map(), ClaseEsferaClave := ""
global RelojClaseClave := "", RelojClaseAccion := 0
global ClaseTiemposGui := 0, ClaseCamposTiempos := []
global ClaseTiemposRapidos := LeerTiemposRapidosClase()
global ClaseUsoTiempos := LeerUsoTiemposClase(), ClaseUsoVersion := 0
global ClaseUsoSecuencia := SecuenciaUsoTiemposClase()
global ClaseGui := 0, ClaseControles := 0
global ClaseMinutos := LeerEnteroClase("Minutos", 5, 1, 180)
global ClaseRelojMostrar := LeerEnteroClase("RelojMostrar", 1, 0, 1)
global ClaseAvisoSonoro := LeerEnteroClase("AvisoSonoro", 0, 0, 1)
global ClaseEnMarcha := false, ClaseFinTick := 0, ClaseRestanteMs := ClaseMinutos * 60000
global ClaseTerminado := false, ClaseRelojSolicitado := false, ClaseTotalMs := ClaseRestanteMs
global RelojClaseGui := 0, RelojClaseCuenta := 0, RelojClaseEstado := 0
global ClaseRelojX := IniRead(ArchivoConfig, "Clase", "RelojX", "")
global ClaseRelojY := IniRead(ArchivoConfig, "Clase", "RelojY", "")
global FocoClaseActivo := false, FocoClaseGui := 0, FocoX := "", FocoY := ""
global FocoRadio := LeerEnteroClase("RadioFoco", 180, 80, 420)
global FocoOpacidad := LeerEnteroClase("OpacidadFoco", 55, 15, 80)
global FocoVirtualX := 0, FocoVirtualY := 0, FocoVirtualW := 0, FocoVirtualH := 0
global AnotInterfazHwnds := Map(), AnotInterfazRects := []
global AnotAreaClave := "", AnotAreaPendiente := false
global AnotBarraPlegada := false, AnotBotonPlegar := 0, AnotAgarreBarra := 0
global AnotBarraAbiertaW := 0, AnotBarraAbiertaH := 0, AnotBarraMarcoW := 0
global AnotBarraMinW := 0, AnotBarraMinH := 0, AnotBarraCambiando := false
global AnotBarraElementos := []
global AnotPausa := false, AnotPausaBoton := 0
global AnotModo := false, AnotLienzo := 0, AnotCaptura := 0, AnotBarra := 0, AnotPic := 0
global AnotAjustes := 0, AnotCampos := 0, AnotHwndCaptura := 0, AnotBotones := Map()
global AnotColores := Map(), AnotArrastre := Map(), AnotEstado := 0, AnotGrosorTexto := 0
global AnotDeshacerBoton := 0, AnotRehacerBoton := 0, AnotBorrarBoton := 0
global AnotHistorial := [], AnotRehacer := []
global AnotTextoGui := 0, AnotTextoCampos := 0, AnotTextoPunto := 0, AnotTextoPendiente := false
global AnotArrastreTexto := 0, AnotTextoEdicion := 0, AnotTextoSeleccionado := 0
global AnotUltimoTexto := 0, AnotUltimoClick := 0, AnotUltimoPunto := 0
global AnotGrosorEtiqueta := 0
global AnotTextoTam := Max(10, Min(96, Integer(IniRead(ArchivoConfig, "Anotaciones", "TextoTam", "24"))))
global AnotTextoNegrita := Integer(IniRead(ArchivoConfig, "Anotaciones", "TextoNegrita", "1"))
global AnotDC := 0, AnotBitmap := 0, AnotClave := "000001", AnotPendiente := false
global AnotX := 0, AnotY := 0, AnotW := 0, AnotH := 0, AnotActual := 0, AnotTrazos := []
global AnotHerramienta := IniRead(ArchivoConfig, "Anotaciones", "Herramienta", "trazo")
if !RegExMatch(AnotHerramienta, "^(trazo|flecha|ovalo|marco|linea|texto)$")
    AnotHerramienta := "trazo"
global AnotColor := ColorMouseValido(IniRead(ArchivoConfig, "Anotaciones", "Color", "FF334D"), "FF334D")
global AnotGrosor := Max(2, Min(16, Integer(IniRead(ArchivoConfig, "Anotaciones", "Grosor", "4"))))
; Una preferencia nueva activa el borrado manual también con configuraciones antiguas.
global AnotBorradoManual := Integer(IniRead(ArchivoConfig, "Anotaciones", "BorradoManual", "1")) != 0
global AnotDuracion := AnotBorradoManual ? 0 : Max(0, Min(60, Integer(IniRead(ArchivoConfig, "Anotaciones", "DuracionSeg", "8"))))

try {
    OnExit(CerrarMostrador)
    OnMessage(0x0020, CursorDemostracionMouse)
    OnMessage(0x0232, GuardarGeometriaBarraAnotaciones)
    OnMessage(0x0047, ProgramarAreaCapturaAnotaciones)
    OnMessage(0x0006, ActivacionDialogosMostrador)
    OnMessage(0x0047, CambioCapasMostrador)
    OnMessage(0x0200, HoverBotonModerno)
    OnMessage(0x0020, CursorBotonModerno)
    OnMessage(0x0201, ArrastrarPanelClase)
    OnMessage(0x004E, PintarBotonAjustesModerno) ; WM_NOTIFY / NM_CUSTOMDRAW
    OnMessage(0x0006, ActivacionMenuMostrador)
    OnMessage(0x0201, PresionarAnotacion)
    OnMessage(0x0203, PresionarAnotacion)
    OnMessage(0x0200, MoverAnotacion)
    OnMessage(0x0202, SoltarAnotacion)
    OnMessage(0x0204, DerechoAnotacion)
    OnMessage(0x0020, CursorAnotacion)
    OnMessage(0x007E, AlCambiarPantallas) ; WM_DISPLAYCHANGE
    OnMessage(0x001A, AlCambiarPantallas) ; WM_SETTINGCHANGE
    OnMessage(0x0047, SeguirPosicionMostrador) ; WM_WINDOWPOSCHANGED
    OnMessage(0x0024, LimitesRedimension) ; WM_GETMINMAXINFO
    OnMessage(0x0083, AreaCompletaTeclado)  ; WM_NCCALCSIZE: borde sin marco visible
    OnMessage(0x0084, DetectarBordeTeclado) ; WM_NCHITTEST
    OnMessage(0x0020, CursorBordeTeclado)   ; WM_SETCURSOR
    OnMessage(0x00A1, ComenzarRedimension)  ; WM_NCLBUTTONDOWN
    OnMessage(0x0214, AjustarRedimension)   ; WM_SIZING
    OnMessage(0x000F, PintarVistaRedimension) ; WM_PAINT
    OnMessage(0x0014, FondoVistaRedimension) ; WM_ERASEBKGND
    OnMessage(0x0005, ActualizarVistaRedimension) ; WM_SIZE
    DefinirPosiciones()
    CargarNombres()
    Construir()
    ConfigurarBandeja()
    CrearControlMinimizar()
    CrearHaloMouse()
    AplicarResplandorMouse()
    AplicarModoSeleccion()
    ActualizarMenuSeleccion()

    OnMessage(0x0201, ArrastrarRelojClase)
    OnMessage(0x0232, GuardarPosicionRelojClase)
    OnMessage(0x0203, AlPresionarMouse)
    OnMessage(0x0201, AlPresionarMouse)    ; WM_LBUTTONDOWN -> arrastrar
    OnMessage(0x0232, AlTerminarArrastre)  ; WM_EXITSIZEMOVE -> guardar posicion

    ; Teclado: InputHook ve TODAS las teclas (ñ, acentos, numpad) sin bloquearlas
    ih := InputHook("V L0")
    ih.KeyOpt("{All}", "N")
    ih.OnKeyDown := TeclaAbajo
    ih.OnKeyUp := TeclaArriba
    ih.Start()

    ; Mouse ("*" = tambien con Ctrl/Shift/Alt presionados)
    for boton in ["LButton", "RButton", "MButton", "XButton1", "XButton2",
                  "WheelUp", "WheelDown", "WheelLeft", "WheelRight"]
        Hotkey("~*" boton, ManejarMouse)

    SetTimer(Tick, 100)
    AgregarAlHistorial("Listo: historial visual · pulsa una tecla")
} catch as err {
    MsgBox("ERROR AL INICIAR:`n`n" err.Message "`n`nLínea: " err.Line, "Mostrador de teclas - error", "Icon!")
    ExitApp()
}

; ---------------- ATAJOS ----------------
; "<^<!" = Ctrl IZQUIERDO + Alt IZQUIERDO. Asi Alt Gr + Q (la @) NO cierra el programa.
<^<!l::AlternarBloqueo()
<^<!PgUp::CambiarEscala(0.1)
<^<!PgDn::CambiarEscala(-0.1)
<^<!k::AlternarModo()
<^<!h::AlternarAutoOcultar()
<^<!d::AlternarDistribucion()
<^<!r::RestablecerPosicion()
<^<!n::AlternarMinimizado()
<^<!i::AlternarHistorial()
<^<!b::AlternarMouseVisual()
<^<!m::AlternarResplandorMouse()
<^<!o::EditarNotaDirecta()
<^<!t::AlternarNota()
<^<!s::AlternarSeleccion()
<^<!a::AlternarAnotaciones()
<^<!x::BorrarAnotaciones()
<^<!c::AbrirPanelClase()
<^<!e::AlternarFocoClase()
<^<!p::AlternarTemporizadorClase()
<^<!q::ExitApp()

#HotIf PanelClaseActivo()
Enter::AlternarTemporizadorClase()
#HotIf EditorTextoAnotacionActivo()
^Enter::InsertarTextoAnotacion()
#HotIf AnotModo
*Esc::FinalizarAnotaciones()
^z::DeshacerAnotacion()
^y::RehacerAnotacion()
Delete::BorrarAnotaciones()
1::ElegirHerramientaAnotacion("trazo")
2::ElegirHerramientaAnotacion("flecha")
3::ElegirHerramientaAnotacion("ovalo")
4::ElegirHerramientaAnotacion("marco")
5::ElegirHerramientaAnotacion("linea")
6::ElegirHerramientaAnotacion("texto")
#HotIf

Pt(px) => Max(6, Round(px * 72 / A_ScreenDPI))
EsModificador(sc) => (sc = 0x1D || sc = 0x11D || sc = 0x2A || sc = 0x36 || sc = 0x38 || sc = 0x138 || sc = 0x15B || sc = 0x15C)

; ============================================================
;  DISTRIBUCION DEL TECLADO (posiciones por scan code, en unidades de tecla)
; ============================================================

DefinirPosiciones() {
    global Posiciones
    P := []

    ; Fila de funciones
    f := [[0x01, 1], [0, 1]]
    Loop 4
        f.Push([0x3A + A_Index, 1])          ; F1-F4
    f.Push([0, 0.5])
    Loop 4
        f.Push([0x3E + A_Index, 1])          ; F5-F8
    f.Push([0, 0.5])
    f.Push([0x43, 1], [0x44, 1], [0x57, 1], [0x58, 1])  ; F9-F12
    Fila(P, 0, 0, f)

    ; Numeros
    f := [[0x29, 1]]
    Loop 12
        f.Push([0x01 + A_Index, 1])          ; 1 ... ¿
    f.Push([0x0E, 2])                        ; Retroceso
    Fila(P, 1.25, 0, f)

    ; QWERTY
    f := [[0x0F, 1.75]]                      ; Tab
    Loop 12
        f.Push([0x0F + A_Index, 1])          ; Q ... +
    f.Push([0x1C, 1.25, 2])                  ; Enter (2 filas de alto)
    Fila(P, 2.25, 0, f)

    ; ASDF
    f := [[0x3A, 1.75]]                      ; Bloq Mayus
    Loop 11
        f.Push([0x1D + A_Index, 1])          ; A ... {
    f.Push([0x2B, 1])                        ; }
    Fila(P, 3.25, 0, f)

    ; ZXCV
    f := [[0x2A, 1.25], [0x56, 1]]           ; Shift, <
    Loop 10
        f.Push([0x2B + A_Index, 1])          ; Z ... -
    f.Push([0x36, 2.75])                     ; Shift derecho
    Fila(P, 4.25, 0, f)

    ; Fila inferior
    Fila(P, 5.25, 0, [[0x1D, 1.25], [0x15B, 1.25], [0x38, 1.25], [0x39, 6.25],
                      [0x138, 1.25], [0x15C, 1.25], [0x15D, 1.25], [0x11D, 1.25]])

    ; Bloque de navegacion y flechas
    Fila(P, 0,    15.5, [[0x137, 1], [0x46, 1], [0x45, 1]])
    Fila(P, 1.25, 15.5, [[0x152, 1], [0x147, 1], [0x149, 1]])
    Fila(P, 2.25, 15.5, [[0x153, 1], [0x14F, 1], [0x151, 1]])
    Fila(P, 4.25, 15.5, [[0, 1], [0x148, 1]])
    Fila(P, 5.25, 15.5, [[0x14B, 1], [0x150, 1], [0x14D, 1]])

    Posiciones := P
}

Fila(P, y, x, specs) {
    for s in specs {
        if s[1]
            P.Push({sc: s[1], x: x, y: y, w: s[2], h: s.Length >= 3 ? s[3] : 1})
        x += s[2]
    }
}

CargarNombres() {
    global Especiales, Leyendas, Distribucion

    Especiales := Map(
        0x01, "Esc", 0x0E, "Retroceso", 0x0F, "Tab", 0x1C, "Enter", 0x3A, "Bloq Mayús",
        0x2A, "Shift", 0x36, "Shift", 0x1D, "Ctrl", 0x11D, "Ctrl", 0x15B, "Win", 0x15C, "Win",
        0x38, "Alt", 0x138, "Alt Gr", 0x15D, "Menú", 0x39, "Espacio",
        0x137, "Impr", 0x46, "Despl", 0x45, "Pausa",
        0x152, "Insert", 0x147, "Inicio", 0x149, "Re Pág",
        0x153, "Supr", 0x14F, "Fin", 0x151, "Av Pág",
        0x148, "↑", 0x150, "↓", 0x14B, "←", 0x14D, "→"
    )
    Loop 10
        Especiales[0x3A + A_Index] := "F" A_Index
    Especiales[0x57] := "F11"
    Especiales[0x58] := "F12"

    ; Leyendas: [normal, con Shift, con Alt Gr]
    Leyendas := Map()
    for i, ch in StrSplit("QWERTYUIOP")
        Leyendas[0x0F + i] := [ch, "", ""]
    for i, ch in StrSplit("ASDFGHJKLÑ")
        Leyendas[0x1D + i] := [ch, "", ""]
    for i, ch in StrSplit("ZXCVBNM")
        Leyendas[0x2B + i] := [ch, "", ""]
    Leyendas[0x0B] := ["0", "=", ""]

    if (Distribucion = "es") {
        sh := ["!", '"', "·", "$", "%", "&", "/", "(", ")"]
        ag := ["|", "@", "#", "~", "€", "¬", "", "", ""]
        extra := Map(
            0x29, ["º", "ª", "\"], 0x0C, ["'", "?", ""], 0x0D, ["¡", "¿", ""],
            0x1A, ["``", "^", "["], 0x1B, ["+", "*", "]"],
            0x28, ["´", "¨", "{"], 0x2B, ["Ç", "", "}"]
        )
        Leyendas[0x12][3] := "€"
    } else {
        sh := ["!", '"', "#", "$", "%", "&", "/", "(", ")"]
        ag := ["", "", "", "", "", "", "", "", ""]
        extra := Map(
            0x29, ["|", "°", "¬"], 0x0C, ["'", "?", "\"], 0x0D, ["¿", "¡", ""],
            0x1A, ["´", "¨", ""], 0x1B, ["+", "*", "~"],
            0x28, ["{", "[", "^"], 0x2B, ["}", "]", "``"]
        )
        Leyendas[0x10][3] := "@"
    }
    Loop 9
        Leyendas[0x01 + A_Index] := [String(A_Index), sh[A_Index], ag[A_Index]]
    for sc, l in extra
        Leyendas[sc] := l
    Leyendas[0x56] := ["<", ">", ""]
    Leyendas[0x33] := [",", "`;", ""]
    Leyendas[0x34] := [".", ":", ""]
    Leyendas[0x35] := ["-", "_", ""]
}

; ============================================================
;  CONSTRUIR LA VENTANA
; ============================================================

Construir() {
    global overlay, txtCombo, txtPrev, Teclas, U, GuiW, GuiH, Visible, HwndTeclado
    global Escala, Bloqueado, MostrarTeclado, Col, Posiciones, Leyendas, Especiales, MostrarMouse, PartesMouse
    global DemostracionMouse, TeclasDemostracion
    global HistorialPic, HistorialBitmap, HistorialW, HistorialH, MostrarHistorial

    DestruirPanelNota()
    SetTimer(AnimarTeclas, 0)
    HwndTeclado := 0
    if IsObject(overlay)
        overlay.Destroy()
    if HistorialBitmap
        DllCall("DeleteObject", "ptr", HistorialBitmap)
    HistorialBitmap := 0, HistorialPic := 0
    LiberarRecursos()          ; borrar imagenes/fuentes de la version anterior
    Teclas := Map()
    PartesMouse := Map()
    Visible := false

    U := Round(40 * Escala * A_ScreenDPI / 96)   ; tamaño de una tecla en pixeles
    pad := Round(U * 0.3)

    ; -DPIScale: pixeles reales.  +E0x20: los clics atraviesan la ventana (bloqueado)
    overlay := Gui("+AlwaysOnTop -Caption +Resize -MinimizeBox -MaximizeBox +ToolWindow -DPIScale +E0x08000000" (Bloqueado && !DemostracionMouse ? " +E0x20" : ""))
    HwndTeclado := overlay.Hwnd
    ; Aplicar el area cliente completa una vez que el HWND ya esta disponible.
    DllCall("SetWindowPos", "ptr", overlay.Hwnd, "ptr", 0, "int", 0, "int", 0,
        "int", 0, "int", 0, "uint", 0x37) ; FRAMECHANGED | NOMOVE | NOSIZE | NOZORDER | NOACTIVATE
    overlay.BackColor := Col.fondo
    overlay.OnEvent("Close", (*) => ExitApp())

    ; ----- Modo solo historial (sin teclado fisico) -----
    if !MostrarTeclado {
        overlay.MarginX := pad
        overlay.MarginY := Round(pad * 0.6)
        if !MostrarHistorial {
            GuiW := Round(14 * U) + 2 * pad
            GuiH := Round(U * 0.8) + 2 * overlay.MarginY
            CrearNota()
            overlay.SetFont("s" Pt(U * 0.45) " c" Col.barra " bold", "Segoe UI")
            txtCombo := overlay.AddText(Format("x{} y{} w{} h{} +0x200 +0x80", pad, overlay.MarginY, Round(14 * U) - AnchoControlesMostrador() - Max(2, Round(U * 0.1)), Round(U * 0.8)))
            txtPrev := 0
            WinSetTransparent(255, overlay)
            return
        }
        HistorialW := Round(14 * U), HistorialH := Round(3.8 * U)
        GuiW := HistorialW + 2 * overlay.MarginX
        GuiH := HistorialH + 2 * overlay.MarginY
        CrearNota()
        HistorialPic := overlay.AddText(Format("x{} y{} w{} h{} +0xE", overlay.MarginX, overlay.MarginY, HistorialW, HistorialH))
        txtCombo := 0, txtPrev := 0
        WinSetTransparent(255, overlay)
        return
    }

    ; ----- Modo teclado -----
    overlay.MarginX := 0
    overlay.MarginY := 0
    anchoTec := Round(18.5 * U)
    barH := Round(0.75 * U)
    GuiW := anchoTec + 2 * pad + (MostrarMouse ? Round(3.5 * U) : 0)
    HistorialW := GuiW - 2 * pad
    HistorialH := MostrarHistorial ? Round(1.25 * U) : 0
    CrearNota()
    historialY := pad + barH + (MostrarHistorial ? Round(U * 0.15) : 0)
    top := historialY + HistorialH + Round(U * 0.2)
    GuiH := top + Round(6.25 * U) + pad

    ; El estado actual es grande; el historial usa mini teclas de otra paleta.
    overlay.SetFont("s" Pt(U * 0.45) " c" Col.barra " bold", "Segoe UI")
    txtCombo := overlay.AddText(Format("x{} y{} w{} h{} +0x200 +0x80 +0x4000", pad, pad, HistorialW - AnchoControlesMostrador() - Max(2, Round(U * 0.1)), barH), "")
    txtPrev := 0
    if MostrarHistorial
        HistorialPic := overlay.AddText(Format("x{} y{} w{} h{} +0xE", pad, historialY, HistorialW, HistorialH))

    ; Teclas
    g := Max(2, Round(U * 0.06))
    p := Round(U * 0.12)
    for pos in Posiciones {
        kx := pad + Round(pos.x * U) + g
        ky := top + Round(pos.y * U) + g
        kw := Round(pos.w * U) - 2 * g
        kh := Round(pos.h * U) - 2 * g
        ; Leyendas de la tecla (coordenadas relativas a la tecla)
        legs := []
        m := Round(p * 0.4)
        if Leyendas.Has(pos.sc) {
            L := Leyendas[pos.sc]
            if (L[2] = "") {
                ; letra: una sola leyenda grande al centro
                legs.Push(Leg(0, 0, kw, kh, L[1], U * 0.42, true, "texto", 0x1))
            } else {
                ; simbolo: Shift arriba, normal abajo
                legs.Push(Leg(p, m, kw - 2 * p, kh // 2 - m, L[2], U * 0.30, true, "shift", 0x0))
                legs.Push(Leg(p, kh // 2, kw // 2, kh // 2 - m, L[1], U * 0.34, true, "texto", 0x0))
            }
            if (L[3] != "")   ; Alt Gr: abajo a la derecha, en azul
                legs.Push(Leg(kw // 2, kh // 2, kw // 2 - p, kh // 2 - m, L[3], U * 0.28, true, "altgr", 0x2))
        } else if Especiales.Has(pos.sc) {
            nombre := Especiales[pos.sc]
            corto := StrLen(nombre) = 1
            legs.Push(Leg(0, 0, kw, kh, nombre, corto ? U * 0.38 : U * 0.23, corto, "especial", 0x1))
        }

        ; Cada tecla es UNA sola imagen (sin controles encimados = nunca se despinta).
        ; Se precalculan los estados elevados y hundidos, con sus colores.
        pic := overlay.AddText(Format("x{} y{} w{} h{} +0xE", kx, ky, kw, kh))   ; 0xE = SS_BITMAP
        bmps := Map()
        for estado in ["", "normal", "mod"] {
            Loop 7 {
                fotograma := A_Index - 1
                bmps[estado "|" fotograma] := DibujarTecla(kw, kh, estado, legs, fotograma)
            }
        }
        SendMessage(0x172, 0, bmps["|0"], pic)   ; STM_SETIMAGE
        Teclas[pos.sc] := {pic: pic, bmps: bmps, x: kx, y: ky, w: kw, h: kh, estado: "|0", color: "",
            nivel: 0.0, desde: 0.0, objetivo: 0, inicio: 0, pulso: -1000}
    }

    if MostrarMouse
        ConstruirMouseVisual(pad + anchoTec + Round(U * 0.4), top + Round(U * 0.5))
    for sc in TeclasDemostracion
        PintarTecla(sc, EsModificador(sc) ? "mod" : "normal")

    WinSetTransparent(255, overlay)
}

Leg(x, y, w, h, texto, px, negrita, rol, align) {
    return {x: x, y: y, w: w, h: h, texto: texto, px: px, negrita: negrita, rol: rol, align: align}
}

PintarTecla(sc, estado) {
    global Teclas, Presionadas, Minimizado, TeclasDemostracion
    if Minimizado
        return
    if !Teclas.Has(sc)
        return
    k := Teclas[sc]
    k.color := TeclasDemostracion.Has(sc) ? (EsModificador(sc) ? "mod" : "normal") : estado
    if Presionadas.Has(sc)
        k.pulso := Presionadas[sc]
    ActualizarAnimacionTecla(sc, k, A_TickCount)
    SetTimer(AnimarTeclas, 16)
}

; Misma idea que translateY(6px) y transition: 0.1s de la referencia.
AnimarTeclas() {
    global Teclas, Minimizado
    if Minimizado {
        SetTimer(AnimarTeclas, 0)
        return
    }
    pendiente := false
    ahora := A_TickCount
    for sc, k in Teclas
        if ActualizarAnimacionTecla(sc, k, ahora)
            pendiente := true
    if !pendiente
        SetTimer(AnimarTeclas, 0)
}

ActualizarAnimacionTecla(sc, k, ahora) {
    global Presionadas, TeclasDemostracion
    ; Tambien las pulsaciones rapidas llegan a verse antes de volver a subir.
    minimoVisible := ahora - k.pulso < 180
    objetivo := (Presionadas.Has(sc) || TeclasDemostracion.Has(sc) || minimoVisible) ? 6 : 0
    if (objetivo != k.objetivo) {
        k.desde := k.nivel
        k.objetivo := objetivo
        k.inicio := ahora
    }
    progreso := Min(1.0, Max(0.0, (ahora - k.inicio) / 100.0))
    suave := 1 - (1 - progreso)**3
    k.nivel := k.desde + (k.objetivo - k.desde) * suave
    fotograma := Max(0, Min(6, Round(k.nivel)))
    estado := k.color "|" fotograma
    if (k.estado != estado) {
        SendMessage(0x172, 0, k.bmps[estado], k.pic)
        k.estado := estado
    }
    return progreso < 1 || minimoVisible
}

; Dibuja una tecla (fondo redondeado + leyendas) en un bitmap con GDI
DibujarTecla(w, h, estado, legs, fotograma := 0) {
    global Col, U, Recursos
    hdcS := DllCall("GetDC", "ptr", 0, "ptr")
    hdc  := DllCall("CreateCompatibleDC", "ptr", hdcS, "ptr")
    hbm  := DllCall("CreateCompatibleBitmap", "ptr", hdcS, "int", w, "int", h, "ptr")
    DllCall("ReleaseDC", "ptr", 0, "ptr", hdcS)
    oldBm := DllCall("SelectObject", "ptr", hdc, "ptr", hbm, "ptr")

    ; Fondo de la ventana (esquinas)
    rc := Buffer(16, 0)
    NumPut("int", 0, "int", 0, "int", w, "int", h, rc)
    br := DllCall("CreateSolidBrush", "uint", BGR(Col.fondo), "ptr")
    DllCall("FillRect", "ptr", hdc, "ptr", rc, "ptr", br)
    DllCall("DeleteObject", "ptr", br)

    ; Base fija y superficie elevada: al pulsar baja la cara de la tecla.
    profundidad := Max(4, Round(U * 0.15))
    desplazamiento := Round(profundidad * fotograma / 6)
    hundida := fotograma >= 5
    altoCara := h - profundidad
    r := Max(4, Round(U * 0.16))
    colorTecla := (estado = "mod") ? Col.mod : (estado = "normal") ? Col.normal : Col.tecla
    borde := hundida ? "181818" : (estado = "mod") ? "FF6B7D" : (estado = "normal") ? "FFE1A0" : "414141"
    base := (estado = "mod") ? "781F2E" : (estado = "normal") ? "735621" : "181818"
    RectTecla(hdc, 0, profundidad, w, h, r, base)
    RectTecla(hdc, 0, desplazamiento, w, desplazamiento + altoCara, r, borde)
    bisel := Max(1, Round(U * 0.035))
    RectTecla(hdc, bisel, desplazamiento + bisel, w - bisel,
        desplazamiento + altoCara - bisel, Max(2, r - bisel), colorTecla)

    ; Leyendas
    DllCall("SetBkMode", "ptr", hdc, "int", 1)   ; TRANSPARENT
    oldF := 0
    for lg in legs {
        prev := DllCall("SelectObject", "ptr", hdc, "ptr", Fuente(lg.px, lg.negrita), "ptr")
        if !oldF
            oldF := prev
        rol := lg.rol
        colorTxt := (estado = "" || estado = "mouse") ? Col.%rol% : (estado = "mod") ? Col.modTxt : Col.normalTxt
        DllCall("SetTextColor", "ptr", hdc, "uint", BGR(colorTxt))
        NumPut("int", lg.x, "int", desplazamiento + Round(lg.y * altoCara / h),
            "int", lg.x + lg.w, "int", desplazamiento + Round((lg.y + lg.h) * altoCara / h), rc)
        ; SINGLELINE | VCENTER | NOPREFIX + alineacion
        DllCall("DrawTextW", "ptr", hdc, "str", lg.texto, "int", -1, "ptr", rc, "uint", lg.align | 0x20 | 0x4 | 0x800)
    }
    if oldF
        DllCall("SelectObject", "ptr", hdc, "ptr", oldF)

    DllCall("SelectObject", "ptr", hdc, "ptr", oldBm)
    DllCall("DeleteDC", "ptr", hdc)
    Recursos.Push(hbm)
    return hbm
}

; Dibuja una capa del relieve sin dejar objetos GDI seleccionados.
RectTecla(dc, x1, y1, x2, y2, radio, color) {
    br := DllCall("CreateSolidBrush", "uint", BGR(color), "ptr")
    oldBr := DllCall("SelectObject", "ptr", dc, "ptr", br, "ptr")
    oldPen := DllCall("SelectObject", "ptr", dc, "ptr", DllCall("GetStockObject", "int", 8, "ptr"), "ptr")
    DllCall("RoundRect", "ptr", dc, "int", x1, "int", y1, "int", x2, "int", y2, "int", radio, "int", radio)
    DllCall("SelectObject", "ptr", dc, "ptr", oldPen)
    DllCall("SelectObject", "ptr", dc, "ptr", oldBr)
    DllCall("DeleteObject", "ptr", br)
}

Fuente(px, negrita) {
    global Fuentes, Recursos
    clave := Round(px) "|" negrita
    if !Fuentes.Has(clave) {
        f := DllCall("CreateFontW", "int", -Round(px), "int", 0, "int", 0, "int", 0,
            "int", negrita ? 700 : 400, "uint", 0, "uint", 0, "uint", 0,
            "uint", 1, "uint", 0, "uint", 0, "uint", 5, "uint", 0, "str", "Segoe UI", "ptr")
        Fuentes[clave] := f
        Recursos.Push(f)
    }
    return Fuentes[clave]
}

BGR(hex) {
    c := Integer("0x" hex)
    return ((c & 0xFF) << 16) | (c & 0xFF00) | ((c >> 16) & 0xFF)
}

LiberarRecursos() {
    global Recursos, Fuentes
    for h in Recursos
        DllCall("DeleteObject", "ptr", h)
    Recursos := []
    Fuentes := Map()
}

; ============================================================
;  TECLADO Y MOUSE
; ============================================================

TeclaAbajo(ih, vk, sc) {
    global Presionadas, Soltadas
    if (vk = 0xE8 || vk = 0xFF || sc = 0 || sc = 0x21D)   ; teclas "fantasma" de Windows
        return
    if (sc = 0x136)
        sc := 0x36
    LimpiarDemostracionMouse()
    if Presionadas.Has(sc)          ; tecla mantenida (autorrepeticion)
        return

    ; Alt Gr: Windows manda un Ctrl falso justo antes. Lo quitamos.
    if (sc = 0x138 && Presionadas.Has(0x1D) && A_TickCount - Presionadas[0x1D] < 80) {
        Presionadas.Delete(0x1D)
        PintarTecla(0x1D, "")
        QuitarUltimo("Ctrl")
    }

    Presionadas[sc] := A_TickCount
    if Soltadas.Has(sc)
        Soltadas.Delete(sc)
    PintarTecla(sc, EsModificador(sc) ? "mod" : "normal")
    AgregarAlHistorial(TextoCombo(sc, vk), true)
}

TeclaArriba(ih, vk, sc) {
    global Presionadas, Soltadas
    if (sc = 0x136)
        sc := 0x36
    if Presionadas.Has(sc) {
        Presionadas.Delete(sc)
        Soltadas[sc] := A_TickCount
        PintarTecla(sc, EsModificador(sc) ? "mod" : "normal")
    }
}

ManejarMouse(HotkeyName) {
    global EventosMouse, DemostracionMouse
    boton := SubStr(HotkeyName, 3)
    EventosMouse[boton] := A_TickCount
    RefrescarMouseVisual()
    if DemostracionMouse && MouseEnMostrador()
        return
    txt := ""
    for m in ModsActivos()
        txt .= m " + "
    AgregarAlHistorial(txt NombreAmigable(SubStr(HotkeyName, 3)), true)
}

; Modificadores presionados en este momento (sin repetir el actual)
ModsActivos(actual := "") {
    global Presionadas
    static grupos := [["Ctrl", [0x1D, 0x11D]], ["Alt Gr", [0x138]], ["Alt", [0x38]],
                      ["Shift", [0x2A, 0x36]], ["Win", [0x15B, 0x15C]]]
    mods := []
    for gr in grupos {
        if (gr[1] = actual)
            continue
        for sc in gr[2]
            if Presionadas.Has(sc) {
                mods.Push(gr[1])
                break
            }
    }
    return mods
}

TextoCombo(sc, vk) {
    global Leyendas
    nombre := NombreTecla(sc, vk)
    mods := ModsActivos(nombre)
    txt := ""
    for m in mods
        txt .= m " + "
    txt .= nombre
    ; Mostrar que caracter se escribe: "Shift + 2  =>  \""  /  "Alt Gr + Q  =>  @"
    if (mods.Length = 1 && Leyendas.Has(sc)) {
        L := Leyendas[sc]
        if (mods[1] = "Shift" && L[2] != "")
            txt .= "   ⇒   " L[2]
        else if (mods[1] = "Alt Gr" && L[3] != "")
            txt .= "   ⇒   " L[3]
    }
    return txt
}

NombreTecla(sc, vk) {
    global Especiales, Leyendas
    if Especiales.Has(sc)
        return Especiales[sc]
    if Leyendas.Has(sc)
        return Leyendas[sc][1]
    return NombreAmigable(GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc)))
}

NombreAmigable(tecla) {
    static nombres := Map(
        "NumLock", "Bloq Num", "NumpadAdd", "+ (num)", "NumpadSub", "- (num)",
        "NumpadMult", "* (num)", "NumpadDiv", "/ (num)", "NumpadDot", ". (num)",
        "NumpadEnter", "Enter (num)",
        "LButton", "Clic izquierdo", "RButton", "Clic derecho", "MButton", "Clic rueda",
        "WheelUp", "Rueda ↑", "WheelDown", "Rueda ↓", "WheelLeft", "Rueda ←", "WheelRight", "Rueda →",
        "XButton1", "Botón atrás", "XButton2", "Botón adelante"
    )
    if nombres.Has(tecla)
        return nombres[tecla]
    if RegExMatch(tecla, "^Numpad(.+)$", &m)
        return m[1] " (num)"
    return (StrLen(tecla) = 1) ? StrUpper(tecla) : tecla
}

; ============================================================
;  HISTORIAL Y VISIBILIDAD
; ============================================================

AgregarAlHistorial(texto, esEntrada := false) {
    global Historial, UltimaTick, AvisoActual
    UltimaTick := A_TickCount
    if !esEntrada {
        AvisoActual := texto
        Refrescar()
        return
    }
    AvisoActual := ""
    n := Historial.Length
    ultima := n ? Historial[n] : ""
    base := RegExReplace(ultima, " ×\d+$")

    if (n && base = texto) {
        veces := RegExMatch(ultima, " ×(\d+)$", &m) ? Min(4, m[1] + 1) : 2      ; contador breve: como maximo ×4
        Historial[n] := texto " ×" veces
    } else if (n && ultima = base && InStr(texto, ultima " + ") = 1) {
        Historial[n] := texto                                           ; "Ctrl" -> "Ctrl + C"
    } else {
        Historial.Push(texto)
        if (Historial.Length > 4)
            Historial.RemoveAt(1)
    }
    LimitarHistorial()
    UltimaTick := A_TickCount
    Refrescar()
}

QuitarUltimo(texto) {
    global Historial
    n := Historial.Length
    if !n
        return
    if (Historial[n] = texto)
        Historial.Pop()
    else if RegExMatch(Historial[n], "^\Q" texto "\E ×(\d+)$", &m)
        Historial[n] := (m[1] > 2) ? texto " ×" (m[1] - 1) : texto
}

Refrescar() {
    global TeclasDemostracion
    global Historial, MostrarTeclado, txtCombo, AvisoActual, MostrarHistorial
    global HistorialPic, HistorialBitmap, HistorialW, HistorialH, Redimension, Minimizado
    if Minimizado
        return
    if IsObject(Redimension)
        return
    if (MostrarTeclado || !MostrarHistorial) {
        n := Historial.Length
        txtCombo.Text := TeclasDemostracion.Count ? "DEMOSTRACIÓN  " TextoDemostracionMouse() : AvisoActual != "" ? AvisoActual : n ? "AHORA  " Historial[n] : "AHORA  —"
    }
    if !MostrarHistorial {
        Mostrar()
        return
    }
    nuevo := DibujarHistorial(HistorialW, HistorialH, !MostrarTeclado)
    SendMessage(0x172, 0, nuevo, HistorialPic)
    anterior := HistorialBitmap
    HistorialBitmap := nuevo
    if anterior
        DllCall("DeleteObject", "ptr", anterior)
    Mostrar()
}

Mostrar() {
    global overlay, Visible, GuiW, GuiH, MostrarTeclado, Minimizado
    if Minimizado
        return
    if (Visible && MostrarTeclado)
        return
    pos := CalcularPosicion(GuiW, GuiH)
    MostrarCapaMostrador(overlay, pos[1], pos[2], GuiW, GuiH)
    Visible := true
    ActualizarControlMinimizar()
}

Ocultar() {
    global overlay, Visible, Historial
    overlay.Hide()
    Visible := false
    Historial := []
    ActualizarControlMinimizar()
}

; Cada 100 ms: limpia teclas "pegadas", apaga las que ya se soltaron
; y oculta la ventana si no hay actividad.
Tick() {
    global TeclasDemostracion
    global Presionadas, Soltadas, ResaltadoMs, AutoOcultar, Bloqueado, Visible, UltimaTick, DuracionMs, NotaEditando
    RefrescarMouseVisual()
    ahora := A_TickCount

    sueltas := []
    for sc in Presionadas
        if !GetKeyState(Format("sc{:03X}", sc), "P")
            sueltas.Push(sc)
    for sc in sueltas {
        Presionadas.Delete(sc)
        Soltadas[sc] := ahora
        PintarTecla(sc, EsModificador(sc) ? "mod" : "normal")
    }

    apagar := []
    for sc, t in Soltadas
        if (ahora - t >= ResaltadoMs)
            apagar.Push(sc)
    for sc in apagar {
        Soltadas.Delete(sc)
        PintarTecla(sc, "")
    }

    if (Visible && AutoOcultar && Bloqueado && !NotaEditando && !TeclasDemostracion.Count && !Presionadas.Count && !Soltadas.Count
        && ahora - UltimaTick >= DuracionMs)
        Ocultar()
}

MedirTexto(ctrl, texto) {
    hwnd  := ctrl.Hwnd
    hdc   := DllCall("GetDC", "ptr", hwnd, "ptr")
    hFont := SendMessage(0x31, 0, 0, hwnd)    ; WM_GETFONT
    hOld  := DllCall("SelectObject", "ptr", hdc, "ptr", hFont, "ptr")
    rc := Buffer(16, 0)
    DllCall("DrawTextW", "ptr", hdc, "str", texto, "int", -1, "ptr", rc, "uint", 0x400 | 0x800)
    DllCall("SelectObject", "ptr", hdc, "ptr", hOld)
    DllCall("ReleaseDC", "ptr", hwnd, "ptr", hdc)
    return [NumGet(rc, 8, "int"), NumGet(rc, 12, "int")]
}

; ============================================================
;  OPCIONES
; ============================================================

AlternarBloqueo() {
    global Redimension
    if IsObject(Redimension)
        return
    global Bloqueado, overlay, DemostracionMouse
    Bloqueado := !Bloqueado
    overlay.Opt(Bloqueado && !DemostracionMouse ? "+E0x20" : "-E0x20")
    AgregarAlHistorial(Bloqueado ? "Posición bloqueada" : "Desbloqueado: arrastra para mover")
}

CambiarEscala(d) {
    global Escala, Redimension
    if IsObject(Redimension)
        return
    Escala := Round(Max(0.6, Min(2.5, Escala + d)), 2)
    GuardarConfig()
    Reconstruir("Tamaño: " Round(Escala * 100) "%")
}

AlternarModo() {
    global Redimension
    if IsObject(Redimension)
        return
    global MostrarTeclado
    MostrarTeclado := !MostrarTeclado
    GuardarConfig()
    Reconstruir(MostrarTeclado ? "Modo teclado" : "Modo solo texto")
}

AlternarAutoOcultar() {
    global AutoOcultar
    AutoOcultar := !AutoOcultar
    GuardarConfig()
    AgregarAlHistorial(AutoOcultar ? "Se oculta tras unos segundos" : "Siempre visible")
}

AlternarDistribucion() {
    global Redimension
    if IsObject(Redimension)
        return
    global Distribucion
    Distribucion := (Distribucion = "es") ? "latam" : "es"
    GuardarConfig()
    CargarNombres()
    Reconstruir("Distribución: " (Distribucion = "es" ? "España" : "Latinoamérica"))
}

Reconstruir(mensaje) {
    global Presionadas, Soltadas, Redimension
    if IsObject(Redimension)
        return
    Construir()
    for sc in Presionadas
        PintarTecla(sc, EsModificador(sc) ? "mod" : "normal")
    for sc in Soltadas
        PintarTecla(sc, EsModificador(sc) ? "mod" : "normal")
    AgregarAlHistorial(mensaje)
}

RestablecerPosicion() {
    global Redimension
    if IsObject(Redimension)
        return
    global Anclaje, MargenX, MargenY, overlay, GuiW, GuiH, Minimizado
    Anclaje := "BR"
    MargenX := 20
    MargenY := 20
    GuardarConfig()
    pos := CalcularPosicion(GuiW, GuiH)
    overlay.Move(pos[1], pos[2])
    if Minimizado
        AlternarMinimizado()
    AgregarAlHistorial("Posición restablecida")
    ActualizarControlMinimizar()
}

; Selección exclusivamente visual: no usa Send ni genera eventos de teclado.
TeclaMouseDemostracion() {
    global DemostracionMouse, MostrarTeclado, Teclas, HwndTeclado, Minimizado
    if !DemostracionMouse || !MostrarTeclado || Minimizado || !HwndTeclado
        return 0
    punto := Buffer(8, 0)
    if !DllCall("GetCursorPos", "ptr", punto) || !DllCall("ScreenToClient", "ptr", HwndTeclado, "ptr", punto)
        return 0
    x := NumGet(punto, 0, "int"), y := NumGet(punto, 4, "int")
    for sc, k in Teclas
        if x >= k.x && x < k.x + k.w && y >= k.y && y < k.y + k.h
            return sc
    return 0
}

MouseEnMostrador() {
    global HwndTeclado
    if !HwndTeclado
        return false
    punto := Buffer(8, 0)
    if !DllCall("GetCursorPos", "ptr", punto)
        return false
    hwnd := DllCall("WindowFromPoint", "int64", NumGet(punto, 0, "int64"), "ptr")
    return hwnd && DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") = HwndTeclado
}

TextoDemostracionMouse() {
    global TeclasDemostracion
    texto := "", nombres := Map()
    for modificador in [true, false] {
        for sc in TeclasDemostracion {
            if !!EsModificador(sc) != modificador
                continue
            nombre := NombreTecla(sc, 0)
            if nombres.Has(nombre)
                continue
            nombres[nombre] := true
            texto .= (texto = "" ? "" : " + ") nombre
        }
    }
    return texto
}

SeleccionarTeclaDemostracion(sc) {
    global TeclasDemostracion, Presionadas, Soltadas, UltimaTick
    if TeclasDemostracion.Has(sc)
        TeclasDemostracion.Delete(sc)
    else
        TeclasDemostracion[sc] := true
    PintarTecla(sc, (Presionadas.Has(sc) || Soltadas.Has(sc)) ? (EsModificador(sc) ? "mod" : "normal") : "")
    UltimaTick := A_TickCount
    if TeclasDemostracion.Count
        AgregarAlHistorial(TextoDemostracionMouse(), true)
    else
        AgregarAlHistorial("Demostración borrada · selecciona otras teclas")
}

LimpiarDemostracionMouse() {
    global TeclasDemostracion, Presionadas, Soltadas
    if !TeclasDemostracion.Count
        return
    anteriores := TeclasDemostracion
    TeclasDemostracion := Map()
    for sc in anteriores
        PintarTecla(sc, (Presionadas.Has(sc) || Soltadas.Has(sc)) ? (EsModificador(sc) ? "mod" : "normal") : "")
    Refrescar()
}

AlternarDemostracionMouse(*) {
    global DemostracionMouse, Bloqueado, overlay, ArchivoConfig
    DemostracionMouse := !DemostracionMouse
    LimpiarDemostracionMouse()
    if VentanaMostradorDisponible()
        overlay.Opt(Bloqueado && !DemostracionMouse ? "+E0x20" : "-E0x20")
    IniWrite(DemostracionMouse, ArchivoConfig, "Teclado", "DemostracionMouse")
    A_TrayMenu.ToggleCheck("Demostrar atajos con el mouse")
    AgregarAlHistorial(DemostracionMouse ? "Haz clic en las teclas para mostrar un atajo sin ejecutarlo" : "Demostración con mouse desactivada")
}

CursorDemostracionMouse(wParam, lParam, msg, hwnd) {
    global HwndTeclado, CerrandoMostrador
    if CerrandoMostrador || !HwndTeclado || (lParam & 0xFFFF) != 1
        return
    if DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") = HwndTeclado && TeclaMouseDemostracion() {
        DllCall("SetCursor", "ptr", DllCall("LoadCursorW", "ptr", 0, "ptr", 32649, "ptr"))
        return 1
    }
}

AlPresionarMouse(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global overlay, Bloqueado
    if IsObject(overlay) && (hwnd = overlay.Hwnd || DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") = overlay.Hwnd) {
        sc := TeclaMouseDemostracion()
        if sc {
            SeleccionarTeclaDemostracion(sc)
            return 0
        }
    }
    if (Bloqueado || !IsObject(overlay))
        return
    if (hwnd = overlay.Hwnd || DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") = overlay.Hwnd) {
        borde := BordeTeclado()
        punto := Buffer(8, 0)
        DllCall("GetCursorPos", "ptr", punto)
        coords := (NumGet(punto, 0, "int") & 0xFFFF) | ((NumGet(punto, 4, "int") & 0xFFFF) << 16)
        PostMessage(0xA1, borde ? borde : 2, coords, , overlay.Hwnd) ; redimensionar o mover
        return 0
    }
}

AlTerminarArrastre(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global overlay, Anclaje, MargenX, MargenY, Redimension

    if (!IsObject(overlay) || hwnd != overlay.Hwnd)
        return
    if IsObject(Redimension) {
        ; Reconstruir despues de salir del bucle nativo de Windows.
        SetTimer(TerminarRedimension, -1)
        return
    }
    overlay.GetPos(&x, &y)
    Anclaje := "XY"
    MargenX := x
    MargenY := y
    GuardarConfig()
}

CalcularPosicion(w, h) {
    global Anclaje, MargenX, MargenY
    MonitorGetWorkArea(MonitorGetPrimary(), &L, &T, &R, &B)   ; sin la barra de tareas
    switch Anclaje {
        case "XY": pos := [MargenX, MargenY]
        case "TL": pos := [L + MargenX, T + MargenY]
        case "TR": pos := [R - w - MargenX, T + MargenY]
        case "BL": pos := [L + MargenX, B - h - MargenY]
        default:   pos := [R - w - MargenX, B - h - MargenY] ; BR
    }
    segura := PosicionEnPantalla(pos[1], pos[2], w, h)
    if Anclaje = "XY" && (segura[1] != MargenX || segura[2] != MargenY) {
        MargenX := segura[1], MargenY := segura[2]
        GuardarConfig()
    }
    return segura
}

PosicionEnPantalla(x, y, w, h) {
    ; MonitorFromRect admite también pantallas situadas en coordenadas negativas.
    rect := Buffer(16, 0)
    NumPut("int", x, "int", y, "int", x + w, "int", y + h, rect)
    monitor := DllCall("MonitorFromRect", "ptr", rect, "uint", 2, "ptr")
    info := Buffer(40, 0)
    NumPut("uint", 40, info)
    if !DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info)
        return [x, y]
    l := NumGet(info, 20, "int"), t := NumGet(info, 24, "int")
    r := NumGet(info, 28, "int"), b := NumGet(info, 32, "int")
    return [Max(l, Min(x, r - w)), Max(t, Min(y, b - h))]
}

AlCambiarPantallas(wParam, lParam, msg, hwnd) {
    global CerrandoMostrador
    if CerrandoMostrador || (msg = 0x001A && wParam != 0x002F)
        return
    ; El dibujo usa las coordenadas anteriores de las pantallas.
    SetTimer(CerrarAnotaciones, -1)
    ; Esperar a que Windows termine de actualizar la distribución de pantallas.
    SetTimer(ReubicarMostrador, -300)
    SetTimer(ActualizarPantallasClase, -350)
}

ReubicarMostrador() {
    global overlay, GuiW, GuiH, Redimension
    if !VentanaMostradorDisponible()
        return
    if IsObject(Redimension) {
        SetTimer(ReubicarMostrador, -300)
        return
    }
    pos := CalcularPosicion(GuiW, GuiH)
    overlay.Move(pos[1], pos[2])
    ActualizarControlMinimizar()
}

GuardarConfig() {
    GuardarEstiloNota()
    GuardarSeleccion()
    global ArchivoConfig, Distribucion, Escala, MostrarTeclado, AutoOcultar, DuracionMs, ResaltadoMs, Anclaje, MargenX, MargenY, ResplandorMouse, MostrarMouse, MostrarHistorial
    global HaloTam, HaloColor, HaloOpacidad, MouseCuerpo, MouseBotones, MousePulsado, MouseRueda
    IniWrite(Distribucion,   ArchivoConfig, "Teclado", "Distribucion")
    IniWrite(Escala,         ArchivoConfig, "Teclado", "Escala")
    IniWrite(MostrarTeclado, ArchivoConfig, "Teclado", "MostrarTeclado")
    IniWrite(AutoOcultar,    ArchivoConfig, "Teclado", "AutoOcultar")
    IniWrite(DuracionMs,     ArchivoConfig, "Teclado", "DuracionMs")
    IniWrite(ResaltadoMs,    ArchivoConfig, "Teclado", "ResaltadoMs")
    IniWrite(Anclaje,        ArchivoConfig, "Teclado", "Anclaje")
    IniWrite(MargenX,        ArchivoConfig, "Teclado", "MargenX")
    IniWrite(MargenY,        ArchivoConfig, "Teclado", "MargenY")
    IniWrite(ResplandorMouse, ArchivoConfig, "Mouse", "Resplandor")
    IniWrite(MostrarMouse, ArchivoConfig, "Mouse", "MostrarVisual")
    IniWrite(MostrarHistorial, ArchivoConfig, "Historial", "Mostrar")
    for clave, valor in Map("HaloTam", HaloTam, "HaloColor", HaloColor, "HaloOpacidad", HaloOpacidad,
        "ColorCuerpo", MouseCuerpo, "ColorBotones", MouseBotones, "ColorPulsado", MousePulsado, "ColorRueda", MouseRueda)
        IniWrite(valor, ArchivoConfig, "Mouse", clave)
}

; ============================================================
; PANEL DE CLASE · temporizador y foco del cursor
; Las ayudas son independientes del teclado y no envían datos.
; ============================================================

; Dibujos GDI opacos para controles SS_BITMAP. Sin imágenes ni fuentes de iconos.
; El llamador conserva el HBITMAP devuelto y debe liberarlo con DeleteObject
; cuando lo sustituya o destruya el control. Las funciones no conservan recursos.
; progreso: fracción entre 0 y 1; el arco avanza desde las doce en sentido horario.

DibujarIconoReloj(tam, fondo := "272727", color := "FFC857") {
    tam := Max(1, Round(tam))
    muestra := 4
    lado := tam * muestra
    superficie := RelojCrearSuperficie(lado, lado)
    try {
        RelojFondo(superficie.dc, lado, lado, fondo)
        centro := lado / 2
        grosor := Max(muestra, lado * 0.060)
        RelojContorno(superficie.dc, centro, centro, lado * 0.315, grosor, color)
        RelojTrazo(superficie.dc,
            [[centro, centro - lado * 0.170], [centro, centro],
            [centro + lado * 0.155, centro + lado * 0.065]], grosor, color, true)
        return RelojReducirSuperficie(superficie, tam, tam)
    } finally {
        RelojLiberarSuperficie(superficie)
    }
}

DibujarEsferaClase(tam, progreso, cuenta, estado, color := "8AB4F8", compacto := false) {
    tam := Max(1, Round(tam))
    progreso := Max(0.0, Min(1.0, progreso))
    muestra := 4
    lado := tam * muestra
    superficie := RelojCrearSuperficie(lado, lado)
    try {
        RelojFondo(superficie.dc, lado, lado, "0F0F0F")
        centro := lado / 2
        radio := lado * 0.414
        grosor := lado * (compacto ? 0.041 : 0.038)
        RelojContorno(superficie.dc, centro, centro, radio, grosor, "272727")
        if progreso > 0 {
            puntos := []
            pasos := Max(1, Ceil(progreso * 240))
            pi := 3.141592653589793
            Loop pasos + 1 {
                angulo := -pi / 2 + 2 * pi * progreso * (A_Index - 1) / pasos
                puntos.Push([centro + Cos(angulo) * radio, centro + Sin(angulo) * radio])
            }
            RelojTrazo(superficie.dc, puntos, grosor, color, true)
        }
        ; La cuenta queda blanca, incluso cuando el aro anuncia el final en rojo.
        RelojTexto(superficie.dc, cuenta, lado * 0.140, lado * 0.345,
            lado * 0.720, lado * 0.240, lado * (compacto ? 0.185 : 0.190), "F1F1F1", true)
        RelojTexto(superficie.dc, estado, lado * 0.180, lado * 0.610,
            lado * 0.640, lado * 0.110, lado * (compacto ? 0.064 : 0.060), "999999")
        return RelojReducirSuperficie(superficie, tam, tam)
    } finally {
        RelojLiberarSuperficie(superficie)
    }
}

RelojCrearSuperficie(ancho, alto) {
    dc := 0, bitmap := 0, anterior := 0
    pantalla := DllCall("user32\GetDC", "ptr", 0, "ptr")
    if !pantalla
        throw Error("No se pudo obtener la superficie del reloj.")
    try {
        dc := DllCall("gdi32\CreateCompatibleDC", "ptr", pantalla, "ptr")
        if !dc
            throw Error("No se pudo preparar el dibujo del reloj.")
        bitmap := DllCall("gdi32\CreateCompatibleBitmap", "ptr", pantalla,
            "int", ancho, "int", alto, "ptr")
        if !bitmap
            throw Error("No se pudo crear la imagen del reloj.")
        anterior := DllCall("gdi32\SelectObject", "ptr", dc, "ptr", bitmap, "ptr")
        if !anterior || anterior = -1
            throw Error("No se pudo seleccionar la imagen del reloj.")
        return {dc: dc, bitmap: bitmap, anterior: anterior, w: ancho, h: alto}
    } catch as err {
        if anterior && anterior != -1
            DllCall("gdi32\SelectObject", "ptr", dc, "ptr", anterior)
        if bitmap
            DllCall("gdi32\DeleteObject", "ptr", bitmap)
        if dc
            DllCall("gdi32\DeleteDC", "ptr", dc)
        throw err
    } finally {
        DllCall("user32\ReleaseDC", "ptr", 0, "ptr", pantalla)
    }
}

RelojLiberarSuperficie(superficie, conservarBitmap := false) {
    if !IsObject(superficie)
        return
    DllCall("gdi32\SelectObject", "ptr", superficie.dc, "ptr", superficie.anterior)
    DllCall("gdi32\DeleteDC", "ptr", superficie.dc)
    if !conservarBitmap
        DllCall("gdi32\DeleteObject", "ptr", superficie.bitmap)
}

RelojReducirSuperficie(origen, ancho, alto) {
    destino := RelojCrearSuperficie(ancho, alto)
    try {
        DllCall("gdi32\SetStretchBltMode", "ptr", destino.dc, "int", 4) ; HALFTONE
        DllCall("gdi32\SetBrushOrgEx", "ptr", destino.dc, "int", 0, "int", 0, "ptr", 0)
        if !DllCall("gdi32\StretchBlt", "ptr", destino.dc, "int", 0, "int", 0,
            "int", ancho, "int", alto, "ptr", origen.dc, "int", 0, "int", 0,
            "int", origen.w, "int", origen.h, "uint", 0x00CC0020)
            throw Error("No se pudo finalizar la imagen del reloj.")
        bitmap := destino.bitmap
        RelojLiberarSuperficie(destino, true)
        destino := 0
        return bitmap
    } finally {
        if IsObject(destino)
            RelojLiberarSuperficie(destino)
    }
}

RelojColor(color) {
    if !RegExMatch(color, "i)^[0-9a-f]{6}$")
        throw ValueError("El color del reloj debe tener seis dígitos RRGGBB.")
    valor := Integer("0x" color)
    return ((valor & 0xFF) << 16) | (valor & 0xFF00) | ((valor >> 16) & 0xFF)
}

RelojFondo(dc, ancho, alto, color) {
    pincel := DllCall("gdi32\CreateSolidBrush", "uint", RelojColor(color), "ptr")
    if !pincel
        throw Error("No se pudo dibujar el fondo del reloj.")
    try {
        rect := Buffer(16, 0)
        NumPut("int", ancho, rect, 8)
        NumPut("int", alto, rect, 12)
        DllCall("user32\FillRect", "ptr", dc, "ptr", rect, "ptr", pincel)
    } finally {
        DllCall("gdi32\DeleteObject", "ptr", pincel)
    }
}

RelojContorno(dc, cx, cy, radio, grosor, color) {
    lapiz := DllCall("gdi32\CreatePen", "int", 0, "int", Max(1, Round(grosor)),
        "uint", RelojColor(color), "ptr")
    if !lapiz
        throw Error("No se pudo dibujar el aro del reloj.")
    lapizAnterior := 0, pincelAnterior := 0
    try {
        lapizAnterior := DllCall("gdi32\SelectObject", "ptr", dc, "ptr", lapiz, "ptr")
        pincelAnterior := DllCall("gdi32\SelectObject", "ptr", dc,
            "ptr", DllCall("gdi32\GetStockObject", "int", 5, "ptr"), "ptr") ; NULL_BRUSH
        DllCall("gdi32\Ellipse", "ptr", dc, "int", Round(cx - radio), "int", Round(cy - radio),
            "int", Round(cx + radio), "int", Round(cy + radio))
    } finally {
        if pincelAnterior
            DllCall("gdi32\SelectObject", "ptr", dc, "ptr", pincelAnterior)
        if lapizAnterior
            DllCall("gdi32\SelectObject", "ptr", dc, "ptr", lapizAnterior)
        DllCall("gdi32\DeleteObject", "ptr", lapiz)
    }
}

RelojPunto(dc, x, y, radio, color) {
    pincel := DllCall("gdi32\CreateSolidBrush", "uint", RelojColor(color), "ptr")
    if !pincel
        throw Error("No se pudo dibujar el extremo del reloj.")
    lapizAnterior := 0, pincelAnterior := 0
    try {
        pincelAnterior := DllCall("gdi32\SelectObject", "ptr", dc, "ptr", pincel, "ptr")
        lapizAnterior := DllCall("gdi32\SelectObject", "ptr", dc,
            "ptr", DllCall("gdi32\GetStockObject", "int", 8, "ptr"), "ptr") ; NULL_PEN
        DllCall("gdi32\Ellipse", "ptr", dc, "int", Round(x - radio), "int", Round(y - radio),
            "int", Round(x + radio), "int", Round(y + radio))
    } finally {
        if lapizAnterior
            DllCall("gdi32\SelectObject", "ptr", dc, "ptr", lapizAnterior)
        if pincelAnterior
            DllCall("gdi32\SelectObject", "ptr", dc, "ptr", pincelAnterior)
        DllCall("gdi32\DeleteObject", "ptr", pincel)
    }
}

RelojTrazo(dc, puntos, grosor, color, extremosRedondos := false) {
    if puntos.Length < 2
        return
    lapiz := DllCall("gdi32\CreatePen", "int", 0, "int", Max(1, Round(grosor)),
        "uint", RelojColor(color), "ptr")
    if !lapiz
        throw Error("No se pudo dibujar el progreso del reloj.")
    anterior := 0
    try {
        anterior := DllCall("gdi32\SelectObject", "ptr", dc, "ptr", lapiz, "ptr")
        datos := Buffer(puntos.Length * 8, 0)
        for indice, punto in puntos
            NumPut("int", Round(punto[1]), "int", Round(punto[2]), datos, (indice - 1) * 8)
        DllCall("gdi32\Polyline", "ptr", dc, "ptr", datos, "int", puntos.Length)
        if extremosRedondos {
            primero := puntos[1], ultimo := puntos[puntos.Length]
            RelojPunto(dc, primero[1], primero[2], grosor / 2, color)
            RelojPunto(dc, ultimo[1], ultimo[2], grosor / 2, color)
        }
    } finally {
        if anterior
            DllCall("gdi32\SelectObject", "ptr", dc, "ptr", anterior)
        DllCall("gdi32\DeleteObject", "ptr", lapiz)
    }
}

RelojTexto(dc, texto, x, y, ancho, alto, pixeles, color, negrita := false) {
    fuente := DllCall("gdi32\CreateFontW", "int", -Max(1, Round(pixeles)), "int", 0,
        "int", 0, "int", 0, "int", negrita ? 700 : 400, "uint", 0, "uint", 0,
        "uint", 0, "uint", 1, "uint", 0, "uint", 0, "uint", 4, "uint", 0,
        "str", "Segoe UI", "ptr") ; ANTIALIASED_QUALITY, sin subpíxeles de color
    if !fuente
        throw Error("No se pudo preparar la tipografía del reloj.")
    anterior := 0, modoAnterior := 0, colorAnterior := 0
    try {
        anterior := DllCall("gdi32\SelectObject", "ptr", dc, "ptr", fuente, "ptr")
        modoAnterior := DllCall("gdi32\SetBkMode", "ptr", dc, "int", 1)
        colorAnterior := DllCall("gdi32\SetTextColor", "ptr", dc, "uint", RelojColor(color), "uint")
        rect := Buffer(16, 0)
        NumPut("int", Round(x), "int", Round(y), "int", Round(x + ancho), "int", Round(y + alto), rect)
        ; CENTER | VCENTER | SINGLELINE | NOPREFIX | END_ELLIPSIS.
        DllCall("user32\DrawTextW", "ptr", dc, "str", texto, "int", -1, "ptr", rect, "uint", 0x8825)
    } finally {
        if modoAnterior
            DllCall("gdi32\SetBkMode", "ptr", dc, "int", modoAnterior)
        DllCall("gdi32\SetTextColor", "ptr", dc, "uint", colorAnterior)
        if anterior
            DllCall("gdi32\SelectObject", "ptr", dc, "ptr", anterior)
        DllCall("gdi32\DeleteObject", "ptr", fuente)
    }
}

; Superficies dibujadas: tipografía estándar y formas propias, sin glifos privados.
EscalaGuiModerna(g) {
    global UIEscalasModernas
    return UIEscalasModernas.Get(g.Hwnd, A_ScreenDPI / 96)
}

RectModerno(g, x, y, w, h) {
    s := EscalaGuiModerna(g)
    return Format("x{} y{} w{} h{}", Round(x * s), Round(y * s), Round(w * s), Round(h * s))
}

DibujarBotonModerno(w, h, texto, fondo := "272727", tinta := "F1F1F1", radio := 18) {
    muestra := 3
    superficie := RelojCrearSuperficie(w * muestra, h * muestra)
    try {
        RelojFondo(superficie.dc, superficie.w, superficie.h, "0F0F0F")
        RectTecla(superficie.dc, 0, 0, superficie.w, superficie.h, Round(2 * radio * muestra), fondo)
        lineas := StrSplit(StrReplace(texto, "`r"), "`n")
        s := A_ScreenDPI / 96
        if lineas.Length > 1 {
            RelojTexto(superficie.dc, lineas[1], w * muestra * 0.04, h * muestra * 0.14,
                w * muestra * 0.92, h * muestra * 0.38, Min(16 * s, h * 0.29) * muestra, tinta, true)
            RelojTexto(superficie.dc, lineas[2], w * muestra * 0.04, h * muestra * 0.53,
                w * muestra * 0.92, h * muestra * 0.28, Min(11 * s, h * 0.22) * muestra, "AAAAAA")
        } else {
            RelojTexto(superficie.dc, texto, 4 * muestra, 0, (w - 8) * muestra,
                h * muestra, Min(15 * s, h * 0.38) * muestra, tinta, true)
        }
        return RelojReducirSuperficie(superficie, w, h)
    } finally {
        RelojLiberarSuperficie(superficie)
    }
}

BotonClaseModerno(g, texto, x, y, w, h, accion, fondo := "272727", tinta := "F1F1F1", radio := 18) {
    global UIBotonesModernos
    s := EscalaGuiModerna(g)
    control := g.AddText(RectModerno(g, x, y, w, h) " +0xE +0x100")
    UIBotonesModernos[control.Hwnd] := {control: control, texto: texto, fondo: fondo, tinta: tinta,
        w: Round(w * s), h: Round(h * s), radio: Round(radio * s)}
    ActualizarBotonModerno(control, texto, fondo, tinta, true)
    control.OnEvent("Click", accion)
    return control
}

ActualizarBotonModerno(control, texto := unset, fondo := unset, tinta := unset, forzar := false) {
    global UIBotonesModernos, UIHoverModerno
    anteriorCritico := A_IsCritical
    Critical "On"
    try {
        if !IsObject(control) || !UIBotonesModernos.Has(control.Hwnd) || !DllCall("IsWindow", "ptr", control.Hwnd)
            return
        d := UIBotonesModernos[control.Hwnd]
        cambio := forzar
        if IsSet(texto) && d.texto != texto
            d.texto := texto, cambio := true
        if IsSet(fondo) && d.fondo != fondo
            d.fondo := fondo, cambio := true
        if IsSet(tinta) && d.tinta != tinta
            d.tinta := tinta, cambio := true
        if !cambio
            return
        color := UIHoverModerno = control.Hwnd ? AclararColorModerno(d.fondo) : d.fondo
        PonerImagenModerna(control, DibujarBotonModerno(d.w, d.h, d.texto, color, d.tinta, d.radio))
    } finally {
        Critical anteriorCritico
    }
}

AclararColorModerno(color) {
    n := Integer("0x" color)
    return Format("{:02X}{:02X}{:02X}", Min(255, ((n >> 16) & 255) + 16),
        Min(255, ((n >> 8) & 255) + 16), Min(255, (n & 255) + 16))
}

PonerImagenModerna(control, imagen) {
    global UIImagenesModernas
    hwnd := control.Hwnd
    anterior := UIImagenesModernas.Get(hwnd, 0)
    try devuelta := SendMessage(0x0172, 0, imagen, control)
    catch as err {
        DllCall("DeleteObject", "ptr", imagen)
        throw err
    }
    UIImagenesModernas[hwnd] := imagen
    if devuelta && devuelta != anterior && devuelta != imagen
        DllCall("DeleteObject", "ptr", devuelta)
    if anterior && anterior != imagen
        DllCall("DeleteObject", "ptr", anterior)
}

LiberarImagenModerna(hwnd) {
    global UIImagenesModernas, UIBotonesModernos, UIHoverModerno
    if UIHoverModerno = hwnd
        UIHoverModerno := 0
    if UIBotonesModernos.Has(hwnd)
        UIBotonesModernos.Delete(hwnd)
    if !UIImagenesModernas.Has(hwnd)
        return
    imagen := UIImagenesModernas[hwnd]
    UIImagenesModernas.Delete(hwnd)
    if DllCall("IsWindow", "ptr", hwnd) {
        devuelta := SendMessage(0x0172, 0, 0, , "ahk_id " hwnd)
        if devuelta && devuelta != imagen
            DllCall("DeleteObject", "ptr", devuelta)
    }
    if imagen
        DllCall("DeleteObject", "ptr", imagen)
}

LiberarImagenesModernas(g) {
    global UIEscalasModernas
    if g is Gui {
        for control in g
            LiberarImagenModerna(control.Hwnd)
        if UIEscalasModernas.Has(g.Hwnd)
            UIEscalasModernas.Delete(g.Hwnd)
    }
}

LiberarTodasImagenesModernas() {
    global UIImagenesModernas, UIBotonesModernos, UIHoverModerno
    SetTimer(SalirHoverModerno, 0)
    for hwnd, imagen in UIImagenesModernas.Clone()
        LiberarImagenModerna(hwnd)
    UIBotonesModernos := Map(), UIHoverModerno := 0
}

HoverBotonModerno(wParam, lParam, msg, hwnd) {
    global UIBotonesModernos, UIHoverModerno, CerrandoMostrador
    ; OnMessage crea su propio hilo; Critical acaba al regresar del callback.
    Critical "On"
    if CerrandoMostrador || hwnd = UIHoverModerno || !UIBotonesModernos.Has(hwnd)
        return
    anterior := UIHoverModerno, UIHoverModerno := hwnd
    if UIBotonesModernos.Has(anterior)
        ActualizarBotonModerno(UIBotonesModernos[anterior].control, , , , true)
    ActualizarBotonModerno(UIBotonesModernos[hwnd].control, , , , true)
    SetTimer(SalirHoverModerno, 100)
}

SalirHoverModerno() {
    global UIHoverModerno, UIBotonesModernos
    Critical "On"
    punto := Buffer(8, 0)
    DllCall("GetCursorPos", "ptr", punto)
    hwnd := DllCall("WindowFromPoint", "int64", NumGet(punto, 0, "int64"), "ptr")
    if hwnd = UIHoverModerno
        return
    anterior := UIHoverModerno, UIHoverModerno := 0
    if UIBotonesModernos.Has(anterior)
        ActualizarBotonModerno(UIBotonesModernos[anterior].control, , , , true)
    SetTimer(SalirHoverModerno, 0)
}

CursorBotonModerno(wParam, lParam, msg, hwnd) {
    global UIBotonesModernos, CerrandoMostrador
    if !CerrandoMostrador && UIBotonesModernos.Has(hwnd) {
        DllCall("SetCursor", "ptr", DllCall("LoadCursorW", "ptr", 0, "ptr", 32649, "ptr"))
        return 1
    }
}

FuentePanelClase(g, tam := 10, tinta := "F1F1F1", negrita := false) {
    g.SetFont("s" Round(tam * EscalaGuiModerna(g) * 96 / A_ScreenDPI, 1)
        " c" tinta (negrita ? " bold" : " norm"), "Segoe UI")
}

ControlVistaClase(vista, control) {
    global ClaseGrupos
    ClaseGrupos[vista].Push(control)
    return control
}

MostrarVistaClase(vista, *) {
    global ClaseGrupos, ClaseVista, ClaseControles, ClaseEsferaClave
    ClaseVista := vista
    for indice, controles in ClaseGrupos {
        for control in controles
            control.Visible := indice = vista
    }
    if IsObject(ClaseControles) {
        for indice, boton in ClaseControles.tabs
            ActualizarBotonModerno(boton, , indice = vista ? "203044" : "1D1D1D", indice = vista ? "B6D7FF" : "909090")
    }
    ClaseEsferaClave := ""
    ActualizarClase()
}

ArrastrarPanelClase(wParam, lParam, msg, hwnd) {
    global ClaseGui, ClaseArrastre, CerrandoMostrador
    if CerrandoMostrador || !(ClaseGui is Gui) || !ClaseArrastre.Has(hwnd)
        return
    DllCall("ReleaseCapture")
    PostMessage(0x00A1, 2, 0, , "ahk_id " ClaseGui.Hwnd)
    return 0
}

PanelClaseActivo() {
    global ClaseGui, ClaseVista
    return (ClaseGui is Gui) && ClaseVista = 1 && WinActive("ahk_id " ClaseGui.Hwnd)
}

AbrirAyudaDesdeClase(accion, *) {
    CerrarPanelClase()
    accion.Call()
}

AlternarPreferenciaClase(tipo, *) {
    global ClaseRelojMostrar, ClaseAvisoSonoro
    if tipo = "reloj"
        ClaseRelojMostrar := !ClaseRelojMostrar
    else
        ClaseAvisoSonoro := !ClaseAvisoSonoro
    GuardarClaseConfig()
    ActualizarClase()
}

ProgramarMinutosClase(*) {
    SetTimer(AplicarMinutosClase, -350)
}

AplicarMinutosClase() {
    global ClaseControles, ClaseEnMarcha, ClaseMinutos, ClaseRestanteMs, ClaseTotalMs, ClaseTerminado, ClaseRelojSolicitado
    if !IsObject(ClaseControles) || ClaseEnMarcha
        return
    valor := ClaseControles.minutos.Value
    if !IsInteger(valor) || valor < 1 || valor > 180 || valor = ClaseMinutos
        return
    ClaseMinutos := Integer(valor), ClaseRestanteMs := ClaseMinutos * 60000, ClaseTotalMs := ClaseRestanteMs
    ClaseTerminado := false, ClaseRelojSolicitado := false
    ActualizarClase()
}

AjustarMinutosClase(delta, *) {
    global ClaseMinutos, ClaseEnMarcha
    if ClaseEnMarcha
        return
    LeerDuracionPanelClase()
    ElegirMinutosClase(Max(1, Min(180, ClaseMinutos + delta)))
}

AjustarFocoClase(tipo, delta, *) {
    global FocoRadio, FocoOpacidad, FocoClaseGui, FocoX, FocoY
    if tipo = "radio"
        FocoRadio := Max(80, Min(420, FocoRadio + delta))
    else
        FocoOpacidad := Max(15, Min(80, FocoOpacidad + delta))
    if FocoClaseGui is Gui {
        WinSetTransparent(Round(FocoOpacidad * 255 / 100), "ahk_id " FocoClaseGui.Hwnd)
        FocoX := "", FocoY := ""
        ActualizarFocoClase()
    }
    GuardarClaseConfig()
    ActualizarClase()
}

; Cuatro accesos editables y tres duraciones frecuentes. Preferencias locales.
LeerTiemposRapidosClase() {
    global ArchivoConfig
    valores := StrSplit(IniRead(ArchivoConfig, "Clase", "TiemposRapidos", "1,3,5,10"), ",")
    vistos := Map(), salida := []
    if valores.Length != 4
        return [1, 3, 5, 10]
    for texto in valores {
        texto := Trim(texto)
        if !IsInteger(texto)
            return [1, 3, 5, 10]
        minutos := Integer(texto)
        if minutos < 1 || minutos > 180 || vistos.Has(minutos)
            return [1, 3, 5, 10]
        vistos[minutos] := true
        salida.Push(minutos)
    }
    return salida
}

LeerUsoTiemposClase() {
    global ArchivoConfig
    salida := Map()
    seccion := IniRead(ArchivoConfig, "ClaseUso", , "")
    for linea in StrSplit(seccion, "`n") {
        if !RegExMatch(Trim(linea, " `t`r"), "^(\d{1,3})=(\d{1,7}),(\d{1,13})$", &dato)
            continue
        minutos := Integer(dato[1]), veces := Integer(dato[2]), ultimo := Integer(dato[3])
        if minutos < 1 || minutos > 180 || veces < 1 || ultimo < 1
            continue
        salida[minutos] := {veces: Min(1000000, veces), ultimo: Min(1000000000000, ultimo)}
    }
    return salida
}

SecuenciaUsoTiemposClase() {
    global ClaseUsoTiempos
    secuencia := 0
    for minutos, uso in ClaseUsoTiempos
        secuencia := Max(secuencia, uso.ultimo)
    return secuencia
}

RegistrarUsoTiempoClase(milisegundos) {
    global ClaseUsoTiempos, ClaseUsoSecuencia, ClaseUsoVersion, ArchivoConfig
    minutos := Max(1, Min(180, Round(milisegundos / 60000)))
    anterior := ClaseUsoTiempos.Get(minutos, {veces: 0, ultimo: 0})
    ClaseUsoSecuencia += 1
    nuevo := {veces: Min(1000000, anterior.veces + 1), ultimo: ClaseUsoSecuencia}
    ClaseUsoTiempos[minutos] := nuevo
    ClaseUsoVersion += 1
    IniWrite(nuevo.veces "," nuevo.ultimo, ArchivoConfig, "ClaseUso", minutos)
}

TiemposMasUsadosClase(limite := 3) {
    global ClaseUsoTiempos
    salida := []
    for minutos, uso in ClaseUsoTiempos {
        registro := {minutos: minutos, veces: uso.veces, ultimo: uso.ultimo}
        posicion := 1
        for previo in salida {
            if registro.veces > previo.veces || (registro.veces = previo.veces && registro.ultimo > previo.ultimo)
                break
            posicion += 1
        }
        if posicion <= limite {
            salida.InsertAt(posicion, registro)
            if salida.Length > limite
                salida.Pop()
        }
    }
    return salida
}

ElegirTiempoRapidoClase(indice, *) {
    global ClaseTiemposRapidos
    if indice >= 1 && indice <= ClaseTiemposRapidos.Length
        ElegirMinutosClase(ClaseTiemposRapidos[indice])
}

ElegirTiempoFrecuenteClase(indice, *) {
    lista := TiemposMasUsadosClase()
    if indice >= 1 && indice <= lista.Length
        ElegirMinutosClase(lista[indice].minutos)
}

ActualizarTiemposPanelClase() {
    global ClaseControles, ClaseTiemposRapidos, ClaseUsoVersion, ClaseVista
    global ClaseMinutos, ClaseRestanteMs, ClaseRelojSolicitado
    if !IsObject(ClaseControles)
        return
    c := ClaseControles
    for indice, boton in c.presets {
        minutos := ClaseTiemposRapidos[indice]
        elegido := !ClaseRelojSolicitado && minutos = ClaseMinutos && ClaseRestanteMs = ClaseMinutos * 60000
        ActualizarBotonModerno(boton, minutos " min", elegido ? "203044" : "232323", elegido ? "B6D7FF" : "D6D6D6")
    }
    if c.usoVersion != ClaseUsoVersion {
        c.topFrecuentes := TiemposMasUsadosClase()
        c.usoVersion := ClaseUsoVersion
        for indice, boton in c.frecuentes {
            if indice <= c.topFrecuentes.Length
                ActualizarBotonModerno(boton, c.topFrecuentes[indice].minutos " min")
        }
    }
    for indice, boton in c.frecuentes
        boton.Visible := ClaseVista = 1 && indice <= c.topFrecuentes.Length
    c.sinFrecuentes.Visible := ClaseVista = 1 && !c.topFrecuentes.Length
}

GuardarTiemposRapidosClase() {
    global ArchivoConfig, ClaseTiemposRapidos
    valores := ""
    for indice, minutos in ClaseTiemposRapidos
        valores .= (indice = 1 ? "" : ",") minutos
    IniWrite(valores, ArchivoConfig, "Clase", "TiemposRapidos")
}

AbrirTiemposRapidosClase(*) {
    global ClaseTiemposGui, ClaseCamposTiempos, ClaseTiemposRapidos, ClaseGui, CerrandoMostrador
    global UIEscalasModernas
    if CerrandoMostrador
        return
    if ClaseTiemposGui is Gui {
        MostrarDialogoMostrador(ClaseTiemposGui)
        return
    }
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", "Tiempos rápidos")
        ClaseTiemposGui := g, ClaseCamposTiempos := []
        s := ClaseGui is Gui ? EscalaGuiModerna(ClaseGui) : A_ScreenDPI / 96
        UIEscalasModernas[g.Hwnd] := s
        g.BackColor := "0F0F0F"
        g.MarginX := 0, g.MarginY := 0
        FuentePanelClase(g, 17, "F1F1F1", true)
        g.AddText(RectModerno(g, 20, 18, 320, 32), "Tus tiempos rápidos")
        FuentePanelClase(g, 10, "AAAAAA")
        g.AddText(RectModerno(g, 20, 60, 320, 46), "Elige cuatro duraciones diferentes.`nEntre 1 y 180 minutos.")
        for indice, minutos in ClaseTiemposRapidos {
            y := 124 + (indice - 1) * 54
            FuentePanelClase(g, 11, "D6D6D6")
            g.AddText(RectModerno(g, 24, y, 128, 36) " +0x200", "Acceso " indice)
            FuentePanelClase(g, 14, "F1F1F1", true)
            campo := g.AddEdit(RectModerno(g, 160, y, 100, 36)
                " Number Center -E0x200 -Border Background181818 cF1F1F1", minutos)
            ClaseCamposTiempos.Push(campo)
            FuentePanelClase(g, 10, "909090")
            g.AddText(RectModerno(g, 274, y, 64, 36) " +0x200", "min")
        }
        BotonClaseModerno(g, "Cancelar", 20, 354, 144, 44, CerrarTiemposRapidosClase)
        BotonClaseModerno(g, "Guardar", 176, 354, 164, 44, AplicarTiemposRapidosClase, "A8C7FA", "10233D", 22)
        g.OnEvent("Close", CerrarTiemposRapidosClase)
        g.OnEvent("Escape", CerrarTiemposRapidosClase)
        w := Round(360 * s), h := Round(420 * s)
        if ClaseGui is Gui {
            ClaseGui.GetPos(&px, &py, &pw, &ph)
            pos := PosicionEnPantalla(px + ((pw - w) // 2), py + ((ph - h) // 2), w, h)
        } else {
            MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
            pos := PosicionEnPantalla(l + ((r - l - w) // 2), t + ((b - t - h) // 2), w, h)
        }
        g.Show(Format("Hide x{} y{} w{} h{}", pos[1], pos[2], w, h))
        RedondearNota(g, w, h, Round(24 * s))
        MostrarDialogoMostrador(g)
    } catch as err {
        CerrarTiemposRapidosClase()
        MsgBox("No se pudo abrir el editor: " err.Message, "Tiempos rápidos")
    } finally {
        Critical criticoAnterior
    }
}

AplicarTiemposRapidosClase(*) {
    global ClaseCamposTiempos, ClaseTiemposRapidos, ClaseTiemposGui
    if ClaseCamposTiempos.Length != 4
        return
    valores := [], vistos := Map()
    for campo in ClaseCamposTiempos {
        valor := campo.Value
        if !IsInteger(valor) || valor < 1 || valor > 180 {
            MsgBox("Cada duración debe estar entre 1 y 180 minutos.", "Tiempos rápidos")
            if (ClaseTiemposGui is Gui) && DllCall("IsWindow", "ptr", campo.Hwnd)
                try campo.Focus()
            return
        }
        minutos := Integer(valor)
        if vistos.Has(minutos) {
            MsgBox("Elige cuatro duraciones diferentes para aprovechar los accesos.", "Tiempos rápidos")
            if (ClaseTiemposGui is Gui) && DllCall("IsWindow", "ptr", campo.Hwnd)
                try campo.Focus()
            return
        }
        vistos[minutos] := true
        valores.Push(minutos)
    }
    ClaseTiemposRapidos := valores
    GuardarTiemposRapidosClase()
    CerrarTiemposRapidosClase()
    ActualizarClase()
}

CerrarTiemposRapidosClase(*) {
    global ClaseTiemposGui, ClaseCamposTiempos
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        g := ClaseTiemposGui
        ClaseTiemposGui := 0, ClaseCamposTiempos := []
        if g is Gui {
            LiberarImagenesModernas(g)
            g.Destroy()
        }
    } finally {
        Critical criticoAnterior
    }
}

LeerEnteroClase(clave, defecto, minimo, maximo) {
    global ArchivoConfig
    valor := IniRead(ArchivoConfig, "Clase", clave, defecto)
    return IsInteger(valor) ? Max(minimo, Min(maximo, Integer(valor))) : defecto
}

RectClase(x, y, w, h) {
    s := A_ScreenDPI / 96
    return Format("x{} y{} w{} h{}", Round(x * s), Round(y * s), Round(w * s), Round(h * s))
}

AbrirPanelClase(*) {
    global ClaseGui, ClaseControles, ClaseMinutos, ClaseRelojMostrar, ClaseAvisoSonoro, ClaseTiemposRapidos
    global ClaseGrupos, ClaseVista, ClaseArrastre, ClaseEsferaClave, UIEscalasModernas
    global FocoRadio, FocoOpacidad, CerrandoMostrador, AnotModo
    if CerrandoMostrador
        return
    if AnotModo
        PausarAnotaciones()
    if ClaseGui is Gui {
        MostrarDialogoMostrador(ClaseGui)
        return
    }
    anteriorCritico := A_IsCritical
    Critical "On"
    try {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", "Panel de clase")
        ClaseGui := g, ClaseGrupos := [[], [], []], ClaseArrastre := Map()
        punto := Buffer(8, 0)
        DllCall("GetCursorPos", "ptr", punto)
        monitor := DllCall("MonitorFromPoint", "int64", NumGet(punto, 0, "int64"), "uint", 2, "ptr")
        info := Buffer(40, 0)
        NumPut("uint", 40, info)
        if DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info) {
            l := NumGet(info, 20, "int"), t := NumGet(info, 24, "int")
            r := NumGet(info, 28, "int"), b := NumGet(info, 32, "int")
        } else {
            MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
        }
        ; Ajustar el panel también a proyectores con menos altura disponible.
        s := Min(A_ScreenDPI / 96, (b - t - 32) / 650, (r - l - 24) / 408)
        UIEscalasModernas[g.Hwnd] := s
        w := Round(408 * s), h := Round(650 * s)
        g.BackColor := "0F0F0F"
        g.MarginX := 0, g.MarginY := 0
        g.AddText(RectModerno(g, 0, 0, 408, 650) " Background303030")
        g.AddText(RectModerno(g, 1, 1, 406, 648) " Background0F0F0F")
        FuentePanelClase(g, 18, "F1F1F1", true)
        titulo := g.AddText(RectModerno(g, 22, 16, 290, 32) " +0x100", "Clase")
        FuentePanelClase(g, 9, "909090")
        subtitulo := g.AddText(RectModerno(g, 22, 49, 290, 22) " +0x100", "Tiempo y atención, a tu ritmo")
        ClaseArrastre[titulo.Hwnd] := true, ClaseArrastre[subtitulo.Hwnd] := true
        BotonClaseModerno(g, "X", 354, 20, 32, 32, CerrarPanelClase, "232323", "AAAAAA", 16)
        tabs := []
        for i, nombre in ["Tiempo", "Foco", "Ayudas"]
            tabs.Push(BotonClaseModerno(g, nombre, 20 + (i - 1) * 124, 86, 120, 38, MostrarVistaClase.Bind(i)))

        cara := ControlVistaClase(1, g.AddText(RectModerno(g, 102, 134, 204, 204) " +0xE"))
        FuentePanelClase(g, 9, "909090")
        ControlVistaClase(1, g.AddText(RectModerno(g, 24, 340, 264, 22), "TIEMPOS RÁPIDOS"))
        ControlVistaClase(1, BotonClaseModerno(g, "Editar", 312, 336, 76, 28, AbrirTiemposRapidosClase,
            "1D1D1D", "B6D7FF", 14))
        presets := []
        for i, minutos in ClaseTiemposRapidos {
            boton := BotonClaseModerno(g, minutos " min", 20 + (i - 1) * 94, 370, 86, 38,
                ElegirTiempoRapidoClase.Bind(i), "232323", "D6D6D6", 19)
            ControlVistaClase(1, boton)
            presets.Push(boton)
        }
        FuentePanelClase(g, 9, "909090")
        ControlVistaClase(1, g.AddText(RectModerno(g, 24, 418, 360, 20), "MÁS USADOS"))
        frecuentes := []
        Loop 3 {
            boton := BotonClaseModerno(g, "—", 20 + (A_Index - 1) * 126, 442, 116, 36,
                ElegirTiempoFrecuenteClase.Bind(A_Index), "1D1D1D", "AAAAAA", 18)
            ControlVistaClase(1, boton)
            frecuentes.Push(boton)
        }
        FuentePanelClase(g, 9, "707070")
        sinFrecuentes := ControlVistaClase(1, g.AddText(RectModerno(g, 24, 446, 360, 26)
            " Center +0x200", "Aparecerán al iniciar tus temporizadores."))
        menos := ControlVistaClase(1, BotonClaseModerno(g, "−", 82, 496, 44, 38, AjustarMinutosClase.Bind(-1), "232323"))
        FuentePanelClase(g, 17, "F1F1F1", true)
        minutosEdit := ControlVistaClase(1, g.AddEdit(RectModerno(g, 138, 496, 76, 38)
            " Number Center -E0x200 -Border Background181818 cF1F1F1", ClaseMinutos))
        minutosEdit.OnEvent("Change", ProgramarMinutosClase)
        FuentePanelClase(g, 10, "909090")
        ControlVistaClase(1, g.AddText(RectModerno(g, 222, 496, 40, 38) " +0x200", "min"))
        mas := ControlVistaClase(1, BotonClaseModerno(g, "+", 280, 496, 44, 38, AjustarMinutosClase.Bind(1), "232323"))
        ControlVistaClase(1, BotonClaseModerno(g, "Reiniciar", 20, 548, 104, 44, ReiniciarTemporizadorClase))
        iniciar := ControlVistaClase(1, BotonClaseModerno(g, "Iniciar", 134, 548, 140, 44,
            AlternarTemporizadorClase, "A8C7FA", "10233D", 23))
        ControlVistaClase(1, BotonClaseModerno(g, "+1 min", 284, 548, 104, 44, SumarMinutoClase))
        reloj := ControlVistaClase(1, BotonClaseModerno(g, "Reloj: sí", 20, 606, 176, 30,
            AlternarPreferenciaClase.Bind("reloj"), "1D1D1D", "AAAAAA", 17))
        sonido := ControlVistaClase(1, BotonClaseModerno(g, "Sonido: no", 208, 606, 180, 30,
            AlternarPreferenciaClase.Bind("sonido"), "1D1D1D", "AAAAAA", 17))

        FuentePanelClase(g, 19, "F1F1F1", true)
        ControlVistaClase(2, g.AddText(RectModerno(g, 24, 156, 360, 34), "Dirige la atención"))
        FuentePanelClase(g, 10, "AAAAAA")
        ControlVistaClase(2, g.AddText(RectModerno(g, 24, 202, 360, 48), "Ilumina lo que señalas y atenúa el resto.`nLos clics siguen funcionando."))
        foco := ControlVistaClase(2, BotonClaseModerno(g, "Activar foco", 20, 266, 368, 52,
            AlternarFocoClase, "203044", "B6D7FF", 26))
        FuentePanelClase(g, 9, "909090")
        ControlVistaClase(2, g.AddText(RectModerno(g, 24, 344, 352, 22), "TAMAÑO DEL FOCO"))
        ControlVistaClase(2, BotonClaseModerno(g, "−", 20, 376, 52, 46, AjustarFocoClase.Bind("radio", -20)))
        FuentePanelClase(g, 18, "F1F1F1", true)
        radioTexto := ControlVistaClase(2, g.AddText(RectModerno(g, 84, 376, 240, 46) " Center +0x200", FocoRadio " px"))
        ControlVistaClase(2, BotonClaseModerno(g, "+", 336, 376, 52, 46, AjustarFocoClase.Bind("radio", 20)))
        FuentePanelClase(g, 9, "909090")
        ControlVistaClase(2, g.AddText(RectModerno(g, 24, 454, 352, 22), "INTENSIDAD"))
        ControlVistaClase(2, BotonClaseModerno(g, "−", 20, 486, 52, 46, AjustarFocoClase.Bind("opacidad", -5)))
        FuentePanelClase(g, 18, "F1F1F1", true)
        opacidadTexto := ControlVistaClase(2, g.AddText(RectModerno(g, 84, 486, 240, 46) " Center +0x200", FocoOpacidad " %"))
        ControlVistaClase(2, BotonClaseModerno(g, "+", 336, 486, 52, 46, AjustarFocoClase.Bind("opacidad", 5)))
        FuentePanelClase(g, 9, "909090")
        ControlVistaClase(2, g.AddText(RectModerno(g, 24, 570, 360, 26) " Center", "Atajo rápido: Ctrl + Alt + E"))

        teclado := ControlVistaClase(3, BotonClaseModerno(g, "Teclado`nMinimizar", 20, 156, 178, 104,
            (*) => AlternarMinimizado(), "232323", "F1F1F1", 24))
        aura := ControlVistaClase(3, BotonClaseModerno(g, "Aura`nApagar", 210, 156, 178, 104,
            (*) => AlternarResplandorMouse(), "232323", "F1F1F1", 24))
        ControlVistaClase(3, BotonClaseModerno(g, "Anotaciones`nDibujar y escribir", 20, 274, 178, 104,
            IniciarAnotaciones, "203044", "B6D7FF", 24))
        ControlVistaClase(3, BotonClaseModerno(g, "Notas`nEditar el texto", 210, 274, 178, 104,
            AbrirAyudaDesdeClase.Bind(EditarNotaDirecta), "35232A", "FFBBC7", 24))
        ControlVistaClase(3, BotonClaseModerno(g, "Mouse y aura`nPersonalizar apariencia", 20, 402, 368, 72,
            AbrirAyudaDesdeClase.Bind(AbrirAjustesMouse), "1D1D1D", "F1F1F1", 22))
        ControlVistaClase(3, BotonClaseModerno(g, "Selección de texto`nContraste y resaltado", 20, 488, 368, 72,
            AbrirAyudaDesdeClase.Bind(AbrirAjustesSeleccion), "1D1D1D", "F1F1F1", 22))
        FuentePanelClase(g, 9, "909090")
        ControlVistaClase(3, g.AddText(RectModerno(g, 24, 580, 360, 22) " Center", "Activa sólo lo que necesites para explicar."))

        ClaseControles := {cuenta: cara, minutos: minutosEdit, iniciar: iniciar, menos: menos, mas: mas,
            reloj: reloj, sonido: sonido, foco: foco, radioTexto: radioTexto, opacidadTexto: opacidadTexto,
            teclado: teclado, aura: aura, presets: presets, tabs: tabs, frecuentes: frecuentes,
            sinFrecuentes: sinFrecuentes, topFrecuentes: [], usoVersion: -1}
        g.OnEvent("Close", CerrarPanelClase)
        g.OnEvent("Escape", CerrarPanelClase)
        ClaseEsferaClave := ""
        MostrarVistaClase(ClaseVista)
        g.Show(Format("Hide x{} y{} w{} h{}", l + ((r - l - w) // 2), t + ((b - t - h) // 2), w, h))
        RedondearNota(g, w, h, Round(26 * s))
        MostrarDialogoMostrador(g)
        SetTimer(ActualizarClase, 250)
    } catch as err {
        CerrarPanelClase()
        MsgBox("No se pudo abrir el panel: " err.Message, "Panel de clase")
    } finally {
        Critical anteriorCritico
    }
}

CerrarPanelClase(*) {
    global ClaseGui, ClaseControles, ClaseGrupos, ClaseArrastre, ClaseEsferaClave, CerrandoMostrador
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        CerrarTiemposRapidosClase()
        SetTimer(AplicarMinutosClase, 0)
        if !CerrandoMostrador && (ClaseGui is Gui) {
            LeerDuracionPanelClase()
            GuardarClaseConfig()
        }
        g := ClaseGui
        ClaseGui := 0, ClaseControles := 0, ClaseGrupos := [[], [], []], ClaseArrastre := Map(), ClaseEsferaClave := ""
        if g is Gui {
            LiberarImagenesModernas(g)
            g.Destroy()
        }
        if !CerrandoMostrador
            ActualizarClase()
    } finally {
        Critical criticoAnterior
    }
}



LeerDuracionPanelClase() {
    global ClaseTotalMs
    global ClaseControles, ClaseMinutos, ClaseEnMarcha, ClaseRestanteMs, ClaseTerminado, ClaseRelojSolicitado
    if !IsObject(ClaseControles) || ClaseEnMarcha
        return
    valor := ClaseControles.minutos.Value
    minutos := IsInteger(valor) ? Max(1, Min(180, Integer(valor))) : ClaseMinutos
    ClaseControles.minutos.Value := minutos
    if minutos != ClaseMinutos {
        ClaseMinutos := minutos, ClaseRestanteMs := minutos * 60000, ClaseTotalMs := ClaseRestanteMs, ClaseTerminado := false, ClaseRelojSolicitado := false
    }
}

ElegirMinutosClase(minutos, *) {
    global ClaseTotalMs
    global ClaseMinutos, ClaseRestanteMs, ClaseEnMarcha, ClaseTerminado, ClaseRelojSolicitado, ClaseControles
    ClaseMinutos := minutos, ClaseRestanteMs := minutos * 60000, ClaseTotalMs := ClaseRestanteMs
    ClaseEnMarcha := false, ClaseTerminado := false, ClaseRelojSolicitado := false
    if IsObject(ClaseControles)
        ClaseControles.minutos.Value := minutos
    GuardarClaseConfig()
    ActualizarClase()
}

AhoraClase() => DllCall("GetTickCount64", "uint64")

AlternarTemporizadorClase(*) {
    global ClaseTotalMs
    global ClaseEnMarcha, ClaseFinTick, ClaseRestanteMs, ClaseTerminado, ClaseRelojSolicitado, ClaseMinutos, CerrandoMostrador
    if CerrandoMostrador
        return
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if ClaseEnMarcha {
            ClaseRestanteMs := Max(0, ClaseFinTick - AhoraClase())
            ClaseEnMarcha := false
            ClaseTerminado := ClaseRestanteMs = 0
        } else {
            LeerDuracionPanelClase()
            SetTimer(AplicarMinutosClase, 0)
            nuevaCuenta := !ClaseRelojSolicitado || ClaseTerminado || ClaseRestanteMs <= 0
            if ClaseRestanteMs <= 0 {
                ClaseRestanteMs := ClaseMinutos * 60000, ClaseTotalMs := ClaseRestanteMs
            }
            if nuevaCuenta
                RegistrarUsoTiempoClase(ClaseRestanteMs)
            ClaseTerminado := false, ClaseEnMarcha := true, ClaseRelojSolicitado := true
            ClaseFinTick := AhoraClase() + ClaseRestanteMs
            SetTimer(ActualizarClase, 250)
        }
        GuardarClaseConfig()
        ActualizarClase()
    } finally {
        Critical criticoAnterior
    }
}

ReiniciarTemporizadorClase(*) {
    global ClaseTotalMs
    global ClaseEnMarcha, ClaseTerminado, ClaseRestanteMs, ClaseMinutos, ClaseRelojSolicitado
    ClaseEnMarcha := false
    LeerDuracionPanelClase()
    ClaseRestanteMs := ClaseMinutos * 60000, ClaseTotalMs := ClaseRestanteMs, ClaseTerminado := false, ClaseRelojSolicitado := false
    GuardarClaseConfig()
    ActualizarClase()
}

SumarMinutoClase(*) {
    global ClaseTotalMs
    global ClaseEnMarcha, ClaseFinTick, ClaseRestanteMs, ClaseTerminado
    LeerDuracionPanelClase()
    SetTimer(AplicarMinutosClase, 0)
    if ClaseEnMarcha {
        ahora := AhoraClase()
        ClaseFinTick := ahora + Min(180 * 60000, Max(0, ClaseFinTick - ahora) + 60000)
    } else {
        ClaseRestanteMs := Min(180 * 60000, ClaseRestanteMs + 60000)
    }
    ClaseTotalMs := Min(180 * 60000, ClaseTotalMs + 60000)
    ClaseTerminado := false
    ActualizarClase()
}

TextoControlClase(control, texto) {
    if control.Text != texto
        control.Text := texto
}

ActualizarClase() {
    global ClaseGui, ClaseControles, ClaseEnMarcha, ClaseFinTick, ClaseRestanteMs, ClaseTotalMs, ClaseTerminado
    global ClaseRelojSolicitado, ClaseRelojMostrar, ClaseAvisoSonoro, ClaseMinutos, ClaseVista, ClaseEsferaClave
    global RelojClaseGui, RelojClaseCuenta, RelojClaseAccion, RelojClaseClave
    global FocoClaseActivo, FocoRadio, FocoOpacidad, Minimizado, ResplandorMouse, CerrandoMostrador
    if CerrandoMostrador
        return
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        aviso := false
        if ClaseEnMarcha {
            ClaseRestanteMs := Max(0, ClaseFinTick - AhoraClase())
            if ClaseRestanteMs = 0 {
                ClaseEnMarcha := false, ClaseTerminado := true
                aviso := ClaseAvisoSonoro
            }
        }
        segundos := Ceil(ClaseRestanteMs / 1000)
        cuenta := Format("{:02}:{:02}", segundos // 60, Mod(segundos, 60))
        estado := ClaseTerminado ? "Tiempo cumplido" : ClaseEnMarcha ? "En curso" : ClaseRelojSolicitado ? "En pausa" : "Listo"
        color := ClaseTerminado ? "FF637D" : (ClaseEnMarcha && segundos <= 10) || (!ClaseEnMarcha && ClaseRelojSolicitado) ? "FFC857" : "8AB4F8"
        progreso := ClaseTerminado ? 1 : Min(1, ClaseRestanteMs / Max(1, ClaseTotalMs))
        clave := cuenta "|" estado "|" color "|" Round(progreso * 360)
        if ClaseRelojMostrar && ClaseRelojSolicitado {
            CrearRelojClase()
            if RelojClaseClave != clave {
                RelojClaseClave := clave
                tam := Round(188 * EscalaGuiModerna(RelojClaseGui))
                PonerImagenModerna(RelojClaseCuenta, DibujarEsferaClase(tam, progreso, cuenta,
                    ClaseTerminado ? "Fin" : ClaseEnMarcha ? "En curso" : "Pausa", color, true))
            }
            ActualizarBotonModerno(RelojClaseAccion, ClaseEnMarcha ? "Pausar" : ClaseTerminado ? "Otra vez" : "Seguir")
            if !DllCall("IsWindowVisible", "ptr", RelojClaseGui.Hwnd)
                RelojClaseGui.Show("NoActivate")
        } else if RelojClaseGui is Gui {
            RelojClaseGui.Hide()
        }
        if IsObject(ClaseControles) {
            c := ClaseControles
            if ClaseVista = 1 && ClaseEsferaClave != clave {
                ClaseEsferaClave := clave
                tam := Round(204 * EscalaGuiModerna(ClaseGui))
                PonerImagenModerna(c.cuenta, DibujarEsferaClase(tam, progreso, cuenta, estado, color))
            }
            ActualizarBotonModerno(c.iniciar, ClaseEnMarcha ? "Pausar" : ClaseRelojSolicitado && !ClaseTerminado ? "Continuar" : "Iniciar")
            ActualizarBotonModerno(c.reloj, "Reloj: " (ClaseRelojMostrar ? "sí" : "no"), , ClaseRelojMostrar ? "B6D7FF" : "909090")
            ActualizarBotonModerno(c.sonido, "Sonido: " (ClaseAvisoSonoro ? "sí" : "no"), , ClaseAvisoSonoro ? "B6D7FF" : "909090")
            ActualizarBotonModerno(c.foco, FocoClaseActivo ? "Apagar foco" : "Activar foco",
                FocoClaseActivo ? "A8C7FA" : "203044", FocoClaseActivo ? "10233D" : "B6D7FF")
            TextoControlClase(c.radioTexto, FocoRadio " px")
            TextoControlClase(c.opacidadTexto, FocoOpacidad " %")
            ActualizarBotonModerno(c.teclado, "Teclado`n" (Minimizado ? "Expandir" : "Minimizar"))
            ActualizarBotonModerno(c.aura, "Aura`n" (ResplandorMouse ? "Apagar" : "Activar"))
            ActualizarTiemposPanelClase()
            if c.minutos.Enabled = ClaseEnMarcha
                c.minutos.Enabled := !ClaseEnMarcha
            c.menos.Enabled := !ClaseEnMarcha
            c.mas.Enabled := !ClaseEnMarcha
            ActualizarBotonModerno(c.menos, , ClaseEnMarcha ? "181818" : "232323", ClaseEnMarcha ? "555555" : "F1F1F1")
            ActualizarBotonModerno(c.mas, , ClaseEnMarcha ? "181818" : "232323", ClaseEnMarcha ? "555555" : "F1F1F1")
        }
        if !ClaseEnMarcha && !(ClaseGui is Gui)
            SetTimer(ActualizarClase, 0)
        if aviso
            SetTimer(AvisarFinClase, -1)
    } finally {
        Critical criticoAnterior
    }
}

AvisarFinClase() {
    global CerrandoMostrador, ClaseTerminado, ClaseAvisoSonoro
    if !CerrandoMostrador && ClaseTerminado && ClaseAvisoSonoro
        SoundBeep(880, 180)
}

CrearRelojClase() {
    global RelojClaseGui, RelojClaseCuenta, RelojClaseAccion, RelojClaseClave, ClaseRelojX, ClaseRelojY
    if RelojClaseGui is Gui
        return
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000", "Reloj de clase")
    RelojClaseGui := g, RelojClaseClave := ""
    g.BackColor := "0F0F0F"
    g.MarginX := 0, g.MarginY := 0
    RelojClaseCuenta := g.AddText(RectModerno(g, 0, 0, 188, 188) " +0xE +0x100")
    RelojClaseAccion := BotonClaseModerno(g, "Pausar", 12, 190, 78, 32, AlternarTemporizadorClase,
        "203044", "B6D7FF", 16)
    BotonClaseModerno(g, "Abrir", 98, 190, 78, 32, AbrirPanelClase, "232323", "D6D6D6", 16)
    g.OnEvent("ContextMenu", AbrirPanelClase)
    s := EscalaGuiModerna(g)
    w := Round(188 * s), h := Round(234 * s)
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    x := IsInteger(ClaseRelojX) ? Integer(ClaseRelojX) : r - w - 20
    y := IsInteger(ClaseRelojY) ? Integer(ClaseRelojY) : t + 20
    pos := PosicionEnPantalla(x, y, w, h)
    g.Show(Format("Hide x{} y{} w{} h{}", pos[1], pos[2], w, h))
    RedondearNota(g, w, h, Round(28 * s))
}

ArrastrarRelojClase(wParam, lParam, msg, hwnd) {
    global RelojClaseGui, RelojClaseCuenta, CerrandoMostrador
    if CerrandoMostrador || !(RelojClaseGui is Gui)
        return
    ; Los botones inferiores reciben sus clics; sólo la esfera arrastra el reloj.
    if hwnd != RelojClaseGui.Hwnd && hwnd != RelojClaseCuenta.Hwnd
        return
    DllCall("ReleaseCapture")
    PostMessage(0x00A1, 2, 0, , "ahk_id " RelojClaseGui.Hwnd)
    return 0
}

GuardarPosicionRelojClase(wParam, lParam, msg, hwnd) {
    global RelojClaseGui, ClaseRelojX, ClaseRelojY, ArchivoConfig, CerrandoMostrador
    if CerrandoMostrador || !(RelojClaseGui is Gui) || hwnd != RelojClaseGui.Hwnd
        return
    RelojClaseGui.GetPos(&x, &y, &w, &h)
    pos := PosicionEnPantalla(x, y, w, h)
    RelojClaseGui.Move(pos[1], pos[2])
    ClaseRelojX := pos[1], ClaseRelojY := pos[2]
    IniWrite(ClaseRelojX, ArchivoConfig, "Clase", "RelojX")
    IniWrite(ClaseRelojY, ArchivoConfig, "Clase", "RelojY")
}



AlternarFocoClase(*) {
    global FocoClaseActivo, CerrandoMostrador
    if CerrandoMostrador
        return
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if FocoClaseActivo {
            FocoClaseActivo := false
            DestruirFocoClase()
        } else {
            FocoClaseActivo := true
            try CrearFocoClase()
            catch as err {
                FocoClaseActivo := false
                DestruirFocoClase()
                MsgBox("No se pudo activar el foco: " err.Message, "Panel de clase")
                return
            }
        }
        try A_TrayMenu.ToggleCheck("Foco del cursor  (Ctrl+Alt+E)")
        GuardarClaseConfig()
        ActualizarClase()
    } finally {
        Critical criticoAnterior
    }
}

CrearFocoClase() {
    global FocoClaseGui, FocoOpacidad, FocoVirtualX, FocoVirtualY, FocoVirtualW, FocoVirtualH
    DestruirFocoClase()
    FocoVirtualX := SysGet(76), FocoVirtualY := SysGet(77)
    FocoVirtualW := SysGet(78), FocoVirtualH := SysGet(79)
    if FocoVirtualW < 1 || FocoVirtualH < 1
        throw Error("Windows todavía no facilita las dimensiones de la pantalla.")
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08080020", "Foco de clase")
    FocoClaseGui := g
    g.BackColor := "000000"
    g.Move(FocoVirtualX, FocoVirtualY, FocoVirtualW, FocoVirtualH)
    WinSetTransparent(Round(FocoOpacidad * 255 / 100), "ahk_id " g.Hwnd)
    if !ActualizarFocoClase()
        throw Error("No se pudo preparar el foco del cursor.")
    g.Show(Format("x{} y{} w{} h{} NoActivate", FocoVirtualX, FocoVirtualY, FocoVirtualW, FocoVirtualH))
    ElevarAyudasClase()
    SetTimer(ActualizarFocoClase, 33)
}

ActualizarFocoClase() {
    global FocoClaseGui, FocoClaseActivo, FocoRadio, FocoX, FocoY
    global FocoVirtualX, FocoVirtualY, FocoVirtualW, FocoVirtualH, CerrandoMostrador
    if CerrandoMostrador || !FocoClaseActivo || !(FocoClaseGui is Gui)
        return false
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        punto := Buffer(8, 0)
        if !DllCall("GetCursorPos", "ptr", punto)
            return false
        x := NumGet(punto, 0, "int") - FocoVirtualX
        y := NumGet(punto, 4, "int") - FocoVirtualY
        if x = FocoX && y = FocoY
            return true
        region := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", FocoVirtualW, "int", FocoVirtualH, "ptr")
        hueco := DllCall("CreateEllipticRgn", "int", x - FocoRadio, "int", y - FocoRadio,
            "int", x + FocoRadio, "int", y + FocoRadio, "ptr")
        if !region || !hueco {
            if region
                DllCall("DeleteObject", "ptr", region)
            if hueco
                DllCall("DeleteObject", "ptr", hueco)
            return false
        }
        resultado := DllCall("CombineRgn", "ptr", region, "ptr", region, "ptr", hueco, "int", 4)
        DllCall("DeleteObject", "ptr", hueco)
        if !resultado || !DllCall("SetWindowRgn", "ptr", FocoClaseGui.Hwnd, "ptr", region, "int", true) {
            DllCall("DeleteObject", "ptr", region)
            return false
        }
        ; Windows pasa a ser propietario de la región asignada.
        FocoX := x, FocoY := y
        return true
    } finally {
        Critical criticoAnterior
    }
}

ElevarAyudasClase() {
    ReordenarCapasMostrador()
}

DestruirFocoClase() {
    global FocoClaseGui, FocoX, FocoY
    SetTimer(ActualizarFocoClase, 0)
    g := FocoClaseGui
    FocoClaseGui := 0, FocoX := "", FocoY := ""
    if g is Gui
        g.Destroy()
}

ActualizarPantallasClase() {
    global FocoClaseActivo, RelojClaseGui, ClaseGui, CerrandoMostrador
    if CerrandoMostrador
        return
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if FocoClaseActivo {
            try CrearFocoClase()
            catch {
                FocoClaseActivo := false
                DestruirFocoClase()
                try A_TrayMenu.Uncheck("Foco del cursor  (Ctrl+Alt+E)")
                ActualizarClase()
            }
        }
        for g in [RelojClaseGui, ClaseGui] {
            if !(g is Gui)
                continue
            g.GetPos(&x, &y, &w, &h)
            pos := PosicionEnPantalla(x, y, w, h)
            g.Move(pos[1], pos[2])
        }
    } finally {
        Critical criticoAnterior
    }
}

GuardarClaseConfig() {
    GuardarTiemposRapidosClase()
    global ArchivoConfig, ClaseMinutos, ClaseRelojMostrar, ClaseAvisoSonoro, FocoRadio, FocoOpacidad
    for clave, valor in Map("Minutos", ClaseMinutos, "RelojMostrar", ClaseRelojMostrar,
        "AvisoSonoro", ClaseAvisoSonoro, "RadioFoco", FocoRadio, "OpacidadFoco", FocoOpacidad)
        IniWrite(valor, ArchivoConfig, "Clase", clave)
}

CerrarHerramientasClase() {
    global RelojClaseGui, RelojClaseCuenta, RelojClaseEstado, ClaseEnMarcha, FocoClaseActivo, RelojClaseAccion
    CerrarTiemposRapidosClase()
    SetTimer(ActualizarClase, 0)
    SetTimer(AplicarMinutosClase, 0)
    SetTimer(AvisarFinClase, 0)
    SetTimer(ActualizarPantallasClase, 0)
    LeerDuracionPanelClase()
    try GuardarClaseConfig()
    ClaseEnMarcha := false, FocoClaseActivo := false
    DestruirFocoClase()
    CerrarPanelClase()
    g := RelojClaseGui
    RelojClaseGui := 0, RelojClaseCuenta := 0, RelojClaseEstado := 0, RelojClaseAccion := 0
    if g is Gui {
        LiberarImagenesModernas(g)
        g.Destroy()
    }
}

ConfigurarBandeja() {
    global MostrarMouse, MostrarHistorial, DemostracionMouse
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Demostrar atajos con el mouse", AlternarDemostracionMouse)
    if DemostracionMouse
        A_TrayMenu.Check("Demostrar atajos con el mouse")
    A_TrayMenu.Add("Panel de clase...  (Ctrl+Alt+C)", AbrirPanelClase)
    A_TrayMenu.Add("Iniciar / pausar temporizador  (Ctrl+Alt+P)", AlternarTemporizadorClase)
    A_TrayMenu.Add("Foco del cursor  (Ctrl+Alt+E)", AlternarFocoClase)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Minimizar / expandir  (Ctrl+Alt+N)", (*) => AlternarMinimizado())
    A_TrayMenu.Add("Editar nota de clase...  (Ctrl+Alt+O)", (*) => EditarNotaDirecta())
    A_TrayMenu.Add("Mostrar / ocultar nota  (Ctrl+Alt+T)", (*) => AlternarNota())
    A_TrayMenu.Add("Ajustes del mouse y aura...", (*) => AbrirAjustesMouse())
    A_TrayMenu.Add("Resaltar selección de texto  (Ctrl+Alt+S)", (*) => AlternarSeleccion())
    A_TrayMenu.Add("Ajustes de selección de texto...", (*) => AbrirAjustesSeleccion())
    A_TrayMenu.Add("Anotar pantalla  (Ctrl+Alt+A)", AlternarAnotaciones)
    A_TrayMenu.Add("Ajustes de anotaciones...", AbrirAjustesAnotaciones)
    A_TrayMenu.Add("Borrar anotaciones  (Ctrl+Alt+X)", BorrarAnotaciones)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Bloquear / desbloquear posición  (Ctrl+Alt+L)", (*) => AlternarBloqueo())
    A_TrayMenu.Add("Más grande  (Ctrl+Alt+RePág)", (*) => CambiarEscala(0.1))
    A_TrayMenu.Add("Más pequeño  (Ctrl+Alt+AvPág)", (*) => CambiarEscala(-0.1))
    A_TrayMenu.Add("Teclado / solo texto  (Ctrl+Alt+K)", (*) => AlternarModo())
    A_TrayMenu.Add("Siempre visible / ocultarse solo  (Ctrl+Alt+H)", (*) => AlternarAutoOcultar())
    A_TrayMenu.Add("Latinoamérica / España  (Ctrl+Alt+D)", (*) => AlternarDistribucion())
    A_TrayMenu.Add("Volver a la esquina  (Ctrl+Alt+R)", (*) => RestablecerPosicion())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Mostrar / ocultar historial  (Ctrl+Alt+I)", (*) => AlternarHistorial())
    if MostrarHistorial
        A_TrayMenu.Check("Mostrar / ocultar historial  (Ctrl+Alt+I)")
    A_TrayMenu.Add("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)", (*) => AlternarMouseVisual())
    if MostrarMouse
        A_TrayMenu.Check("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)")
    A_TrayMenu.Add("Resplandor del mouse  (Ctrl+Alt+M)", (*) => AlternarResplandorMouse())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Salir  (Ctrl+Alt+Q)", (*) => ExitApp())
    A_IconTip := "Mostrador · teclado, notas y herramientas de clase"
}


; Halo amarillo suave, independiente del autoocultado del teclado.
; Ventana por pixel: no roba el foco y todos los clics la atraviesan.
CrearHaloMouse() {
    global HaloMouse, HaloDC, HaloBitmap, HaloAnterior, HaloTam, HaloColor, HaloOpacidad
    ; Preparar los recursos nuevos antes de soltar los anteriores.
    nuevoGui := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80020 +E0x08000000")
    bi := Buffer(40, 0)
    NumPut("uint", 40, "int", HaloTam, "int", -HaloTam, "ushort", 1, "ushort", 32, bi)
    bits := 0
    nuevoDC := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
    nuevoBmp := DllCall("CreateDIBSection", "ptr", nuevoDC, "ptr", bi,
        "uint", 0, "ptr*", &bits, "ptr", 0, "uint", 0, "ptr")
    if (!nuevoDC || !nuevoBmp) {
        nuevoGui.Destroy()
        if nuevoBmp
            DllCall("DeleteObject", "ptr", nuevoBmp)
        if nuevoDC
            DllCall("DeleteDC", "ptr", nuevoDC)
        throw Error("No se pudo crear el resplandor del mouse.")
    }
    nuevoAnterior := DllCall("SelectObject", "ptr", nuevoDC, "ptr", nuevoBmp, "ptr")
    radio := HaloTam / 2
    rgb := Integer("0x" HaloColor)
    rojo := (rgb >> 16) & 255, verde := (rgb >> 8) & 255, azul := rgb & 255
    intensidad := 255 * HaloOpacidad / 100
    Loop HaloTam {
        y := A_Index - 1
        Loop HaloTam {
            x := A_Index - 1
            distancia := Sqrt((x - radio + 0.5)**2 + (y - radio + 0.5)**2)
            alpha := Round(intensidad * Max(0, 1 - (distancia / radio)**2)**1.4)
            pixel := (alpha << 24) | (Round(rojo * alpha / 255) << 16)
                | (Round(verde * alpha / 255) << 8) | Round(azul * alpha / 255)
            NumPut("uint", pixel, bits + 4 * (y * HaloTam + x))
        }
    }
    DestruirHaloMouse()
    HaloMouse := nuevoGui, HaloDC := nuevoDC, HaloBitmap := nuevoBmp, HaloAnterior := nuevoAnterior
}

DestruirHaloMouse() {
    global HaloMouse, HaloDC, HaloBitmap, HaloAnterior
    SetTimer(ActualizarHaloMouse, 0)
    if IsObject(HaloMouse)
        HaloMouse.Destroy()
    if (HaloDC && HaloAnterior)
        DllCall("SelectObject", "ptr", HaloDC, "ptr", HaloAnterior)
    if HaloBitmap
        DllCall("DeleteObject", "ptr", HaloBitmap)
    if HaloDC
        DllCall("DeleteDC", "ptr", HaloDC)
    HaloMouse := 0, HaloDC := 0, HaloBitmap := 0, HaloAnterior := 0
}

ActualizarHaloMouse() {
    global HaloMouse, HaloDC, HaloTam, HaloX, HaloY
    punto := Buffer(8, 0)
    if !DllCall("GetCursorPos", "ptr", punto)
        return
    x := NumGet(punto, 0, "int") - HaloTam // 2
    y := NumGet(punto, 4, "int") - HaloTam // 2
    if (x = HaloX && y = HaloY)
        return
    destino := Buffer(8, 0), tam := Buffer(8, 0), origen := Buffer(8, 0)
    mezcla := Buffer(4, 0)
    NumPut("int", x, "int", y, destino)
    NumPut("int", HaloTam, "int", HaloTam, tam)
    NumPut("uchar", 255, mezcla, 2)
    NumPut("uchar", 1, mezcla, 3) ; AC_SRC_ALPHA
    if DllCall("UpdateLayeredWindow", "ptr", HaloMouse.Hwnd, "ptr", 0,
        "ptr", destino, "ptr", tam, "ptr", HaloDC, "ptr", origen,
        "uint", 0, "ptr", mezcla, "uint", 2) {
        HaloX := x, HaloY := y
    }
}

AplicarResplandorMouse() {
    global ResplandorMouse, HaloMouse, HaloX, HaloY
    SetTimer(ActualizarHaloMouse, 0)
    if ResplandorMouse {
        HaloX := "", HaloY := ""
        ActualizarHaloMouse()
        DllCall("ShowWindow", "ptr", HaloMouse.Hwnd, "int", 8) ; sin activar
        SetTimer(ActualizarHaloMouse, 16)
        A_TrayMenu.Check("Resplandor del mouse  (Ctrl+Alt+M)")
    } else {
        HaloMouse.Hide()
        A_TrayMenu.Uncheck("Resplandor del mouse  (Ctrl+Alt+M)")
    }
}

AlternarResplandorMouse() {
    global ResplandorMouse
    ResplandorMouse := !ResplandorMouse
    AplicarResplandorMouse()
    GuardarConfig()
    AgregarAlHistorial(ResplandorMouse ? "Resplandor del mouse activado" : "Resplandor del mouse desactivado")
}

LiberarHaloMouse(*) {
    DestruirPanelNota()
    global ControlMinimizar, AjustesMouseGui, NotasGui
    if IsObject(NotasGui)
        NotasGui.Destroy()
    if IsObject(ControlMinimizar)
        ControlMinimizar.Destroy()
    if IsObject(AjustesMouseGui)
        AjustesMouseGui.Destroy()
    DestruirHaloMouse()
}


; Mouse visual integrado en la misma ventana: se mueve con el teclado.
ConstruirMouseVisual(x, y) {
    global overlay, U, PartesMouse
    w := Round(U * 2.8), h := Round(U * 4.8)
    pic := overlay.AddText(Format("x{} y{} w{} h{} +0xE", x, y, w, h))
    bmps := Map()
    ; Una imagen completa por combinacion: permite clics simultaneos.
    Loop 32
        bmps[A_Index - 1] := DibujarMouse(w, h, A_Index - 1)
    SendMessage(0x172, 0, bmps[0], pic)
    PartesMouse["dibujo"] := {pic: pic, bmps: bmps, estado: 0}
}

RefrescarMouseVisual() {
    global PartesMouse, EventosMouse, ResaltadoMs, Minimizado
    if Minimizado
        return
    if !PartesMouse.Has("dibujo")
        return
    estado := 0
    for i, boton in ["LButton", "RButton", "MButton", "WheelUp", "WheelDown"] {
        activo := EventosMouse.Has(boton) && A_TickCount - EventosMouse[boton] < ResaltadoMs
        if (i <= 3 && GetKeyState(boton, "P")) {
            activo := true
            EventosMouse[boton] := A_TickCount
        }
        if activo
            estado |= 1 << (i - 1)
    }
    parte := PartesMouse["dibujo"]
    if (parte.estado != estado) {
        SendMessage(0x172, 0, parte.bmps[estado], parte.pic)
        parte.estado := estado
    }
}

; Silueta con curvas Bezier, dibujada a triple resolucion para suavizar bordes.
DibujarMouse(w, h, estado) {
    global Col, Recursos, MouseCuerpo, MouseBotones, MousePulsado, MouseRueda
    ww := w * 3, hh := h * 3
    dc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
    pantalla := DllCall("GetDC", "ptr", 0, "ptr")
    grande := DllCall("CreateCompatibleBitmap", "ptr", pantalla, "int", ww, "int", hh, "ptr")
    bmp := DllCall("CreateCompatibleBitmap", "ptr", pantalla, "int", w, "int", h, "ptr")
    DllCall("ReleaseDC", "ptr", 0, "ptr", pantalla)
    anterior := DllCall("SelectObject", "ptr", dc, "ptr", grande, "ptr")
    sx := ww / 112, sy := hh / 192
    rc := Buffer(16, 0)
    NumPut("int", ww, rc, 8), NumPut("int", hh, rc, 12)
    br := DllCall("CreateSolidBrush", "uint", BGR(Col.fondo), "ptr")
    DllCall("FillRect", "ptr", dc, "ptr", rc, "ptr", br)
    DllCall("DeleteObject", "ptr", br)
    ; Sombra y carcasa con lados curvos y base redondeada.
    forma := [56,7, 17,7,9,17,7,53, 3,91,2,140,13,164,
        21,183,39,185,56,185, 78,185,94,181,101,162,
        111,135,108,88,105,53, 102,17,94,7,56,7]
    MouseCurva(dc, sx, sy, forma, "272727", "0A0A0A", 2)
    MouseCurva(dc, sx, sy, [56,11, 23,11,14,21,12,53,
        10,66,9,79,9,89, 26,84,42,83,56,83,
        56,60,56,34,56,11], (estado & 1) ? MousePulsado : MouseBotones, "121212", 1.6)
    MouseCurva(dc, sx, sy, [56,11, 89,11,98,21,100,53,
        102,66,103,79,103,89, 86,84,70,83,56,83,
        56,60,56,34,56,11], (estado & 2) ? MousePulsado : MouseBotones, "121212", 1.6)
    ; Panel de palma, con una curva que une ambos botones.
    MouseCurva(dc, sx, sy, [9,94, 38,86,74,86,103,94,
        105,119,104,145,97,162, 91,177,76,180,56,180,
        36,180,21,177,15,162, 8,145,7,119,9,94], MouseCuerpo, "121212", 1.6)
    ; Rueda central con surcos. Se ilumina al pulsar o desplazar.
    rueda := (estado & 4) ? MousePulsado : (estado & 24) ? MouseRueda : "303030"
    MouseCurva(dc, sx, sy, [56,29, 48,29,47,34,47,40,
        47,47,47,56,47,62, 47,70,50,73,56,73,
        62,73,65,70,65,62, 65,56,65,47,65,40,
        65,34,64,29,56,29], rueda, "121212", 2)
    Loop 5 {
        yy := 38 + A_Index * 5
        MouseLinea(dc, sx, sy, 51, yy, 61, yy, "B3B3B3", 0.7)
    }
    ; Flechas discretas: azul indica el sentido de desplazamiento.
    MouseLinea(dc, sx, sy, 52,24,56,20, (estado & 8) ? MouseRueda : "909090", 1.6)
    MouseLinea(dc, sx, sy, 56,20,60,24, (estado & 8) ? MouseRueda : "909090", 1.6)
    MouseLinea(dc, sx, sy, 52,77,56,81, (estado & 16) ? MouseRueda : "909090", 1.6)
    MouseLinea(dc, sx, sy, 56,81,60,77, (estado & 16) ? MouseRueda : "909090", 1.6)
    salida := DllCall("CreateCompatibleDC", "ptr", dc, "ptr")
    previo := DllCall("SelectObject", "ptr", salida, "ptr", bmp, "ptr")
    DllCall("SetStretchBltMode", "ptr", salida, "int", 4)
    DllCall("SetBrushOrgEx", "ptr", salida, "int", 0, "int", 0, "ptr", 0)
    DllCall("StretchBlt", "ptr", salida, "int", 0, "int", 0, "int", w, "int", h,
        "ptr", dc, "int", 0, "int", 0, "int", ww, "int", hh, "uint", 0xCC0020)
    DllCall("SelectObject", "ptr", salida, "ptr", previo)
    DllCall("DeleteDC", "ptr", salida)
    DllCall("SelectObject", "ptr", dc, "ptr", anterior)
    DllCall("DeleteObject", "ptr", grande)
    DllCall("DeleteDC", "ptr", dc)
    Recursos.Push(bmp)
    return bmp
}

MouseCurva(dc, sx, sy, puntos, relleno, borde, grosor) {
    br := DllCall("CreateSolidBrush", "uint", BGR(relleno), "ptr")
    pen := DllCall("CreatePen", "int", 0, "int", Max(1, Round(grosor*sx)), "uint", BGR(borde), "ptr")
    oldBr := DllCall("SelectObject", "ptr", dc, "ptr", br, "ptr")
    oldPen := DllCall("SelectObject", "ptr", dc, "ptr", pen, "ptr")
    DllCall("BeginPath", "ptr", dc)
    DllCall("MoveToEx", "ptr", dc, "int", Round(puntos[1]*sx), "int", Round(puntos[2]*sy), "ptr", 0)
    cantidad := (puntos.Length - 2) // 2
    coords := Buffer(cantidad * 8, 0)
    Loop cantidad {
        NumPut("int", Round(puntos[A_Index*2+1]*sx), "int", Round(puntos[A_Index*2+2]*sy), coords, (A_Index-1)*8)
    }
    DllCall("PolyBezierTo", "ptr", dc, "ptr", coords, "uint", cantidad)
    DllCall("CloseFigure", "ptr", dc)
    DllCall("EndPath", "ptr", dc)
    DllCall("StrokeAndFillPath", "ptr", dc)
    DllCall("SelectObject", "ptr", dc, "ptr", oldBr)
    DllCall("SelectObject", "ptr", dc, "ptr", oldPen)
    DllCall("DeleteObject", "ptr", br)
    DllCall("DeleteObject", "ptr", pen)
}

MouseLinea(dc, sx, sy, x1, y1, x2, y2, color, grosor) {
    pen := DllCall("CreatePen", "int", 0, "int", Max(1, Round(grosor*sx)), "uint", BGR(color), "ptr")
    old := DllCall("SelectObject", "ptr", dc, "ptr", pen, "ptr")
    DllCall("MoveToEx", "ptr", dc, "int", Round(x1*sx), "int", Round(y1*sy), "ptr", 0)
    DllCall("LineTo", "ptr", dc, "int", Round(x2*sx), "int", Round(y2*sy))
    DllCall("SelectObject", "ptr", dc, "ptr", old)
    DllCall("DeleteObject", "ptr", pen)
}

AlternarMouseVisual() {
    global Redimension
    if IsObject(Redimension)
        return
    global MostrarMouse
    MostrarMouse := !MostrarMouse
    GuardarConfig()
    if MostrarMouse
        A_TrayMenu.Check("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)")
    else
        A_TrayMenu.Uncheck("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)")
    Reconstruir(MostrarMouse ? "Mouse visual activado (modo teclado)" : "Mouse visual oculto")
}


; ============================================================
; REDIMENSIONAR DESDE EL PERIMETRO (solo desbloqueado, modo teclado)
; ============================================================

AreaCompletaTeclado(wParam, lParam, msg, hwnd) {
    if VentanaMostradorDisponible(hwnd)
        return 0
}

BordeTeclado() {
    if !VentanaMostradorDisponible()
        return 0
    global HwndTeclado
    global overlay, Bloqueado, MostrarTeclado
    if (Bloqueado || !MostrarTeclado || !IsObject(overlay))
        return 0
    punto := Buffer(8, 0), rc := Buffer(16, 0)
    if !DllCall("GetCursorPos", "ptr", punto)
        return 0
    DllCall("GetWindowRect", "ptr", HwndTeclado, "ptr", rc)
    x := NumGet(punto, 0, "int"), y := NumGet(punto, 4, "int")
    l := NumGet(rc, 0, "int"), t := NumGet(rc, 4, "int")
    r := NumGet(rc, 8, "int"), b := NumGet(rc, 12, "int")
    if (x < l || x >= r || y < t || y >= b)
        return 0
    margen := Max(6, Round(8 * A_ScreenDPI / 96))
    izq := x < l + margen, der := x >= r - margen
    arriba := y < t + margen, abajo := y >= b - margen
    if arriba
        return izq ? 13 : der ? 14 : 12 ; HTTOPLEFT, HTTOPRIGHT, HTTOP
    if abajo
        return izq ? 16 : der ? 17 : 15 ; HTBOTTOMLEFT, HTBOTTOMRIGHT, HTBOTTOM
    return izq ? 10 : der ? 11 : 0     ; HTLEFT, HTRIGHT
}

DetectarBordeTeclado(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado
    global overlay
    if !IsObject(overlay) || hwnd != HwndTeclado
        return
    borde := BordeTeclado()
    if borde
        return borde
    return 1 ; HTCLIENT: sin redimensionar cuando esta bloqueado o en solo texto
}

CursorBordeTeclado(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado
    global overlay
    if !IsObject(overlay)
        return
    if (hwnd != HwndTeclado && DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") != HwndTeclado)
        return
    borde := BordeTeclado()
    if !borde
        return
    cursor := (borde = 10 || borde = 11) ? 32644 : (borde = 12 || borde = 15) ? 32645
        : (borde = 13 || borde = 17) ? 32642 : 32643
    DllCall("SetCursor", "ptr", DllCall("LoadCursorW", "ptr", 0, "ptr", cursor, "ptr"))
    return 1
}

ComenzarRedimension(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado
    global overlay, Bloqueado, MostrarTeclado, Redimension, Escala
    if (!IsObject(overlay) || hwnd != HwndTeclado || Bloqueado || !MostrarTeclado
        || wParam < 10 || wParam > 17 || IsObject(Redimension))
        return
    overlay.GetPos(&x, &y, &w, &h)
    pantalla := DllCall("GetDC", "ptr", HwndTeclado, "ptr")
    dc := DllCall("CreateCompatibleDC", "ptr", pantalla, "ptr")
    bmp := DllCall("CreateCompatibleBitmap", "ptr", pantalla, "int", w, "int", h, "ptr")
    DllCall("ReleaseDC", "ptr", HwndTeclado, "ptr", pantalla)
    if (!dc || !bmp) {
        if dc
            DllCall("DeleteDC", "ptr", dc)
        if bmp
            DllCall("DeleteObject", "ptr", bmp)
        return 0 ; no iniciar si no hay recursos para la vista previa
    }
    old := DllCall("SelectObject", "ptr", dc, "ptr", bmp, "ptr")
    ; Captura el contenido propio, incluidos todos sus controles, sin el halo.
    if !DllCall("PrintWindow", "ptr", HwndTeclado, "ptr", dc, "uint", 1) {
        DllCall("SelectObject", "ptr", dc, "ptr", old)
        DllCall("DeleteObject", "ptr", bmp)
        DllCall("DeleteDC", "ptr", dc)
        return 0
    }
    Redimension := {x: x, y: y, w: w, h: h, escala: Escala,
        nueva: Escala, dc: dc, bmp: bmp, old: old}
    SetTimer(AnimarTeclas, 0)
    for ctrl in overlay
        ctrl.Visible := false
    DllCall("InvalidateRect", "ptr", HwndTeclado, "ptr", 0, "int", false)
}

DimensionesTeclado(escala) {
    global HwndTeclado, MostrarHistorial
    global MostrarMouse
    unidad := Round(40 * escala * A_ScreenDPI / 96)
    pad := Round(unidad * 0.3)
    w := Round(18.5 * unidad) + 2 * pad + (MostrarMouse ? Round(3.5 * unidad) : 0)
    h := pad + Round(unidad * 0.75)
        + (MostrarHistorial ? Round(unidad * 0.15) + Round(unidad * 1.25) : 0)
        + Round(unidad * 0.2) + Round(6.25 * unidad) + pad
    return [w, h]
}

AjustarRedimension(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado
    global overlay, Redimension
    if (!IsObject(Redimension) || !IsObject(overlay) || hwnd != HwndTeclado)
        return
    red := Redimension
    l := NumGet(lParam, 0, "int"), t := NumGet(lParam, 4, "int")
    r := NumGet(lParam, 8, "int"), b := NumGet(lParam, 12, "int")
    factorX := (r - l) / red.w, factorY := (b - t) / red.h
    if (wParam = 1 || wParam = 2)
        factor := factorX
    else if (wParam = 3 || wParam = 6)
        factor := factorY
    else
        factor := Abs(factorX - 1) >= Abs(factorY - 1) ? factorX : factorY
    red.nueva := Max(0.6, Min(2.5, red.escala * factor))
    tam := DimensionesTeclado(red.nueva)
    w := tam[1], h := tam[2]
    ; Conservar la esquina opuesta; los bordes laterales escalan desde su centro.
    if (wParam = 1 || wParam = 4 || wParam = 7)
        l := r - w
    else if (wParam = 2 || wParam = 5 || wParam = 8)
        r := l + w
    else {
        l := Round(red.x + (red.w - w) / 2)
        r := l + w
    }
    if (wParam = 3 || wParam = 4 || wParam = 5)
        t := b - h
    else if (wParam = 6 || wParam = 7 || wParam = 8)
        b := t + h
    else {
        t := Round(red.y + (red.h - h) / 2)
        b := t + h
    }
    NumPut("int", l, "int", t, "int", r, "int", b, lParam)
    return 1
}

ActualizarVistaRedimension(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado
    global overlay, Redimension
    if IsObject(Redimension) && IsObject(overlay) && hwnd = HwndTeclado
        DllCall("InvalidateRect", "ptr", hwnd, "ptr", 0, "int", false)
}

FondoVistaRedimension(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado
    global overlay, Redimension
    if IsObject(Redimension) && IsObject(overlay) && hwnd = HwndTeclado
        return 1
}

PintarVistaRedimension(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado
    global overlay, Redimension
    if (!IsObject(Redimension) || !IsObject(overlay) || hwnd != HwndTeclado)
        return
    red := Redimension
    ps := Buffer(A_PtrSize = 8 ? 72 : 64, 0), rc := Buffer(16, 0)
    dc := DllCall("BeginPaint", "ptr", hwnd, "ptr", ps, "ptr")
    DllCall("GetClientRect", "ptr", hwnd, "ptr", rc)
    DllCall("SetStretchBltMode", "ptr", dc, "int", 4)
    DllCall("SetBrushOrgEx", "ptr", dc, "int", 0, "int", 0, "ptr", 0)
    DllCall("StretchBlt", "ptr", dc, "int", 0, "int", 0,
        "int", NumGet(rc, 8, "int"), "int", NumGet(rc, 12, "int"),
        "ptr", red.dc, "int", 0, "int", 0, "int", red.w, "int", red.h, "uint", 0xCC0020)
    DllCall("EndPaint", "ptr", hwnd, "ptr", ps)
    return 0
}

TerminarRedimension() {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado
    global overlay, Redimension, Escala, Anclaje, MargenX, MargenY
    if !IsObject(Redimension)
        return
    Critical
    red := Redimension
    overlay.GetPos(&x, &y, &w, &h)
    ; Escape en el bucle nativo restaura el rectangulo original.
    Escala := (w = red.w && h = red.h) ? red.escala : red.nueva
    Anclaje := "XY", MargenX := x, MargenY := y
    Redimension := 0
    DllCall("SelectObject", "ptr", red.dc, "ptr", red.old)
    DllCall("DeleteObject", "ptr", red.bmp)
    DllCall("DeleteDC", "ptr", red.dc)
    Reconstruir("Tamaño: " Round(Escala * 100) "%")
    GuardarConfig()
}


LimitesRedimension(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado, MostrarTeclado
    if (hwnd != HwndTeclado || !MostrarTeclado)
        return
    minimo := DimensionesTeclado(0.6), maximo := DimensionesTeclado(2.5)
    NumPut("int", minimo[1], "int", minimo[2], lParam, 24)
    NumPut("int", maximo[1], "int", maximo[2], lParam, 32)
    return 0
}


; ============================================================
; HISTORIAL CON MINI TECLAS: turquesa (normal), violeta (modificador)
; ============================================================

PartesEntradaHistorial(texto) {
    veces := ""
    if RegExMatch(texto, " ×(\d+)$", &m) {
        veces := "×" m[1]
        texto := RegExReplace(texto, " ×\d+$")
    }
    lados := StrSplit(texto, "⇒")
    teclas := StrSplit(Trim(lados[1]), [" + "])
    partes := []
    for i, tecla in teclas {
        if (i > 1)
            partes.Push({texto: "+", tipo: "separador"})
        modificador := (tecla = "Ctrl" || tecla = "Shift" || tecla = "Alt" || tecla = "Alt Gr" || tecla = "Win")
        partes.Push({texto: tecla, tipo: modificador ? "mod" : "tecla"})
    }
    if lados.Length > 1
        partes.Push({texto: "⇒ " Trim(lados[2]), tipo: "resultado"})
    if veces != ""
        partes.Push({texto: veces, tipo: "veces"})
    return partes
}

AnchoTextoHistorial(dc, texto, px) {
    old := DllCall("SelectObject", "ptr", dc, "ptr", Fuente(px, true), "ptr")
    tam := Buffer(8, 0)
    DllCall("GetTextExtentPoint32W", "ptr", dc, "str", texto, "int", StrLen(texto), "ptr", tam)
    DllCall("SelectObject", "ptr", dc, "ptr", old)
    return NumGet(tam, 0, "int")
}

TextoHistorial(dc, texto, x, y, w, h, px, color, centrado := false) {
    if (w <= 0 || h <= 0)
        return
    old := DllCall("SelectObject", "ptr", dc, "ptr", Fuente(px, true), "ptr")
    DllCall("SetBkMode", "ptr", dc, "int", 1)
    DllCall("SetTextColor", "ptr", dc, "uint", BGR(color))
    rc := Buffer(16, 0)
    NumPut("int", x, "int", y, "int", x + w, "int", y + h, rc)
    DllCall("DrawTextW", "ptr", dc, "str", texto, "int", -1, "ptr", rc,
        "uint", 0x20 | 0x4 | 0x800 | 0x8000 | (centrado ? 1 : 0))
    DllCall("SelectObject", "ptr", dc, "ptr", old)
}

MedirGrupoHistorial(dc, texto, px) {
    global U
    partes := PartesEntradaHistorial(texto)
    total := 0, gap := Max(2, Round(U * 0.08))
    for parte in partes {
        relleno := (parte.tipo = "tecla" || parte.tipo = "mod") ? Round(U * 0.3) : Round(U * 0.08)
        parte.w := Max(Round(U * 0.32), AnchoTextoHistorial(dc, parte.texto, px) + relleno)
        total += parte.w + gap
    }
    return {partes: partes, w: Max(0, total - gap), gap: gap}
}

PintarGrupoHistorial(dc, grupo, x, y, maxW, alto, px) {
    global U
    factor := Min(1.0, maxW / Max(1, grupo.w))
    for parte in grupo.partes {
        w := Max(1, Floor(parte.w * factor))
        if (parte.tipo = "tecla" || parte.tipo = "mod") {
            esMod := parte.tipo = "mod"
            borde := esMod ? "AC8CC4" : "6FADB2"
            fondo := esMod ? "33283E" : "203638"
            tinta := esMod ? "E9DDF5" : "D8ECEB"
            RectTecla(dc, x, y, x + w, y + alto, Max(4, Round(U * 0.13)), borde)
            RectTecla(dc, x + 1, y + 1, x + w - 1, y + alto - 1, Max(3, Round(U * 0.11)), fondo)
            TextoHistorial(dc, parte.texto, x + 2, y, w - 4, alto, px, tinta, true)
        } else {
            tinta := parte.tipo = "resultado" ? "C2D2E8" : "AAAAAA"
            TextoHistorial(dc, parte.texto, x, y, w, alto, px, tinta, true)
        }
        x += w + Floor(grupo.gap * factor)
    }
}

DibujarHistorial(w, h, vertical := false) {
    global Historial, U, AvisoActual
    pantalla := DllCall("GetDC", "ptr", 0, "ptr")
    dc := DllCall("CreateCompatibleDC", "ptr", pantalla, "ptr")
    bmp := DllCall("CreateCompatibleBitmap", "ptr", pantalla, "int", w, "int", h, "ptr")
    DllCall("ReleaseDC", "ptr", 0, "ptr", pantalla)
    old := DllCall("SelectObject", "ptr", dc, "ptr", bmp, "ptr")
    rc := Buffer(16, 0)
    NumPut("int", w, rc, 8), NumPut("int", h, rc, 12)
    br := DllCall("CreateSolidBrush", "uint", BGR("0F0F0F"), "ptr")
    DllCall("FillRect", "ptr", dc, "ptr", rc, "ptr", br)
    DllCall("DeleteObject", "ptr", br)
    RectTecla(dc, 0, 0, w, h, Round(U * 0.2), "373737")
    RectTecla(dc, 1, 1, w - 1, h - 1, Round(U * 0.2), "181818")
    pad := Max(4, Round(U * 0.18))
    cab := Round(U * 0.42), alto := Round(U * 0.62)
    px := Max(9, Round(U * 0.27))
    etiqueta := "RECIENTES  ·  hasta 4 teclas →"
    TextoHistorial(dc, etiqueta, pad, 1, w - 2 * pad, cab, Max(8, Round(U * 0.21)), "AAAAAA")
    n := Historial.Length
    if !n {
        TextoHistorial(dc, "Pulsa una tecla o un atajo para comenzar", pad, cab,
            w - 2 * pad, alto, px, "AAAAAA")
    } else if vertical {
        for i, entrada in Historial {
            grupo := MedirGrupoHistorial(dc, entrada, px)
            y := cab + (i - 1) * (alto + Round(U * 0.12))
            PintarGrupoHistorial(dc, grupo, pad, y, w - 2 * pad, alto, px)
        }
    } else {
        grupos := [], total := 0, separacion := Round(U * 0.45)
        for entrada in Historial {
            grupo := MedirGrupoHistorial(dc, entrada, px)
            grupos.Push(grupo)
            total += grupo.w + separacion
        }
        total -= separacion
        omitidas := false, limite := w - 2 * pad
        ; Priorizar las acciones recientes completas si no caben las cuatro.
        while (grupos.Length > 1 && total > limite - (omitidas ? Round(U * 0.5) : 0)) {
            total -= grupos[1].w + separacion
            grupos.RemoveAt(1)
            omitidas := true
        }
        x := pad
        if omitidas {
            TextoHistorial(dc, "…", x, cab, Round(U * 0.4), alto, px, "AAAAAA")
            x += Round(U * 0.5)
        }
        for i, grupo in grupos {
            espacio := Min(grupo.w, w - pad - x)
            PintarGrupoHistorial(dc, grupo, x, cab, espacio, alto, px)
            x += espacio
            if i < grupos.Length {
                TextoHistorial(dc, "›", x, cab, separacion, alto, px, "808080", true)
                x += separacion
            }
        }
    }
    if (vertical && AvisoActual != "")
        TextoHistorial(dc, AvisoActual, pad, h - Round(U * 0.43), w - 2 * pad,
            Round(U * 0.36), Max(8, Round(U * 0.22)), "C2D2E8")
    DllCall("SelectObject", "ptr", dc, "ptr", old)
    DllCall("DeleteDC", "ptr", dc)
    return bmp
}


AlternarHistorial() {
    global MostrarHistorial, Redimension
    if IsObject(Redimension)
        return
    MostrarHistorial := !MostrarHistorial
    GuardarConfig()
    if MostrarHistorial
        A_TrayMenu.Check("Mostrar / ocultar historial  (Ctrl+Alt+I)")
    else
        A_TrayMenu.Uncheck("Mostrar / ocultar historial  (Ctrl+Alt+I)")
    Reconstruir(MostrarHistorial ? "Historial visible: hasta 4 teclas recientes" : "Historial oculto")
}

ContarTeclasHistorial(texto) {
    cantidad := 0
    for parte in PartesEntradaHistorial(texto)
        if (parte.tipo = "tecla" || parte.tipo = "mod")
            cantidad++
    return cantidad
}

LimitarHistorial() {
    global Historial
    total := 0
    for entrada in Historial
        total += ContarTeclasHistorial(entrada)
    ; Retirar primero los atajos antiguos completos, sin partir sus teclas.
    while (total > 4 && Historial.Length > 1) {
        total -= ContarTeclasHistorial(Historial[1])
        Historial.RemoveAt(1)
    }
    ; Un atajo excepcional con mas de cuatro teclas conserva las cuatro finales.
    if (total > 4 && Historial.Length = 1) {
        teclas := [], sufijo := ""
        for parte in PartesEntradaHistorial(Historial[1]) {
            if (parte.tipo = "tecla" || parte.tipo = "mod")
                teclas.Push(parte.texto)
            else if parte.tipo = "resultado"
                sufijo .= "   " parte.texto
            else if parte.tipo = "veces"
                sufijo .= " " parte.texto
        }
        while teclas.Length > 4
            teclas.RemoveAt(1)
        texto := ""
        for i, tecla in teclas
            texto .= (i = 1 ? "" : " + ") tecla
        Historial[1] := texto sufijo
    }
}


; ============================================================
; BOTON SUPERIOR DERECHO Y MODO MINIMIZADO CON ICONO FLOTANTE
; ============================================================

TamBotonMinimizar() {
    global U
    return Max(18, Round(U * 0.65))
}

AnchoControlesMostrador() {
    global U
    return 5 * TamBotonMinimizar() + 4 * Max(2, Round(U * 0.1))
}

CrearControlMinimizar() {
    global ControlMinimizar, BotonMinimizar, BotonAjustes, BotonNotas, BotonAnotaciones, BotonClase
    ; Una ventana independiente permite pulsarlo incluso con el teclado bloqueado.
    ControlMinimizar := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000", "Minimizar mostrador")
    ControlMinimizar.MarginX := 0, ControlMinimizar.MarginY := 0
    ControlMinimizar.BackColor := "272727"
    ControlMinimizar.SetFont("s" Pt(17) " cF1F1F1", "Segoe UI Symbol")
    BotonMinimizar := ControlMinimizar.AddText("x0 y0 w26 h26 Center +0x200 +0x100", "−")
    BotonMinimizar.OnEvent("Click", (*) => AlternarMinimizado())
    BotonAjustes := ControlMinimizar.AddText("x0 y0 w26 h26 Center +0x200 +0x100", "⚙")
    BotonAjustes.OnEvent("Click", AbrirMenuAjustes)
    BotonNotas := ControlMinimizar.AddText("x0 y0 w26 h26 Center +0x200 +0x100", "✎")
    BotonNotas.OnEvent("Click", (*) => EditarNotaDirecta())
    BotonNotas.SetFont("cFF6B7D")
    BotonAnotaciones := ControlMinimizar.AddText("x0 y0 w26 h26 Center +0x200 +0x100", Chr(0xE76D))
    BotonAnotaciones.SetFont("s" Pt(17) " c8AB4F8", "Segoe MDL2 Assets")
    BotonAnotaciones.OnEvent("Click", AlternarAnotaciones)
    BotonClase := ControlMinimizar.AddText("x0 y0 w26 h26 +0xE +0x100")
    BotonClase.OnEvent("Click", AbrirPanelClase)
    ControlMinimizar.OnEvent("ContextMenu", AbrirMenuAjustes)
    ControlMinimizar.OnEvent("Close", (*) => AlternarMinimizado())
}

SeguirPosicionMostrador(wParam, lParam, msg, hwnd) {
    if !VentanaMostradorDisponible()
        return
    global HwndTeclado, Minimizado
    if (hwnd = HwndTeclado && !Minimizado)
        ActualizarControlMinimizar()
}

ActualizarControlMinimizar() {
    PosicionarPanelNota()
    if !VentanaMostradorDisponible()
        return
    global ControlMinimizar, BotonMinimizar, BotonAjustes, BotonNotas, BotonAnotaciones, BotonClase, Minimizado, Visible, overlay, U
    global IconoMinX, IconoMinY, MostrarTeclado, MostrarHistorial, BotonClaseTam, UIImagenesModernas
    if !IsObject(ControlMinimizar)
        return
    if (!Minimizado && !Visible) {
        ControlMinimizar.Hide()
        return
    }
    if Minimizado {
        tam := Max(30, Round(38 * A_ScreenDPI / 96))
        ancho := tam, separacion := 0
        x := IconoMinX, y := IconoMinY
        BotonMinimizar.Text := "⌨"
        ControlMinimizar.Title := "Expandir teclado (Ctrl+Alt+N)"
    } else {
        overlay.GetPos(&ox, &oy, &ow, &oh)
        tam := TamBotonMinimizar()
        pad := Round(U * 0.3)
        margenY := MostrarTeclado ? pad : Round(pad * 0.6)
        separacion := Max(2, Round(U * 0.1))
        ancho := AnchoControlesMostrador()
        x := ox + ow - pad - ancho, y := oy + margenY
        BotonMinimizar.Text := "−"
        ControlMinimizar.Title := "Minimizar teclado (Ctrl+Alt+N)"
    }
    ; Mantener el control accesible si el mostrador rebasa una pantalla.
    monitor := DllCall("MonitorFromWindow", "ptr", overlay.Hwnd, "uint", 2, "ptr")
    info := Buffer(40, 0)
    NumPut("uint", 40, info)
    if DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info) {
        x := Max(NumGet(info, 20, "int"), Min(x, NumGet(info, 28, "int") - ancho))
        y := Max(NumGet(info, 24, "int"), Min(y, NumGet(info, 32, "int") - tam))
    }
    IconoMinX := Minimizado ? x : x + 4 * (tam + separacion)
    IconoMinY := y
    BotonClase.Visible := !Minimizado
    BotonAnotaciones.Visible := !Minimizado
    BotonNotas.Visible := !Minimizado
    BotonAjustes.Visible := !Minimizado
    if !Minimizado {
        BotonNotas.Move(0, 0, tam, tam)
        BotonNotas.SetFont("s" Pt(tam * 0.65) " cFF6B7D", "Segoe UI Symbol")
        BotonAnotaciones.Move(tam + separacion, 0, tam, tam)
        BotonAnotaciones.SetFont("s" Pt(tam * 0.62) " c8AB4F8", "Segoe MDL2 Assets")
        BotonClase.Move(2 * (tam + separacion), 0, tam, tam)
        if BotonClaseTam != tam || !UIImagenesModernas.Has(BotonClase.Hwnd) {
            PonerImagenModerna(BotonClase, DibujarIconoReloj(tam))
            BotonClaseTam := tam
        }
        BotonAjustes.Move(3 * (tam + separacion), 0, tam, tam)
        BotonAjustes.SetFont("s" Pt(tam * 0.65) " cF1F1F1", "Segoe UI Symbol")
    }
    BotonMinimizar.Move(Minimizado ? 0 : 4 * (tam + separacion), 0, tam, tam)
    BotonMinimizar.SetFont("s" Pt(tam * 0.65) " cF1F1F1", "Segoe UI Symbol")
    MostrarCapaMostrador(ControlMinimizar, x, y, ancho, tam)
}

AlternarMinimizado() {
    global Minimizado, Redimension, overlay, Visible, Presionadas, Soltadas, Teclas, ControlMinimizar
    if IsObject(Redimension)
        return
    Minimizado := !Minimizado
    if Minimizado {
        overlay.Hide()
        Visible := false
        SetTimer(AnimarTeclas, 0)
        A_TrayMenu.Check("Minimizar / expandir  (Ctrl+Alt+N)")
        ActualizarControlMinimizar()
    } else {
        ControlMinimizar.Hide()
        A_TrayMenu.Uncheck("Minimizar / expandir  (Ctrl+Alt+N)")
        ; Recuperar los estados reales, incluso si se cambiaron opciones minimizado.
        for sc in Teclas
            PintarTecla(sc, (Presionadas.Has(sc) || Soltadas.Has(sc)) ? (EsModificador(sc) ? "mod" : "normal") : "")
        RefrescarMouseVisual()
        AgregarAlHistorial("Mostrador expandido")
    }
}


; ============================================================
; AJUSTES DE AURA Y COLORES DEL MOUSE
; ============================================================

LeerColorTema(seccion, clave, anterior, nuevo) {
    global ArchivoConfig
    color := ColorMouseValido(IniRead(ArchivoConfig, seccion, clave, nuevo), nuevo)
    ; Actualiza los antiguos valores predeterminados al cargar las preferencias.
    return color = anterior ? nuevo : color
}

PintarBotonAjustesModerno(wParam, lParam, msg, hwnd) {
    global CerrandoMostrador, AjustesMouseGui, NotasGui, AjustesSeleccionGui, AnotAjustes
    if CerrandoMostrador || !lParam
        return
    ; NMHDR.code == NM_CUSTOMDRAW. No intervenir en otras notificaciones.
    if NumGet(lParam, 2 * A_PtrSize, "int") != -12
        return
    propio := false
    for g in [AjustesMouseGui, NotasGui, AjustesSeleccionGui, AnotAjustes] {
        if (g is Gui) && hwnd = g.Hwnd {
            propio := true
            break
        }
    }
    if !propio
        return
    control := NumGet(lParam, 0, "ptr")
    clase := Buffer(32, 0)
    if !DllCall("GetClassNameW", "ptr", control, "ptr", clase, "int", 16)
        return
    if StrGet(clase, "UTF-16") != "Button"
        return
    estilo := DllCall(A_PtrSize = 8 ? "GetWindowLongPtrW" : "GetWindowLongW",
        "ptr", control, "int", -16, "ptr")
    tipo := estilo & 0xF
    if tipo != 0 && tipo != 1 ; sólo PushButton / DefPushButton; no checkboxes
        return
    etapa := NumGet(lParam, A_PtrSize = 8 ? 24 : 12, "uint")
    if etapa != 1 ; CDDS_PREPAINT
        return
    dc := NumGet(lParam, A_PtrSize = 8 ? 32 : 16, "ptr")
    rectOffset := A_PtrSize = 8 ? 40 : 20
    x := NumGet(lParam, rectOffset, "int"), y := NumGet(lParam, rectOffset + 4, "int")
    w := NumGet(lParam, rectOffset + 8, "int") - x
    h := NumGet(lParam, rectOffset + 12, "int") - y
    estado := NumGet(lParam, A_PtrSize = 8 ? 64 : 40, "uint")
    if !dc || w < 1 || h < 1
        return
    guardado := DllCall("SaveDC", "ptr", dc)
    if !guardado
        return
    bmp := 0, memoria := 0, anterior := 0
    try {
        longitud := DllCall("GetWindowTextLengthW", "ptr", control)
        bufferTexto := Buffer((longitud + 1) * 2, 0)
        DllCall("GetWindowTextW", "ptr", control, "ptr", bufferTexto, "int", longitud + 1)
        texto := StrGet(bufferTexto, "UTF-16")
        primario := tipo = 1 || (estado & 0x20)
        fondo := primario ? "45232B" : "272727"
        tinta := primario ? "FFB3BF" : "F1F1F1"
        if estado & 0x4 {
            fondo := "191919", tinta := "707070"
        } else if estado & 0x1 {
            fondo := primario ? "613440" : "414141"
        } else if estado & 0x40 {
            fondo := primario ? "55303B" : "333333"
        }
        bmp := DibujarBotonModerno(w, h, texto, fondo, tinta, Min(18, h // 2))
        if !bmp
            return
        memoria := DllCall("CreateCompatibleDC", "ptr", dc, "ptr")
        if !memoria
            return
        anterior := DllCall("SelectObject", "ptr", memoria, "ptr", bmp, "ptr")
        if !DllCall("BitBlt", "ptr", dc, "int", x, "int", y, "int", w, "int", h,
            "ptr", memoria, "int", 0, "int", 0, "uint", 0x00CC0020)
            return
        if (estado & 0x10) && !(estado & 0x4) {
            ; Un contorno visible conserva la indicación de foco del teclado.
            pen := DllCall("CreatePen", "int", 0, "int", Max(1, Round(A_ScreenDPI / 96)), "uint", BGR("8AB4F8"), "ptr")
            if pen {
                lapizAnterior := DllCall("SelectObject", "ptr", dc, "ptr", pen, "ptr")
                brochaAnterior := DllCall("SelectObject", "ptr", dc, "ptr", DllCall("GetStockObject", "int", 5, "ptr"), "ptr")
                radio := Min(h - 4, Round(20 * A_ScreenDPI / 96))
                DllCall("RoundRect", "ptr", dc, "int", x + 2, "int", y + 2,
                    "int", x + w - 2, "int", y + h - 2, "int", radio, "int", radio)
                DllCall("SelectObject", "ptr", dc, "ptr", brochaAnterior)
                DllCall("SelectObject", "ptr", dc, "ptr", lapizAnterior)
                DllCall("DeleteObject", "ptr", pen)
            }
        }
        return 4 ; CDRF_SKIPDEFAULT, sólo después de dibujar correctamente
    } catch {
        ; Conservar el botón nativo si no se pudo generar su imagen.
        return
    } finally {
        if memoria {
            if anterior
                DllCall("SelectObject", "ptr", memoria, "ptr", anterior)
            DllCall("DeleteDC", "ptr", memoria)
        }
        if bmp
            DllCall("DeleteObject", "ptr", bmp)
        DllCall("RestoreDC", "ptr", dc, "int", guardado)
    }
}

AplicarTemaAjustes(g) {
    g.BackColor := "0F0F0F"
    oscuro := Buffer(4, 0)
    NumPut("int", 1, oscuro)
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", g.Hwnd, "uint", 20, "ptr", oscuro, "uint", 4)
    for control in g {
        switch control.Type {
            case "Edit", "DropDownList":
                control.Opt("Background272727 cF1F1F1")
            case "CheckBox":
                control.Opt("cF1F1F1")
            case "Button", "UpDown":
                DllCall("uxtheme\SetWindowTheme", "ptr", control.Hwnd, "str", "DarkMode_Explorer", "ptr", 0)
            case "Slider":
                control.Opt("Background0F0F0F")
        }
    }
}

ColorMouseValido(valor, defecto := "") {
    valor := StrUpper(LTrim(Trim(valor), "#"))
    return RegExMatch(valor, "^[0-9A-F]{6}$") ? valor : defecto
}

AbrirAjustesMouse() {
    global AjustesMouseGui, CamposMouse, Redimension
    global ResplandorMouse, MostrarMouse, HaloTam, HaloColor, HaloOpacidad
    global MouseCuerpo, MouseBotones, MousePulsado, MouseRueda
    if IsObject(Redimension)
        return
    if IsObject(AjustesMouseGui) {
        MostrarDialogoMostrador(AjustesMouseGui)
        return
    }
    g := Gui("+AlwaysOnTop +ToolWindow", "Ajustes del mouse y aura")
    AjustesMouseGui := g
    g.SetFont("s10 cF1F1F1", "Segoe UI")
    g.BackColor := "0F0F0F"
    g.AddText("x18 y14 w475 h22", "AURA DEL CURSOR")
    activo := g.AddCheckbox("x18 y42 w465 h24", "Activar el resplandor que sigue al cursor")
    activo.Value := ResplandorMouse
    color := CampoColorMouse(g, 76, "Color del aura", HaloColor)
    g.AddText("x18 y120 w170 h24", "Diámetro del aura")
    diametro := g.AddSlider("x198 y114 w235 h32 Range40-240 ToolTip", HaloTam)
    diamTexto := g.AddText("x438 y120 w65 h24", HaloTam " px")
    diametro.OnEvent("Change", (*) => diamTexto.Text := diametro.Value " px")
    g.AddText("x18 y162 w170 h24", "Opacidad del aura")
    opacidad := g.AddSlider("x198 y156 w235 h32 Range5-85 ToolTip", HaloOpacidad)
    opTexto := g.AddText("x438 y162 w65 h24", HaloOpacidad "%")
    opacidad.OnEvent("Change", (*) => opTexto.Text := opacidad.Value "%")
    g.AddText("x18 y207 w475 h22", "MOUSE VISUAL DEL TECLADO")
    visible := g.AddCheckbox("x18 y235 w465 h24", "Mostrar el mouse visual junto al teclado")
    visible.Value := MostrarMouse
    cuerpo := CampoColorMouse(g, 272, "Cuerpo del mouse", MouseCuerpo)
    botones := CampoColorMouse(g, 308, "Botones en reposo", MouseBotones)
    pulsado := CampoColorMouse(g, 344, "Clics y rueda pulsada", MousePulsado)
    rueda := CampoColorMouse(g, 380, "Desplazamiento de rueda", MouseRueda)
    g.AddText("x18 y424 w480 h36", "Puedes elegir un color o escribir su código HEX. Pulsa Aplicar para guardar los cambios.")
    g.AddButton("x18 y476 w135 h30", "Restablecer valores").OnEvent("Click", (*) => RestablecerAjustesMouse())
    g.AddButton("x285 y476 w100 h30 Default", "Aplicar").OnEvent("Click", (*) => AplicarAjustesMouse())
    g.AddButton("x395 y476 w100 h30", "Cerrar").OnEvent("Click", CerrarAjustesMouse)
    CamposMouse := {activo: activo, visible: visible, color: color, diametro: diametro,
        diamTexto: diamTexto, opacidad: opacidad, opTexto: opTexto,
        cuerpo: cuerpo, botones: botones, pulsado: pulsado, rueda: rueda}
    g.OnEvent("Close", CerrarAjustesMouse)
    g.OnEvent("Escape", CerrarAjustesMouse)
    AplicarTemaAjustes(g)
    MostrarDialogoMostrador(g, "w515 h524")
}

CampoColorMouse(g, y, etiqueta, valor) {
    g.AddText(Format("x18 y{} w180 h25 +0x200", y), etiqueta)
    muestra := g.AddText(Format("x202 y{} w30 h25 Background{}", y, valor))
    campo := g.AddEdit(Format("x244 y{} w110 h25 Limit7", y), valor)
    g.AddButton(Format("x368 y{} w127 h25", y), "Elegir color...").OnEvent("Click", (*) => ElegirColorMouse(campo, muestra, g.Hwnd))
    campo.OnEvent("Change", (*) => ActualizarMuestraMouse(campo, muestra))
    return {campo: campo, muestra: muestra}
}

ActualizarMuestraMouse(campo, muestra) {
    color := ColorMouseValido(campo.Text)
    if color != "" {
        muestra.Opt("Background" color)
        DllCall("InvalidateRect", "ptr", muestra.Hwnd, "ptr", 0, "int", true)
    }
}

ElegirColorMouse(campo, muestra, owner) {
    global ColoresMousePersonalizados
    color := ColorMouseValido(campo.Text, "FFD600")
    cc := Buffer(A_PtrSize = 8 ? 72 : 36, 0)
    NumPut("uint", cc.Size, cc)
    NumPut("ptr", owner, cc, A_PtrSize = 8 ? 8 : 4)
    NumPut("uint", BGR(color), cc, A_PtrSize = 8 ? 24 : 12)
    NumPut("ptr", ColoresMousePersonalizados.Ptr, cc, A_PtrSize = 8 ? 32 : 16)
    NumPut("uint", 3, cc, A_PtrSize = 8 ? 40 : 20) ; RGBINIT | FULLOPEN
    if !DllCall("Comdlg32\ChooseColorW", "ptr", cc)
        return
    rgb := NumGet(cc, A_PtrSize = 8 ? 24 : 12, "uint")
    campo.Text := Format("{:02X}{:02X}{:02X}", rgb & 255, (rgb >> 8) & 255, (rgb >> 16) & 255)
    ActualizarMuestraMouse(campo, muestra)
}

CerrarAjustesMouse(*) {
    global AjustesMouseGui, CamposMouse
    if IsObject(AjustesMouseGui)
        AjustesMouseGui.Destroy()
    AjustesMouseGui := 0, CamposMouse := 0
}

RestablecerAjustesMouse() {
    global CamposMouse
    c := CamposMouse
    c.activo.Value := 1, c.visible.Value := 1
    c.diametro.Value := 88, c.diamTexto.Text := "88 px"
    c.opacidad.Value := 35, c.opTexto.Text := "35%"
    for nombre, color in Map("color", "FFD600", "cuerpo", "383838", "botones", "606060", "pulsado", "FF334D", "rueda", "8AB4F8") {
        item := c.%nombre%
        item.campo.Text := color
        ActualizarMuestraMouse(item.campo, item.muestra)
    }
}

AplicarAjustesMouse() {
    global CamposMouse, Redimension, ResplandorMouse, MostrarMouse, AjustesMouseGui
    global HaloTam, HaloColor, HaloOpacidad, MouseCuerpo, MouseBotones, MousePulsado, MouseRueda
    if IsObject(Redimension)
        return
    c := CamposMouse
    colores := Map()
    for nombre in ["color", "cuerpo", "botones", "pulsado", "rueda"] {
        item := c.%nombre%
        valor := ColorMouseValido(item.campo.Text)
        if valor = "" {
            MsgBox("Escribe un color HEX de seis caracteres, por ejemplo FF8800.", "Color no válido", "Icon!")
            item.campo.Focus()
            return
        }
        colores[nombre] := valor
    }
    Critical
    viejo := {tam: HaloTam, color: HaloColor, opacidad: HaloOpacidad}
    cambiarMouse := (MouseCuerpo != colores["cuerpo"] || MouseBotones != colores["botones"]
        || MousePulsado != colores["pulsado"] || MouseRueda != colores["rueda"] || MostrarMouse != c.visible.Value)
    SetTimer(ActualizarHaloMouse, 0)
    HaloTam := Max(40, Min(240, Integer(c.diametro.Value)))
    HaloColor := colores["color"]
    HaloOpacidad := Max(5, Min(85, Integer(c.opacidad.Value)))
    try CrearHaloMouse()
    catch as err {
        HaloTam := viejo.tam, HaloColor := viejo.color, HaloOpacidad := viejo.opacidad
        AplicarResplandorMouse()
        MsgBox(err.Message, "No se pudieron aplicar los ajustes", "Icon!")
        return
    }
    ResplandorMouse := c.activo.Value, MostrarMouse := c.visible.Value
    MouseCuerpo := colores["cuerpo"], MouseBotones := colores["botones"]
    MousePulsado := colores["pulsado"], MouseRueda := colores["rueda"]
    AplicarResplandorMouse()
    if MostrarMouse
        A_TrayMenu.Check("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)")
    else
        A_TrayMenu.Uncheck("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)")
    GuardarConfig()
    if cambiarMouse
        Reconstruir("Colores del mouse guardados")
    else
        AgregarAlHistorial("Ajustes del aura guardados")
    MostrarDialogoMostrador(AjustesMouseGui)
}


; Los mensajes de Windows tambien pueden llegar durante la liberacion de globals.
; IsSet y el HWND nulo impiden leer una GUI que ya no existe.
VentanaMostradorDisponible(hwnd := 0) {
    global CerrandoMostrador, HwndTeclado, overlay
    if (!IsSet(CerrandoMostrador) || CerrandoMostrador)
        return false
    if (!IsSet(HwndTeclado) || !HwndTeclado)
        return false
    if (!IsSet(overlay) || !IsObject(overlay))
        return false
    return (hwnd = 0 || hwnd = HwndTeclado) && DllCall("IsWindow", "ptr", HwndTeclado)
}

CerrarMostrador(*) {
    global CerrandoMostrador, HwndTeclado, overlay, ih, HistorialBitmap, Redimension
    CerrandoMostrador := true
    OnMessage(0x0020, CursorDemostracionMouse, 0)
    OnMessage(0x0203, AlPresionarMouse, 0)
    OnMessage(0x0232, GuardarGeometriaBarraAnotaciones, 0)
    OnMessage(0x0047, ProgramarAreaCapturaAnotaciones, 0)
    LiberarAreaCapturaAnotaciones()
    OnMessage(0x0006, ActivacionDialogosMostrador, 0)
    OnMessage(0x0047, CambioCapasMostrador, 0)
    SetTimer(ReordenarCapasMostrador, 0)
    OnMessage(0x0200, HoverBotonModerno, 0)
    OnMessage(0x0020, CursorBotonModerno, 0)
    OnMessage(0x0201, ArrastrarPanelClase, 0)
    SetTimer(SalirHoverModerno, 0)
    SetTimer(AplicarMinutosClase, 0)
    OnMessage(0x004E, PintarBotonAjustesModerno, 0)
    OnMessage(0x0006, ActivacionMenuMostrador, 0)
    CerrarMenuMostrador()
    OnMessage(0x0201, ArrastrarRelojClase, 0)
    OnMessage(0x0232, GuardarPosicionRelojClase, 0)
    CerrarHerramientasClase()
    OnMessage(0x0201, PresionarAnotacion, 0)
    OnMessage(0x0203, PresionarAnotacion, 0)
    OnMessage(0x0200, MoverAnotacion, 0)
    OnMessage(0x0202, SoltarAnotacion, 0)
    OnMessage(0x0204, DerechoAnotacion, 0)
    OnMessage(0x0020, CursorAnotacion, 0)
    SetTimer(CerrarAnotaciones, 0)
    CerrarAnotaciones()
    CerrarAjustesAnotaciones()
    DetenerSeleccion()
    CerrarAjustesSeleccion()
    HwndTeclado := 0
    ; Desconectar primero: destruir las ventanas genera mas mensajes de Windows.
    OnMessage(0x007E, AlCambiarPantallas, 0)
    OnMessage(0x001A, AlCambiarPantallas, 0)
    OnMessage(0x0047, SeguirPosicionMostrador, 0)
    OnMessage(0x0024, LimitesRedimension, 0)
    OnMessage(0x0083, AreaCompletaTeclado, 0)
    OnMessage(0x0084, DetectarBordeTeclado, 0)
    OnMessage(0x0020, CursorBordeTeclado, 0)
    OnMessage(0x00A1, ComenzarRedimension, 0)
    OnMessage(0x0214, AjustarRedimension, 0)
    OnMessage(0x000F, PintarVistaRedimension, 0)
    OnMessage(0x0014, FondoVistaRedimension, 0)
    OnMessage(0x0005, ActualizarVistaRedimension, 0)
    OnMessage(0x0201, AlPresionarMouse, 0)
    OnMessage(0x0232, AlTerminarArrastre, 0)
    for temporizador in [Tick, AnimarTeclas, ActualizarHaloMouse, TerminarRedimension, ReubicarMostrador]
        SetTimer(temporizador, 0)
    if IsSet(ih) && IsObject(ih)
        ih.Stop()
    LiberarHaloMouse()
    if IsSet(overlay) && IsObject(overlay)
        overlay.Destroy()
    overlay := 0
    if IsObject(Redimension) {
        DllCall("SelectObject", "ptr", Redimension.dc, "ptr", Redimension.old)
        DllCall("DeleteObject", "ptr", Redimension.bmp)
        DllCall("DeleteDC", "ptr", Redimension.dc)
        Redimension := 0
    }
    if HistorialBitmap
        DllCall("DeleteObject", "ptr", HistorialBitmap)
    HistorialBitmap := 0
    LiberarTodasImagenesModernas()
    LiberarRecursos()
}

; Notas independientes del historial: espacios intactos y fuente monoespaciada.
LeerNota() {
    global ArchivoNota
    try return FileRead(ArchivoNota, "UTF-8")
    catch
        return ""
}

TextoNotaVisible(texto, marcas) {
    texto := StrReplace(texto, "`r")
    resultado := "", columna := 0
    Loop Parse texto {
        ch := A_LoopField
        if ch = "`n" {
            resultado .= ch, columna := 0
        } else if ch = "`t" {
            cantidad := 4 - Mod(columna, 4)
            resultado .= marcas ? "→" : " "
            Loop cantidad - 1
                resultado .= marcas ? "·" : " "
            columna += cantidad
        } else {
            resultado .= marcas && ch = " " ? "·" : ch
            columna += 1
        }
    }
    return resultado
}

AltoNota(escala) {
    global NotaMostrar, NotaTexto, NotaTam, NotaLineas, NotaContraida
    if !NotaMostrar
        return 0
    if NotaContraida
        return Max(16, Round(20 * A_ScreenDPI / 96 * escala))
    return CabeceraNota(escala) + Round((NotaTam * A_ScreenDPI / 72 * 1.45 * NotaLineas + 20 * A_ScreenDPI / 96) * escala)
}

; El panel es una ventana propiedad del teclado: admite clics aun bloqueado.
CabeceraNota(escala) => Max(32, Round(46 * A_ScreenDPI / 96 * escala))

GuardarNotaDirecta(*) {
    global NotaEditor, NotaEditando, NotaTexto, NotaGuardada, ArchivoNota, NotaEstado
    SetTimer(GuardarNotaDirecta, 0)
    if NotaEditando && IsObject(NotaEditor)
        NotaTexto := NotaEditor.Value
    if NotaTexto = NotaGuardada
        return true
    try {
        f := FileOpen(ArchivoNota ".tmp", "w", "UTF-8-RAW")
        f.Write(NotaTexto)
        f.Close()
        FileMove(ArchivoNota ".tmp", ArchivoNota, true)
        NotaGuardada := NotaTexto
        if IsObject(NotaEstado)
            NotaEstado.Text := "Nota · guardada"
        return true
    } catch as err {
        if IsObject(NotaEstado)
            NotaEstado.Text := "Error al guardar"
        return false
    }
}

DestruirPanelNota() {
    global PanelNota, NotaEditor, NotaEstado, NotaAncho, NotaAlto, NotaOffsetX
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        GuardarNotaDirecta()
        ventanaNota := PanelNota
        ; Invalidar primero las referencias que pueden consultar los mensajes de Windows.
        PanelNota := 0, NotaEditor := 0, NotaEstado := 0
        NotaAncho := 0, NotaAlto := 0, NotaOffsetX := 0
        if ventanaNota is Gui
            ventanaNota.Destroy()
    } finally {
        Critical criticoAnterior
    }
}

CrearNota() {
    global overlay, Escala, NotaTam, NotaFuente, NotaColor, NotaFondo, NotaNegrita, NotaTexto, NotaEspacios
    global PanelNota, NotaEditor, NotaEditando, NotaContraida, NotaEstado, U, GuiW, Col, NotaFondoTeclado
    global NotaAncho, NotaAlto, NotaOffsetX
    h := AltoNota(Escala)
    if !h
        return
    w := GuiW - 2 * Round(U * 0.3)
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +Owner" overlay.Hwnd, "Nota de clase")
    g.BackColor := "303030"
    fondoNota := NotaFondoTeclado ? Col.fondo : NotaFondo
    g.MarginX := 0, g.MarginY := 0
    if NotaContraida {
        ; Sólo la pestaña asoma por detrás del borde superior del mostrador.
        w := Min(w, Max(80, Round(120 * Escala * A_ScreenDPI / 96)))
        g.Opt("+E0x08000000")
        g.SetFont("s" Pt(Max(10, h * 0.55)) " cD6D6D6", "Segoe UI")
        pestana := g.AddText(Format("x1 y1 w{} h{} Center +0x200 +0x100 Background{}", w - 2, h - 1, Col.fondo), "▴  NOTA")
        pestana.OnEvent("Click", ContraerNota)
        g.OnEvent("Close", (*) => OcultarNotaDirecta())
        RedondearNota(g, w, h, Max(6, Round(h * 0.5)))
        NotaAncho := w, NotaAlto := h, NotaOffsetX := (GuiW - w) // 2
        PanelNota := g
        return
    }
    cab := CabeceraNota(Escala)
    pad := Max(7, Round(12 * Escala * A_ScreenDPI / 96))
    tam := cab - 2 * Max(5, Round(cab * 0.15))
    separacion := Max(4, Round(U * 0.14))
    g.AddText(Format("x1 y1 w{} h{} Background{}", w - 2, h - 2, fondoNota))
    g.AddText(Format("x1 y1 w{} h{} Background{}", w - 2, cab - 1, Col.fondo))
    g.AddText(Format("x1 y{} w{} h1 Background272727", cab - 1, w - 2))
    g.SetFont("s" Pt(Max(10, tam * 0.43)) " cAAAAAA", "Segoe UI")
    anchoBotones := 6 * (tam + separacion)
    NotaEstado := g.AddText(Format("x{} y1 w{} h{} +0x200 Background{}", pad,
        Max(20, w - anchoBotones - 2 * pad), cab - 2, Col.fondo), NotaEditando ? "Nota · editando" : "Nota")
    ; Glifos de Windows. Minimizar y cerrar ocupan el extremo superior derecho.
    acciones := [[NotaEditando ? Chr(0xE74E) : Chr(0xE70F), (*) => EditarNotaDirecta(), "Segoe MDL2 Assets"],
        ["A−", (*) => CambiarLetraNota(-2), "Segoe UI"],
        ["A+", (*) => CambiarLetraNota(2), "Segoe UI"],
        [Chr(0xE713), (*) => AbrirNotas(), "Segoe MDL2 Assets"],
        [Chr(0xE921), (*) => ContraerNota(), "Segoe MDL2 Assets"],
        [Chr(0xE8BB), (*) => OcultarNotaDirecta(), "Segoe MDL2 Assets"]]
    for i, accion in acciones {
        tinta := i = 1 && NotaEditando ? "FF899A" : "D6D6D6"
        g.SetFont("s" Pt(tam * 0.48) " c" tinta " norm", accion[3])
        boton := g.AddText(Format("x{} y{} w{} h{} Center +0x200 +0x100 Background{}",
            w - pad - (7 - i) * (tam + separacion), (cab - tam) // 2, tam, tam, Col.fondo), accion[1])
        boton.OnEvent("Click", accion[2])
    }
    if !NotaContraida {
        g.SetFont("s" Max(6, Round(NotaTam * Escala)) " c" NotaColor (NotaNegrita ? " bold" : " norm"), NotaFuente)
        opts := Format("x{} y{} w{} h{}", pad, cab + pad, w - 2 * pad, Max(1, h - cab - 2 * pad))
        if NotaEditando {
            NotaEditor := g.AddEdit(opts " Multi WantTab Limit0 -E0x200 -Border Background" fondoNota, NotaTexto)
            NotaEditor.OnEvent("Change", NotaModificada)
        } else {
            lectura := g.AddText(opts " +0x80 +0x100 Background" fondoNota, TextoNotaVisible(NotaTexto, NotaEspacios))
            lectura.OnEvent("DoubleClick", (*) => EditarNotaDirecta())
        }
    }
    radio := Max(8, Round(14 * Escala * A_ScreenDPI / 96))
    RedondearNota(g, w, h, radio)
    g.OnEvent("Close", (*) => OcultarNotaDirecta())
    g.OnEvent("Escape", (*) => FinalizarEdicionNota())
    NotaAncho := w, NotaAlto := h, NotaOffsetX := Round(U * 0.3)
    PanelNota := g
}

RedondearNota(g, w, h, radio) {
    region := DllCall("CreateRoundRectRgn", "int", 0, "int", 0, "int", w + 1, "int", h + 1, "int", radio, "int", radio, "ptr")
    if region && !DllCall("SetWindowRgn", "ptr", g.Hwnd, "ptr", region, "int", false)
        DllCall("DeleteObject", "ptr", region)
}

ActualizarNota(mensaje) {
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        DestruirPanelNota()
        CrearNota()
        AgregarAlHistorial(mensaje)
        PosicionarPanelNota()
    } finally {
        Critical criticoAnterior
    }
}

PosicionarPanelNota() {
    global PanelNota, Visible, Minimizado, overlay, Redimension, NotaAncho, NotaAlto, NotaOffsetX
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        ventanaNota := PanelNota
        if !(ventanaNota is Gui)
            return
        if !VentanaMostradorDisponible() || !Visible || Minimizado || IsObject(Redimension) {
            ventanaNota.Hide()
            return
        }
        if NotaAncho <= 0 || NotaAlto <= 0
            return
        overlay.GetPos(&x, &y)
        ; La pestaña se centra y la tarjeta abierta conserva el ancho del mostrador.
        MostrarCapaMostrador(ventanaNota, x + NotaOffsetX, y - NotaAlto, NotaAncho, NotaAlto)
    } finally {
        Critical criticoAnterior
    }
}

NotaModificada(*) {
    global NotaEstado
    if IsObject(NotaEstado)
        NotaEstado.Text := "Nota · editando"
    SetTimer(GuardarNotaDirecta, -500)
}

FocoNota() {
    global PanelNota, NotaEditor, NotaEditando
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if NotaEditando && (PanelNota is Gui) && IsObject(NotaEditor) {
            MostrarDialogoMostrador(PanelNota)
            NotaEditor.Focus()
            SendMessage(0xB1, -1, -1, NotaEditor) ; EM_SETSEL: cursor al final
        }
    } finally {
        Critical criticoAnterior
    }
}

EditarNotaDirecta(*) {
    global NotaMostrar, NotaContraida, NotaEditando, Redimension, Minimizado
    if IsObject(Redimension) || !GuardarNotaDirecta()
        return
    if NotaEditando {
        FinalizarEdicionNota()
        return
    }
    NotaMostrar := 1, NotaContraida := 0, NotaEditando := true
    if Minimizado
        AlternarMinimizado()
    GuardarEstiloNota()
    ActualizarNota("Edita directamente la nota · ✓ para terminar")
    FocoNota()
}

FinalizarEdicionNota(*) {
    global NotaEditando
    if !NotaEditando || !GuardarNotaDirecta()
        return
    NotaEditando := false
    ActualizarNota("Nota guardada")
}

CambiarLetraNota(delta) {
    global NotaTam, NotaEditando, CamposNotas, Redimension
    if IsObject(Redimension) || !GuardarNotaDirecta()
        return
    nuevoTam := Max(10, Min(48, NotaTam + delta))
    if nuevoTam = NotaTam
        return
    NotaTam := nuevoTam
    if IsObject(CamposNotas)
        CamposNotas.tam.Value := NotaTam
    GuardarEstiloNota()
    ActualizarNota("Letra de la nota: " NotaTam " pt")
    FocoNota()
}

ContraerNota(*) {
    global NotaContraida, NotaEditando, Redimension
    if IsObject(Redimension) || !GuardarNotaDirecta()
        return
    NotaEditando := false, NotaContraida := !NotaContraida
    GuardarEstiloNota()
    ActualizarNota(NotaContraida ? "Nota guardada detrás · pulsa la pestaña NOTA" : "Nota expandida")
}

OcultarNotaDirecta(*) {
    global NotaMostrar, NotaEditando, Redimension
    if IsObject(Redimension) || !GuardarNotaDirecta()
        return
    NotaEditando := false, NotaMostrar := 0
    GuardarEstiloNota()
    ActualizarNota("Nota oculta · ✎ para recuperarla")
}


GuardarEstiloNota() {
    global ArchivoConfig, NotaMostrar, NotaFuente, NotaTam, NotaLineas, NotaNegrita, NotaEspacios, NotaColor, NotaFondo
    global NotaContraida, NotaFondoTeclado
    for k, v in Map("FondoTeclado", NotaFondoTeclado, "Contraida", NotaContraida, "Mostrar", NotaMostrar, "Fuente", NotaFuente, "Tamano", NotaTam, "Lineas", NotaLineas,
        "Negrita", NotaNegrita, "Espacios", NotaEspacios, "Color", NotaColor, "Fondo", NotaFondo)
        IniWrite(v, ArchivoConfig, "Notas", k)
}

AlternarNota() {
    global NotaMostrar, NotaTexto, NotaEditando, Redimension
    if IsObject(Redimension)
        return
    if NotaTexto = "" {
        EditarNotaDirecta()
        return
    }
    if !GuardarNotaDirecta()
        return
    NotaEditando := false
    NotaMostrar := !NotaMostrar
    GuardarEstiloNota()
    ActualizarNota(NotaMostrar ? "Nota visible" : "Nota oculta")
}

CerrarNotas(*) {
    global NotasGui, CamposNotas
    if IsObject(NotasGui)
        NotasGui.Destroy()
    NotasGui := 0, CamposNotas := 0
}

AbrirNotas() {
    FinalizarEdicionNota()
    global NotasGui, CamposNotas, NotaMostrar, NotaTexto, NotaFuente, NotaTam, NotaLineas
    global NotaNegrita, NotaEspacios, NotaColor, NotaFondo, Redimension, NotaFondoTeclado
    if IsObject(Redimension)
        return
    if IsObject(NotasGui) {
        MostrarDialogoMostrador(NotasGui)
        return
    }
    g := Gui("+AlwaysOnTop", "Notas de clase · Mostrador de teclas")
    NotasGui := g
    g.SetFont("s10 cF1F1F1", "Segoe UI")
    g.AddText("x18 y14 w500 h26", "NOTA DE CLASE · texto independiente del historial")
    mostrar := g.AddCheckbox("x18 y46 w500 h26", "Mostrar nota encima del teclado")
    mostrar.Value := NotaTexto = "" ? 1 : NotaMostrar
    g.SetFont("s11 norm", "Consolas")
    texto := g.AddEdit("x18 y80 w500 h180 Multi WantTab -Wrap Limit0", NotaTexto)
    g.SetFont("s10 norm", "Segoe UI")
    g.AddText("x18 y276 w56 h24", "Fuente")
    fuentes := ["Consolas", "Cascadia Mono", "Lucida Console", "Courier New"]
    fuente := g.AddDropDownList("x78 y272 w220", fuentes)
    fuente.Choose(1)
    for i, nombre in fuentes
        if nombre = NotaFuente
            fuente.Choose(i)
    g.AddText("x312 y276 w65 h24", "Tamaño")
    tam := g.AddEdit("x382 y272 w64 Number", NotaTam)
    g.AddUpDown("Range10-48", NotaTam)
    negrita := g.AddCheckbox("x18 y310 w220 h26", "Negrita")
    negrita.Value := NotaNegrita
    color := CampoColorMouse(g, 352, "Color del texto", NotaColor)
    fondo := CampoColorMouse(g, 392, "Fondo personalizado", NotaFondo)
    espacios := g.AddCheckbox("x18 y436 w500 h26", "Marcar espacios (·) y tabulaciones (→)")
    espacios.Value := NotaEspacios
    g.AddText("x18 y480 w245 h25", "Altura del panel (líneas)")
    lineas := g.AddEdit("x280 y476 w70 Number", NotaLineas)
    g.AddUpDown("Range1-8", NotaLineas)
    g.AddText("x18 y520 w500 h36", "Si el texto no cabe, aumenta la altura o reduce el tamaño. Se conservan los espacios y saltos de línea.")
    fondoTeclado := g.AddCheckbox("x18 y562 w500 h24", "Usar el mismo fondo del teclado")
    fondoTeclado.Value := NotaFondoTeclado
    g.AddButton("x260 y594 w130 h32 Default", "Aplicar").OnEvent("Click", AplicarNota)
    g.AddButton("x400 y594 w118 h32", "Cerrar").OnEvent("Click", CerrarNotas)
    g.OnEvent("Close", CerrarNotas)
    g.OnEvent("Escape", CerrarNotas)
    CamposNotas := {mostrar: mostrar, texto: texto, fuente: fuente, tam: tam, negrita: negrita,
        color: color, fondo: fondo, espacios: espacios, lineas: lineas, fondoTeclado: fondoTeclado}
    AplicarTemaAjustes(g)
    MostrarDialogoMostrador(g, "w538 h644")
    texto.Focus()
}

AplicarNota(*) {
    global CamposNotas, NotasGui, ArchivoNota, NotaMostrar, NotaTexto, NotaFuente, NotaTam, NotaLineas
    global NotaNegrita, NotaEspacios, NotaColor, NotaFondo, Redimension, NotaGuardada, NotaEditando, NotaFondoTeclado
    if IsObject(Redimension) || !GuardarNotaDirecta()
        return
    c := CamposNotas
    color := ColorMouseValido(c.color.campo.Value), fondo := ColorMouseValido(c.fondo.campo.Value)
    if color = "" || fondo = "" || !IsInteger(c.tam.Value) || !IsInteger(c.lineas.Value) {
        MsgBox("Revisa los colores (6 dígitos hexadecimales), el tamaño y las líneas.", "Nota de clase")
        return
    }
    texto := c.texto.Value
    try {
        f := FileOpen(ArchivoNota ".tmp", "w", "UTF-8-RAW")
        f.Write(texto)
        f.Close()
        FileMove(ArchivoNota ".tmp", ArchivoNota, true)
    } catch as err {
        MsgBox("No se pudo guardar la nota: " err.Message, "Nota de clase")
        return
    }
    NotaEditando := false
    NotaTexto := texto, NotaGuardada := texto
    NotaMostrar := c.mostrar.Value, NotaFuente := c.fuente.Text
    NotaTam := Max(10, Min(48, Integer(c.tam.Value))), NotaLineas := Max(1, Min(8, Integer(c.lineas.Value)))
    NotaNegrita := c.negrita.Value, NotaEspacios := c.espacios.Value
    NotaColor := color, NotaFondo := fondo, NotaFondoTeclado := c.fondoTeclado.Value
    GuardarEstiloNota()
    ActualizarNota("Nota guardada · Ctrl+Alt+T para mostrar / ocultar")
}

; Selección global: el lector se ejecuta aparte para aislar los proveedores UIA.
AplicarModoSeleccion() {
    global SeleccionActivo, SeleccionPid, ArchivoConfig
    if SeleccionPid && !ProcessExist(SeleccionPid)
        SeleccionPid := 0
    if !SeleccionActivo {
        if SeleccionPid
            try ProcessClose(SeleccionPid)
        SeleccionPid := 0
        return
    }
    if SeleccionPid
        return
    componente := A_ScriptDir "\mostrador-seleccion.ahk"
    if !FileExist(componente) {
        SeleccionActivo := false
        IniWrite(0, ArchivoConfig, "Seleccion", "Activo")
        MsgBox("Coloca mostrador-seleccion.ahk junto al mostrador para activar el resaltado.", "Selección de texto")
        return
    }
    try Run('"' A_AhkPath '" "' componente '" ' ProcessExist() ' "' ArchivoConfig '"', A_ScriptDir, "Hide", &SeleccionPid)
    catch as err {
        SeleccionActivo := false, SeleccionPid := 0
        IniWrite(0, ArchivoConfig, "Seleccion", "Activo")
        MsgBox("No se pudo iniciar el resaltado: " err.Message, "Selección de texto")
    }
}

GuardarSeleccion() {
    global ArchivoConfig, SeleccionActivo, SeleccionFondo, SeleccionTexto, SeleccionSombra, SeleccionGrosor, SeleccionNegrita
    for clave, valor in Map("Activo", SeleccionActivo, "Fondo", SeleccionFondo, "Texto", SeleccionTexto,
        "Sombra", SeleccionSombra, "Grosor", SeleccionGrosor, "Negrita", SeleccionNegrita)
        IniWrite(valor, ArchivoConfig, "Seleccion", clave)
}

AlternarSeleccion(*) {
    global SeleccionActivo, CamposSeleccion
    SeleccionActivo := !SeleccionActivo
    GuardarSeleccion()
    AplicarModoSeleccion()
    if IsObject(CamposSeleccion)
        CamposSeleccion.activo.Value := SeleccionActivo
    ActualizarMenuSeleccion()
}

ActualizarMenuSeleccion() {
    global SeleccionActivo
    item := "Resaltar selección de texto  (Ctrl+Alt+S)"
    if SeleccionActivo
        A_TrayMenu.Check(item)
    else
        A_TrayMenu.Uncheck(item)
}

HwndGuiMostrador(g, visible := false) {
    if !(g is Gui)
        return 0
    try hwnd := g.Hwnd
    catch
        return 0
    if !hwnd || !DllCall("IsWindow", "ptr", hwnd)
        return 0
    return visible && !DllCall("IsWindowVisible", "ptr", hwnd) ? 0 : hwnd
}

VentanasDialogoMostrador() {
    global MenuMostradorGui, ClaseGui, ClaseTiemposGui, AjustesMouseGui, NotasGui
    global AjustesSeleccionGui, AnotAjustes, AnotTextoGui, PanelNota, NotaEditando
    tiempos := IsSet(ClaseTiemposGui) ? ClaseTiemposGui : 0
    return [ClaseGui, tiempos, AjustesMouseGui, NotasGui, AjustesSeleccionGui,
        AnotAjustes, AnotTextoGui, NotaEditando ? PanelNota : 0, MenuMostradorGui]
}

CapasMostrador() {
    global FocoClaseGui, overlay, PanelNota, RelojClaseGui, HaloMouse, ControlMinimizar
    global AnotLienzo, AnotCaptura, AnotBarra
    ; Del fondo hacia delante. Los diálogos se ordenan al terminar.
    ; La entrada y la tinta quedan por debajo de los controles interactivos.
    return [FocoClaseGui, AnotLienzo, AnotCaptura, overlay, PanelNota, RelojClaseGui,
        HaloMouse, ControlMinimizar, AnotBarra]
}

RecordarFrenteMostrador(hwnd) {
    global FrenteOrdenMostrador
    orden := []
    for anterior in FrenteOrdenMostrador
        if anterior != hwnd
            orden.Push(anterior)
    orden.Push(hwnd)
    FrenteOrdenMostrador := orden
}

MostrarDialogoMostrador(g, opciones := "") {
    global CerrandoMostrador, AnotModo, AnotTextoGui
    if CerrandoMostrador || !HwndGuiMostrador(g)
        return
    ; Los atajos de herramientas no deben interceptar la escritura en un diálogo.
    if AnotModo && HwndGuiMostrador(g) != HwndGuiMostrador(AnotTextoGui)
        PausarAnotaciones()
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        g.Show(opciones)
        hwnd := HwndGuiMostrador(g, true)
        if !hwnd
            return
        RecordarFrenteMostrador(hwnd)
        DllCall("SetWindowPos", "ptr", hwnd, "ptr", -1, "int", 0, "int", 0,
            "int", 0, "int", 0, "uint", 0x0213)
        ; Sólo una apertura solicitada activa la ventana. Reposicionar capas no lo hace.
        try WinActivate("ahk_id " hwnd)
        MantenerFrenteDialogosMostrador()
    } finally {
        Critical criticoAnterior
    }
}

MostrarCapaMostrador(g, x, y, w, h) {
    global CerrandoMostrador
    hwnd := HwndGuiMostrador(g)
    if CerrandoMostrador || !hwnd
        return
    if DllCall("IsWindowVisible", "ptr", hwnd) {
        ; NOMOVE/NOSIZE no se usan: sólo conservar Z y activación, también para notas.
        DllCall("SetWindowPos", "ptr", hwnd, "ptr", 0, "int", x, "int", y,
            "int", w, "int", h, "uint", 0x0214)
    } else {
        g.Show(Format("x{} y{} w{} h{} NoActivate", x, y, w, h))
        ReordenarCapasMostrador()
    }
}

ActivacionDialogosMostrador(wParam, lParam, msg, hwnd) {
    global CerrandoMostrador
    if CerrandoMostrador || (wParam & 0xFFFF) = 0
        return
    for g in VentanasDialogoMostrador() {
        if HwndGuiMostrador(g) = hwnd {
            RecordarFrenteMostrador(hwnd)
            return
        }
    }
}

CambioCapasMostrador(wParam, lParam, msg, hwnd) {
    global CerrandoMostrador, FrenteReordenandoMostrador
    if CerrandoMostrador || FrenteReordenandoMostrador || !lParam
        return
    ; WINDOWPOS.flags: ignorar los movimientos que ya conservan el orden Z.
    if NumGet(lParam, 2 * A_PtrSize + 16, "uint") & 0x0004
        return
    for g in CapasMostrador() {
        if HwndGuiMostrador(g, true) = hwnd {
            SetTimer(ReordenarCapasMostrador, -1)
            return
        }
    }
}

OrdenarDialogosMostradorInterno() {
    global FrenteOrdenMostrador
    visibles := Map(), orden := []
    for g in VentanasDialogoMostrador() {
        hwnd := HwndGuiMostrador(g, true)
        if hwnd
            visibles[hwnd] := true
    }
    for hwnd in FrenteOrdenMostrador {
        if visibles.Has(hwnd) {
            orden.Push(hwnd)
            visibles.Delete(hwnd)
        }
    }
    for hwnd, valor in visibles
        orden.Push(hwnd)
    ; Conservar también los selectores y mensajes nativos que está usando el usuario.
    frente := DllCall("GetForegroundWindow", "ptr")
    proceso := 0
    if frente
        DllCall("GetWindowThreadProcessId", "ptr", frente, "uint*", &proceso)
    esCapa := false
    if proceso = ProcessExist() {
        for g in CapasMostrador()
            if HwndGuiMostrador(g) = frente
                esCapa := true
        if !esCapa {
            sinFrente := []
            for hwnd in orden
                if hwnd != frente
                    sinFrente.Push(hwnd)
            sinFrente.Push(frente)
            orden := sinFrente
        }
    }
    FrenteOrdenMostrador := orden.Clone()
    for hwnd in orden {
        if DllCall("IsWindow", "ptr", hwnd) && DllCall("IsWindowVisible", "ptr", hwnd)
            DllCall("SetWindowPos", "ptr", hwnd, "ptr", -1, "int", 0, "int", 0,
                "int", 0, "int", 0, "uint", 0x0213)
    }
}

MantenerFrenteDialogosMostrador() {
    global CerrandoMostrador, FrenteReordenandoMostrador
    if CerrandoMostrador || FrenteReordenandoMostrador
        return
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        FrenteReordenandoMostrador := true
        OrdenarDialogosMostradorInterno()
    } finally {
        FrenteReordenandoMostrador := false
        Critical criticoAnterior
    }
}

ReordenarCapasMostrador() {
    global CerrandoMostrador, FrenteReordenandoMostrador
    if CerrandoMostrador || FrenteReordenandoMostrador
        return
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        FrenteReordenandoMostrador := true
        for g in CapasMostrador() {
            hwnd := HwndGuiMostrador(g, true)
            if hwnd
                DllCall("SetWindowPos", "ptr", hwnd, "ptr", -1, "int", 0, "int", 0,
                    "int", 0, "int", 0, "uint", 0x0213)
        }
        OrdenarDialogosMostradorInterno()
    } finally {
        FrenteReordenandoMostrador := false
        Critical criticoAnterior
    }
}

AbrirMenuAjustes(*) {
    global MenuMostradorGui, MenuMostradorControles, AnotModo, CerrandoMostrador
    if CerrandoMostrador
        return
    if MenuMostradorGui is Gui {
        CerrarMenuMostrador()
        return
    }
    if AnotModo
        PausarAnotaciones()
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", "Ajustes · Mostrador")
        MenuMostradorGui := g, MenuMostradorControles := []
        g.BackColor := "0F0F0F"
        g.MarginX := 0, g.MarginY := 0
        g.AddText(RectClase(0, 0, 352, 438) " Background303030")
        g.AddText(RectClase(1, 1, 350, 436) " Background0F0F0F")
        g.SetFont("s17 cF1F1F1 bold", "Segoe UI")
        g.AddText(RectClase(18, 14, 258, 30) " Background0F0F0F", "Ajustes")
        g.SetFont("s9 c909090 norm", "Segoe UI")
        g.AddText(RectClase(18, 44, 300, 22) " Background0F0F0F", "Todo para tu clase, en un lugar")
        MenuMostradorControles.Push(BotonClaseModerno(g, "X", 302, 16, 32, 32, CerrarMenuMostrador, "232323", "AAAAAA", 16))
        entradas := [["Panel de clase", "Temporizador, foco y accesos rápidos", AbrirPanelClase],
            ["Mouse y aura", "Colores, tamaño y brillo del cursor", AbrirAjustesMouse],
            ["Notas", "Tipografía, colores y presentación", AbrirNotas],
            ["Selección de texto", "Resaltado y contraste de la selección", AbrirAjustesSeleccion],
            ["Anotar pantalla", "Dibuja, señala y escribe sobre la clase", IniciarAnotaciones],
            ["Ajustes de anotaciones", "Herramientas, color y duración", AbrirAjustesAnotaciones]]
        for i, entrada in entradas {
            y := 80 + (i - 1) * 58
            fondo := i = 1 ? "203044" : "1D1D1D"
            tinta := i = 1 ? "B6D7FF" : "F1F1F1"
            accion := ElegirAccionMenuMostrador.Bind(entrada[3])
            MenuMostradorControles.Push(BotonClaseModerno(g, entrada[1] "`n" entrada[2], 18, y, 316, 52, accion, fondo, tinta, 15))
        }
        g.OnEvent("Close", CerrarMenuMostrador)
        g.OnEvent("Escape", CerrarMenuMostrador)
        s := A_ScreenDPI / 96
        w := Round(352 * s), h := Round(438 * s)
        punto := Buffer(8, 0)
        DllCall("GetCursorPos", "ptr", punto)
        x := NumGet(punto, 0, "int") - w + Round(22 * s)
        y := NumGet(punto, 4, "int") + Round(12 * s)
        pos := PosicionEnPantalla(x, y, w, h)
        g.Show(Format("Hide x{} y{} w{} h{}", pos[1], pos[2], w, h))
        RedondearNota(g, w, h, Round(18 * s))
        MostrarDialogoMostrador(g)
    } catch as err {
        CerrarMenuMostrador()
        MsgBox("No se pudo abrir el menú: " err.Message, "Mostrador")
    } finally {
        Critical criticoAnterior
    }
}

ElegirAccionMenuMostrador(accion, *) {
    CerrarMenuMostrador()
    accion.Call()
}

ActivacionMenuMostrador(wParam, lParam, msg, hwnd) {
    global MenuMostradorGui, CerrandoMostrador
    if CerrandoMostrador || !(MenuMostradorGui is Gui) || hwnd != MenuMostradorGui.Hwnd
        return
    if (wParam & 0xFFFF) = 0
        SetTimer(CerrarMenuMostradorSiInactivo, -1)
    else
        SetTimer(CerrarMenuMostradorSiInactivo, 0)
}

CerrarMenuMostradorSiInactivo() {
    global MenuMostradorGui
    if (MenuMostradorGui is Gui) && DllCall("GetForegroundWindow", "ptr") != MenuMostradorGui.Hwnd
        CerrarMenuMostrador()
}

CerrarMenuMostrador(*) {
    global MenuMostradorGui, MenuMostradorControles
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        SetTimer(CerrarMenuMostradorSiInactivo, 0)
        g := MenuMostradorGui
        MenuMostradorGui := 0, MenuMostradorControles := []
        if g is Gui {
            LiberarImagenesModernas(g)
            g.Destroy()
        }
    } finally {
        Critical criticoAnterior
    }
}

AbrirAjustesSeleccion(*) {
    global AjustesSeleccionGui, CamposSeleccion, SeleccionActivo, SeleccionFondo, SeleccionTexto, SeleccionSombra
    global SeleccionGrosor, SeleccionNegrita
    if IsObject(AjustesSeleccionGui) {
        MostrarDialogoMostrador(AjustesSeleccionGui)
        return
    }
    g := Gui("+AlwaysOnTop", "Selección de texto · Mostrador")
    AjustesSeleccionGui := g
    g.SetFont("s16 cF1F1F1 bold", "Segoe UI")
    g.AddText("x18 y16 w490 h32", "Selección de texto")
    g.SetFont("s10 norm cAAAAAA", "Segoe UI")
    g.AddText("x18 y54 w490 h40", "Resalta el texto seleccionado en las aplicaciones que exponen su selección a Windows.")
    g.SetFont("s10 cF1F1F1", "Segoe UI")
    activo := g.AddCheckbox("x18 y106 w490 h26", "Activar resaltado global · Ctrl + Alt + S")
    activo.Value := SeleccionActivo
    fondo := CampoColorMouse(g, 152, "Fondo del resaltado", SeleccionFondo)
    texto := CampoColorMouse(g, 194, "Color de las letras", SeleccionTexto)
    sombra := CampoColorMouse(g, 236, "Sombra y contorno", SeleccionSombra)
    g.AddText("x18 y286 w265 h25", "Grosor de sombra y contorno")
    grosor := g.AddEdit("x300 y282 w70 Number", SeleccionGrosor)
    g.AddUpDown("Range1-6", SeleccionGrosor)
    negrita := g.AddCheckbox("x18 y328 w400 h26", "Letras en negrita")
    negrita.Value := SeleccionNegrita
    g.SetFont("s9 cAAAAAA", "Segoe UI")
    g.AddText("x18 y374 w490 h56", "La capa deja pasar los clics y se retira al cambiar de ventana o selección. Si una aplicación no facilita el texto y su posición, conserva su selección habitual.")
    g.SetFont("s10 cF1F1F1", "Segoe UI")
    g.AddButton("x18 y452 w155 h34", "Colores iniciales").OnEvent("Click", RestablecerSeleccion)
    g.AddButton("x280 y452 w110 h34 Default", "Aplicar").OnEvent("Click", AplicarAjustesSeleccion)
    g.AddButton("x400 y452 w110 h34", "Cerrar").OnEvent("Click", CerrarAjustesSeleccion)
    CamposSeleccion := {activo: activo, fondo: fondo, texto: texto, sombra: sombra, grosor: grosor, negrita: negrita}
    g.OnEvent("Close", CerrarAjustesSeleccion)
    g.OnEvent("Escape", CerrarAjustesSeleccion)
    AplicarTemaAjustes(g)
    MostrarDialogoMostrador(g, "w530 h508")
}

RestablecerSeleccion(*) {
    global CamposSeleccion
    c := CamposSeleccion
    for clave, color in Map("fondo", "FFD600", "texto", "FFFFFF", "sombra", "000000") {
        campo := c.%clave%
        campo.campo.Value := color
        ActualizarMuestraMouse(campo.campo, campo.muestra)
    }
    c.grosor.Value := 3, c.negrita.Value := 1
}

AplicarAjustesSeleccion(*) {
    global CamposSeleccion, SeleccionActivo, SeleccionFondo, SeleccionTexto, SeleccionSombra, SeleccionGrosor, SeleccionNegrita
    c := CamposSeleccion
    fondo := ColorMouseValido(c.fondo.campo.Value)
    texto := ColorMouseValido(c.texto.campo.Value)
    sombra := ColorMouseValido(c.sombra.campo.Value)
    if fondo = "" || texto = "" || sombra = "" || !IsInteger(c.grosor.Value) {
        MsgBox("Revisa los tres colores y el grosor de la sombra.", "Selección de texto")
        return
    }
    SeleccionActivo := c.activo.Value, SeleccionFondo := fondo, SeleccionTexto := texto, SeleccionSombra := sombra
    SeleccionGrosor := Max(1, Min(6, Integer(c.grosor.Value))), SeleccionNegrita := c.negrita.Value
    ; Reiniciar sólo el lector para aplicar el estilo de forma coherente.
    DetenerSeleccion()
    GuardarSeleccion()
    AplicarModoSeleccion()
    c.activo.Value := SeleccionActivo
    ActualizarMenuSeleccion()
}

DetenerSeleccion() {
    global SeleccionPid
    if SeleccionPid && ProcessExist(SeleccionPid)
        try ProcessClose(SeleccionPid)
    SeleccionPid := 0
}

CerrarAjustesSeleccion(*) {
    global AjustesSeleccionGui, CamposSeleccion
    if IsObject(AjustesSeleccionGui)
        AjustesSeleccionGui.Destroy()
    AjustesSeleccionGui := 0, CamposSeleccion := 0
}

; Anotaciones temporales. El lienzo deja pasar los clics; sólo el modo de dibujo
; muestra una superficie de captura independiente y una barra de herramientas.
IniciarAnotaciones(*) {
    global AnotModo, AnotCaptura, AnotBarra, AnotTextoGui, AnotPausa, ClaseGui
    ; Cerrar el panel libera espacio y evita que sus campos compartan atajos de dibujo.
    if ClaseGui is Gui
        CerrarPanelClase()
    if AnotTextoGui is Gui {
        MostrarDialogoMostrador(AnotTextoGui)
        return
    }
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if AnotModo
            return
        CrearLienzoAnotaciones()
        AnotModo := true, AnotPausa := false
        MostrarCapturaAnotaciones()
        if AnotBarra is Gui {
            ActualizarPaletaAnotaciones()
            AnotBarra.Show("NoActivate")
        } else {
            CrearBarraAnotaciones()
        }
        ActualizarAreaCapturaAnotaciones()
        ReordenarCapasMostrador()
        A_TrayMenu.Check("Anotar pantalla  (Ctrl+Alt+A)")
    } catch as err {
        CerrarAnotaciones()
        MsgBox("No se pudo abrir el modo de anotación: " err.Message, "Anotaciones")
    } finally {
        Critical criticoAnterior
    }
}

AlternarAnotaciones(*) {
    global AnotModo
    if AnotModo
        FinalizarAnotaciones()
    else
        IniciarAnotaciones()
}

FinalizarAnotaciones(*) {
    global AnotModo, AnotActual, AnotCaptura, AnotBarra, AnotHwndCaptura, AnotTextoPendiente, AnotTextoEdicion, AnotDuracion
    global AnotPausa
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        SetTimer(AbrirTextoAnotacion, 0)
        AnotTextoPendiente := false
        CancelarMovimientoTextoAnotacion()
        if IsObject(AnotTextoEdicion)
            AnotTextoEdicion.vence := AnotDuracion ? A_TickCount + AnotDuracion * 1000 : 0
        AnotTextoEdicion := 0
        LiberarAreaCapturaAnotaciones()
        AnotModo := false, AnotPausa := false, AnotActual := 0
        if AnotHwndCaptura && DllCall("GetCapture", "ptr") = AnotHwndCaptura
            DllCall("ReleaseCapture")
        if AnotCaptura is Gui
            AnotCaptura.Hide()
        if AnotBarra is Gui
            AnotBarra.Hide()
        A_TrayMenu.Uncheck("Anotar pantalla  (Ctrl+Alt+A)")
        SolicitarPintadoAnotaciones()
    } finally {
        Critical criticoAnterior
    }
}

AlternarPausaAnotaciones(*) {
    global AnotModo
    if AnotModo
        PausarAnotaciones()
    else
        IniciarAnotaciones()
}

PausarAnotaciones(*) {
    global AnotModo, AnotPausa, AnotActual, AnotCaptura, AnotBarra, AnotHwndCaptura
    global AnotTextoPendiente, AnotTextoEdicion, AnotDuracion, AnotTextoGui
    if AnotTextoGui is Gui {
        MostrarDialogoMostrador(AnotTextoGui)
        return
    }
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if !AnotModo
            return
        SetTimer(AbrirTextoAnotacion, 0)
        AnotTextoPendiente := false
        CancelarTrazoAnotacion()
        if IsObject(AnotTextoEdicion)
            AnotTextoEdicion.vence := AnotDuracion ? A_TickCount + AnotDuracion * 1000 : 0
        AnotTextoEdicion := 0
        LiberarAreaCapturaAnotaciones()
        AnotModo := false, AnotPausa := true, AnotActual := 0
        if AnotHwndCaptura && DllCall("GetCapture", "ptr") = AnotHwndCaptura
            DllCall("ReleaseCapture")
        if AnotCaptura is Gui
            AnotCaptura.Hide()
        ActualizarPaletaAnotaciones()
        if AnotBarra is Gui
            AnotBarra.Show("NoActivate")
        A_TrayMenu.Uncheck("Anotar pantalla  (Ctrl+Alt+A)")
        SolicitarPintadoAnotaciones()
    } finally {
        Critical criticoAnterior
    }
}

CrearLienzoAnotaciones() {
    global AnotLienzo, AnotCaptura, AnotHwndCaptura, AnotPic, AnotDC, AnotBitmap
    global AnotX, AnotY, AnotW, AnotH, AnotClave
    if AnotLienzo is Gui
        return
    AnotX := SysGet(76), AnotY := SysGet(77)
    AnotW := SysGet(78), AnotH := SysGet(79)
    pantalla := DllCall("GetDC", "ptr", 0, "ptr")
    try {
        AnotDC := DllCall("CreateCompatibleDC", "ptr", pantalla, "ptr")
        AnotBitmap := DllCall("CreateCompatibleBitmap", "ptr", pantalla, "int", AnotW, "int", AnotH, "ptr")
    } finally {
        DllCall("ReleaseDC", "ptr", 0, "ptr", pantalla)
    }
    if !AnotDC || !AnotBitmap
        throw Error("No se pudo preparar el lienzo de pantalla.")
    AnotLienzo := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000020", "Anotaciones")
    AnotLienzo.MarginX := 0, AnotLienzo.MarginY := 0
    AnotLienzo.BackColor := AnotClave
    AnotPic := AnotLienzo.AddText(Format("x0 y0 w{} h{} +0xE", AnotW, AnotH))
    WinSetTransColor(AnotClave, AnotLienzo)
    AnotCaptura := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000", "Dibujar sobre la pantalla")
    AnotCaptura.BackColor := "000000"
    WinSetTransparent(1, AnotCaptura)
    AnotHwndCaptura := AnotCaptura.Hwnd
    PintarAnotaciones()
    AnotLienzo.Show(Format("x{} y{} w{} h{} NoActivate", AnotX, AnotY, AnotW, AnotH))
    SetTimer(ExpirarAnotaciones, 200)
}

; La captura de dibujo deja libres las ventanas interactivas del mostrador.
VentanasInterfazAnotacion() {
    global AnotBarra, overlay, ControlMinimizar, PanelNota, RelojClaseGui
    ventanas := [AnotBarra, overlay, ControlMinimizar, PanelNota, RelojClaseGui]
    for g in VentanasDialogoMostrador()
        ventanas.Push(g)
    return ventanas
}

ProgramarAreaCapturaAnotaciones(wParam, lParam, msg, hwnd) {
    global AnotModo, AnotHwndCaptura, AnotInterfazHwnds, AnotAreaPendiente, CerrandoMostrador
    if CerrandoMostrador || !AnotModo || !AnotHwndCaptura || hwnd = AnotHwndCaptura
        return
    protegido := AnotInterfazHwnds.Has(hwnd)
    if !protegido {
        for g in VentanasInterfazAnotacion() {
            if HwndGuiMostrador(g) = hwnd {
                protegido := true
                break
            }
        }
    }
    if protegido {
        AnotAreaPendiente := true
        SetTimer(ActualizarAreaCapturaAnotaciones, -1)
    }
}

ActualizarAreaCapturaAnotaciones() {
    global AnotModo, AnotCaptura, AnotHwndCaptura, AnotX, AnotY, AnotW, AnotH
    global AnotInterfazHwnds, AnotInterfazRects, AnotAreaClave, AnotAreaPendiente, CerrandoMostrador
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        SetTimer(ActualizarAreaCapturaAnotaciones, 0)
        AnotAreaPendiente := false
        if CerrandoMostrador || !AnotModo || !(AnotCaptura is Gui) || !AnotHwndCaptura
            return false
        if HwndGuiMostrador(AnotCaptura) != AnotHwndCaptura || AnotW < 1 || AnotH < 1
            return false
        ventanas := Map(), rectangulos := [], clave := AnotX "," AnotY "," AnotW "," AnotH
        for g in VentanasInterfazAnotacion() {
            hwnd := HwndGuiMostrador(g, true)
            if !hwnd || ventanas.Has(hwnd)
                continue
            rect := Buffer(16, 0)
            if !DllCall("GetWindowRect", "ptr", hwnd, "ptr", rect)
                continue
            l := Max(AnotX, NumGet(rect, 0, "int")), t := Max(AnotY, NumGet(rect, 4, "int"))
            r := Min(AnotX + AnotW, NumGet(rect, 8, "int")), b := Min(AnotY + AnotH, NumGet(rect, 12, "int"))
            if r <= l || b <= t
                continue
            ventanas[hwnd] := true
            rectangulos.Push([l, t, r, b])
            clave .= "|" hwnd ":" l "," t "," r "," b
        }
        ; También recordar HWND anteriores permite reaccionar a Hide/Destroy.
        AnotInterfazHwnds := ventanas, AnotInterfazRects := rectangulos
        if clave = AnotAreaClave
            return true
        region := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", AnotW, "int", AnotH, "ptr")
        if !region
            return false
        try {
            for rect in rectangulos {
                hueco := DllCall("CreateRectRgn", "int", rect[1] - AnotX, "int", rect[2] - AnotY,
                    "int", rect[3] - AnotX, "int", rect[4] - AnotY, "ptr")
                if !hueco
                    return false
                try resultado := DllCall("CombineRgn", "ptr", region, "ptr", region, "ptr", hueco, "int", 4)
                finally DllCall("DeleteObject", "ptr", hueco)
                if !resultado
                    return false
            }
            if !DllCall("SetWindowRgn", "ptr", AnotHwndCaptura, "ptr", region, "int", true)
                return false
            ; Después del éxito, Windows conserva y libera la región asignada.
            region := 0, AnotAreaClave := clave
            return true
        } finally {
            if region
                DllCall("DeleteObject", "ptr", region)
        }
    } finally {
        Critical criticoAnterior
    }
}

PunteroEnInterfazAnotacion() {
    global AnotInterfazRects, AnotAreaPendiente
    if AnotAreaPendiente
        ActualizarAreaCapturaAnotaciones()
    punto := Buffer(8, 0)
    if !DllCall("GetCursorPos", "ptr", punto)
        return false
    x := NumGet(punto, 0, "int"), y := NumGet(punto, 4, "int")
    for rect in AnotInterfazRects
        if x >= rect[1] && x < rect[3] && y >= rect[2] && y < rect[4]
            return true
    return false
}

LiberarAreaCapturaAnotaciones() {
    global AnotInterfazHwnds, AnotInterfazRects, AnotAreaClave, AnotAreaPendiente
    SetTimer(ActualizarAreaCapturaAnotaciones, 0)
    AnotInterfazHwnds := Map(), AnotInterfazRects := [], AnotAreaClave := "", AnotAreaPendiente := false
}

ConfirmarAnotacionSinMover(cruzandoInterfaz := false) {
    global AnotActual, AnotArrastreTexto, AnotTrazos, AnotDuracion, AnotHwndCaptura, AnotUltimoTexto
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if IsObject(AnotArrastreTexto) {
            TerminarMovimientoTextoAnotacion(false)
            if cruzandoInterfaz
                AnotUltimoTexto := 0
            return true
        }
        if !IsObject(AnotActual)
            return false
        antes := AnotTrazos.Clone()
        AnotActual.vence := AnotDuracion ? A_TickCount + AnotDuracion * 1000 : 0
        AnotTrazos.Push(AnotActual)
        AnotActual := 0
        RegistrarCambioAnotacion(antes)
        if AnotHwndCaptura && DllCall("GetCapture", "ptr") = AnotHwndCaptura
            DllCall("ReleaseCapture")
        SolicitarPintadoAnotaciones()
        return true
    } finally {
        Critical criticoAnterior
    }
}

FlechaInterfazAnotacion() {
    DllCall("SetCursor", "ptr", DllCall("LoadCursorW", "ptr", 0, "ptr", 32512, "ptr"))
}

MostrarCapturaAnotaciones() {
    global AnotCaptura, AnotX, AnotY, AnotW, AnotH
    ActualizarAreaCapturaAnotaciones()
    AnotCaptura.Show(Format("x{} y{} w{} h{} NoActivate", AnotX, AnotY, AnotW, AnotH))
    ReordenarCapasMostrador()
}

AlternarBarraAnotacionesPlegada(*) {
    global AnotBarra, AnotBarraPlegada, AnotBarraAbiertaW, AnotBarraAbiertaH, AnotBarraMarcoW
    global AnotBarraMinW, AnotBarraMinH, AnotBotonPlegar, CerrandoMostrador, AnotBarraCambiando, AnotBarraElementos
    if CerrandoMostrador || !(AnotBarra is Gui)
        return
    anterior := A_IsCritical
    Critical "On"
    try {
        AnotBarraCambiando := true
        g := AnotBarra
        g.GetPos(&x, &y, &totalW)
        derecha := x + totalW
        plegando := !AnotBarraPlegada
        lateral := "derecho"
        monitor := DllCall("MonitorFromWindow", "ptr", g.Hwnd, "uint", 2, "ptr")
        trabajo := Buffer(40, 0)
        NumPut("uint", 40, trabajo)
        tienePantalla := DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", trabajo)
        if tienePantalla {
            bordeL := NumGet(trabajo, 20, "int"), bordeR := NumGet(trabajo, 28, "int")
            lateral := Abs(x - bordeL) < Abs(bordeR - derecha) ? "izquierdo" : "derecho"
        }
        if !AnotBarraPlegada {
            g.GetClientPos(, , &AnotBarraAbiertaW, &AnotBarraAbiertaH)
            AnotBarraMarcoW := totalW - AnotBarraAbiertaW
            AnotBarraPlegada := true
            AnotBotonPlegar.Text := "+"
            g.Opt("+MinSize1x1 -Resize")
            w := Round(44 * A_ScreenDPI / 96), h := Round(64 * A_ScreenDPI / 96)
        } else {
            AnotBarraPlegada := false
            AnotBotonPlegar.Text := "−"
            w := AnotBarraAbiertaW, h := AnotBarraAbiertaH
            monitor := DllCall("MonitorFromWindow", "ptr", g.Hwnd, "uint", 2, "ptr")
            info := Buffer(40, 0)
            NumPut("uint", 40, info)
            if DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info) {
                disponibleW := NumGet(info, 28, "int") - NumGet(info, 20, "int") - 24
                disponibleH := NumGet(info, 32, "int") - NumGet(info, 24, "int") - 24
                ajuste := Min(1, disponibleW / (w + 16), disponibleH / (h + 16))
                w := Max(1, Round(w * ajuste)), h := Max(1, Round(h * ajuste))
            }
            g.Opt("+Resize +MinSize" Min(AnotBarraMinW, w) "x" Min(AnotBarraMinH, h))
        }
        pos := PosicionEnPantalla(derecha - w, y, w, h)
        g.Show(Format("x{} y{} w{} h{} NoActivate", pos[1], pos[2], w, h))
        g.GetPos(, , &nuevoW, &nuevoH)
        destinoX := derecha - nuevoW
        if plegando && tienePantalla
            destinoX := lateral = "izquierdo" ? bordeL + 8 : bordeR - nuevoW - 8
        pos := PosicionEnPantalla(destinoX, y, nuevoW, nuevoH)
        g.Move(pos[1], pos[2])
        for d in AnotBarraElementos
            d.imagenClave := ""
        AnotBarraCambiando := false
        g.GetClientPos(, , &cw, &ch)
        AjustarBarraAnotaciones(g, 0, cw, ch)
        DllCall("RedrawWindow", "ptr", g.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x185)
        ActualizarAreaCapturaAnotaciones()
        ReordenarCapasMostrador()
        GuardarGeometriaBarraAnotaciones(0, 0, 0, g.Hwnd)
    } finally {
        AnotBarraCambiando := false
        Critical anterior
    }
}

AjustarControlesBarraPlegada(ancho, alto) {
    global AnotBarraElementos, AnotBotonPlegar, AnotAgarreBarra
    for d in AnotBarraElementos
        d.control.Visible := d.control.Hwnd = AnotBotonPlegar.Hwnd || d.control.Hwnd = AnotAgarreBarra.Hwnd
    s := Min(ancho / 44, alto / 64)
    DllCall("SetWindowRgn", "ptr", AnotAgarreBarra.Hwnd, "ptr", 0, "int", false)
    DllCall("SetWindowRgn", "ptr", AnotBotonPlegar.Hwnd, "ptr", 0, "int", false)
    AnotAgarreBarra.Move(0, 0, ancho, Round(22 * s))
    AnotAgarreBarra.SetFont("s" Pt(16 * s))
    AnotBotonPlegar.Move(Round(4 * s), Round(26 * s), Max(1, ancho - Round(8 * s)), Round(32 * s))
    AnotBotonPlegar.SetFont("s" Pt(20 * s))
}

CrearBarraAnotaciones() {
    global AnotBarraPlegada, AnotBotonPlegar, AnotAgarreBarra, AnotBarraMinW, AnotBarraMinH
    global AnotBarra, AnotBotones, AnotColores, AnotArrastre, AnotEstado, AnotBarraElementos
    global AnotGrosorTexto, AnotGrosorEtiqueta, AnotDeshacerBoton, AnotRehacerBoton, AnotBorrarBoton, AnotPausaBoton, ArchivoConfig
    if AnotBarra is Gui {
        LiberarImagenesModernas(AnotBarra)
        AnotBarra.Destroy()
    }
    AnotBarraPlegada := false
    AnotBarraElementos := [], AnotBotones := Map(), AnotColores := Map(), AnotArrastre := Map(), AnotEstado := 0
    g := Gui("+AlwaysOnTop -Caption +Resize -MinimizeBox -MaximizeBox +ToolWindow -DPIScale +E0x08000000", "Anotaciones")
    AnotBarra := g
    g.BackColor := "0F0F0F"
    g.MarginX := 0, g.MarginY := 0
    AnotAgarreBarra := ElementoBarraAnotacion(g, "···", 8, 4, 64, 24, 0, "0F0F0F", "909090", 20)
    AnotArrastre[AnotAgarreBarra.Hwnd] := true
    AnotBotonPlegar := ElementoBarraAnotacion(g, "−", 80, 4, 24, 24, AlternarBarraAnotacionesPlegada, "232323", "D6D6D6", 16)
    for i, herramienta in [["Trazo", "trazo"], ["Flecha", "flecha"], ["Óvalo", "ovalo"], ["Marco", "marco"], ["Línea", "linea"], ["Texto", "texto"]]
        AnotBotones[herramienta[2]] := ElementoBarraAnotacion(g, herramienta[1], 8, 34 + (i - 1) * 34, 96, 30, ElegirHerramientaAnotacion.Bind(herramienta[2]), "232323", "D6D6D6", 12, herramienta[2])
    for i, color in ["FF334D", "FFC857", "71DCA7", "8AB4F8", "C5A5F5", "F1F1F1"]
        AnotColores[color] := ElementoBarraAnotacion(g, "", 12 + Mod(i - 1, 3) * 32, 246 + ((i - 1) // 3) * 30, 24, 24, ElegirColorAnotacion.Bind(color), color, "181818")
    AnotGrosorEtiqueta := ElementoBarraAnotacion(g, "Grosor", 8, 312, 96, 18, 0, "0F0F0F", "909090", 11)
    ElementoBarraAnotacion(g, "−", 8, 336, 28, 28, CambiarGrosorAnotacion.Bind(-1))
    AnotGrosorTexto := ElementoBarraAnotacion(g, "", 38, 336, 36, 28, 0, "0F0F0F", "D6D6D6", 11)
    ElementoBarraAnotacion(g, "+", 76, 336, 28, 28, CambiarGrosorAnotacion.Bind(1))
    AnotDeshacerBoton := ElementoBarraAnotacion(g, "↶", 8, 376, 44, 30, DeshacerAnotacion, "232323", "D6D6D6", 20)
    AnotRehacerBoton := ElementoBarraAnotacion(g, "↷", 60, 376, 44, 30, RehacerAnotacion, "232323", "D6D6D6", 20)
    AnotPausaBoton := ElementoBarraAnotacion(g, "Escritorio", 8, 418, 96, 32, AlternarPausaAnotaciones, "203044", "A9CDFF")
    AnotBorrarBoton := ElementoBarraAnotacion(g, "Borrar todo", 8, 462, 96, 30, BorrarAnotaciones, "352126", "FF9AAA")
    ElementoBarraAnotacion(g, "Ajustes", 8, 502, 96, 28, AbrirAjustesAnotaciones)
    ElementoBarraAnotacion(g, "Ocultar", 8, 538, 96, 26, FinalizarAnotaciones, "1D1D1D", "AAAAAA")
    ElementoBarraAnotacion(g, "Cerrar todo", 8, 574, 96, 26, (*) => CerrarAnotaciones(), "352126", "FF9AAA")
    punto := Buffer(8, 0)
    DllCall("GetCursorPos", "ptr", punto)
    monitor := DllCall("MonitorFromPoint", "int64", NumGet(punto, 0, "int64"), "uint", 2, "ptr")
    info := Buffer(40, 0)
    NumPut("uint", 40, info)
    if DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info) {
        l := NumGet(info, 20, "int"), t := NumGet(info, 24, "int"), r := NumGet(info, 28, "int"), b := NumGet(info, 32, "int")
    } else {
        MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    }
    dpi := A_ScreenDPI / 96
    ajuste := Min(dpi, (b - t - 32) / 608)
    ancho := IniRead(ArchivoConfig, "Anotaciones", "BarraAncho", "")
    alto := IniRead(ArchivoConfig, "Anotaciones", "BarraAlto", "")
    w := IsNumber(ancho) ? Round(Max(84 * ajuste, Min(ancho * dpi, r - l - 24))) : Round(112 * ajuste)
    h := IsNumber(alto) ? Round(Max(456 * ajuste, Min(alto * dpi, b - t - 24))) : Round(608 * ajuste)
    x := IniRead(ArchivoConfig, "Anotaciones", "BarraX", "")
    y := IniRead(ArchivoConfig, "Anotaciones", "BarraY", "")
    pos := PosicionEnPantalla(IsInteger(x) ? Integer(x) : r - w - 16,
        IsInteger(y) ? Integer(y) : t + ((b - t - h) // 2), w + 16, h + 16)
    AnotBarraMinW := Round(84 * ajuste), AnotBarraMinH := Round(456 * ajuste)
    g.Opt("+MinSize" AnotBarraMinW "x" AnotBarraMinH)
    g.OnEvent("Size", AjustarBarraAnotaciones)
    g.OnEvent("Close", FinalizarAnotaciones)
    AplicarTemaAjustes(g)
    g.Show(Format("x{} y{} w{} h{} NoActivate", pos[1], pos[2], w, h))
    g.GetClientPos(, , &cw, &ch)
    AjustarBarraAnotaciones(g, 0, cw, ch)
    ActualizarPaletaAnotaciones()
    ActualizarAreaCapturaAnotaciones()
    ReordenarCapasMostrador()
}

PintarIconoHerramientaBarra(d, w, h) {
    global AnotHerramienta
    anterior := A_IsCritical
    Critical "On"
    try {
        activa := d.figura = AnotHerramienta
        clave := w "|" h "|" activa
        if d.imagenClave = clave
            return
        bmp := DibujarHerramientaBarra(d.figura, d.texto, w, h, activa)
        PonerImagenModerna(d.control, bmp)
        d.imagenClave := clave
    } finally {
        Critical anterior
    }
}

DibujarHerramientaBarra(figura, texto, w, h, activa) {
    muestra := 3
    superficie := RelojCrearSuperficie(w * muestra, h * muestra)
    try {
        s := Min(w / 96, h / 30) * muestra
        fondo := activa ? "45232B" : "232323"
        tinta := activa ? "FF96A8" : "D6D6D6"
        RelojFondo(superficie.dc, superficie.w, superficie.h, "0F0F0F")
        RectTecla(superficie.dc, 0, 0, superficie.w, superficie.h, Round(10 * s), fondo)
        cx := 19 * s, cy := superficie.h / 2
        puntos := []
        switch figura {
            case "trazo":
                Loop 25 {
                    x := -8 + (A_Index - 1) * 16 / 24
                    puntos.Push([cx + x * s, cy + Sin(x * 0.55) * 3.5 * s])
                }
            case "flecha":
                puntos := [[cx - 7 * s, cy + 5 * s], [cx + 7 * s, cy - 5 * s]]
                RelojTrazo(superficie.dc, [[cx, cy - 5 * s], [cx + 7 * s, cy - 5 * s], [cx + 7 * s, cy + 2 * s]], 1.5 * s, tinta, true)
            case "ovalo":
                Loop 49 {
                    angulo := (A_Index - 1) * 6.283185307179586 / 48
                    puntos.Push([cx + Cos(angulo) * 8 * s, cy + Sin(angulo) * 6 * s])
                }
            case "marco":
                puntos := [[cx - 8 * s, cy - 6 * s], [cx + 8 * s, cy - 6 * s],
                    [cx + 8 * s, cy + 6 * s], [cx - 8 * s, cy + 6 * s], [cx - 8 * s, cy - 6 * s]]
            case "linea":
                puntos := [[cx - 7 * s, cy + 5 * s], [cx + 7 * s, cy - 5 * s]]
            case "texto":
                RelojTexto(superficie.dc, "Aa", cx - 11 * s, 0, 22 * s, superficie.h, 13 * s, tinta, true)
        }
        if puntos.Length
            RelojTrazo(superficie.dc, puntos, 1.5 * s, tinta, true)
        RelojTexto(superficie.dc, texto, 34 * s, 0, superficie.w - 38 * s, superficie.h, 12 * s, tinta)
        return RelojReducirSuperficie(superficie, w, h)
    } finally {
        RelojLiberarSuperficie(superficie)
    }
}

ElementoBarraAnotacion(g, texto, x, y, w, h, accion := 0, fondo := "232323", tinta := "D6D6D6", px := 12, figura := "") {
    global AnotBarraElementos
    g.SetFont("s" Pt(px) " c" tinta, "Segoe UI")
    estilo := figura = "" ? " Center +0x200 +0x100 Background" fondo : " +0xE +0x40 +0x100"
    control := g.AddText(Format("x{} y{} w{} h{}", x, y, w, h) estilo, figura = "" ? texto : "")
    if IsObject(accion)
        control.OnEvent("Click", accion)
    AnotBarraElementos.Push({control: control, x: x, y: y, w: w, h: h, px: px, figura: figura, texto: texto, imagenClave: ""})
    return control
}

AjustarBarraAnotaciones(g, minmax, ancho, alto) {
    global AnotBarra, AnotBarraElementos, CerrandoMostrador, AnotBarraPlegada, AnotBarraCambiando
    if CerrandoMostrador || AnotBarraCambiando || minmax = -1 || !(AnotBarra is Gui) || g.Hwnd != AnotBarra.Hwnd
        return
    anterior := A_IsCritical
    Critical "On"
    try {
        ; Los Size pendientes pueden contener medidas anteriores al desplegado.
        g.GetClientPos(, , &ancho, &alto)
        if ancho < 1 || alto < 1
            return
        if AnotBarraPlegada {
            AjustarControlesBarraPlegada(ancho, alto)
            if AnotModoActivoBarra()
                ActualizarAreaCapturaAnotaciones()
            return
        }
        sx := ancho / 112, sy := alto / 608
        for d in AnotBarraElementos {
            DllCall("SetWindowRgn", "ptr", d.control.Hwnd, "ptr", 0, "int", false)
            w := Max(1, Round(d.w * sx)), h := Max(1, Round(d.h * sy))
            d.control.Move(Round(d.x * sx), Round(d.y * sy), w, h)
            if d.figura != ""
                PintarIconoHerramientaBarra(d, w, h)
            else
                d.control.SetFont("s" Pt(d.px * Min(sx, sy)))
            RedondearNota(d.control, w, h, Max(4, Round(10 * Min(sx, sy))))
            d.control.Visible := true
            DllCall("InvalidateRect", "ptr", d.control.Hwnd, "ptr", 0, "int", true)
        }
        if AnotModoActivoBarra()
            ActualizarAreaCapturaAnotaciones()
    } finally {
        Critical anterior
    }
}

AnotModoActivoBarra() {
    global AnotModo
    return AnotModo
}

GuardarGeometriaBarraAnotaciones(wParam, lParam, msg, hwnd) {
    global AnotBarraPlegada, AnotBarraAbiertaW, AnotBarraAbiertaH, AnotBarraMarcoW
    global AnotBarra, ArchivoConfig, CerrandoMostrador
    if CerrandoMostrador || !(AnotBarra is Gui) || hwnd != AnotBarra.Hwnd
        return
    AnotBarra.GetPos(&x, &y, &totalW, &totalH)
    pos := PosicionEnPantalla(x, y, totalW, totalH)
    x := pos[1], y := pos[2]
    AnotBarra.Move(x, y)
    AnotBarra.GetClientPos(, , &w, &h)
    if AnotBarraPlegada {
        x += totalW - AnotBarraAbiertaW - AnotBarraMarcoW
        w := AnotBarraAbiertaW, h := AnotBarraAbiertaH
    }
    dpi := A_ScreenDPI / 96
    for clave, valor in Map("BarraX", x, "BarraY", y, "BarraAncho", Round(w / dpi, 2), "BarraAlto", Round(h / dpi, 2))
        IniWrite(valor, ArchivoConfig, "Anotaciones", clave)
}

BotonPaletaAnotacion(g, texto, x, y, w, h, accion, fondo := "232323", tinta := "D6D6D6", fuente := "Segoe UI") {
    escala := A_ScreenDPI / 96
    g.SetFont("s10 c" tinta " norm", fuente)
    boton := g.AddText(Format("x{} y{} w{} h{} Center +0x200 +0x100 Background{}",
        Round(x * escala), Round(y * escala), Round(w * escala), Round(h * escala), fondo), texto)
    boton.OnEvent("Click", accion)
    RedondearNota(boton, Round(w * escala), Round(h * escala), Round(8 * escala))
    return boton
}

ElegirHerramientaAnotacion(herramienta, *) {
    global AnotHerramienta
    AnotHerramienta := herramienta
    ActualizarPaletaAnotaciones()
    GuardarAnotacionesConfig()
}

ElegirColorAnotacion(color, *) {
    global AnotColor
    AnotColor := color
    ActualizarPaletaAnotaciones()
    GuardarAnotacionesConfig()
}

CambiarGrosorAnotacion(delta, *) {
    global AnotGrosor, AnotTextoTam, AnotHerramienta
    if AnotHerramienta = "texto"
        AnotTextoTam := Max(10, Min(96, AnotTextoTam + delta * 2))
    else
        AnotGrosor := Max(2, Min(16, AnotGrosor + delta))
    ActualizarPaletaAnotaciones()
    GuardarAnotacionesConfig()
}

ActualizarPaletaAnotaciones() {
    global AnotBarraElementos
    global AnotBotones, AnotColores, AnotHerramienta, AnotColor, AnotEstado, AnotDuracion, AnotGrosor
    global AnotPausa, AnotPausaBoton
    global AnotGrosorTexto, AnotDeshacerBoton, AnotRehacerBoton, AnotBorrarBoton
    global AnotHistorial, AnotRehacer, AnotActual, AnotTrazos, AnotTextoTam, AnotGrosorEtiqueta, AnotArrastreTexto
    for d in AnotBarraElementos {
        if d.figura != "" {
            d.control.GetPos(, , &w, &h)
            PintarIconoHerramientaBarra(d, w, h)
        }
    }
    for color, boton in AnotColores
        boton.Text := color = AnotColor ? "✓" : ""
    if IsObject(AnotGrosorTexto)
        AnotGrosorTexto.Text := AnotHerramienta = "texto" ? AnotTextoTam " pt" : AnotGrosor " px"
    if IsObject(AnotGrosorEtiqueta)
        AnotGrosorEtiqueta.Text := AnotHerramienta = "texto" ? "Letra" : "Grosor"
    if IsObject(AnotEstado) {
        nombres := Map("trazo", "Trazo libre", "flecha", "Flecha", "ovalo", "Óvalo", "marco", "Marco", "linea", "Línea", "texto", "Texto · pulsa para escribir")
        AnotEstado.Text := (AnotPausa ? "Escritorio libre · " : "") nombres[AnotHerramienta] " · " (AnotDuracion ? AnotDuracion " s" : "Borrado manual")
    }
    if IsObject(AnotPausaBoton)
        AnotPausaBoton.Text := AnotPausa ? "Dibujar" : "Escritorio"
    if IsObject(AnotDeshacerBoton)
        AnotDeshacerBoton.Enabled := AnotHistorial.Length > 0 || IsObject(AnotActual) || IsObject(AnotArrastreTexto)
    if IsObject(AnotRehacerBoton)
        AnotRehacerBoton.Enabled := AnotRehacer.Length > 0
    if IsObject(AnotBorrarBoton)
        AnotBorrarBoton.Enabled := AnotTrazos.Length > 0 || IsObject(AnotActual) || IsObject(AnotArrastreTexto)
}

RegistrarCambioAnotacion(antes) {
    global AnotHistorial, AnotRehacer, AnotTrazos
    AnotHistorial.Push({antes: antes, despues: AnotTrazos.Clone()})
    AnotRehacer := []
    ActualizarPaletaAnotaciones()
}

CancelarTrazoAnotacion() {
    if CancelarMovimientoTextoAnotacion()
        return true
    global AnotActual, AnotHwndCaptura
    if !IsObject(AnotActual)
        return false
    AnotActual := 0
    if AnotHwndCaptura && DllCall("GetCapture", "ptr") = AnotHwndCaptura
        DllCall("ReleaseCapture")
    SolicitarPintadoAnotaciones()
    ActualizarPaletaAnotaciones()
    return true
}

DeshacerAnotacion(*) {
    global AnotHistorial, AnotRehacer
    if CancelarTrazoAnotacion() || !AnotHistorial.Length
        return
    cambio := AnotHistorial.Pop()
    AnotRehacer.Push(cambio)
    RestaurarDibujosAnotacion(cambio.antes)
}

RehacerAnotacion(*) {
    global AnotHistorial, AnotRehacer
    if CancelarTrazoAnotacion() || !AnotRehacer.Length
        return
    cambio := AnotRehacer.Pop()
    AnotHistorial.Push(cambio)
    RestaurarDibujosAnotacion(cambio.despues)
}

RestaurarDibujosAnotacion(dibujos) {
    global AnotTrazos, AnotDuracion, AnotTextoSeleccionado, AnotUltimoTexto
    AnotTextoSeleccionado := 0, AnotUltimoTexto := 0
    AnotTrazos := dibujos.Clone()
    for trazo in AnotTrazos
        trazo.vence := AnotDuracion ? A_TickCount + AnotDuracion * 1000 : 0
    ActualizarPaletaAnotaciones()
    SolicitarPintadoAnotaciones()
}

BorrarAnotaciones(*) {
    global AnotTrazos, AnotTextoSeleccionado, AnotUltimoTexto
    CancelarTrazoAnotacion()
    AnotTextoSeleccionado := 0, AnotUltimoTexto := 0
    if !AnotTrazos.Length
        return
    antes := AnotTrazos.Clone()
    AnotTrazos := []
    RegistrarCambioAnotacion(antes)
    SolicitarPintadoAnotaciones()
}


PuntoAnotacion() {
    global AnotX, AnotY
    punto := Buffer(8, 0)
    DllCall("GetCursorPos", "ptr", punto)
    return [NumGet(punto, 0, "int") - AnotX, NumGet(punto, 4, "int") - AnotY]
}

PresionarAnotacion(wParam, lParam, msg, hwnd) {
    global AnotModo, AnotHwndCaptura, AnotActual, AnotHerramienta, AnotColor, AnotGrosor, AnotBarra, AnotArrastre
    global AnotTextoPunto, AnotTextoPendiente, AnotPausa
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if (AnotModo || AnotPausa) && (AnotBarra is Gui) && (hwnd = AnotBarra.Hwnd || AnotArrastre.Has(hwnd)) {
            DllCall("ReleaseCapture")
            PostMessage(0x00A1, 2, 0, , AnotBarra)
            return 0
        }
        if !AnotModo || hwnd != AnotHwndCaptura
            return
        if PunteroEnInterfazAnotacion() {
            FlechaInterfazAnotacion()
            return 0
        }
        if IniciarInteraccionTextoAnotacion(msg)
            return 0
        if AnotHerramienta = "texto" {
            AnotTextoPunto := PuntoAnotacion()
            AnotTextoPendiente := true
            SetTimer(AbrirTextoAnotacion, -20)
            return 0
        }
        AnotActual := {herramienta: AnotHerramienta, puntos: [PuntoAnotacion()], color: AnotColor,
            grosor: Max(2, Round(AnotGrosor * A_ScreenDPI / 96)), vence: 0}
        DllCall("SetCapture", "ptr", AnotHwndCaptura)
        ActualizarPaletaAnotaciones()
        SolicitarPintadoAnotaciones()
        return 0
    } finally {
        Critical criticoAnterior
    }
}

MoverAnotacion(wParam, lParam, msg, hwnd) {
    global AnotModo, AnotHwndCaptura, AnotActual, AnotArrastreTexto
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if !AnotModo || hwnd != AnotHwndCaptura
            return
        if PunteroEnInterfazAnotacion() {
            ConfirmarAnotacionSinMover(true)
            FlechaInterfazAnotacion()
            return 0
        }
        if IsObject(AnotArrastreTexto) {
            MoverTextoAnotacion()
            return 0
        }
        if !IsObject(AnotActual)
            return
        punto := PuntoAnotacion(), puntos := AnotActual.puntos
        if AnotActual.herramienta = "trazo" {
            previo := puntos[puntos.Length]
            if Abs(punto[1] - previo[1]) + Abs(punto[2] - previo[2]) < 2
                return
            puntos.Push(punto)
        } else if puntos.Length = 1 {
            puntos.Push(punto)
        } else {
            puntos[2] := punto
        }
        SolicitarPintadoAnotaciones()
        return 0
    } finally {
        Critical criticoAnterior
    }
}

SoltarAnotacion(wParam, lParam, msg, hwnd) {
    global AnotHwndCaptura, AnotActual, AnotTrazos, AnotDuracion, AnotArrastreTexto
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if hwnd != AnotHwndCaptura
            return
        if !IsObject(AnotActual) && !IsObject(AnotArrastreTexto)
            return
        sobreInterfaz := PunteroEnInterfazAnotacion()
        if !sobreInterfaz
            MoverAnotacion(wParam, lParam, msg, hwnd)
        ConfirmarAnotacionSinMover(sobreInterfaz)
        return 0
    } finally {
        Critical criticoAnterior
    }
}

DerechoAnotacion(wParam, lParam, msg, hwnd) {
    global AnotModo, AnotHwndCaptura
    if AnotModo && hwnd = AnotHwndCaptura && !PunteroEnInterfazAnotacion() {
        DeshacerAnotacion()
        return 0
    }
}

CursorAnotacion(wParam, lParam, msg, hwnd) {
    global AnotModo, AnotHwndCaptura, AnotHerramienta, AnotArrastreTexto, AnotActual
    if AnotModo && hwnd = AnotHwndCaptura {
        if PunteroEnInterfazAnotacion() {
            FlechaInterfazAnotacion()
            return 1
        }
        sobreTexto := IsObject(AnotArrastreTexto) || (!IsObject(AnotActual) && TextoAnotacionEnPunto(PuntoAnotacion()))
        tipoCursor := sobreTexto ? 32646 : AnotHerramienta = "texto" ? 32513 : 32515
        cursor := DllCall("LoadCursorW", "ptr", 0, "ptr", tipoCursor, "ptr")
        DllCall("SetCursor", "ptr", cursor)
        return 1
    }
}


ExpirarAnotaciones() {
    global AnotTrazos, AnotActual, AnotModo, AnotHwndCaptura, AnotTextoGui, AnotTextoPendiente, AnotArrastreTexto
    global AnotPausa
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        ; Un trazo se detiene antes de entrar en la interfaz, sin reproducir clics.
        if IsObject(AnotActual) || IsObject(AnotArrastreTexto) {
            if PunteroEnInterfazAnotacion() {
                ConfirmarAnotacionSinMover(true)
                FlechaInterfazAnotacion()
            } else if !GetKeyState("LButton", "P") {
                SoltarAnotacion(0, 0, 0, AnotHwndCaptura)
            }
        }
        nuevas := [], cambio := false
        for trazo in AnotTrazos {
            if trazo.vence && A_TickCount >= trazo.vence && !TextoAnotacionOcupado(trazo)
                cambio := true
            else
                nuevas.Push(trazo)
        }
        if cambio {
            AnotTrazos := nuevas
            ActualizarPaletaAnotaciones()
            SolicitarPintadoAnotaciones()
        }
        if !AnotModo && !AnotPausa && !AnotTrazos.Length && !IsObject(AnotActual) && !(AnotTextoGui is Gui) && !AnotTextoPendiente
            CerrarAnotaciones()
    } finally {
        Critical criticoAnterior
    }
}

SolicitarPintadoAnotaciones() {
    global AnotPendiente, AnotLienzo
    if !(AnotLienzo is Gui) || AnotPendiente
        return
    AnotPendiente := true
    SetTimer(PintarAnotaciones, -16)
}

PintarAnotaciones() {
    global AnotPendiente, AnotLienzo, AnotPic, AnotDC, AnotBitmap, AnotW, AnotH
    global AnotClave, AnotTrazos, AnotActual, AnotColor, AnotModo, AnotTextoSeleccionado
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        AnotPendiente := false
        if !(AnotLienzo is Gui) || !AnotDC || !AnotBitmap
            return
        usados := Map("000000", true)
        usados[AnotColor] := true
        for trazo in AnotTrazos
            usados[trazo.color] := true
        if IsObject(AnotActual)
            usados[AnotActual.color] := true
        numero := 1
        while usados.Has(Format("{:06X}", numero))
            numero += 1
        clave := Format("{:06X}", numero)
        if clave != AnotClave {
            AnotClave := clave
            AnotLienzo.BackColor := clave
            WinSetTransColor(clave, AnotLienzo)
        }
        anterior := DllCall("SelectObject", "ptr", AnotDC, "ptr", AnotBitmap, "ptr")
        pincel := DllCall("CreateSolidBrush", "uint", BGR(AnotClave), "ptr")
        try {
            rect := Buffer(16, 0)
            NumPut("int", AnotW, rect, 8), NumPut("int", AnotH, rect, 12)
            DllCall("FillRect", "ptr", AnotDC, "ptr", rect, "ptr", pincel)
            for trazo in AnotTrazos
                PintarTrazoAnotacion(AnotDC, trazo)
            if IsObject(AnotActual)
                PintarTrazoAnotacion(AnotDC, AnotActual)
            if AnotModo && IndiceTextoAnotacion(AnotTextoSeleccionado)
                PintarSeleccionTextoAnotacion(AnotDC, AnotTextoSeleccionado)
        } finally {
            DllCall("DeleteObject", "ptr", pincel)
            DllCall("SelectObject", "ptr", AnotDC, "ptr", anterior)
        }
        SendMessage(0x172, 0, AnotBitmap, AnotPic)
        DllCall("RedrawWindow", "ptr", AnotPic.Hwnd, "ptr", 0, "ptr", 0, "uint", 0x101)
    } finally {
        Critical criticoAnterior
    }
}

PintarTrazoAnotacion(dc, trazo) {
    if trazo.herramienta = "texto" {
        PintarTextoAnotacion(dc, trazo)
        return
    }
    for estilo in [["000000", trazo.grosor + 2], [trazo.color, trazo.grosor]] {
        brocha := Buffer(A_PtrSize = 8 ? 16 : 12, 0)
        NumPut("uint", BGR(estilo[1]), brocha, 4)
        lapiz := DllCall("ExtCreatePen", "uint", 0x10000, "uint", estilo[2], "ptr", brocha, "uint", 0, "ptr", 0, "ptr")
        previo := DllCall("SelectObject", "ptr", dc, "ptr", lapiz, "ptr")
        pincelPrevio := DllCall("SelectObject", "ptr", dc, "ptr", DllCall("GetStockObject", "int", 5, "ptr"), "ptr")
        try {
            puntos := trazo.puntos, primero := puntos[1], ultimo := puntos[puntos.Length]
            if puntos.Length = 1 {
                DllCall("MoveToEx", "ptr", dc, "int", primero[1], "int", primero[2], "ptr", 0)
                DllCall("LineTo", "ptr", dc, "int", primero[1] + 1, "int", primero[2] + 1)
            } else if trazo.herramienta = "marco" {
                DllCall("Rectangle", "ptr", dc, "int", Min(primero[1], ultimo[1]), "int", Min(primero[2], ultimo[2]),
                    "int", Max(primero[1], ultimo[1]), "int", Max(primero[2], ultimo[2]))
            } else if trazo.herramienta = "ovalo" {
                DllCall("Ellipse", "ptr", dc, "int", Min(primero[1], ultimo[1]), "int", Min(primero[2], ultimo[2]),
                    "int", Max(primero[1], ultimo[1]), "int", Max(primero[2], ultimo[2]))
            } else {
                PolilineaAnotacion(dc, puntos)
                if trazo.herramienta = "flecha" {
                    angulo := DllCall("msvcrt\atan2", "double", ultimo[2] - primero[2], "double", ultimo[1] - primero[1], "cdecl double")
                    largo := Max(14, trazo.grosor * 4)
                    cabeza := [[Round(ultimo[1] - largo * Cos(angulo - 0.5)), Round(ultimo[2] - largo * Sin(angulo - 0.5))],
                        ultimo, [Round(ultimo[1] - largo * Cos(angulo + 0.5)), Round(ultimo[2] - largo * Sin(angulo + 0.5))]]
                    PolilineaAnotacion(dc, cabeza)
                }
            }
        } finally {
            DllCall("SelectObject", "ptr", dc, "ptr", pincelPrevio)
            DllCall("SelectObject", "ptr", dc, "ptr", previo)
            DllCall("DeleteObject", "ptr", lapiz)
        }
    }
}

PolilineaAnotacion(dc, puntos) {
    datos := Buffer(puntos.Length * 8, 0)
    for i, punto in puntos
        NumPut("int", punto[1], "int", punto[2], datos, (i - 1) * 8)
    DllCall("Polyline", "ptr", dc, "ptr", datos, "int", puntos.Length)
}

CerrarAnotaciones(*) {
    global AnotModo, AnotHwndCaptura, AnotLienzo, AnotCaptura, AnotBarra, AnotDC, AnotBitmap
    global AnotActual, AnotTrazos, AnotPendiente, AnotPic, AnotBotones, AnotHistorial, AnotRehacer
    global AnotColores, AnotArrastre, AnotEstado, AnotGrosorTexto, AnotDeshacerBoton, AnotRehacerBoton, AnotBorrarBoton, AnotGrosorEtiqueta
    global AnotArrastreTexto, AnotTextoSeleccionado, AnotUltimoTexto
    global AnotBarraPlegada, AnotBotonPlegar, AnotAgarreBarra
    global AnotPausa, AnotPausaBoton, AnotBarraElementos
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        LiberarAreaCapturaAnotaciones()
        SetTimer(PintarAnotaciones, 0)
        SetTimer(ExpirarAnotaciones, 0)
        CerrarTextoAnotacion()
        AnotArrastreTexto := 0, AnotTextoSeleccionado := 0, AnotUltimoTexto := 0
        if AnotHwndCaptura && DllCall("GetCapture", "ptr") = AnotHwndCaptura
            DllCall("ReleaseCapture")
        AnotBarraPlegada := false, AnotBotonPlegar := 0, AnotAgarreBarra := 0
        AnotBarraElementos := []
        AnotModo := false, AnotPausa := false, AnotPausaBoton := 0
        AnotHwndCaptura := 0, AnotActual := 0, AnotTrazos := [], AnotPendiente := false
        for ventana in [AnotBarra, AnotCaptura, AnotLienzo] {
            if ventana is Gui {
                LiberarImagenesModernas(ventana)
                ventana.Destroy()
            }
        }
        AnotBarra := 0, AnotCaptura := 0, AnotLienzo := 0, AnotPic := 0, AnotBotones := Map()
        AnotHistorial := [], AnotRehacer := [], AnotColores := Map(), AnotArrastre := Map()
        AnotEstado := 0, AnotGrosorTexto := 0, AnotDeshacerBoton := 0, AnotRehacerBoton := 0, AnotBorrarBoton := 0, AnotGrosorEtiqueta := 0
        if AnotBitmap
            DllCall("DeleteObject", "ptr", AnotBitmap)
        if AnotDC
            DllCall("DeleteDC", "ptr", AnotDC)
        AnotBitmap := 0, AnotDC := 0
        try A_TrayMenu.Uncheck("Anotar pantalla  (Ctrl+Alt+A)")
    } finally {
        Critical criticoAnterior
    }
}

GuardarAnotacionesConfig() {
    global ArchivoConfig, AnotHerramienta, AnotColor, AnotGrosor, AnotDuracion, AnotTextoTam, AnotTextoNegrita
    global AnotBorradoManual
    AnotBorradoManual := AnotDuracion = 0
    for clave, valor in Map("Herramienta", AnotHerramienta, "Color", AnotColor, "Grosor", AnotGrosor, "DuracionSeg", AnotDuracion, "BorradoManual", AnotBorradoManual, "TextoTam", AnotTextoTam, "TextoNegrita", AnotTextoNegrita)
        IniWrite(valor, ArchivoConfig, "Anotaciones", clave)
}

AbrirAjustesAnotaciones(*) {
    global AnotAjustes, AnotCampos, AnotColor, AnotGrosor, AnotDuracion, AnotHerramienta, AnotTextoTam, AnotTextoNegrita, AnotTextoGui
    if AnotTextoGui is Gui {
        MostrarDialogoMostrador(AnotTextoGui)
        return
    }
    FinalizarAnotaciones()
    if AnotAjustes is Gui {
        MostrarDialogoMostrador(AnotAjustes)
        return
    }
    g := Gui("+AlwaysOnTop", "Anotaciones · Mostrador")
    AnotAjustes := g
    g.SetFont("s15 cF1F1F1 bold", "Segoe UI")
    g.AddText("x18 y16 w475 h30", "Anotaciones")
    g.SetFont("s10 cF1F1F1 norm", "Segoe UI")
    g.AddText("x18 y76 w180 h25", "Herramienta inicial")
    herramienta := g.AddDropDownList("x202 y72 w293", ["Trazo", "Flecha", "Óvalo", "Marco", "Línea", "Texto"])
    herramienta.Choose(Map("trazo", 1, "flecha", 2, "ovalo", 3, "marco", 4, "linea", 5, "texto", 6)[AnotHerramienta])
    color := CampoColorMouse(g, 122, "Color del dibujo", AnotColor)
    g.AddText("x18 y174 w180 h25", "Grosor del trazo")
    grosor := g.AddEdit("x202 y170 w80 Number", AnotGrosor)
    g.AddUpDown("Range2-16", AnotGrosor)
    g.AddText("x18 y222 w180 h25", "Borrado automático (s)")
    duracion := g.AddEdit("x202 y218 w80 Number", AnotDuracion)
    g.AddUpDown("Range0-60", AnotDuracion)
    g.AddText("x300 y222 w195 h25", "0 = conservar hasta borrar")
    g.AddText("x18 y270 w180 h25", "Tamaño de letra")
    letra := g.AddEdit("x202 y266 w80 Number", AnotTextoTam)
    g.AddUpDown("Range10-96", AnotTextoTam)
    negrita := g.AddCheckbox("x300 y266 w160 h26", "Negrita")
    negrita.Value := AnotTextoNegrita
    g.SetFont("s9 cAAAAAA", "Segoe UI")
    g.AddText("x18 y316 w475 h68", "0 conserva textos y dibujos. De 1 a 60 s activa el borrado automático. Esc y la X sólo ocultan la paleta. Borrar todo limpia el lienzo; Cerrar todo borra la sesión y cierra esta herramienta. Ctrl+Z deshace.")
    g.SetFont("s10 cF1F1F1", "Segoe UI")
    g.AddButton("x222 y404 w173 h34 Default", "Guardar y dibujar").OnEvent("Click", AplicarAjustesAnotaciones)
    g.AddButton("x405 y404 w90 h34", "Cerrar").OnEvent("Click", CerrarAjustesAnotaciones)
    AnotCampos := {herramienta: herramienta, color: color, grosor: grosor, duracion: duracion, letra: letra, negrita: negrita}
    g.OnEvent("Close", CerrarAjustesAnotaciones)
    g.OnEvent("Escape", CerrarAjustesAnotaciones)
    AplicarTemaAjustes(g)
    MostrarDialogoMostrador(g, "w515 h458")
}

AplicarAjustesAnotaciones(*) {
    global AnotCampos, AnotColor, AnotGrosor, AnotDuracion, AnotHerramienta, AnotTextoTam, AnotTextoNegrita
    c := AnotCampos
    color := ColorMouseValido(c.color.campo.Value)
    if color = "" || !IsInteger(c.grosor.Value) || !IsInteger(c.duracion.Value) || !IsInteger(c.letra.Value) {
        MsgBox("Revisa el color, el grosor, la duración y el tamaño de letra.", "Anotaciones")
        return
    }
    AnotColor := color, AnotGrosor := Max(2, Min(16, Integer(c.grosor.Value)))
    AnotDuracion := Max(0, Min(60, Integer(c.duracion.Value)))
    AnotHerramienta := ["trazo", "flecha", "ovalo", "marco", "linea", "texto"][c.herramienta.Value]
    AnotTextoTam := Max(10, Min(96, Integer(c.letra.Value))), AnotTextoNegrita := c.negrita.Value
    GuardarAnotacionesConfig()
    CerrarAjustesAnotaciones()
    IniciarAnotaciones()
}

CerrarAjustesAnotaciones(*) {
    global AnotAjustes, AnotCampos
    if AnotAjustes is Gui
        AnotAjustes.Destroy()
    AnotAjustes := 0, AnotCampos := 0
}

EditorTextoAnotacionActivo() {
    global AnotTextoGui
    return (AnotTextoGui is Gui) && WinActive("ahk_id " AnotTextoGui.Hwnd)
}

AbrirTextoAnotacion() {
    global AnotTextoPendiente, AnotTextoPunto, AnotTextoGui, AnotTextoCampos, AnotModo
    global AnotTextoTam, AnotTextoNegrita, AnotColor, AnotX, AnotY, AnotTextoEdicion
    if !AnotTextoPendiente || !AnotModo
        return
    if GetKeyState("LButton", "P") {
        SetTimer(AbrirTextoAnotacion, -20)
        return
    }
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        edicion := AnotTextoEdicion
        tamInicial := IsObject(edicion) ? edicion.tam : AnotTextoTam
        negritaInicial := IsObject(edicion) ? edicion.negrita : AnotTextoNegrita
        colorInicial := IsObject(edicion) ? edicion.color : AnotColor
        contenido := IsObject(edicion) ? edicion.texto : ""
        FinalizarAnotaciones()
        AnotTextoEdicion := edicion
        g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale", "Texto · Anotaciones")
        AnotTextoGui := g
        g.BackColor := "0F0F0F"
        escala := A_ScreenDPI / 96
        g.SetFont("s11 cF1F1F1", "Segoe UI")
        g.AddText(Format("x{} y{} w{} h{} +0x200", Round(16 * escala), Round(10 * escala), Round(310 * escala), Round(26 * escala)), IsObject(edicion) ? "Editar texto" : "Escribe tu texto")
        g.AddText(Format("x{} y{} w{} h{} Background{}", Round(370 * escala), Round(18 * escala), Round(16 * escala), Round(16 * escala), colorInicial))
        BotonPaletaAnotacion(g, Chr(0xE8BB), 400, 10, 24, 26, CancelarTextoAnotacion, "232323", "D6D6D6", "Segoe MDL2 Assets")
        g.SetFont("s12 cF1F1F1 norm", "Segoe UI")
        texto := g.AddEdit(Format("x{} y{} w{} h{} Multi WantTab Limit0 -E0x200 -Border Background181818",
            Round(16 * escala), Round(48 * escala), Round(408 * escala), Round(114 * escala)), contenido)
        g.SetFont("s9 cAAAAAA", "Segoe UI")
        g.AddText(Format("x{} y{} w{} h{} +0x200", Round(16 * escala), Round(174 * escala), Round(50 * escala), Round(26 * escala)), "Letra")
        g.SetFont("s10 cF1F1F1", "Segoe UI")
        tam := g.AddEdit(Format("x{} y{} w{} h{} Number Background232323", Round(70 * escala), Round(174 * escala), Round(64 * escala), Round(26 * escala)), tamInicial)
        g.AddUpDown("Range10-96", tamInicial)
        negrita := g.AddCheckbox(Format("x{} y{} w{} h{}", Round(150 * escala), Round(174 * escala), Round(100 * escala), Round(26 * escala)), "Negrita")
        negrita.Value := negritaInicial
        g.SetFont("s9 c999999", "Segoe UI")
        g.AddText(Format("x{} y{} w{} h{} +0x200", Round(16 * escala), Round(214 * escala), Round(220 * escala), Round(26 * escala)), "Ctrl + Enter para insertar")
        BotonPaletaAnotacion(g, IsObject(edicion) ? "Guardar" : "Insertar", 250, 212, 80, 28, InsertarTextoAnotacion, "45232B", "FF96A8")
        BotonPaletaAnotacion(g, "Cancelar", 340, 212, 84, 28, CancelarTextoAnotacion)
        AnotTextoCampos := {texto: texto, tam: tam, negrita: negrita}
        g.OnEvent("Escape", CancelarTextoAnotacion)
        g.OnEvent("Close", CancelarTextoAnotacion)
        ancho := Round(440 * escala), alto := Round(252 * escala)
        AplicarTemaAjustes(g)
        RedondearNota(g, ancho, alto, Round(12 * escala))
        pos := PosicionEnPantalla(AnotX + AnotTextoPunto[1], AnotY + AnotTextoPunto[2], ancho, alto)
        MostrarDialogoMostrador(g, Format("x{} y{} w{} h{}", pos[1], pos[2], ancho, alto))
        texto.Focus()
        SendMessage(0xB1, -1, -1, texto)
    } finally {
        Critical criticoAnterior
    }
}

CancelarTextoAnotacion(*) {
    CerrarTextoAnotacion(true)
}

CerrarTextoAnotacion(continuar := false) {
    global AnotTextoGui, AnotTextoCampos, AnotTextoPendiente, AnotModo, AnotCaptura, AnotBarra, CerrandoMostrador, AnotTextoEdicion, AnotDuracion
    global AnotPausa
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        SetTimer(AbrirTextoAnotacion, 0)
        AnotTextoPendiente := false
        ventanaTexto := AnotTextoGui
        if IsObject(AnotTextoEdicion)
            AnotTextoEdicion.vence := AnotDuracion ? A_TickCount + AnotDuracion * 1000 : 0
        AnotTextoEdicion := 0
        AnotTextoGui := 0, AnotTextoCampos := 0
        if ventanaTexto is Gui
            ventanaTexto.Destroy()
        if continuar && !CerrandoMostrador && (AnotCaptura is Gui) && (AnotBarra is Gui) {
            AnotModo := true, AnotPausa := false
            MostrarCapturaAnotaciones()
            ActualizarPaletaAnotaciones()
            AnotBarra.Show("NoActivate")
            ActualizarAreaCapturaAnotaciones()
            ReordenarCapasMostrador()
            A_TrayMenu.Check("Anotar pantalla  (Ctrl+Alt+A)")
        }
    } finally {
        Critical criticoAnterior
    }
}

InsertarTextoAnotacion(*) {
    global AnotTextoCampos, AnotTextoTam, AnotTextoNegrita, AnotTextoPunto, AnotColor, AnotDuracion, AnotTrazos, AnotTextoEdicion, AnotTextoSeleccionado
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if !IsObject(AnotTextoCampos)
            return
        c := AnotTextoCampos
        if !IsInteger(c.tam.Value) {
            MsgBox("Escribe un tamaño de letra entre 10 y 96.", "Texto")
            return
        }
        texto := c.texto.Value
        if Trim(texto, " `t`r`n") = "" {
            c.texto.Focus()
            return
        }
        tam := Max(10, Min(96, Integer(c.tam.Value)))
        trazo := {herramienta: "texto", texto: texto, puntos: [AnotTextoPunto.Clone()], tam: tam,
            negrita: c.negrita.Value, color: IsObject(AnotTextoEdicion) ? AnotTextoEdicion.color : AnotColor, vence: 0}
        PrepararTextoAnotacion(trazo)
        AnotTextoTam := tam, AnotTextoNegrita := c.negrita.Value
        GuardarAnotacionesConfig()
        trazo.vence := AnotDuracion ? A_TickCount + AnotDuracion * 1000 : 0
        antes := AnotTrazos.Clone()
        indice := IndiceTextoAnotacion(AnotTextoEdicion)
        if indice
            AnotTrazos[indice] := trazo
        else
            AnotTrazos.Push(trazo)
        AnotTextoSeleccionado := trazo
        AnotTextoEdicion := 0
        RegistrarCambioAnotacion(antes)
        CerrarTextoAnotacion(true)
        SolicitarPintadoAnotaciones()
    } finally {
        Critical criticoAnterior
    }
}

FuenteTextoAnotacion(trazo) {
    return DllCall("CreateFontW", "int", -Round(trazo.tam * A_ScreenDPI / 72), "int", 0, "int", 0, "int", 0,
        "int", trazo.negrita ? 700 : 400, "uint", 0, "uint", 0, "uint", 0,
        "uint", 1, "uint", 0, "uint", 0, "uint", 5, "uint", 0, "str", "Segoe UI", "ptr")
}

PrepararTextoAnotacion(trazo) {
    global AnotX, AnotY
    x := AnotX + trazo.puntos[1][1], y := AnotY + trazo.puntos[1][2]
    punto := Buffer(8, 0)
    NumPut("int", x, "int", y, punto)
    monitor := DllCall("MonitorFromPoint", "int64", NumGet(punto, 0, "int64"), "uint", 2, "ptr")
    info := Buffer(40, 0)
    NumPut("uint", 40, info)
    if DllCall("GetMonitorInfoW", "ptr", monitor, "ptr", info) {
        l := NumGet(info, 20, "int"), t := NumGet(info, 24, "int")
        r := NumGet(info, 28, "int"), b := NumGet(info, 32, "int")
    } else {
        MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    }
    margen := Max(8, Round(12 * A_ScreenDPI / 96))
    maxW := Max(1, Min(Round(720 * A_ScreenDPI / 96), r - l - 2 * margen))
    dc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
    fuente := FuenteTextoAnotacion(trazo)
    previa := DllCall("SelectObject", "ptr", dc, "ptr", fuente, "ptr")
    try {
        rect := Buffer(16, 0)
        NumPut("int", maxW, rect, 8)
        DllCall("DrawTextW", "ptr", dc, "str", trazo.texto, "int", -1, "ptr", rect, "uint", 0xC50)
        trazo.ancho := Max(1, Min(maxW, NumGet(rect, 8, "int") + 2))
        trazo.alto := Max(1, NumGet(rect, 12, "int") + 2)
        trazo.puntos[1] := [Max(l + margen, Min(x, r - trazo.ancho - margen)) - AnotX,
            Max(t + margen, Min(y, b - trazo.alto - margen)) - AnotY]
    } finally {
        DllCall("SelectObject", "ptr", dc, "ptr", previa)
        DllCall("DeleteObject", "ptr", fuente)
        DllCall("DeleteDC", "ptr", dc)
    }
}

PintarTextoAnotacion(dc, trazo) {
    fuente := FuenteTextoAnotacion(trazo)
    previa := DllCall("SelectObject", "ptr", dc, "ptr", fuente, "ptr")
    try {
        DllCall("SetBkMode", "ptr", dc, "int", 1)
        rect := Buffer(16, 0)
        x := trazo.puntos[1][1], y := trazo.puntos[1][2]
        sombra := Max(1, Min(4, Round(trazo.tam * A_ScreenDPI / 72 / 18)))
        DllCall("SetTextColor", "ptr", dc, "uint", BGR("000000"))
        for offset in [[-sombra,0],[sombra,0],[0,-sombra],[0,sombra],[-sombra,-sombra],[sombra,sombra],[-sombra,sombra],[sombra,-sombra]] {
            NumPut("int", x + offset[1], "int", y + offset[2], "int", x + offset[1] + trazo.ancho,
                "int", y + offset[2] + trazo.alto, rect)
            DllCall("DrawTextW", "ptr", dc, "str", trazo.texto, "int", -1, "ptr", rect, "uint", 0x850)
        }
        DllCall("SetTextColor", "ptr", dc, "uint", BGR(trazo.color))
        NumPut("int", x, "int", y, "int", x + trazo.ancho, "int", y + trazo.alto, rect)
        DllCall("DrawTextW", "ptr", dc, "str", trazo.texto, "int", -1, "ptr", rect, "uint", 0x850)
    } finally {
        DllCall("SelectObject", "ptr", dc, "ptr", previa)
        DllCall("DeleteObject", "ptr", fuente)
    }
}

IndiceTextoAnotacion(referencia) {
    global AnotTrazos
    if !IsObject(referencia)
        return 0
    dibujos := AnotTrazos
    for i, trazo in dibujos
        if trazo == referencia
            return i
    return 0
}

TextoAnotacionEnPunto(punto) {
    global AnotTrazos
    dibujos := AnotTrazos
    margen := Max(4, Round(4 * A_ScreenDPI / 96))
    Loop dibujos.Length {
        i := dibujos.Length + 1 - A_Index
        trazo := dibujos[i]
        if trazo.herramienta != "texto"
            continue
        origen := trazo.puntos[1]
        if punto[1] >= origen[1] - margen && punto[1] <= origen[1] + trazo.ancho + margen
            && punto[2] >= origen[2] - margen && punto[2] <= origen[2] + trazo.alto + margen
            return i
    }
    return 0
}

IniciarInteraccionTextoAnotacion(msg) {
    global AnotTrazos, AnotArrastreTexto, AnotTextoSeleccionado, AnotHwndCaptura
    global AnotUltimoTexto, AnotUltimoClick, AnotUltimoPunto
    global AnotTextoEdicion, AnotTextoPunto, AnotTextoPendiente
    punto := PuntoAnotacion()
    indice := TextoAnotacionEnPunto(punto)
    if !indice {
        AnotTextoSeleccionado := 0, AnotUltimoTexto := 0
        SolicitarPintadoAnotaciones()
        return false
    }
    original := AnotTrazos[indice]
    AnotTextoSeleccionado := original
    margen := Max(4, Round(4 * A_ScreenDPI / 96))
    doble := msg = 0x0203 || (IsObject(AnotUltimoTexto) && AnotUltimoTexto == original
        && A_TickCount - AnotUltimoClick <= DllCall("GetDoubleClickTime", "uint")
        && Abs(punto[1] - AnotUltimoPunto[1]) <= margen && Abs(punto[2] - AnotUltimoPunto[2]) <= margen)
    if doble {
        AnotUltimoTexto := 0, AnotArrastreTexto := 0
        AnotTextoEdicion := original
        AnotTextoPunto := original.puntos[1].Clone()
        AnotTextoPendiente := true
        SetTimer(AbrirTextoAnotacion, -20)
    } else {
        copia := original.Clone()
        copia.puntos := [original.puntos[1].Clone()]
        AnotArrastreTexto := {original: original, copia: copia, punto: punto, origen: original.puntos[1].Clone(),
            antes: AnotTrazos.Clone(), movido: false, inicio: A_TickCount}
        DllCall("SetCapture", "ptr", AnotHwndCaptura)
    }
    ActualizarPaletaAnotaciones()
    SolicitarPintadoAnotaciones()
    return true
}

MoverTextoAnotacion() {
    global AnotArrastreTexto, AnotTextoSeleccionado, AnotTrazos, AnotW, AnotH
    if !IsObject(AnotArrastreTexto)
        return
    movimiento := AnotArrastreTexto
    punto := PuntoAnotacion()
    dx := punto[1] - movimiento.punto[1], dy := punto[2] - movimiento.punto[2]
    if !movimiento.movido && Abs(dx) + Abs(dy) < Max(4, Round(4 * A_ScreenDPI / 96))
        return
    referencia := movimiento.movido ? movimiento.copia : movimiento.original
    indice := IndiceTextoAnotacion(referencia)
    if !indice
        return
    ; La copia evita modificar los objetos guardados en el historial de deshacer.
    movimiento.copia.puntos[1] := [Max(0, Min(movimiento.origen[1] + dx, AnotW - movimiento.copia.ancho)),
        Max(0, Min(movimiento.origen[2] + dy, AnotH - movimiento.copia.alto))]
    AnotTrazos[indice] := movimiento.copia
    movimiento.movido := true
    AnotTextoSeleccionado := movimiento.copia
    SolicitarPintadoAnotaciones()
}

TerminarMovimientoTextoAnotacion(actualizarPunto := true) {
    global AnotArrastreTexto, AnotTextoSeleccionado, AnotHwndCaptura, AnotDuracion
    global AnotUltimoTexto, AnotUltimoClick, AnotUltimoPunto
    if !IsObject(AnotArrastreTexto)
        return
    if actualizarPunto
        MoverTextoAnotacion()
    movimiento := AnotArrastreTexto
    AnotArrastreTexto := 0
    if DllCall("GetCapture", "ptr") = AnotHwndCaptura
        DllCall("ReleaseCapture")
    AnotTextoSeleccionado := movimiento.movido ? movimiento.copia : movimiento.original
    AnotTextoSeleccionado.vence := AnotDuracion ? A_TickCount + AnotDuracion * 1000 : 0
    if movimiento.movido {
        AnotUltimoTexto := 0
        RegistrarCambioAnotacion(movimiento.antes)
    } else {
        AnotUltimoTexto := movimiento.original
        AnotUltimoClick := movimiento.inicio
        AnotUltimoPunto := movimiento.punto
    }
    ActualizarPaletaAnotaciones()
    SolicitarPintadoAnotaciones()
}

CancelarMovimientoTextoAnotacion() {
    global AnotArrastreTexto, AnotTextoSeleccionado, AnotTrazos, AnotHwndCaptura, AnotDuracion
    criticoAnterior := A_IsCritical
    Critical "On"
    try {
        if !IsObject(AnotArrastreTexto)
            return false
        movimiento := AnotArrastreTexto
        AnotArrastreTexto := 0
        if movimiento.movido {
            indice := IndiceTextoAnotacion(movimiento.copia)
            if indice
                AnotTrazos[indice] := movimiento.original
        }
        AnotTextoSeleccionado := movimiento.original
        movimiento.original.vence := AnotDuracion ? A_TickCount + AnotDuracion * 1000 : 0
        if DllCall("GetCapture", "ptr") = AnotHwndCaptura
            DllCall("ReleaseCapture")
        ActualizarPaletaAnotaciones()
        SolicitarPintadoAnotaciones()
        return true
    } finally {
        Critical criticoAnterior
    }
}

TextoAnotacionOcupado(trazo) {
    global AnotArrastreTexto, AnotTextoEdicion
    if IsObject(AnotTextoEdicion) && trazo == AnotTextoEdicion
        return true
    return IsObject(AnotArrastreTexto) && (trazo == AnotArrastreTexto.original || trazo == AnotArrastreTexto.copia)
}

PintarSeleccionTextoAnotacion(dc, trazo) {
    margen := Max(4, Round(4 * A_ScreenDPI / 96))
    x := trazo.puntos[1][1], y := trazo.puntos[1][2]
    lapiz := DllCall("CreatePen", "int", 2, "int", 1, "uint", BGR("8AB4F8"), "ptr")
    previo := DllCall("SelectObject", "ptr", dc, "ptr", lapiz, "ptr")
    pincel := DllCall("SelectObject", "ptr", dc, "ptr", DllCall("GetStockObject", "int", 5, "ptr"), "ptr")
    try DllCall("Rectangle", "ptr", dc, "int", x - margen, "int", y - margen,
        "int", x + trazo.ancho + margen, "int", y + trazo.alto + margen)
    finally {
        DllCall("SelectObject", "ptr", dc, "ptr", pincel)
        DllCall("SelectObject", "ptr", dc, "ptr", previo)
        DllCall("DeleteObject", "ptr", lapiz)
    }
}
