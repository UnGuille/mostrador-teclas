# Mostrador de Teclas

Teclado y mouse visuales en pantalla para clases, tutoriales y demostraciones. Muestra las teclas y combinaciones que pulsas, anima su movimiento y ayuda a seguir el cursor.

Hecho con [AutoHotkey v2](https://www.autohotkey.com/) para Windows.

## Funciones

- **Teclas animadas:** bajan y pierden su sombra inferior al pulsarlas, como un teclado físico. El recorrido es de 6 píxeles al tamaño predeterminado, con una transición de 100 ms. Las pulsaciones rápidas permanecen hundidas al menos 180 ms para que se alcancen a ver.
- **Colores:** amarillo para teclas normales y rojo para modificadores (`Ctrl`, `Shift`, `Alt`, `Alt Gr` y `Win`). Al soltar una tecla, vuelve a subir y conserva el color brevemente.
- **Combinaciones e historial:** muestra, por ejemplo, `Ctrl + C`, `Alt Gr + Q ⇒ @` o `Shift + 2 ⇒ "`, junto con las combinaciones anteriores.
- **Distribuciones Latinoamérica y España:** los símbolos escritos con **Alt Gr** aparecen en azul.
- **Mouse visual opcional:** cuerpo curvo, botones integrados y rueda central. Los clics izquierdo, derecho y central se iluminan en amarillo; el desplazamiento de la rueda se indica en azul con flechas hacia arriba o abajo. Permite mostrar clics simultáneos.
- **Resplandor del cursor:** halo amarillo suave que sigue el puntero, sin impedir los clics ni cambiar el foco de la ventana activa. Se controla por separado del mouse visual.
- **Posición y tamaño ajustables:** arrastra el mostrador, cambia su tamaño o utiliza el modo de solo texto.

## Cómo usarlo

1. Instala [AutoHotkey v2](https://www.autohotkey.com/).
2. Descarga `mostrador-teclas.ahk` y haz doble clic en él.
3. El mostrador inicia **desbloqueado**, para que puedas arrastrarlo hasta donde prefieras. En el primer inicio aparece en la esquina inferior derecha; después utiliza la posición guardada.
4. Pulsa **Ctrl + Alt + L** para bloquearlo cuando esté en su sitio. Al bloquearlo, los clics atraviesan el mostrador.

Sin configuración previa, el mouse visual y el halo del cursor están activados. Puedes apagarlos de forma independiente; tu preferencia queda guardada.

El **autoocultado solo actúa cuando el mostrador está bloqueado** y esa opción está activada. Tras unos segundos sin actividad se oculta y vuelve a aparecer al pulsar una tecla o usar los botones o la rueda del mouse. Mientras está desbloqueado permanece visible para facilitar su colocación. El halo del cursor funciona independientemente del autoocultado.

## Atajos

Usa **Ctrl y Alt del lado izquierdo**, para evitar conflictos con Alt Gr.

| Atajo | Acción |
|---|---|
| `Ctrl + Alt + L` | Bloquear / desbloquear la posición |
| `Ctrl + Alt + RePág` | Aumentar el tamaño |
| `Ctrl + Alt + AvPág` | Reducir el tamaño |
| `Ctrl + Alt + K` | Alternar entre teclado visual y solo texto |
| `Ctrl + Alt + H` | Alternar entre siempre visible y autoocultado |
| `Ctrl + Alt + D` | Cambiar entre Latinoamérica y España |
| `Ctrl + Alt + R` | Volver a la esquina inferior derecha |
| `Ctrl + Alt + B` | Mostrar / ocultar el mouse visual |
| `Ctrl + Alt + M` | Activar / desactivar el resplandor del cursor |
| `Ctrl + Alt + Q` | Cerrar el programa |

Las mismas opciones están disponibles al hacer clic derecho en el icono de la bandeja del sistema.

El mouse visual aparece **junto al teclado y se mueve con él**. No se muestra en el modo de solo texto; el halo del cursor sigue disponible en ambos modos.

## Configuración

Las preferencias se guardan automáticamente en `overlay-config.ini`, junto al script: tamaño, posición, distribución, modo de visualización, autoocultado, mouse visual y halo del cursor. La carpeta debe permitir la escritura de ese archivo.

El bloqueo de posición no se conserva: **cada vez que abres el programa inicia desbloqueado**.

Puedes editar estas opciones con el programa cerrado y volver a abrirlo para aplicarlas:

| Sección | Opción | Valor predeterminado | Función |
|---|---|---|---|
| `[Teclado]` | `DuracionMs` | `6000` | Tiempo de inactividad antes de ocultarse, con el mostrador bloqueado y el autoocultado activo |
| `[Teclado]` | `ResaltadoMs` | `900` | Tiempo que permanece el color después de soltar una tecla; también se usa para los indicadores del mouse |
| `[Mouse]` | `MostrarVisual` | `1` | Mouse visual: `1` activado, `0` desactivado |
| `[Mouse]` | `Resplandor` | `1` | Halo del cursor: `1` activado, `0` desactivado |

La duración de la animación de pulsación es independiente de `ResaltadoMs`.

## Limitaciones

- En ventanas que se ejecutan como administrador, puede ser necesario ejecutar también el mostrador como administrador para detectar las pulsaciones.
- La tecla `Fn` de las laptops no se puede detectar.
- El mouse visual representa los clics izquierdo, derecho y central, y la rueda vertical. Los botones laterales y la rueda horizontal aparecen en el historial de texto.
