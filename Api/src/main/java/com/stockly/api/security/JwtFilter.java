package com.stockly.api.security;

import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.jwk.source.JWKSource;
import com.nimbusds.jose.jwk.source.RemoteJWKSet;
import com.nimbusds.jose.proc.JWSVerificationKeySelector;
import com.nimbusds.jose.proc.SecurityContext;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.proc.ConfigurableJWTProcessor;
import com.nimbusds.jwt.proc.DefaultJWTProcessor;
import com.stockly.api.model.Usuario;
import com.stockly.api.repository.UsuarioRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.URL;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

// Valida el JWT de Supabase (ECC P-256) usando el endpoint JWKS público.
// Las claves se descargan una vez al arrancar y nimbus las cachea automáticamente.
@Component
public class JwtFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(JwtFilter.class);

    private final UsuarioRepository usuarioRepository;
    private ConfigurableJWTProcessor<SecurityContext> jwtProcessor;

    public JwtFilter(UsuarioRepository usuarioRepository,
                     @Value("${supabase.jwks.uri}") String jwksUri) {
        this.usuarioRepository = usuarioRepository;
        try {
            log.info("[JWT] Inicializando JWKS desde: {}", jwksUri);
            JWKSource<SecurityContext> jwkSource = new RemoteJWKSet<>(new URL(jwksUri));
            jwtProcessor = new DefaultJWTProcessor<>();
            jwtProcessor.setJWSKeySelector(
                    new JWSVerificationKeySelector<>(JWSAlgorithm.ES256, jwkSource));
            log.info("[JWT] JWKS cargado correctamente");
        } catch (Exception e) {
            throw new IllegalStateException("[JWT] No se pudo inicializar el JWKS: " + e.getMessage(), e);
        }
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String token = authHeader.substring(7);

        try {
            JWTClaimsSet claims = jwtProcessor.process(token, null);
            String supabaseUserId = claims.getSubject();
            log.info("[JWT] Token válido. sub={}", supabaseUserId);

            // Cargar rol desde la tabla local de usuarios
            Optional<Usuario> usuarioOpt = usuarioRepository
                    .findBySupabaseUserId(UUID.fromString(supabaseUserId));

            if (usuarioOpt.isEmpty()) {
                log.warn("[JWT] Usuario no encontrado en BD para sub={}", supabaseUserId);
            } else {
                log.info("[JWT] Usuario encontrado: email={}, rol={}",
                        usuarioOpt.get().getEmail(), usuarioOpt.get().getRol());
            }

            List<SimpleGrantedAuthority> authorities = usuarioOpt
                    .map(u -> List.of(new SimpleGrantedAuthority("ROLE_" + u.getRol().name())))
                    .orElse(List.of());

            UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(supabaseUserId, null, authorities);

            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (Exception e) {
            log.error("[JWT] Error al validar token: {} - {}", e.getClass().getSimpleName(), e.getMessage());
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
