package com.stockly.api.service.impl;

import com.stockly.api.model.Producto;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.service.AlertaService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class AlertaServiceImpl implements AlertaService {

    private final ProductoRepository productoRepository;

    // TODO (Fase 3): inyectar FcmService para notificaciones push reales

    @Override
    public void comprobarStockMinimo(Producto producto) {
        if (producto.getStockActual() < producto.getStockMinimo()) {
            // TODO (Fase 3): enviar notificación push via FCM.
            // Anti-spam: registrar en tabla 'alertas_enviadas' y no reenviar
            // hasta que el stock suba por encima del mínimo y vuelva a bajar.
            log.warn("ALERTA STOCK MÍNIMO — Producto: '{}' | Stock actual: {} | Stock mínimo: {}",
                    producto.getNombre(),
                    producto.getStockActual(),
                    producto.getStockMinimo());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Producto> obtenerProductosBajoMinimo() {
        return productoRepository.findProductosBajoStockMinimo();
    }
}
