---
name: presupuesto
description: "Calcula un presupuesto con las tarifas del negocio (~/Mi negocio/tarifas.md) y prepara la respuesta al cliente. Úsala siempre que alguien pida precio o presupuesto."
version: 1.0.0
author: Julio Barroeta (@julio.tomoko)
license: MIT
---

# Presupuesto

1. Lee `~/Mi negocio/tarifas.md` entero. Trabaja solo con lo que pone ahí.
2. Saca de la petición los datos que necesitan las tarifas (por ejemplo: fecha, cantidad, servicio, lugar). Si falta
   alguno que cambia el precio, pregúntalo antes de calcular. No supongas.
3. **Repasa las tarifas apartado por apartado** (cada título de `tarifas.md`: productos o servicios, extras, personal,
   desplazamiento, condiciones…) y para cada uno decide si se aplica a esta petición. Todo lo que tenga precio y se
   aplique va en el presupuesto **con su propia línea**, aunque el cliente no lo haya pedido (por ejemplo, el personal
   o el desplazamiento que marcan las tarifas). Nada que tenga precio en las tarifas se da por «incluido».
4. Calcula concepto a concepto y escribe cada cuenta (cantidad × precio = total). Aplica las reglas de las tarifas:
   redondeos, mínimos, recargos, horas, lo incluido. Suma y vuelve a sumar.
5. Escribe la respuesta al cliente con el desglose, el total y las condiciones (señal, validez, lo incluido), en el
   tono y con la firma de `~/Mi negocio/mi-negocio.md`.
6. Debajo, separado con una línea, «Para el dueño:» con lo que tiene que decidir o comprobar (si no hay nada, «Nada
   que decidir»).

Nunca confirmes la fecha ni des descuentos: eso lo decide el dueño.
