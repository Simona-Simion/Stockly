package com.horecastock.api.service;

import com.horecastock.api.dto.VentaEscandalloRequest;
import com.horecastock.api.model.Venta;

import java.util.List;

public interface VentaService {

    Venta registrarVenta(VentaEscandalloRequest request);

    List<Venta> listarVentas();
}
