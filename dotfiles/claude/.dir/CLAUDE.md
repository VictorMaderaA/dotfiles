# Preferencias globales de trabajo

## Lenguaje y estilo de comunicación

- Responde en **español** por defecto.
- Prefiere explicaciones concisas y prácticas, con ejemplos solo cuando aporten claridad real.
- Cuando propongas comandos o cambios de ficheros, indica siempre **qué hace** y **posibles riesgos** antes de ejecutarlo.

## Estilo de código general

- Prefiere **TypeScript** estricto, evitando `any` salvo casos muy justificados.
- Sigue buenas prácticas de **Angular** (componentes “smart/dumb”, OnPush, trackBy, evitar lógica pesada en templates).
- En monorepos **Nx**, respeta boundaries entre libs/apps, usa tags, y sugiere refactors que reduzcan coupling.
- Al escribir tests, favorece:
    - Tests rápidos y deterministas.
    - Nombres descriptivos.
    - Cobertura de casos límite relevantes, no solo happy path.

## Uso eficiente del contexto y tokens

- Evita leer archivos enormes o generados automáticamente (`node_modules`, `dist`, `build`, `.git`, logs grandes) salvo que el usuario lo pida explícitamente.
- Cuando necesites contexto de un archivo grande, intenta:
    - Leer solo las secciones relevantes (p.ej. funciones o componentes que mencione el usuario).
    - Resumirlo antes de usarlo, en lugar de mantenerlo íntegro en el contexto.
- No pegues logs completos; resume puntos clave y ofrece el detalle solo si el usuario lo solicita.

## Cambios en el código

- Prefiere cambios **incrementales y seguros**:
    - Explica el plan antes de hacer cambios grandes.
    - Intenta modificar solo lo necesario para resolver el problema descrito.
- Cuando propongas refactors en Angular/Nx:
    - Señala el impacto en imports, rutas, tests y configuración de Nx.
    - Sugiere comandos (`nx g`, `nx move`, etc.) cuando tenga sentido, con explicación de efectos.

## Entornos Linux / WSL / Ubuntu

- Asume que los proyectos se ejecutan en entornos tipo Linux (Ubuntu, WSL2) con herramientas habituales de CLI.
- Cuando propongas herramientas adicionales (`jq`, `direnv`, `prettier` global, etc.), incluye el comando de instalación recomendado.
- Ten en cuenta posibles diferencias de rutas entre Windows y WSL y prefiera rutas POSIX cuando sea posible.