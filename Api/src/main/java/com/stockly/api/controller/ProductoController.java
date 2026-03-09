package com.stockly.api.controller;

import com.stockly.api.model.Producto;
import com.stockly.api.service.ProductoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService service;

    @GetMapping
    public ResponseEntity<List<Producto>> getAll() {
        return ResponseEntity.ok(service.findAll());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Producto> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.findById(id));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping
    public ResponseEntity<Producto> create(@Valid @RequestBody Producto producto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.save(producto));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/{id}")
    public ResponseEntity<Producto> update(@PathVariable UUID id, @Valid @RequestBody Producto producto) {
        return ResponseEntity.ok(service.update(id, producto));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/scan/{codigo}")
    public ResponseEntity<Producto> getByBarcode(@PathVariable String codigo) {
        return ResponseEntity.ok(service.findByCodigoBarras(codigo));
    }
}
