# Codex Provider Switcher

<p align="center">
  <img src="https://raw.githubusercontent.com/GL-Technologies/codex-provider-switcher/main/docs/app-icon.png" width="112" alt="Codex Provider Switcher icon">
</p>

<p align="center">
  <a href="../../README.md">English</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · Español
</p>

Una utilidad nativa para macOS que permite cambiar Codex entre OpenAI y varios proveedores compatibles con OpenAI. Las API que solo ofrecen Chat Completions pueden usarse mediante un puente local compatible con Responses.

> Este proyecto no está afiliado ni respaldado por OpenAI ni por las marcas de proveedores mostradas en la aplicación.

## Funciones principales

- Cambio con un clic entre OpenAI y múltiples proveedores guardados.
- **Auto Bridge** activado de forma predeterminada.
- Detección automática de Responses API y Chat Completions.
- Descubrimiento de modelos mediante endpoints `/models` compatibles.
- Conversión de funciones, herramientas custom/freeform de Codex, tool search, namespaces, reasoning habitual y metadatos de uso.
- Control permanente desde la barra de menús de macOS para cambiar de proveedor, revisar el estado del puente, abrir Ajustes o salir.
- Restauración automática del puente al volver a abrir la app si Codex sigue apuntando a localhost.
- Copias de seguridad antes de modificar `~/.codex/config.toml` y `~/.codex/.env`.
- Interfaz nativa SwiftUI con modo claro y oscuro.

## Cómo funciona

```text
Proveedor con Responses nativo
Codex ─────────────────────────────→ Provider /responses

Proveedor solo Chat Completions
Codex → localhost Responses Bridge → Provider /chat/completions
```

El puente escucha únicamente en localhost. Cerrar la ventana principal no detiene el servicio; el icono de la barra de menús mantiene la aplicación activa. El puente se detiene al salir completamente de la app.

## Inicio rápido

1. Pulsa **Add Provider** e introduce Base URL, modelo y API Key. El nombre puede dejarse vacío para generarlo automáticamente.
2. Usa **Find Models** si el proveedor expone un endpoint `/models` compatible.
3. Ejecuta **Test Connection**. La app prueba primero Responses y después Chat Completions.
4. Pulsa **Use**.
   - Los proveedores con Responses se conectan directamente.
   - Los proveedores solo Chat Completions usan Auto Bridge automáticamente cuando está activado.
5. Reinicia Codex cuando se indique.
6. Después podrás cambiar rápidamente de proveedor desde la barra de menús.
7. Para volver a la configuración oficial, elige OpenAI → **Use OpenAI**.

## Instalación

Descarga la versión más reciente desde **Releases**, descomprímela y mueve **Codex Provider Switcher.app** a Applications.

La compilación pública actual usa firma ad-hoc. Si macOS bloquea el primer inicio, intenta abrir la app una vez y después ve a **Ajustes del Sistema → Privacidad y seguridad** y selecciona **Abrir de todos modos**.

## Credenciales y datos

Las API Key se guardan en:

```text
~/.codex/provider-switcher/credentials.json
```

El archivo usa permisos `0600` y el directorio de estado `0700`. La configuración de proveedores y las copias de seguridad también se almacenan en `~/.codex/provider-switcher/`.

Consulta [docs/BRIDGE.md](../BRIDGE.md) para conocer la arquitectura y los límites del puente.

## License

MIT © 2026 GL-Technologies.
