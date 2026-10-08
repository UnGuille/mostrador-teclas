# Mostrador de Teclas

Teclado visual en pantalla para clases: ilumina en tiempo real las teclas y combinaciones que pulsas, para que los estudiantes vean exactamente qué teclas usar.

- **Amarillo**: tecla normal (letras, números, flechas…)
- **Rojo**: modificadores (Ctrl, Shift, Alt, Alt Gr, Win)
- Arriba del teclado se escribe la combinación, por ejemplo `Ctrl + C`, `Alt Gr + Q ⇒ @` o `Shift + 2 ⇒ "`
- Los símbolos en **azul** se escriben con **Alt Gr**
- También muestra los clics y la rueda del mouse

Hecho con [AutoHotkey v2](https://www.autohotkey.com/) para Windows.

## Cómo usarlo

1. Instala **AutoHotkey v2** (es gratis): https://www.autohotkey.com/
2. Descarga `mostrador-teclas.ahk`
3. Haz doble clic en el archivo

El teclado aparece en la esquina inferior derecha y se oculta solo tras unos segundos sin actividad.

## Atajos

Usa **Ctrl y Alt del lado izquierdo**.

| Atajo | Acción |
|---|---|
| `Ctrl + Alt + L` | Bloquear / desbloquear (desbloqueado se puede arrastrar) |
| `Ctrl + Alt + RePág` | Más grande |
| `Ctrl + Alt + AvPág` | Más pequeño |
| `Ctrl + Alt + K` | Teclado visual / solo texto |
| `Ctrl + Alt + H` | Siempre visible / ocultarse solo |
| `Ctrl + Alt + D` | Distribución Latinoamérica / España |
| `Ctrl + Alt + R` | Volver a la esquina inferior derecha |
| `Ctrl + Alt + Q` | Cerrar |

Las mismas opciones están en el menú del icono de la bandeja del sistema.

## Configuración

Las preferencias (tamaño, posición, distribución, etc.) se guardan solas en `overlay-config.ini`, junto al script. En ese archivo también puedes cambiar:

- `DuracionMs`: tiempo sin actividad antes de ocultarse (por defecto 6000 ms)
- `ResaltadoMs`: cuánto sigue iluminada una tecla después de soltarla (por defecto 900 ms)

## Limitaciones

- En ventanas que se ejecutan como administrador (por ejemplo, el Administrador de tareas) no se detectan las teclas, salvo que el script también se ejecute como administrador.
- La tecla `Fn` de las laptops no se puede detectar.
