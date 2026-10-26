# Ecos de Nara

Videojuego narrativo 2D de exploración y aprendizaje contextual de alemán. El jugador elige ser forastero o forastera, despierta sin recuerdos en un pueblo aislado y utiliza una libreta para descifrar una carta escrita en alemán.

## Tecnología

- Motor: Godot Engine **4.7.2-stable Standard**.
- Lenguaje: GDScript.
- Renderizador: Compatibility.
- Publicación objetivo: exportación Web para itch.io.

## Ejecutar el proyecto

1. Instalar Godot Engine 4.7.2-stable Standard y sus plantillas de exportación.
2. Abrir el archivo `project.godot` con Godot.
3. Ejecutar el proyecto con `F5` o el botón de reproducción.

## Controles previstos

| Acción | Tecla |
|---|---|
| Mover arriba | W |
| Mover abajo | S |
| Mover izquierda | A |
| Mover derecha | D |
| Interactuar | E |
| Abrir libreta | N |
| Pausa | Esc |

## Estructura inicial

```text
assets/      Recursos visuales, audio y fuentes.
scenes/      Escenas de Godot: mundo, jugador, NPC e interfaz.
scripts/     Lógica GDScript organizada por responsabilidad.
data/        Diálogos, vocabulario y progreso narrativo en JSON.
tests/       Escenas y scripts de prueba.
```

## Flujo de trabajo

El desarrollo sigue las secciones de `PLAN_DESARROLLO_PARA_AGENTE.md`. Cada sección se implementa, se prueba y se revisa antes de crear manualmente el commit correspondiente. El agente no debe hacer commits ni iniciar la siguiente sección sin autorización explícita.
