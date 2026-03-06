package com.horecastock.api.service;

import com.horecastock.api.model.Proveedor;
import com.horecastock.api.repository.ProveedorRepository;
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
