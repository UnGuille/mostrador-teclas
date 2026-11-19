# Mostrador de Teclas

Teclado y mouse visuales en pantalla para clases, tutoriales y demostraciones. Muestra las teclas y combinaciones que pulsas, anima su movimiento y ayuda a seguir el cursor.

Hecho con [AutoHotkey v2](https://www.autohotkey.com/) para Windows.

## Funciones

La interfaz usa un tema oscuro de grises neutros, superficies grafito, texto claro
y acentos rojos. Las teclas conservan su relieve y animación de pulsación.

- **Teclas animadas:** bajan y pierden su sombra inferior al pulsarlas, como un teclado físico. El recorrido es de 6 píxeles al tamaño predeterminado, con una transición de 100 ms. Las pulsaciones rápidas permanecen hundidas al menos 180 ms para que se alcancen a ver.
- **Colores:** ámbar para teclas normales y rojo para modificadores (`Ctrl`, `Shift`, `Alt`, `Alt Gr` y `Win`). Al soltar una tecla, vuelve a subir y conserva el color brevemente.
- **Combinación actual e historial visual:** la línea «AHORA» muestra la acción reciente. Debajo, una franja independiente representa hasta cuatro teclas recientes como mini teclas: turquesa para teclas normales y violeta para modificadores, con colores y tamaños distintos del teclado principal. Los atajos se agrupan con signos `+`, los resultados con `⇒` y las repeticiones con `×N`.
- **Distribuciones Latinoamérica y España:** los símbolos escritos con **Alt Gr** aparecen en azul.
- **Mouse visual opcional:** cuerpo curvo, botones integrados y rueda central. Por defecto, los clics izquierdo, derecho y central se iluminan en rojo y el desplazamiento de la rueda se indica en azul; las flechas indican el sentido de desplazamiento. Ambos colores se pueden personalizar. Permite mostrar clics simultáneos.
- **Resplandor del cursor:** halo suave con color, diámetro y opacidad personalizables (amarillo por defecto) que sigue el puntero, sin impedir los clics ni cambiar el foco de la ventana activa. Se controla por separado del mouse visual.
- **Posición y tamaño ajustables:** arrastra el mostrador y cambia su tamaño desde sus bordes o esquinas, manteniendo las proporciones del teclado y del mouse visual. También puedes usar los atajos de tamaño o el modo de solo texto.

## Cómo usarlo

1. Instala [AutoHotkey v2](https://www.autohotkey.com/).
2. Descarga `mostrador-teclas.ahk` y `mostrador-seleccion.ahk` en la misma carpeta. Haz doble clic en `mostrador-teclas.ahk`.
3. El mostrador inicia **desbloqueado**, para que puedas arrastrarlo hasta donde prefieras. En el primer inicio aparece en la esquina inferior derecha; después utiliza la posición guardada.
4. Pulsa **Ctrl + Alt + L** para bloquearlo cuando esté en su sitio. Al bloquearlo, los clics atraviesan el mostrador.

Sin configuración previa, el mouse visual y el halo del cursor están activados. Puedes apagarlos de forma independiente; tu preferencia queda guardada.

El **autoocultado solo actúa cuando el mostrador está bloqueado** y esa opción está activada. Tras unos segundos sin actividad se oculta y vuelve a aparecer al pulsar una tecla o usar los botones o la rueda del mouse. Mientras está desbloqueado permanece visible para facilitar su colocación. El halo del cursor funciona independientemente del autoocultado.

## Personalizar el mouse y el aura

Pulsa **⚙ junto al botón de minimizar**, en la esquina superior derecha. También puedes abrir **Ajustes del mouse y aura...** desde la bandeja o hacer **clic derecho en el icono flotante ⌨** cuando esté minimizado.

Desde el panel puedes:

- Activar o desactivar el aura del cursor.
- Elegir su **color**, aumentar o reducir su **diámetro entre 40 y 240 píxeles** y ajustar su **opacidad entre 5 y 85 %**.
- Mostrar u ocultar el mouse visual del teclado.
- Cambiar por separado los colores del **cuerpo**, los **botones en reposo**, los **clics** y el **desplazamiento de la rueda** del mouse visual.

Cada campo tiene una muestra de color y un botón **Elegir color...** que abre el selector de Windows. También puedes escribir un código HEX, por ejemplo `FF8800` o `#FF8800`.

Pulsa **Aplicar** para ver y guardar los cambios. **Restablecer valores** carga los valores predeterminados en el formulario; pulsa Aplicar para guardarlos. Cerrar el panel sin aplicar descarta las modificaciones pendientes.

Los ajustes se conservan al reiniciar. Puedes personalizar el aura mientras el mostrador está minimizado, sin expandirlo.

## Minimizar y expandir

Pulsa el botón **− de la esquina superior derecha** para ocultar el teclado, el mouse visual y el historial. Quedará únicamente un pequeño icono flotante **⌨**: haz clic en él para expandir de nuevo el mostrador.

- También puedes usar **Ctrl + Alt + N** o **Minimizar / expandir** en el menú de la bandeja.
- El botón funciona aunque la posición del teclado esté bloqueada.
- El resplandor del cursor mantiene su estado: puedes dejar solo el halo y el icono en pantalla, o apagar el halo con **Ctrl + Alt + M**.
- Pulsar teclas, hacer clic o usar la rueda **no expande automáticamente** el mostrador. El historial sigue conservando únicamente las teclas recientes.
- Al expandir se mantienen el tamaño, la posición y las opciones elegidas. El modo minimizado dura hasta que lo expandas o cierres el programa; al volver a iniciar se abre expandido.

## Leer el historial

Usa **Ctrl + Alt + I** o la opción de la bandeja para **mostrar u ocultar** el historial. La preferencia queda guardada. Al ocultarlo desaparece la franja y el teclado aprovecha ese espacio; la línea de la combinación actual sigue disponible.

El teclado grande sigue usando **amarillo y rojo** para mostrar las pulsaciones. La franja **RECIENTES** usa teclas más pequeñas de color **turquesa y violeta**, para distinguir las acciones anteriores del teclado en vivo.

- Cada atajo mantiene sus teclas juntas, por ejemplo `[Ctrl] + [C]`.
- Las acciones se leen de **izquierda a derecha, de la más antigua a la más reciente**, separadas por `›`.
- Se conservan **hasta cuatro teclas en total**, contando también los modificadores: `Ctrl + C` ocupa dos lugares. Los atajos antiguos se retiran completos para no fragmentarlos. Si una combinación supera cuatro teclas, se conservan sus cuatro teclas finales.
- Las repeticiones consecutivas se agrupan, con un contador limitado a `×4`. Si no caben todas las entradas en pantalla, se priorizan las más recientes.
- `⇒` muestra el carácter producido y `×N` indica repeticiones consecutivas.
- Los avisos de tamaño, posición o modo se muestran aparte y no ocupan lugares del historial.
- En el modo **solo texto**, las mini teclas del historial se presentan en filas, sin el teclado grande.

## Cambiar el tamaño con el mouse

1. Desbloquea el mostrador con **Ctrl + Alt + L** si está bloqueado.
2. Acerca el cursor a cualquier borde o esquina del teclado: aparecerá una flecha de redimensionar.
3. Mantén pulsado el botón izquierdo y arrastra hacia fuera para agrandarlo o hacia dentro para reducirlo. Verás una vista previa proporcional mientras arrastras.
4. Suelta el botón para aplicar el tamaño y guardar la posición. Pulsa **Esc** antes de soltarlo si quieres cancelar el cambio.

El tamaño se limita al **60–250 %** y se conserva al volver a abrir el programa. El mouse visual cambia de tamaño junto con el teclado. Arrastrar desde el interior sigue sirviendo para mover el mostrador.

El cambio de tamaño desde el perímetro está disponible en el **modo teclado desbloqueado**. En el modo de solo texto puedes seguir usando **Ctrl + Alt + RePág / AvPág**.

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
| `Ctrl + Alt + N` | Minimizar / expandir el mostrador |
| `Ctrl + Alt + I` | Mostrar / ocultar el historial |
| `Ctrl + Alt + B` | Mostrar / ocultar el mouse visual |
| `Ctrl + Alt + M` | Activar / desactivar el resplandor del cursor |
| `Ctrl + Alt + S` | Activar / desactivar resaltado de selección |
| `Ctrl + Alt + A` | Entrar / salir del modo de anotaciones |
| `Ctrl + Alt + X` | Borrar todas las anotaciones |
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
| `[Historial]` | `Mostrar` | `1` | Historial: `1` visible, `0` oculto |
| `[Mouse]` | `MostrarVisual` | `1` | Mouse visual: `1` activado, `0` desactivado |
| `[Mouse]` | `Resplandor` | `1` | Halo del cursor: `1` activado, `0` desactivado |
| `[Mouse]` | `HaloTam` | `88` | Diámetro del aura en píxeles (40–240) |
| `[Mouse]` | `HaloColor` | `FFD600` | Color HEX del aura |
| `[Mouse]` | `HaloOpacidad` | `35` | Opacidad máxima del aura, en porcentaje (5–85) |
| `[Mouse]` | `ColorCuerpo` | `B6BEC7` | Color HEX del cuerpo del mouse visual |
| `[Mouse]` | `ColorBotones` | `E5E9ED` | Color HEX de los botones en reposo |
| `[Mouse]` | `ColorPulsado` | `FFD21F` | Color HEX del clic y la rueda pulsada |
| `[Mouse]` | `ColorRueda` | `5AB0FF` | Color HEX del desplazamiento de la rueda |

La duración de la animación de pulsación es independiente de `ResaltadoMs`.

## Limitaciones

- En ventanas que se ejecutan como administrador, puede ser necesario ejecutar también el mostrador como administrador para detectar las pulsaciones.
- La tecla `Fn` de las laptops no se puede detectar.
- El mouse visual representa los clics izquierdo, derecho y central, y la rueda vertical. Los botones laterales y la rueda horizontal aparecen en el historial de texto.


## Notas de clase

Pulsa **✎**, junto a ⚙ y minimizar, o **Ctrl + Alt + O** (del lado izquierdo).
Puedes escribir directamente sobre la nota, sin abrir ajustes. El texto se guarda
automáticamente tras una breve pausa; pulsa **✓** para terminar de editar.
También puedes hacer doble clic sobre el texto para editarlo.

La propia nota tiene estos controles:

| Control | Acción |
|---|---|
| ✎ / ✓ | Editar el texto / terminar y guardar |
| A− / A+ | Reducir / aumentar la letra en 2 puntos (entre 10 y 48) |
| − / pestaña NOTA | Guardar la nota detrás del teclado / desplegarla |
| × | Ocultar la nota sin borrarla |
| ⚙ | Colores, fuente, negrita, altura y espacios visibles |

El botón ✎ principal recupera una nota oculta y permite editarla. **Ctrl + Alt + T**
también muestra u oculta la nota. Los controles funcionan con el teclado bloqueado.
La nota acompaña al teclado al moverlo o cambiar su tamaño y se oculta al minimizar
todo el mostrador. La nota se expande hacia arriba y sus controles se quedan
junto al mostrador. El teclado conserva su posición. Durante la edición no se activa el ocultado automático.

Se usa una fuente monoespaciada (Consolas por defecto). En ⚙ puedes cambiar los colores
del texto y del fondo, elegir otra fuente, activar negrita y ajustar la altura de
1 a 8 líneas. Si el texto no cabe, aumenta las líneas o reduce la letra.
**Marcar espacios** representa cada espacio con `·` y cada tabulación con `→` durante
la lectura; al editar se muestra el texto original y se conservan todos los espacios.

Para mantener la nota visible fuera de la edición, desactiva el ocultado automático
con **Ctrl + Alt + H**. El contenido se guarda en `overlay-nota.txt` y la apariencia
en `overlay-config.ini`; ambos son locales y están excluidos de Git.


Si desconectas una pantalla extendida, el mostrador ajusta su posición a una pantalla
disponible. También comprueba la posición guardada al abrirse. Puedes recuperarlo
manualmente con **Ctrl izquierdo + Alt izquierdo + R**, que lo devuelve a la esquina
inferior derecha de la pantalla principal y lo expande si estaba minimizado.

Los antiguos colores predeterminados del mouse y de las notas se adaptan al nuevo
tema al cargar las preferencias. Los demás colores personalizados se conservan.


## Resaltado de selección de texto

Actívalo con **Ctrl izquierdo + Alt izquierdo + S** o desde la bandeja.
En **⚙ → Selección de texto** puedes activarlo y cambiar el fondo, las letras,
el color y grosor del contorno/sombra y la negrita. El estilo inicial usa fondo
amarillo, letras blancas y contorno negro pronunciado.

Se dibuja una capa sobre las líneas seleccionadas en la aplicación activa.
La capa deja pasar los clics, desaparece al cambiar de ventana o selección y puede
seguir activa con el mostrador minimizado. El modo se inicia desactivado hasta que
lo habilites; después recuerda tu preferencia.

La detección usa UI Automation de Windows. Funciona cuando la aplicación facilita
su selección y las posiciones del texto. La compatibilidad depende de cada navegador,
editor o lector PDF. Imágenes, documentos escaneados, controles de contraseñas y
aplicaciones sin TextPattern mantienen su selección habitual. La tipografía de la
capa se ajusta a los rectángulos disponibles, por lo que puede diferir de la original.
Procesa hasta cuatro rangos y 60 líneas visibles por actualización.

`mostrador-seleccion.ahk` es un componente en AutoHotkey v2 que se abre y cierra
desde el mostrador. Aísla las consultas de accesibilidad para que un proveedor lento
no bloquee el teclado. Ambos archivos deben permanecer juntos. El texto seleccionado
se procesa en memoria y las preferencias se guardan en `[Seleccion]` de `overlay-config.ini`.

Las notas usan una tarjeta de esquinas redondeadas, márgenes amplios y una barra
grafito con botones de mayor tamaño. Su contenido conserva la fuente, el tamaño y
los colores elegidos en ajustes, y sigue expandiéndose hacia arriba.

Al contraer la nota, sólo asoma una pequeña pestaña **▴ NOTA** centrada sobre el
mostrador. Púlsala para desplegar la tarjeta hacia arriba. La barra de edición
completa aparece con la tarjeta abierta.

Las notas abiertas tienen los controles en la esquina superior derecha, con
iconos de Windows y minimizar y cerrar al extremo derecho. Su fondo se sincroniza
con el teclado por defecto. Para elegir otro color, desmarca **Usar el mismo fondo
del teclado** en los ajustes de la nota y cambia **Fondo personalizado**.


## Anotaciones temporales sobre la pantalla

Pulsa el **botón azul de dibujo** junto a las notas, ⚙ y minimizar, o usa
**Ctrl izquierdo + Alt izquierdo + A**. Se abre una paleta flotante oscura con
herramientas, colores y acciones. Arrastra su cabecera para moverla.

- **Trazo, Flecha, Óvalo, Marco, Línea y Texto** para dibujar, subrayar o señalar un área.
- **Colores rápidos** y botones **− / +** para cambiar el grosor desde la paleta.
- **Deshacer y Rehacer**, también después de **Borrar todo**.
- **Volver** o **Esc** para salir del dibujo y usar las ventanas.
- **⚙** para elegir cualquier color y modificar la herramienta inicial y la duración.

Mientras el modo está activo, arrastra con el botón izquierdo para dibujar sobre
la pantalla. Las marcas permanecen en su posición aunque cambie el contenido de
las ventanas. La herramienta seleccionada se distingue con un acento rojo.

| Control | Acción |
|---|---|
| `1`, `2`, `3`, `4`, `5`, `6` en modo dibujo | Trazo, flecha, óvalo, marco, línea y texto |
| `Ctrl + Z` o clic derecho en el lienzo | Deshacer |
| `Ctrl + Y` en modo dibujo | Rehacer |
| `Supr` en modo dibujo | Borrar todos los dibujos |
| `Esc` o Volver | Salir del modo dibujo |
| `Ctrl izquierdo + Alt izquierdo + X` | Borrar también fuera del modo dibujo |

Cada dibujo desaparece **8 segundos** después de terminarlo por defecto. Puedes
ajustar esa duración en **⚙ → Ajustes de anotaciones**. Una duración de **0** conserva
las marcas hasta borrarlas. Al deshacer o rehacer se renueva la duración de las
marcas restauradas. El nuevo color y grosor se aplican a los dibujos siguientes.

Las preferencias se guardan en `[Anotaciones]` de `overlay-config.ini`. Los dibujos
y su historial permanecen en memoria. Al cerrar el programa o cambiar la distribución
de pantallas se borran. El modo funciona también con el teclado minimizado y cubre
las pantallas conectadas.


### Escribir texto sobre la pantalla

Elige **Aa Texto** o pulsa **6** en modo dibujo. Los botones **− / +** de la paleta
ajustan entonces el tamaño de letra. Pulsa donde quieras colocar la anotación y
escribe en el editor oscuro. Puedes usar varias líneas y cambiar el tamaño y la
negrita. Pulsa **Insertar** o **Ctrl + Enter** para colocarla, o **Esc** para cancelar.
Mientras escribes, los atajos de dibujo se suspenden para permitir editar el texto.

La anotación usa el color elegido en la paleta, una sombra oscura y la duración
configurada. El tiempo empieza al insertarla. Puedes deshacerla, rehacerla o borrarla
como cualquier otro dibujo. Cerca del borde se ajusta su posición para mantenerla
visible en la pantalla donde pulsaste. El tamaño y la negrita también se guardan
desde los ajustes de anotaciones.
