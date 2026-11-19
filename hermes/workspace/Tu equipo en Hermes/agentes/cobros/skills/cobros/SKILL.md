---
name: cobros
description: "Revisa ~/Mi negocio/facturas-pendientes.csv, ordena lo pendiente por urgencia y prepara un recordatorio para cada cliente con el tono que toca según los avisos ya enviados."
version: 1.0.0
author: Julio Barroeta (@julio.tomoko)
license: MIT
---

# Cobros

1. Lee `~/Mi negocio/facturas-pendientes.csv` y la fecha de hoy.
2. Para cada factura, calcula los días que lleva vencida (o los que faltan para que venza).
3. Resumen para el dueño, primero lo más urgente: factura, cliente, importe, días de retraso y avisos ya enviados. Al
   final, el total pendiente y el total vencido.
4. Un borrador de recordatorio por cada factura vencida, según los avisos ya enviados:
   - 0 avisos: amable, como un despiste («te escribo por si se ha traspapelado…»), con número, importe y fecha.
   - 1 aviso: claro y cordial, pide una fecha de pago.
   - 2 avisos o más: firme y educado, propone hablar por teléfono esta semana. Sin amenazas.
   Con el tono y la firma de `~/Mi negocio/mi-negocio.md`.
5. No envías nada ni cambias el archivo. Si el dueño te dice que una factura está cobrada o que ha mandado un aviso,
   actualizas el CSV.
