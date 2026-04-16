package com.stockly.api.controller;

import com.stockly.api.dto.RecetaRequest;
import com.stockly.api.model.Receta;
import com.stockly.api.service.RecetaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/recetas")
@RequiredArgsConstructor
public class RecetaController {

    private final RecetaService service;

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping
    public ResponseEntity<List<Receta>> listar() {
        return ResponseEntity.ok(service.listar());
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping("/{id}")
    public ResponseEntity<Receta> obtener(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(service.obtener(id));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping
    public ResponseEntity<Receta> crear(@Valid @RequestBody RecetaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.crear(request));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @PutMapping("/{id}")
    public ResponseEntity<Receta> actualizar(@PathVariable("id") UUID id,
                                              @Valid @RequestBody RecetaRequest request) {
        return ResponseEntity.ok(service.actualizar(id, request));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> desactivar(@PathVariable("id") UUID id) {
        service.desactivar(id);
        return ResponseEntity.noContent().build();
    }
}
