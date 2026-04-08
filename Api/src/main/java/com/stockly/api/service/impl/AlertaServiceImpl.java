package com.stockly.api.service.impl;

import com.stockly.api.model.Producto;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.service.AlertaService;
import com.stockly.api.service.FcmService;
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
    private final FcmService fcmService;

    @Override
    public void comprobarStockMinimo(Producto producto) {
        if (producto.getStockActual() < producto.getStockMinimo()) {
            log.warn("ALERTA STOCK — '{}': actual={} mínimo={}",
                    producto.getNombre(), producto.getStockActual(), producto.getStockMinimo());

            fcmService.enviarAAdmins(
                    "⚠ Stock bajo: " + producto.getNombre(),
                    String.format("Stock actual: %.2f (mínimo: %.2f)",
                            producto.getStockActual(), producto.getStockMinimo())
            );
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<Producto> obtenerProductosBajoMinimo() {
        return productoRepository.findProductosBajoStockMinimo();
    }
}
