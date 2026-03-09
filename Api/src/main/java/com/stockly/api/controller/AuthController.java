package com.stockly.api.controller;

import com.stockly.api.model.Usuario;
import com.stockly.api.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UsuarioService usuarioService;

    // Devuelve el perfil del usuario autenticado (email + rol).
    // El frontend llama a este endpoint justo después de hacer login.
    // @AuthenticationPrincipal recibe el subject del JWT (UUID de Supabase).
    @GetMapping("/me")
    public ResponseEntity<Usuario> me(@AuthenticationPrincipal String supabaseUserId) {
        return ResponseEntity.ok(usuarioService.findBySupabaseId(supabaseUserId));
    }
}
