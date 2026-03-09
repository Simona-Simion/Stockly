package com.stockly.api.service;

import com.stockly.api.model.Usuario;
import com.stockly.api.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository repository;

    // Devuelve el usuario por su UUID de Supabase.
    // Lanza excepción si no existe (el usuario no está registrado en la tabla local).
    public Usuario findBySupabaseId(String supabaseUserId) {
        return repository.findBySupabaseUserId(UUID.fromString(supabaseUserId))
                .orElseThrow(() -> new RuntimeException(
                        "Usuario no registrado en el sistema: " + supabaseUserId));
    }

    public Usuario save(Usuario usuario) {
        return repository.save(usuario);
    }
}
