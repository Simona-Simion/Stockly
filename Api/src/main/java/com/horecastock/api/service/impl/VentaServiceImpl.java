package com.horecastock.api.service.impl;

import com.horecastock.api.dto.VentaEscandalloRequest;
import com.horecastock.api.exception.ResourceNotFoundException;
import com.horecastock.api.model.Receta;
import com.horecastock.api.model.Venta;
import com.horecastock.api.repository.RecetaRepository;
import com.horecastock.api.repository.VentaRepository;
import com.horecastock.api.service.EscandalloService;
import com.horecastock.api.service.VentaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class VentaServiceImpl implements VentaService {

    private final RecetaRepository recetaRepository;
    private final VentaRepository ventaRepository;
    private final EscandalloService escandalloService;

    @Override
    @Transactional
    public Venta registrarVenta(VentaEscandalloRequest request) {

        // 1. Buscar la receta
        Receta receta = recetaRepository.findById(request.getRecetaId())
                .orElseThrow(() -> new ResourceNotFoundException("Receta", "id", request.getRecetaId()));

        // 2. Verificar que la receta está activa
        if (!receta.getActivo()) {
            throw new RuntimeException("La receta '" + receta.getNombre() + "' no está activa");
        }

        // 3. Determinar origen (por defecto MANUAL)
        String origen = (request.getOrigen() != null && !request.getOrigen().isBlank())
                ? request.getOrigen()
                : "MANUAL";

        // 4. Aplicar escandallo: valida stock de todos los ingredientes y descuenta.
        //    Si hay stock insuficiente lanza StockInsuficienteException → rollback completo.
        escandalloService.aplicarEscandallo(receta, request.getCantidad(), origen);

        // 5. Crear y persistir la venta
        Venta venta = new Venta();
        venta.setReceta(receta);
        venta.setCantidad(request.getCantidad());
        venta.setPrecioTotal(receta.getPrecioVenta() * request.getCantidad());
        venta.setOrigen(origen);

        return ventaRepository.save(venta);
    }

    @Override
    @Transactional(readOnly = true)
    public List<Venta> listarVentas() {
        return ventaRepository.findAll();
    }
}
