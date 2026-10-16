# MILAN iOS

Aplicación nativa en Swift 6 y SwiftUI, con MVVM sencilla y compatibilidad mínima con iOS 18.2. Sin dependencias externas. El catálogo y las imágenes están incluidos en la aplicación. Autenticación, carrito y órdenes viven exclusivamente en memoria. Cerrar sesión elimina esos datos y un nuevo proceso inicia anónimo y vacío.

## Abrir y ejecutar

Abrir `MILAN.xcodeproj`, elegir el esquema compartido **MILAN** y el simulador **iPhone 16 Pro (iOS 18.2)**. Compilar con ⌘B, ejecutar con ⌘R y probar con ⌘U. La implementación se valida con Xcode 27.1. Para ejecutar en un dispositivo físico será necesario configurar el equipo de firma en Xcode.

El diseño definitivo del App Icon está pendiente y no se ha inventado uno. La interfaz usa la tipografía del sistema de Apple, español de México y precios MXN sin cambiar los valores semilla.

## Estructura

- `MILAN/MilanApp.swift`: punto de entrada y carga del catálogo empaquetado.
- `MILAN/Models/`: catálogo, carrito, instantáneas de órdenes, validaciones y aritmética `Decimal`.
- `MILAN/ViewModels/`: estado observable de catálogo, carrito y sesión/compra en el actor principal.
- `MILAN/Views/`: catálogo, filtros, carrito, acceso, revisión, confirmación, órdenes y detalle.
- `MILAN/Resources/catalog.json`: doce productos; los precios son cadenas decimales exactas.
- `MILAN/Resources/Assets.xcassets/`: doce imágenes, logotipo y panorama originales.
- `MILANTests/`: pruebas unitarias de catálogo, carrito, dinero, sesión, compra y órdenes.
- `MILANUITests/`: pruebas de navegación pública, filtros, carrito, acceso, compra, órdenes, cierre y reinicio.
- `MILAN.xcodeproj/xcshareddata/xcschemes/MILAN.xcscheme`: esquema compartido de compilación y pruebas.

## Uso

Aplicar filtros por Marca y Tipo; avanzar o retroceder entre páginas de diez productos. Agregar un producto abre el carrito. Las cantidades editadas se confirman con **Actualizar** o automáticamente al pulsar **Finalizar compra**, tras validarlas todas antes de aplicar cambios; cero elimina el artículo. **Seguir comprando** conserva filtros y página. Los importes reflejan el estado confirmado, no el borrador. Catálogo y carrito son públicos. **Finalizar compra** solicita acceso solo si falta sesión y después retoma la revisión con el mismo carrito. Cancelar el acceso regresa al carrito sin perderlo. **Pagar ahora** confirma una simulación sin cargo real, registra una orden y vacía el carrito. **Mis órdenes** permite consultar compras y detalles de la sesión; **Cerrar sesión** borra identidad, carrito e historial. No hay búsqueda por texto, ficha de producto, registro, recuperación ni pago real.

Cuentas locales de demostración: `cliente@doceolab.com` y `admin@doceolab.com`, ambas con contraseña `Pass@word1`. Se comparan literalmente. El usuario admin no tiene funciones de administración adicionales. El menú **Sesión** permite acceder voluntariamente, consultar órdenes y cerrar sesión.

## Verificación por terminal

```sh
xcodebuild -project MILAN.xcodeproj -scheme MILAN -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  -derivedDataPath /tmp/MILANDerivedData build CODE_SIGNING_ALLOWED=NO

xcodebuild -project MILAN.xcodeproj -scheme MILAN -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.2' \
  -derivedDataPath /tmp/MILANDerivedData test CODE_SIGNING_ALLOWED=NO
```

Los resultados ejecutados y las limitaciones se documentan en `VERIFICACION_MILAN_IOS.md`. Los logs y productos de compilación se mantienen fuera del repositorio. No se requiere un generador de proyectos ni instalar paquetes.

## Referencia y contrato

`CONTRATO_MILAN_IOS.md` conserva la especificación aprobada. Sus restricciones de no crear Swift/Xcode describen la etapa de elaboración del contrato; la solicitud posterior de implementación autoriza esta etapa. No se modifica el contrato ni se amplía su alcance funcional.

Los datos y recursos provienen de `../milan-mct`, tratado exclusivamente como fuente de lectura. `NOTICE.md` conserva el aviso de licencia de la referencia. No se realizan commits ni publicación en GitHub.
