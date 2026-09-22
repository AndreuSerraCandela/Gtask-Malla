# Task Malla — guía para el agente

Extensión **Business Central OnPrem** (BC 27) que amplía **Malla Wave 2.0**. Publisher: Andreu By Malla.

## Repos relacionados

| Repo | Ruta local | Rol |
|------|------------|-----|
| **Task Malla** (este) | `C:\Users\Andres\Source\Bc\Gtask-Malla` | Tareas / Task Malla |
| **Funciones** | `C:\Users\Andres\Source\Bc\Funciones` | Extensiones, páginas, informes sobre tablas Malla |
| **Malla Wave 2.0** | `C:\Users\Andres\Source\Bc\MallaWaweBc270` | App base: tablas, objetos core |
| **Utilidades** | `C:\Users\Andres\Source\Bc\Utilidades` | Utilidades Malla |
| **MyBeLic** | `C:\Users\Andres\Source\Python\MyBeLic` | Panel y API en `https://license.malla.es` |
| **MyBeLic Publish Runner** | `C:\Users\Andres\Source\Python\MyBeLicPublishRunner` | Demonio bandeja → crea tareas publish/upgrade |
| **MgtExtBc** | `C:\Users\Andres\Source\Bc\MgtExtBc` | Codeunit OData para publicar en BC on-prem |
| **Objetos BC** | `C:\Users\Andres\Source\Python\Objetos` | Reserva IDs en `objetos.malla.es` |

App id Task Malla: `366ac4b9-199a-4725-a5f2-9bead2fe08b5`  
Cliente MyBeLic Malla (por defecto): `4e27c722-48a2-4228-81c6-3317d20f98b1`

## Cuando el usuario pida compilar, subir versión o publicar en license

Interpretar frases como: *compila*, *sube versión*, *publica en license*, *copia a Malla*, *deploy MyBeLic*.

### 1. Subir versión

- Editar `aapp.json` → campo `version` (patch: `1.0.4.8` → `1.0.4.9`).
- Si cambian las dependencias, actualizar también su versión en `dependencies` y el `.app` en `.alpackages/`.

### 2. Compilar

**No** invocar `alc.exe` sin `/assemblyprobingpaths`: fallan los DotNet de `CompantInfo.Al` (`AL0185`). Las rutas están en `.vscode/settings.json` → `al.assemblyProbingPaths` (`.netpackages`, `C:\net`); el script `.vscode/Build-And-CopyAppToMalla.ps1` ya las aplica.

**Solo compilar** (sin copiar al buzón / sin publicar):

```powershell
powershell -ExecutionPolicy Bypass -File ".vscode\Build-And-CopyAppToMalla.ps1" -WorkspaceFolder "C:\Users\Andres\Source\Bc\Gtask-Malla" -CompileOnly
```

Alternativa: Ctrl+Shift+B en el IDE (AL: Package). El agente **no** debe llamar a `alc` sin `/assemblyprobingpaths`.

El `.app` se genera en la raíz: `Andreu By Malla_Task Malla_{version}.app`.

### 3. Publicar (elegir **una** vía — nunca ambas)

**Regla crítica:** el **MyBeLic Publish Runner** vigila el buzón (p. ej. `C:\apps\Malla`). **Cada copia de un `.app` al buzón dispara tareas de publicación.** No copiar dos veces el mismo fichero ni combinar buzón + API para el mismo despliegue.

#### Vía A — Buzón (actual, script existente)

Una sola copia con `.vscode/Build-And-CopyAppToMalla.ps1`:

```powershell
powershell -ExecutionPolicy Bypass -File ".vscode\Build-And-CopyAppToMalla.ps1" -WorkspaceFolder "C:\Users\Andres\Source\Bc\Gtask-Malla"
```

- Destino: `C:\apps\Malla`
- El runner crea tarea **publish** (`auto_schedule`) y, si la versión es mayor que el catálogo MyBeLic (on-prem), **upgrade** +5 min después.
- **No** volver a copiar si el script ya respondió OK. **No** hacer copia manual de verificación.

#### Vía B — API MyBeLic (alternativa, sin buzón)

Documentación: `Python\MyBeLic\API.md`. Misma lógica que el runner (`processor.py`).

1. Cabecera: `X-MyBeLic-Token` (valor en `mybelic.env` / `publish_runner.env`; **no commitear**).
2. `POST /api/v1/admin/customers/{customer_id}/tasks` — `action=publish`, `auto_schedule=true`, multipart `app_file`.
3. Si versión nueva y cliente on-prem: `POST` — `action=upgrade`, mismo `.app`, `run_at` = publish + 5 min.
4. Opcional: `PATCH .../applications/{record_id}` con la nueva versión en catálogo.
5. Verificar: `GET /api/v1/admin/customers/{customer_id}/tasks`.

Si se usa la API, **no** copiar al buzón.

### 4. Orden si hay más apps

1. **Malla Wave 2.0** (base) — compilar, publicar.
2. Extensiones dependientes en orden (p. ej. **Funciones**, luego **Task Malla**) — actualizar dependencia en `app.json`, compilar, publicar.

### 5. Cambios en tablas base

Si el campo/objeto vive en Malla: modificar `MallaWaweBc270`, subir versión Malla, compilar, publicar Malla, copiar `.app` a `.alpackages` de esta extensión, luego compilar y publicar **Task Malla**.

## IDs de objetos nuevos

Ver `.cursor/rules/bc-object-ids.mdc`. No inventar IDs; reservar en `objetos.malla.es`. Extensión en URL: `Task Malla` (name de `aapp.json`).

## Convenciones de código

- Responder al usuario en **español**.
- Cambios mínimos; no commitear salvo petición explícita.
- No subir `.app`, `.alpackages` ni tokens al repositorio sin que lo pidan.
- Preprocessor: `CLEAN27`.

## Comandos útiles

| Acción | Comando / archivo |
|--------|-------------------|
| Copiar .app al buzón | `.vscode/Build-And-CopyAppToMalla.ps1` |
| Tarea VS Code | *Copiar .app a Malla* en `tasks.json` |
| Debug BC local | `.vscode/launch.json` → `local` (BC270) |
| API tareas MyBeLic | `GET .../api/v1/admin/customers/{id}/tasks` |

## Pendiente / mejora futura

Script `Schedule-AppToMyBeLic.ps1` (API directa + comprobación de tareas) y regla `.cursor/rules/mybelic-publish.mdc` — aún no creados; priorizar buzón único hasta entonces.
