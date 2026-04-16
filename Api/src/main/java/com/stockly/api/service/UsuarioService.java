package com.stockly.api.service;

import com.stockly.api.model.Rol;
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

    public Usuario findOrCreate(String supabaseUserId, String email) {
        UUID userId;

        try {
            userId = UUID.fromString(supabaseUserId);
        } catch (Exception e) {
            throw new RuntimeException("ID de Supabase inválido: " + supabaseUserId);
        }

        return repository.findBySupabaseUserId(userId)
                .orElseGet(() -> {
                    String safeEmail = email != null ? email : "usuario_" + userId + "@stockly.local";
                    String safeNombre = safeEmail.contains("@")
                            ? safeEmail.substring(0, safeEmail.indexOf("@"))
                            : safeEmail;

                    return repository.save(Usuario.builder()
                            .supabaseUserId(userId)
                            .email(safeEmail)
                            .nombre(safeNombre)
                            .rol(Rol.EMPLEADO)
                            .build());
                });
    }


    public Usuario save(Usuario usuario) {
        return repository.save(usuario);
    }
}
