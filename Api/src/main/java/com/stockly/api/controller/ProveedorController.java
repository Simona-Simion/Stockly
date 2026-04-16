package com.stockly.api.controller;

import com.stockly.api.model.Proveedor;
import com.stockly.api.service.ProveedorService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/proveedores")
@RequiredArgsConstructor
public class ProveedorController {

    private final ProveedorService service;

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping
    public Proveedor crear(@RequestBody Proveedor proveedor) {
        return service.crear(proveedor);
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping
    public List<Proveedor> listar() {
        return service.listar();
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public void eliminar(@PathVariable("id") UUID id) {
        service.eliminar(id);
    }
}
