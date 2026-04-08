package com.stockly.api.service;

import com.stockly.api.dto.VentaEscandalloRequest;
import com.stockly.api.dto.VentaProductoRequest;
import com.stockly.api.model.Venta;

import java.util.List;

public interface VentaService {

    Venta registrarVenta(VentaEscandalloRequest request);

    Venta registrarVentaProducto(VentaProductoRequest request);

    List<Venta> listarVentas();
}
