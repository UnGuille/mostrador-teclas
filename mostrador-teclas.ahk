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
;    Ctrl+Alt+B       -> Mostrar / ocultar mouse visual
;    Ctrl+Alt+M       -> Activar / desactivar resplandor del mouse
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
    fondo: "141414", tecla: "2F2F2F", texto: "F2F2F2", shift: "BDBDBD",
    altgr: "5AB0FF", especial: "D0D0D0",
    normal: "FFD21F", normalTxt: "111111",
    mod: "E3262B", modTxt: "FFFFFF",
    barra: "00FF90", previo: "8A8A8A"
}

global ResplandorMouse := Integer(IniRead(ArchivoConfig, "Mouse", "Resplandor", "1"))
global MostrarMouse := Integer(IniRead(ArchivoConfig, "Mouse", "MostrarVisual", "1"))
global PartesMouse := Map(), EventosMouse := Map()
global HaloMouse := 0, HaloDC := 0, HaloBitmap := 0, HaloAnterior := 0
global HaloTam := 88, HaloX := "", HaloY := ""

; ---------------- ESTADO ----------------
global Bloqueado := false, Visible := false
global Historial := [], UltimaTick := 0
global Presionadas := Map(), Soltadas := Map()
global Teclas := Map(), Leyendas := Map(), Especiales := Map(), Posiciones := []
global overlay := 0, txtCombo := 0, txtPrev := 0, U := 40, GuiW := 0, GuiH := 0
global ih := 0, Recursos := [], Fuentes := Map()

try {
    DefinirPosiciones()
    CargarNombres()
    Construir()
    ConfigurarBandeja()
    OnExit(LiberarHaloMouse)
    CrearHaloMouse()
    AplicarResplandorMouse()

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
    AgregarAlHistorial("Listo: presiona cualquier tecla")
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
<^<!b::AlternarMouseVisual()
<^<!m::AlternarResplandorMouse()
<^<!q::ExitApp()

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
    global overlay, txtCombo, txtPrev, Teclas, U, GuiW, GuiH, Visible
    global Escala, Bloqueado, MostrarTeclado, Col, Posiciones, Leyendas, Especiales, MostrarMouse, PartesMouse

    if IsObject(overlay)
        overlay.Destroy()
    LiberarRecursos()          ; borrar imagenes/fuentes de la version anterior
    Teclas := Map()
    PartesMouse := Map()
    Visible := false

    U := Round(40 * Escala * A_ScreenDPI / 96)   ; tamaño de una tecla en pixeles
    pad := Round(U * 0.3)

    ; -DPIScale: pixeles reales.  +E0x20: los clics atraviesan la ventana (bloqueado)
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale" (Bloqueado ? " +E0x20" : ""))
    overlay.BackColor := Col.fondo
    overlay.OnEvent("Close", (*) => ExitApp())

    ; ----- Modo solo texto -----
    if !MostrarTeclado {
        overlay.MarginX := pad
        overlay.MarginY := Round(pad * 0.6)
        overlay.SetFont("s" Pt(U * 0.6) " c" Col.barra " bold", "Consolas")
        txtCombo := overlay.AddText("x" overlay.MarginX " y" overlay.MarginY " +0x80", "")
        txtPrev := 0
        WinSetTransparent(235, overlay)
        return
    }

    ; ----- Modo teclado -----
    overlay.MarginX := 0
    overlay.MarginY := 0
    anchoTec := Round(18.5 * U)
    barH := U
    GuiW := anchoTec + 2 * pad + (MostrarMouse ? Round(3.5 * U) : 0)
    top := pad + barH + Round(U * 0.2)
    GuiH := top + Round(6.25 * U) + pad

    ; Barra superior: combinacion actual (grande) y anteriores (gris)
    anchoCombo := Round(anchoTec * 0.62)
    overlay.SetFont("s" Pt(U * 0.55) " c" Col.barra " bold", "Segoe UI")
    txtCombo := overlay.AddText(Format("x{} y{} w{} h{} +0x200 +0x80 +0x4000", pad, pad, anchoCombo, barH), "")
    overlay.SetFont("s" Pt(U * 0.3) " c" Col.previo " norm", "Segoe UI")
    txtPrev := overlay.AddText(Format("x{} y{} w{} h{} Right +0x200 +0x80 +0x4000", pad + anchoCombo, pad, anchoTec - anchoCombo, barH), "")

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
        for estado in ["", "normal", "mod", "normal-down", "mod-down"]
            bmps[estado] := DibujarTecla(kw, kh, estado, legs)
        SendMessage(0x172, 0, bmps[""], pic)   ; STM_SETIMAGE
        Teclas[pos.sc] := {pic: pic, bmps: bmps, estado: ""}
    }

    if MostrarMouse
        ConstruirMouseVisual(pad + anchoTec + Round(U * 0.4), top + Round(U * 0.5))

    WinSetTransparent(245, overlay)
}

Leg(x, y, w, h, texto, px, negrita, rol, align) {
    return {x: x, y: y, w: w, h: h, texto: texto, px: px, negrita: negrita, rol: rol, align: align}
}

PintarTecla(sc, estado) {
    global Teclas, Presionadas
    if !Teclas.Has(sc)
        return
    if (estado != "" && Presionadas.Has(sc))
        estado .= "-down"
    k := Teclas[sc]
    if (k.estado = estado)
        return
    k.estado := estado
    SendMessage(0x172, 0, k.bmps[estado], k.pic)   ; cambiar a la imagen ya dibujada
}

; Dibuja una tecla (fondo redondeado + leyendas) en un bitmap con GDI
DibujarTecla(w, h, estado, legs) {
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
    hundida := InStr(estado, "-down") != 0
    estado := StrReplace(estado, "-down")
    profundidad := Max(2, Round(U * 0.10))
    desplazamiento := hundida ? profundidad - 1 : 0
    altoCara := h - profundidad
    r := Max(4, Round(U * 0.16))
    colorTecla := (estado = "mod") ? Col.mod : (estado = "normal") ? Col.normal : Col.tecla
    borde := hundida ? "101010" : (estado = "mod") ? "FF7276" : (estado = "normal") ? "FFF19A" : "606060"
    base := (estado = "mod") ? "741216" : (estado = "normal") ? "80620B" : "171717"
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
    AgregarAlHistorial(TextoCombo(sc, vk))
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
    global EventosMouse
    boton := SubStr(HotkeyName, 3)
    EventosMouse[boton] := A_TickCount
    RefrescarMouseVisual()
    txt := ""
    for m in ModsActivos()
        txt .= m " + "
    AgregarAlHistorial(txt NombreAmigable(SubStr(HotkeyName, 3)))
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

AgregarAlHistorial(texto) {
    global Historial, UltimaTick
    n := Historial.Length
    ultima := n ? Historial[n] : ""
    base := RegExReplace(ultima, " ×\d+$")

    if (n && base = texto) {
        veces := RegExMatch(ultima, " ×(\d+)$", &m) ? m[1] + 1 : 2      ; "A ×3"
        Historial[n] := texto " ×" veces
    } else if (n && ultima = base && InStr(texto, ultima " + ") = 1) {
        Historial[n] := texto                                           ; "Ctrl" -> "Ctrl + C"
    } else {
        Historial.Push(texto)
        if (Historial.Length > 4)
            Historial.RemoveAt(1)
    }
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
    global Historial, MostrarTeclado, txtCombo, txtPrev, overlay, GuiW, GuiH
    n := Historial.Length
    if MostrarTeclado {
        txtCombo.Text := n ? Historial[n] : ""
        prev := ""
        i := n - 1
        while (i >= 1 && i >= n - 2) {
            prev .= (prev = "" ? "" : "      ") Historial[i]
            i--
        }
        txtPrev.Text := prev
    } else {
        if !n {
            Ocultar()
            return
        }
        texto := ""
        for i, linea in Historial
            texto .= (i = 1 ? "" : "`n") linea
        tam := MedirTexto(txtCombo, texto)
        txtCombo.Move(, , tam[1] + 6, tam[2] + 4)
        txtCombo.Text := texto
        GuiW := tam[1] + 6 + overlay.MarginX * 2
        GuiH := tam[2] + 4 + overlay.MarginY * 2
    }
    Mostrar()
}

Mostrar() {
    global overlay, Visible, GuiW, GuiH, MostrarTeclado
    if (Visible && MostrarTeclado)
        return
    pos := CalcularPosicion(GuiW, GuiH)
    overlay.Show(Format("x{} y{} w{} h{} NoActivate", pos[1], pos[2], GuiW, GuiH))
    overlay.Opt("+AlwaysOnTop")
    Visible := true
}

Ocultar() {
    global overlay, Visible, Historial
    overlay.Hide()
    Visible := false
    Historial := []
}

; Cada 100 ms: limpia teclas "pegadas", apaga las que ya se soltaron
; y oculta la ventana si no hay actividad.
Tick() {
    global Presionadas, Soltadas, ResaltadoMs, AutoOcultar, Bloqueado, Visible, UltimaTick, DuracionMs
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

    if (Visible && AutoOcultar && Bloqueado && !Presionadas.Count && !Soltadas.Count
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
    global Bloqueado, overlay
    Bloqueado := !Bloqueado
    overlay.Opt(Bloqueado ? "+E0x20" : "-E0x20")
    AgregarAlHistorial(Bloqueado ? "Posición bloqueada" : "Desbloqueado: arrastra para mover")
}

CambiarEscala(d) {
    global Escala
    Escala := Round(Max(0.6, Min(2.5, Escala + d)), 2)
    GuardarConfig()
    Reconstruir("Tamaño: " Round(Escala * 100) "%")
}

AlternarModo() {
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
    global Distribucion
    Distribucion := (Distribucion = "es") ? "latam" : "es"
    GuardarConfig()
    CargarNombres()
    Reconstruir("Distribución: " (Distribucion = "es" ? "España" : "Latinoamérica"))
}

Reconstruir(mensaje) {
    global Presionadas, Soltadas
    Construir()
    for sc in Presionadas
        PintarTecla(sc, EsModificador(sc) ? "mod" : "normal")
    for sc in Soltadas
        PintarTecla(sc, EsModificador(sc) ? "mod" : "normal")
    AgregarAlHistorial(mensaje)
}

RestablecerPosicion() {
    global Anclaje, MargenX, MargenY, Visible, overlay
    Anclaje := "BR"
    MargenX := 20
    MargenY := 20
    GuardarConfig()
    overlay.Hide()
    Visible := false
    AgregarAlHistorial("Posición restablecida")
}

AlPresionarMouse(wParam, lParam, msg, hwnd) {
    global overlay, Bloqueado
    if (Bloqueado || !IsObject(overlay))
        return
    if (hwnd = overlay.Hwnd || DllCall("GetAncestor", "ptr", hwnd, "uint", 2, "ptr") = overlay.Hwnd) {
        PostMessage(0xA1, 2, 0, , overlay.Hwnd)   ; arrastrar como barra de titulo
        return 0
    }
}

AlTerminarArrastre(wParam, lParam, msg, hwnd) {
    global overlay, Anclaje, MargenX, MargenY
    if (!IsObject(overlay) || hwnd != overlay.Hwnd)
        return
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
        case "XY": return [MargenX, MargenY]
        case "TL": return [L + MargenX, T + MargenY]
        case "TR": return [R - w - MargenX, T + MargenY]
        case "BL": return [L + MargenX, B - h - MargenY]
        default:   return [R - w - MargenX, B - h - MargenY]   ; "BR"
    }
}

GuardarConfig() {
    global ArchivoConfig, Distribucion, Escala, MostrarTeclado, AutoOcultar, DuracionMs, ResaltadoMs, Anclaje, MargenX, MargenY, ResplandorMouse, MostrarMouse
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
}

ConfigurarBandeja() {
    global MostrarMouse
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Bloquear / desbloquear posición  (Ctrl+Alt+L)", (*) => AlternarBloqueo())
    A_TrayMenu.Add("Más grande  (Ctrl+Alt+RePág)", (*) => CambiarEscala(0.1))
    A_TrayMenu.Add("Más pequeño  (Ctrl+Alt+AvPág)", (*) => CambiarEscala(-0.1))
    A_TrayMenu.Add("Teclado / solo texto  (Ctrl+Alt+K)", (*) => AlternarModo())
    A_TrayMenu.Add("Siempre visible / ocultarse solo  (Ctrl+Alt+H)", (*) => AlternarAutoOcultar())
    A_TrayMenu.Add("Latinoamérica / España  (Ctrl+Alt+D)", (*) => AlternarDistribucion())
    A_TrayMenu.Add("Volver a la esquina  (Ctrl+Alt+R)", (*) => RestablecerPosicion())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)", (*) => AlternarMouseVisual())
    if MostrarMouse
        A_TrayMenu.Check("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)")
    A_TrayMenu.Add("Resplandor del mouse  (Ctrl+Alt+M)", (*) => AlternarResplandorMouse())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Salir  (Ctrl+Alt+Q)", (*) => ExitApp())
    A_IconTip := "Mostrador de teclas"
}


; Halo amarillo suave, independiente del autoocultado del teclado.
; Ventana por pixel: no roba el foco y todos los clics la atraviesan.
CrearHaloMouse() {
    global HaloMouse, HaloDC, HaloBitmap, HaloAnterior, HaloTam
    HaloMouse := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x80020 +E0x08000000")
    bi := Buffer(40, 0)
    NumPut("uint", 40, "int", HaloTam, "int", -HaloTam, "ushort", 1, "ushort", 32, bi)
    bits := 0
    HaloDC := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
    HaloBitmap := DllCall("CreateDIBSection", "ptr", HaloDC, "ptr", bi,
        "uint", 0, "ptr*", &bits, "ptr", 0, "uint", 0, "ptr")
    if (!HaloDC || !HaloBitmap)
        throw Error("No se pudo crear el resplandor del mouse.")
    HaloAnterior := DllCall("SelectObject", "ptr", HaloDC, "ptr", HaloBitmap, "ptr")
    radio := HaloTam / 2
    Loop HaloTam {
        y := A_Index - 1
        Loop HaloTam {
            x := A_Index - 1
            distancia := Sqrt((x - radio + 0.5)**2 + (y - radio + 0.5)**2)
            ; Amarillo con alpha premultiplicado y borde difuminado.
            alpha := Round(90 * Max(0, 1 - (distancia / radio)**2)**1.4)
            pixel := (alpha << 24) | (alpha << 16) | (Round(alpha * 0.84) << 8)
            NumPut("uint", pixel, bits + 4 * (y * HaloTam + x))
        }
    }
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
    global PartesMouse, EventosMouse, ResaltadoMs
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
    global Col, Recursos
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
    MouseCurva(dc, sx, sy, forma, "33383E", "080A0C", 2)
    MouseCurva(dc, sx, sy, [56,11, 23,11,14,21,12,53,
        10,66,9,79,9,89, 26,84,42,83,56,83,
        56,60,56,34,56,11], (estado & 1) ? "FFD21F" : "E5E9ED", "161A20", 1.6)
    MouseCurva(dc, sx, sy, [56,11, 89,11,98,21,100,53,
        102,66,103,79,103,89, 86,84,70,83,56,83,
        56,60,56,34,56,11], (estado & 2) ? "FFD21F" : "E5E9ED", "161A20", 1.6)
    ; Panel de palma, con una curva que une ambos botones.
    MouseCurva(dc, sx, sy, [9,94, 38,86,74,86,103,94,
        105,119,104,145,97,162, 91,177,76,180,56,180,
        36,180,21,177,15,162, 8,145,7,119,9,94], "B6BEC7", "161A20", 1.6)
    ; Rueda central con surcos. Se ilumina al pulsar o desplazar.
    rueda := (estado & 4) ? "FFD21F" : (estado & 24) ? "5AB0FF" : "555F6A"
    MouseCurva(dc, sx, sy, [56,29, 48,29,47,34,47,40,
        47,47,47,56,47,62, 47,70,50,73,56,73,
        62,73,65,70,65,62, 65,56,65,47,65,40,
        65,34,64,29,56,29], rueda, "101419", 2)
    Loop 5 {
        yy := 38 + A_Index * 5
        MouseLinea(dc, sx, sy, 51, yy, 61, yy, "909AA4", 0.7)
    }
    ; Flechas discretas: azul indica el sentido de desplazamiento.
    MouseLinea(dc, sx, sy, 52,24,56,20, (estado & 8) ? "5AB0FF" : "707983", 1.6)
    MouseLinea(dc, sx, sy, 56,20,60,24, (estado & 8) ? "5AB0FF" : "707983", 1.6)
    MouseLinea(dc, sx, sy, 52,77,56,81, (estado & 16) ? "5AB0FF" : "707983", 1.6)
    MouseLinea(dc, sx, sy, 56,81,60,77, (estado & 16) ? "5AB0FF" : "707983", 1.6)
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
    global MostrarMouse
    MostrarMouse := !MostrarMouse
    GuardarConfig()
    if MostrarMouse
        A_TrayMenu.Check("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)")
    else
        A_TrayMenu.Uncheck("Mostrar / ocultar mouse visual  (Ctrl+Alt+B)")
    Reconstruir(MostrarMouse ? "Mouse visual activado (modo teclado)" : "Mouse visual oculto")
}
