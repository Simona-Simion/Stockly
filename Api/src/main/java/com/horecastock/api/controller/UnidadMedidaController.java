package com.horecastock.api.controller;

import com.horecastock.api.model.UnidadMedida;
import com.horecastock.api.service.UnidadMedidaService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/unidades")
@RequiredArgsConstructor
public class UnidadMedidaController {

    private final UnidadMedidaService service;

    @PostMapping
    public UnidadMedida crear(@RequestBody UnidadMedida unidad) {
        return service.crear(unidad);
    }

    @GetMapping
    public List<UnidadMedida> listar() {
        return service.listar();
    }

    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable UUID id) {
        service.eliminar(id);
    }
}
