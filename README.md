# ManaTools

ManaTools es un addon de World of Warcraft orientado a calidad de vida. Reúne múltiples utilidades bajo un mismo panel de configuración y un namespace compartido.

## Características principales

- NoWasteCoin: activa la Bonus Roll actual sin depender de la instancia o dificultad.
- CinematicSkip: omite cinemáticas, películas y talking heads.
- NoInfo: oculta tooltips innecesarios y permite modo de inspección con valor de Mythic+.
- ChatCopy: añade una ventana para copiar el contenido del chat general.
- QueueAutoAccept: acepta invitaciones y comprobaciones de roles de cola automáticamente.
- Permalogging: mantiene activo el combat log mientras está habilitado.

## Estado del proyecto

- Lenguaje: Lua
- Interface: 120100 / 120150
- Versión: 1.1.0
- Autor: Seikarii
- Variables guardadas: ManaToolsDB
- Punto de entrada: Bootstrap.lua
- Orden de carga: definida por ManaTools.toc

## Instalación

1. Descarga o clona este repositorio en tu carpeta de addons de WoW.
2. Asegúrate de que la estructura quede dentro de:
   `World of Warcraft/_retail_/Interface/AddOns/ManaTools`
3. Reinicia WoW o recarga la interfaz.
4. En la pestaña de addons, el panel de configuración aparecerá como "ManaTools".

## Estructura del addon

```text
ManaTools/
├── Bootstrap.lua
├── ManaTools.toc
├── Options.lua
├── SlashCmd.lua
├── ChatCopy/
│   └── ChatCopy.lua
├── CinematicSkip/
│   ├── cinematicskip.lua
│   └── profesionskip.lua
├── NoInfo/
│   └── NoInfo.lua
├── NoWasteCoin/
│   └── NoWasteCoin.lua
├── Permalogging/
│   └── Permalogging.lua
├── QueueAutoAccept/
│   ├── AutoInvite.lua
│   └── QueueAutoAccept.lua
├── test/
│   ├── mockwow.lua
│   ├── test_all.lua
│   ├── test_chat_copy.lua
│   ├── test_cinematic_skip.lua
│   ├── test_mana_coin.lua
│   ├── test_no_info.lua
│   ├── test_no_waste_coin_behavior.lua
│   ├── test_permalogging.lua
│   ├── test_profession_skip.lua
│   └── test_queue_auto_accept.lua
├── LICENSE
├── README.md
└── test/perf/
    └── benchmark.lua
```

## Orden de carga

El addon se carga en este orden desde ManaTools.toc:

1. Bootstrap.lua
2. NoWasteCoin/NoWasteCoin.lua
3. CinematicSkip/cinematicskip.lua
4. CinematicSkip/profesionskip.lua
5. NoInfo/NoInfo.lua
6. ChatCopy/ChatCopy.lua
7. Permalogging/Permalogging.lua
8. QueueAutoAccept/AutoInvite.lua
9. QueueAutoAccept/QueueAutoAccept.lua
10. Options.lua
11. SlashCmd.lua

Bootstrap se ejecuta antes que los módulos para preparar el namespace y la base de datos compartida.

## Configuración y comandos

El addon crea una categoría llamada ManaTools en la configuración del juego. Desde allí puedes activar o desactivar cada módulo individualmente:

- Cinematic Skip
- NoInfo
- Chat Copy
- Queue Auto Accept
- Permalogging

### Comandos disponibles

```text
/mana
```
Abre la configuración de ManaTools.

```text
/coin
```
Activa la Bonus Roll actual si hay una abierta.

```text
/copy
```
Activa o desactiva Chat Copy.

## Base de datos y namespaces

Se usa un namespace compartido:

```lua
ManaTools
ManaTools.DB
```

La base de datos persistente se guarda en:

```lua
ManaToolsDB
```

Y cada módulo se inicializa dentro del namespace principal, por ejemplo:

```lua
ManaTools.NoWasteCoin
ManaTools.CinematicSkip
ManaTools.NoInfo
ManaTools.ChatCopy
ManaTools.QueueAutoAccept
ManaTools.Permalogging
```

## Descripción rápida de cada módulo

### NoWasteCoin

Permite desbloquear la Bonus Roll actual con un comando manual cuando una tirada está activa. Es útil para evitar que el sistema te impida gastar el roll actual.

### CinematicSkip

Se encarga de cancelar o ocultar bloqueos visuales como cinemáticas, películas y talking heads, según el evento que se produzca.

### NoInfo

Oculta tooltips no esenciales y ofrece modos de inspección para mostrar información de Mythic+ cuando se necesita.

### ChatCopy

Añade una ventana emergente para copiar el contenido del chat general sin depender de una tercera herramienta externa.

### QueueAutoAccept

Acepta automáticamente invitaciones de grupo y comprobaciones de roles compatibles con la cola actual, siempre que la lógica pueda determinar una opción válida.

### Permalogging

Mantiene el combat log activo a lo largo de la sesión, útil para conservar registros de combate aunque el juego o el estado del usuario lo desactive.

## Testing

El repositorio incluye pruebas Lua con un entorno mock de WoW para validar cada módulo. Se pueden ejecutar individualmente o en conjunto:

```bash
lua test/test_queue_auto_accept.lua
lua test/test_all.lua
```

La suite completa verifica los principales módulos del addon antes de aceptar cambios de comportamiento.

## Compatibilidad

Este addon depende de APIs del cliente de WoW, como:

- CreateFrame
- GameTooltip
- BonusRollFrame
- C_PlayerInfo
- Settings
- InterfaceOptions_AddCategory
- eventos de WoW y scripts asociados

## Licencia

Este proyecto se distribuye bajo la licencia incluida en LICENSE.
