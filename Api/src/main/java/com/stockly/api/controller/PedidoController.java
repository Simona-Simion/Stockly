package com.stockly.api.controller;

import com.stockly.api.dto.CrearPedidoRequest;
import com.stockly.api.dto.PedidoResponse;
import com.stockly.api.dto.RecibirPedidoRequest;
import com.stockly.api.service.PedidoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/pedidos")
@RequiredArgsConstructor
public class PedidoController {

    private final PedidoService service;

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @PostMapping
    public ResponseEntity<PedidoResponse> crear(@Valid @RequestBody CrearPedidoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.crear(request));
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping
    public ResponseEntity<List<PedidoResponse>> listar() {
        return ResponseEntity.ok(service.listar());
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @GetMapping("/{id}")
    public ResponseEntity<PedidoResponse> obtener(@PathVariable("id") UUID id) {
        return ResponseEntity.ok(service.obtener(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @PutMapping("/{id}/estado")
    public ResponseEntity<PedidoResponse> actualizarEstado(
            @PathVariable("id") UUID id,
            @RequestParam String estado
    ) {
        return ResponseEntity.ok(service.actualizarEstado(id, estado));
    }

    @PreAuthorize("hasAnyRole('ADMIN','EMPLEADO')")
    @PostMapping("/{id}/recibir")
    public ResponseEntity<PedidoResponse> recibir(
            @PathVariable("id") UUID id,
            @Valid @RequestBody RecibirPedidoRequest request
    ) {
        return ResponseEntity.ok(service.recibir(id, request));
    }
}
