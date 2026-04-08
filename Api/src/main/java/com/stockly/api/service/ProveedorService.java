package com.stockly.api.service;

import com.stockly.api.model.Proveedor;
import com.stockly.api.repository.ProveedorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ProveedorService {

    private final ProveedorRepository repository;

    public Proveedor crear(Proveedor proveedor) {
        return repository.save(proveedor);
    }

    public List<Proveedor> listar() {
        return repository.findAll();
    }

    public void eliminar(UUID id) {
        repository.deleteById(id);
    }
}
