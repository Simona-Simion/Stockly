package com.stockly.api.repository;

import com.stockly.api.model.FcmToken;
import com.stockly.api.model.Rol;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FcmTokenRepository extends JpaRepository<FcmToken, UUID> {

    Optional<FcmToken> findByToken(String token);

    // Obtiene todos los tokens de los usuarios con un rol concreto
    @Query("SELECT t FROM FcmToken t WHERE t.usuario.rol = :rol")
    List<FcmToken> findAllByUsuarioRol(Rol rol);
}
