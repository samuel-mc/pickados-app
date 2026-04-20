# pickados_app

Base movil en Flutter creada a partir de la experiencia web existente en `picka2`.

## Estado actual

Esta primera migracion ya incluye:

- login real contra `POST /auth/login`
- restauracion de sesion con `GET /auth/session`
- feed principal con `GET /posts/feed`
- guardados con `GET /posts/saved`
- perfil propio con `GET /me/profile`
- acciones basicas de reaccion y guardado
- detalle de post con comentarios
- composer movil para analisis, pick simple y parley

## Arquitectura

La app quedo organizada en:

- `lib/src/app`: bootstrap y tema
- `lib/src/services`: cliente HTTP y manejo de cookie de sesion
- `lib/src/features/auth`: login y estado de sesion
- `lib/src/features/feed`: feed y cards de post
- `lib/src/features/profile`: perfil propio
- `lib/src/features/posts`: creacion y detalle de post

## Ejecutar

Instala dependencias:

```bash
flutter pub get
```

Corre la app apuntando al backend:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8080
```

Si pruebas en emulador Android, normalmente necesitas:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Si pruebas en dispositivo fisico, usa la IP local de tu maquina:

```bash
flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:8080
```

## Deep Links

La app ya reconoce links con esquema custom:

```text
pickados://posts/123
pickados://posts/123?commentId=456
pickados://perfil/77
pickados://tipster/perfil/77
```

La configuración base para ese esquema quedó en Android e iOS. Los universal links HTTP(S) todavía no están configurados.

## Universal Links

El parser interno ya soporta rutas HTTP(S) de posts y perfiles, pero la activación real de universal links todavía depende de:

- dominio público final
- `applicationId` Android final
- bundle identifier iOS final
- Team ID Apple
- certificado release Android

La guía y plantillas quedaron en:

- `docs/universal-links/README.md`
- `docs/universal-links/assetlinks.json.template`
- `docs/universal-links/apple-app-site-association.template`

## Siguientes pasos sugeridos

- migrar edicion de perfil
- agregar replies, likes de comentario y subida de imagen
- homologar catalogos y flujos de creacion de picks/parleys
# pickados-app
