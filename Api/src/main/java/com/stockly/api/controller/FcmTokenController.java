package com.stockly.api.controller;

import com.stockly.api.model.FcmToken;
import com.stockly.api.model.Usuario;
import com.stockly.api.repository.FcmTokenRepository;
import com.stockly.api.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/fcm")
@RequiredArgsConstructor
public class FcmTokenController {

    private final FcmTokenRepository fcmTokenRepository;
    private final UsuarioService usuarioService;

    // Registra o actualiza el token FCM del dispositivo del usuario autenticado.
    // La app Flutter llama a este endpoint tras hacer login y obtener el token.
    @PostMapping("/token")
    public ResponseEntity<Void> registrar(
            @AuthenticationPrincipal String supabaseUserId,
            @RequestBody Map<String, String> body) {

        String token = body.get("token");
        if (token == null || token.isBlank()) {
            return ResponseEntity.badRequest().build();
        }

        Usuario usuario = usuarioService.findBySupabaseId(supabaseUserId);

        // Si el token ya existe lo reutiliza; si no, crea uno nuevo
        fcmTokenRepository.findByToken(token).orElseGet(() ->
            fcmTokenRepository.save(
                FcmToken.builder()
                    .usuario(usuario)
                    .token(token)
                    .build()
            )
        );

        return ResponseEntity.ok().build();
    }
}
