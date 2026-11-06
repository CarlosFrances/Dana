# El juego de Dana ♥

Juego para móvil hecho con **Godot 4.3** (renderizador *Mobile*, orientación vertical).
Es el clásico puzle deslizante: la foto se corta en piezas, se quita una, se
desordenan y hay que usar el hueco para volver a formar la foto.

## Cómo abrirlo

1. Clona/copia esta carpeta en `D:\proyectos\El juego de Dana`.
2. Abre Godot 4.3 (o superior) → **Importar** → selecciona `project.godot`.
3. Pulsa **F5** para jugarlo en el PC (el ratón simula el dedo).

## Cómo jugar

- Elige la dificultad (3x3, 4x4 o 5x5) y pulsa **Jugar**.
- Elige una foto.
- **Toca** una pieza que esté en la misma fila o columna que el hueco para
  deslizarla (si hay varias en medio, se mueven todas), o **desliza el dedo**
  en una dirección.
- **Ver foto**: mantenlo pulsado para ver la foto original.
- **Números**: muestra el número de cada pieza como ayuda.
- Al completarlo aparece la pieza que faltaba, lluvia de corazones y se guarda
  tu récord (movimientos y tiempo) por foto y dificultad.

## Cambiar las fotos

Mete las imágenes en `assets/photos/` (`.png`, `.jpg`, `.jpeg` o `.webp`).
El juego las detecta solas y las ordena por nombre (`foto_01.png`, `foto_02.png`...).
Se recorta automáticamente un cuadrado del centro de cada foto, así que lo
mejor es que lo importante esté centrado. Las tres que hay ahora son de
relleno.

## Exportar a Android

1. En Godot: **Editor → Gestionar plantillas de exportación** → descargar.
2. **Editor → Configuración del editor → Exportar → Android**: indica el SDK
   de Android y el keystore de depuración.
3. **Proyecto → Exportar → Añadir… → Android** → Exportar proyecto (`.apk`).

## Estructura

```
project.godot
icon.svg                     icono (corazón + puzle)
scenes/                      main_menu, photo_select, puzzle
scripts/game_state.gd        autoload "Game": ajustes, récords, utilidades de estilo
scripts/heart_background.gd  fondo con corazones flotando
scripts/main_menu.gd         menú principal
scripts/photo_select.gd      selección de foto
scripts/puzzle.gd            lógica del puzle deslizante
scripts/tile.gd              dibujo de cada pieza
assets/photos/               fotos del puzle
```
