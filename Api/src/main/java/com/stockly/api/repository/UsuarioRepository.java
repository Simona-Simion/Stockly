package com.stockly.api.repository;

import com.stockly.api.model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UsuarioRepository extends JpaRepository<Usuario, UUID> {
    Optional<Usuario> findBySupabaseUserId(UUID supabaseUserId);
}
