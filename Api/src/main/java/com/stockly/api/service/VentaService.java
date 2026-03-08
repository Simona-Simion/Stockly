package com.stockly.api.service;

import com.stockly.api.dto.VentaEscandalloRequest;
import com.stockly.api.model.Venta;

import java.util.List;

public interface VentaService {

    Venta registrarVenta(VentaEscandalloRequest request);

    List<Venta> listarVentas();
}
