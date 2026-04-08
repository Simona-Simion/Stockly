package com.stockly.api.service;

import com.stockly.api.model.Pedido;
import com.stockly.api.repository.PedidoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PedidoService {

    private final PedidoRepository repository;

    public Pedido crear(Pedido pedido) {
        return repository.save(pedido);
    }

    public List<Pedido> listar() {
        return repository.findAll();
    }

    public Pedido actualizarEstado(UUID id, String estado) {
        Pedido pedido = repository.findById(id).orElseThrow();
        pedido.setEstado(estado);
        return repository.save(pedido);
    }
}
