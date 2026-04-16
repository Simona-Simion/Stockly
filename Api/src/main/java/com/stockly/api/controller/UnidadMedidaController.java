package com.stockly.api.controller;

import com.stockly.api.model.UnidadMedida;
import com.stockly.api.service.UnidadMedidaService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/unidades-medida")
@RequiredArgsConstructor
public class UnidadMedidaController {

    private final UnidadMedidaService service;

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping
    public UnidadMedida crear(@RequestBody UnidadMedida unidad) {
        return service.crear(unidad);
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping
    public List<UnidadMedida> listar() {
        return service.listar();
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable("id") UUID id) {
        service.eliminar(id);
    }
}
