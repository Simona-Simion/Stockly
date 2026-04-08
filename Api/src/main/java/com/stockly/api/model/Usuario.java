package com.stockly.api.model;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

// Tabla propia de usuarios que extiende la autenticación de Supabase.
// Cada registro referencia al usuario de Supabase por su UUID.
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "usuarios")
public class Usuario {

    @Id
    @GeneratedValue
    private UUID id;

    // UUID del usuario en Supabase Auth (auth.users.id)
    @Column(name = "supabase_user_id", nullable = false, unique = true)
    private UUID supabaseUserId;

    @Column(nullable = false, length = 150)
    private String email;

    @Column(nullable = false, length = 100)
    private String nombre;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private Rol rol = Rol.EMPLEADO;
}
