# Revisión del parser de daml-lint

Versión revisada: `cba698832991f640f0e0d8a9e2bfb683717c6024`, la fijada por este proyecto. No se verificó si estos problemas están resueltos en otras versiones.

El parser invoca tree-sitter pero descarta el árbol (`parser.rs:16`). La extracción real usa texto, prefijos e indentación. Los ejemplos listados compilaron con Daml SDK 3.5.2. Los resultados corresponden al binario original, sin modificarlo. “HIGH/MEDIUM” indica la severidad del finding ocultado, no una clasificación del bug del parser.

| Caso | Control → variante | Efecto confirmado | Ubicación |
|---|---|---|---|
| Prefijos en parámetros de choice | `recipient` → `donor` o `controllerParty`, antes de `amount : Decimal` | 1 HIGH → 0; omite amount sin validación | parser.rs:381–382 |
| Espacios alrededor del separador | `payload : Text` → `payload: Text` | 1 MEDIUM → 0 | parser.rs:200–203 |
| `with` en la cabecera | `template T` seguido de `with` → `template T with` | 1 MEDIUM → 0; omite campos | parser.rs:181 |
| Comentario al final del tipo | `payload : Text` → `payload : Text -- comentario` | 1 MEDIUM → 0; tipo pasa a Unknown | parser.rs:209 e ir.rs:31–63 |
| Tipo en otra línea | `payload : Text` → `payload :` y `Text` en la siguiente línea | 1 MEDIUM → 0 | parser.rs:200–209 |
| Comentario sin indentación dentro del template | insertar comentario en columna cero antes de payload | 1 MEDIUM → 0; corta el template | parser.rs:112–115 |
| Código dentro de comentario de bloque | un template comentado produce 1 MEDIUM falso; un ensure comentado silencia 1 MEDIUM real | ambos confirmados | parser.rs:84–89 y 244–266 |
| Definición con `=` en otra línea | `divide x y = x / y` → `divide x y` seguido de `  = x / y` | 1 HIGH → 0; omite función | parser.rs:573–587 |

El problema conocido de `observers` también afecta nombres como `keyData`: es la misma raíz en parser.rs:189–195, no otro bug independiente. La omisión de funciones con guards es una limitación adicional ya detectada antes, relacionada con el reconocimiento incompleto de definiciones.

## Reproducciones

Los ejemplos incorporados al repositorio están en las subcarpetas de `lint-bugs/`:

- [Prefijos de palabras clave](keyword-prefix/KeywordPrefix.daml): `observers` frente a `watchers`.
- [Comentarios de bloque](block-comments/BlockComments.daml): un `ensure` comentado silencia un finding real.
- [Espacios alrededor de `:`](colon-spacing/ColonSpacing.daml).
- [`with` en la cabecera](inline-with/InlineWith.daml).

Los demás casos de la tabla se confirmaron en paquetes temporales durante la revisión;
sus reproducciones todavía no están incorporadas al repositorio. La omisión de funciones
con guards se confirmó en una revisión anterior.

Las instrucciones para ejecutar todos los ejemplos o uno en particular están en el
[README](README.md).

## Correcciones sugeridas

1. Comparar palabras clave completas; `do` no debe coincidir con `donor`. Identificar primero las declaraciones de campos, respetando su contexto.
2. Reconocer el separador `:` sin exigir exactamente un espacio a cada lado y reunir declaraciones que ocupan varias líneas.
3. Reconocer `with` en la cabecera de template.
4. Usar un lexer que descarte comentarios de línea y de bloque, incluidos bloques anidados, preservando saltos de línea y posiciones. No eliminar comentarios con una regex que pueda consumir strings. Mantener separado el procesamiento de anotaciones `daml-lint: allow` reales.
5. Calcular límites de bloques sobre tokens de código; los comentarios no terminan templates ni funciones.
6. Reconocer definiciones de función completas, incluidos guards y `=` en otra línea.
7. Agregar regresiones basadas en cada par control/variante: misma semántica debe producir mismos findings; código comentado no debe producir ni silenciar findings. Incluir comprobación con el compilador Daml para garantizar que las entradas sean válidas.

La revisión se hizo sin modificar el código del linter. Los ejemplos se compilaron en paquetes temporales; las reproducciones incorporadas al repositorio se enumeran arriba.
