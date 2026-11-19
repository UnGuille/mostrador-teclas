#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon
Persistent
DetectHiddenWindows true

; Componente del mostrador. UI Automation se consulta en un proceso separado
; para que un proveedor lento no bloquee las teclas ni el aura del cursor.
if A_Args.Length != 2 || !IsInteger(A_Args[1])
    ExitApp()
global Padre := Integer(A_Args[1]), Config := A_Args[2]
global Capas := [], Firma := "", VentanaAnterior := 0, Ocupado := false
global Lector := 0
OnExit(LimpiarSeleccion)
try Lector := LectorSeleccion()
catch
    ExitApp()
SetTimer(ActualizarSeleccion, 350)

ActualizarSeleccion() {
    global Padre, Config, Capas, Firma, Lector, Ocupado, VentanaAnterior
    if Ocupado
        return
    Ocupado := true
    try {
        if !ProcessExist(Padre) || !Integer(IniRead(Config, "Seleccion", "Activo", "0"))
            ExitApp()
        ventana := DllCall("GetForegroundWindow", "ptr")
        pid := 0
        DllCall("GetWindowThreadProcessId", "ptr", ventana, "uint*", &pid)
        if ventana != VentanaAnterior || GetKeyState("LButton", "P") || pid = A_Pid {
            LimpiarSeleccion()
            VentanaAnterior := ventana
            return
        }
        estilo := EstiloSeleccion()
        rangos := Lector.Seleccion(pid)
        firmaNueva := ventana "|" estilo.firma
        for rango in rangos {
            firmaNueva .= "|" Lector.Texto(rango)
            for valor in Lector.Rectangulos(rango)
                firmaNueva .= ":" Round(valor)
        }
        if firmaNueva = Firma
            return
        lineas := []
        for rango in rangos {
            for linea in Lector.Lineas(rango) {
                lineas.Push(linea)
                if lineas.Length >= 60
                    break
            }
            if lineas.Length >= 60
                break
        }
        ; Descartar resultados que llegaron después de cambiar de ventana.
        if DllCall("GetForegroundWindow", "ptr") != ventana
            return
        LimpiarSeleccion()
        for linea in lineas
            Capas.Push(CrearCapaSeleccion(linea, estilo))
        Firma := firmaNueva
    } catch {
        LimpiarSeleccion()
    } finally {
        Ocupado := false
    }
}

EstiloSeleccion() {
    global Config
    fondo := ColorSeleccion("Fondo", "FFD600")
    texto := ColorSeleccion("Texto", "FFFFFF")
    sombra := ColorSeleccion("Sombra", "000000")
    grosor := Max(1, Min(6, Integer(IniRead(Config, "Seleccion", "Grosor", "3"))))
    negrita := Integer(IniRead(Config, "Seleccion", "Negrita", "1"))
    return {fondo: fondo, texto: texto, sombra: sombra, grosor: grosor, negrita: negrita,
        firma: fondo texto sombra grosor negrita}
}

ColorSeleccion(clave, defecto) {
    global Config
    color := StrUpper(IniRead(Config, "Seleccion", clave, defecto))
    return RegExMatch(color, "^[0-9A-F]{6}$") ? color : defecto
}

LimpiarSeleccion(*) {
    global Capas, Firma
    for capa in Capas {
        capa.gui.Destroy()
        DllCall("DeleteObject", "ptr", capa.bitmap)
    }
    Capas := [], Firma := ""
}

class LectorSeleccion {
    __New() {
        this.uia := ComObject("{FF48DBA4-60EF-4201-AA87-54103EEF594E}", "{30CBE57D-D9D0-452A-AB13-7AC5AC4825EE}")
        p := 0
        ComCall(14, this.uia, "ptr*", &p) ; get_ControlViewWalker
        this.walker := this.Interfaz(p)
        this.iidTexto := Buffer(16, 0)
        DllCall("ole32\CLSIDFromString", "wstr", "{32EBA289-3583-42C9-9C59-3B6D9A1E9B6A}", "ptr", this.iidTexto)
    }

    Interfaz(p) {
        if !p
            throw Error("La aplicación no expone este elemento.")
        return ComValue(13, p, 1)
    }

    Seleccion(pid) {
        candidatos := []
        p := 0
        try {
            ComCall(8, this.uia, "ptr*", &p) ; GetFocusedElement
            candidatos.Push(this.Interfaz(p))
        }
        punto := Buffer(8, 0)
        if DllCall("GetCursorPos", "ptr", punto) {
            p := 0
            try {
                ComCall(7, this.uia, "int64", NumGet(punto, 0, "int64"), "ptr*", &p)
                candidatos.Push(this.Interfaz(p))
            }
        }
        for elemento in candidatos {
            Loop 8 {
                proceso := 0
                ComCall(20, elemento, "int*", &proceso) ; CurrentProcessId
                if proceso != pid
                    break
                if this.EsContrasena(elemento)
                    break
                p := 0
                try {
                    ComCall(14, elemento, "int", 10014, "ptr", this.iidTexto, "ptr*", &p)
                    patron := this.Interfaz(p)
                    p := 0
                    ComCall(5, patron, "ptr*", &p) ; TextPattern.GetSelection
                    arreglo := this.Interfaz(p)
                    cantidad := 0
                    ComCall(3, arreglo, "int*", &cantidad)
                    rangos := []
                    Loop Min(4, cantidad) {
                        p := 0
                        ComCall(4, arreglo, "int", A_Index - 1, "ptr*", &p)
                        rango := this.Interfaz(p)
                        if this.Texto(rango) != "" && this.Rectangulos(rango).Length
                            rangos.Push(rango)
                    }
                    if rangos.Length
                        return rangos
                }
                p := 0
                ComCall(3, this.walker, "ptr", ComObjValue(elemento), "ptr*", &p)
                if !p
                    break
                elemento := this.Interfaz(p)
            }
        }
        return []
    }

    EsContrasena(elemento) {
        valor := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
        try {
            ComCall(10, elemento, "int", 30019, "ptr", valor)
            return NumGet(valor, 0, "ushort") = 11 && NumGet(valor, 8, "short") != 0
        } finally {
            DllCall("oleaut32\VariantClear", "ptr", valor)
        }
    }

    Texto(rango) {
        p := 0
        ComCall(12, rango, "int", 8000, "ptr*", &p) ; GetText
        try return p ? StrGet(p, "UTF-16") : ""
        finally {
            if p
                DllCall("oleaut32\SysFreeString", "ptr", p)
        }
    }

    Rectangulos(rango) {
        arreglo := 0, datos := 0, valores := []
        ComCall(10, rango, "ptr*", &arreglo) ; GetBoundingRectangles
        if !arreglo
            return valores
        try {
            inferior := 0, superior := -1
            if DllCall("oleaut32\SafeArrayGetDim", "ptr", arreglo, "uint") != 1
                return valores
            DllCall("oleaut32\SafeArrayGetLBound", "ptr", arreglo, "uint", 1, "int*", &inferior)
            DllCall("oleaut32\SafeArrayGetUBound", "ptr", arreglo, "uint", 1, "int*", &superior)
            if DllCall("oleaut32\SafeArrayAccessData", "ptr", arreglo, "ptr*", &datos, "int") < 0
                return valores
            Loop Min(2400, superior - inferior + 1)
                valores.Push(NumGet(datos, (A_Index - 1) * 8, "double"))
        } finally {
            if datos
                DllCall("oleaut32\SafeArrayUnaccessData", "ptr", arreglo)
            DllCall("oleaut32\SafeArrayDestroy", "ptr", arreglo)
        }
        return valores
    }

    Clonar(rango) {
        p := 0
        ComCall(3, rango, "ptr*", &p)
        return this.Interfaz(p)
    }

    Comparar(a, extremoA, b, extremoB) {
        diferencia := 0
        ComCall(5, a, "int", extremoA, "ptr", ComObjValue(b), "int", extremoB, "int*", &diferencia)
        return diferencia
    }

    Extremo(a, extremoA, b, extremoB) {
        ComCall(15, a, "int", extremoA, "ptr", ComObjValue(b), "int", extremoB)
    }

    Lineas(rango) {
        resultado := [], cursor := this.Clonar(rango)
        this.Extremo(cursor, 1, cursor, 0)
        Loop 60 {
            if this.Comparar(cursor, 0, rango, 1) >= 0
                break
            linea := this.Clonar(cursor)
            ComCall(6, linea, "int", 3) ; ExpandToEnclosingUnit(TextUnit_Line)
            this.Extremo(linea, 0, cursor, 0)
            if this.Comparar(linea, 1, rango, 1) > 0
                this.Extremo(linea, 1, rango, 1)
            if this.Comparar(linea, 1, cursor, 0) <= 0
                break
            texto := RTrim(this.Texto(linea), "`r`n")
            rects := this.Rectangulos(linea)
            if texto != "" && rects.Length >= 4 {
                x := rects[1], y := rects[2], derecha := x + rects[3], abajo := y + rects[4]
                Loop rects.Length // 4 {
                    i := (A_Index - 1) * 4 + 1
                    x := Min(x, rects[i]), y := Min(y, rects[i + 1])
                    derecha := Max(derecha, rects[i] + rects[i + 2])
                    abajo := Max(abajo, rects[i + 1] + rects[i + 3])
                }
                if derecha > x && abajo > y && derecha - x <= 12000 && abajo - y <= 2000
                    resultado.Push({x: Round(x), y: Round(y), w: Max(1, Round(derecha - x)), h: Max(1, Round(abajo - y)), texto: texto})
            }
            this.Extremo(cursor, 0, linea, 1)
            this.Extremo(cursor, 1, cursor, 0)
        }
        return resultado
    }
}

CrearCapaSeleccion(linea, estilo) {
    bitmap := PintarSeleccion(linea.w, linea.h, linea.texto, estilo)
    g := Gui("+AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000020", "Resaltado de selección")
    try {
        g.MarginX := 0, g.MarginY := 0
        pic := g.AddText(Format("x0 y0 w{} h{} +0xE", linea.w, linea.h))
        SendMessage(0x172, 0, bitmap, pic)
        WinSetTransparent(255, g)
        g.Show(Format("x{} y{} w{} h{} NoActivate", linea.x, linea.y, linea.w, linea.h))
        return {gui: g, bitmap: bitmap}
    } catch as err {
        g.Destroy()
        DllCall("DeleteObject", "ptr", bitmap)
        throw err
    }
}

PintarSeleccion(w, h, texto, estilo) {
    pantalla := DllCall("GetDC", "ptr", 0, "ptr")
    dc := DllCall("CreateCompatibleDC", "ptr", pantalla, "ptr")
    bitmap := DllCall("CreateCompatibleBitmap", "ptr", pantalla, "int", w, "int", h, "ptr")
    DllCall("ReleaseDC", "ptr", 0, "ptr", pantalla)
    anterior := DllCall("SelectObject", "ptr", dc, "ptr", bitmap, "ptr")
    fuente := 0, fuenteAnterior := 0, pincel := 0
    try {
        rect := Buffer(16, 0)
        NumPut("int", w, rect, 8), NumPut("int", h, rect, 12)
        pincel := DllCall("CreateSolidBrush", "uint", RGBSeleccion(estilo.fondo), "ptr")
        DllCall("FillRect", "ptr", dc, "ptr", rect, "ptr", pincel)
        px := Max(6, Floor(h * 0.82))
        Loop 2 {
            fuente := DllCall("CreateFontW", "int", -px, "int", 0, "int", 0, "int", 0,
                "int", estilo.negrita ? 700 : 400, "uint", 0, "uint", 0, "uint", 0,
                "uint", 1, "uint", 0, "uint", 0, "uint", 5, "uint", 0, "str", "Segoe UI", "ptr")
            previa := DllCall("SelectObject", "ptr", dc, "ptr", fuente, "ptr")
            if !fuenteAnterior
                fuenteAnterior := previa
            medida := Buffer(8, 0)
            DllCall("GetTextExtentPoint32W", "ptr", dc, "str", texto, "int", StrLen(texto), "ptr", medida)
            ancho := NumGet(medida, 0, "int")
            if ancho <= w || A_Index = 2
                break
            DllCall("SelectObject", "ptr", dc, "ptr", fuenteAnterior)
            DllCall("DeleteObject", "ptr", fuente)
            fuente := 0
            px := Max(6, Floor(px * w / Max(1, ancho)))
        }
        DllCall("SetBkMode", "ptr", dc, "int", 1)
        grosor := Min(estilo.grosor, Max(1, Floor(h / 6)))
        DllCall("SetTextColor", "ptr", dc, "uint", RGBSeleccion(estilo.sombra))
        for desplazamiento in [[-grosor,0],[grosor,0],[0,-grosor],[0,grosor],[-grosor,-grosor],[grosor,grosor],[-grosor,grosor],[grosor,-grosor]] {
            NumPut("int", desplazamiento[1], "int", desplazamiento[2], "int", w + desplazamiento[1], "int", h + desplazamiento[2], rect)
            DllCall("DrawTextW", "ptr", dc, "str", texto, "int", -1, "ptr", rect, "uint", 0x864)
        }
        DllCall("SetTextColor", "ptr", dc, "uint", RGBSeleccion(estilo.texto))
        NumPut("int", 0, "int", 0, "int", w, "int", h, rect)
        DllCall("DrawTextW", "ptr", dc, "str", texto, "int", -1, "ptr", rect, "uint", 0x864)
    } catch as err {
        DllCall("SelectObject", "ptr", dc, "ptr", anterior)
        DllCall("DeleteObject", "ptr", bitmap)
        throw err
    } finally {
        if fuenteAnterior
            DllCall("SelectObject", "ptr", dc, "ptr", fuenteAnterior)
        if fuente
            DllCall("DeleteObject", "ptr", fuente)
        if pincel
            DllCall("DeleteObject", "ptr", pincel)
        DllCall("SelectObject", "ptr", dc, "ptr", anterior)
        DllCall("DeleteDC", "ptr", dc)
    }
    return bitmap
}

RGBSeleccion(hex) {
    c := Integer("0x" hex)
    return ((c & 255) << 16) | (c & 0xFF00) | ((c >> 16) & 255)
}
