package com.stockly.api.controller;

import com.stockly.api.model.Usuario;
import com.stockly.api.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
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
    // Authentication expone el subject del JWT y el email extraido en el filtro.
    @PreAuthorize("isAuthenticated()")
    @GetMapping("/me")
    public ResponseEntity<Usuario> me(Authentication authentication) {
        String supabaseUserId = authentication.getName();
        String email = (String) authentication.getDetails();
        Usuario usuario = usuarioService.findOrCreate(supabaseUserId, email);
        return ResponseEntity.ok(usuario);
    }
}
