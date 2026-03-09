package com.stockly.api.security;

import com.stockly.api.model.Usuario;
import com.stockly.api.repository.UsuarioRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
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

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

// Valida el JWT de Supabase y carga el rol real del usuario desde la BD.
@Component
public class JwtFilter extends OncePerRequestFilter {

    @Value("${supabase.jwt.secret}")
    private String jwtSecret;

    private final UsuarioRepository usuarioRepository;

    public JwtFilter(UsuarioRepository usuarioRepository) {
        this.usuarioRepository = usuarioRepository;
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
            Claims claims = Jwts.parser()
                    .verifyWith(Keys.hmacShaKeyFor(jwtSecret.getBytes(StandardCharsets.UTF_8)))
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            String supabaseUserId = claims.getSubject();

            // Cargar rol desde la tabla local de usuarios
            Optional<Usuario> usuarioOpt = usuarioRepository
                    .findBySupabaseUserId(UUID.fromString(supabaseUserId));

            List<SimpleGrantedAuthority> authorities = usuarioOpt
                    .map(u -> List.of(new SimpleGrantedAuthority("ROLE_" + u.getRol().name())))
                    .orElse(List.of());

            UsernamePasswordAuthenticationToken auth =
                    new UsernamePasswordAuthenticationToken(supabaseUserId, null, authorities);

            SecurityContextHolder.getContext().setAuthentication(auth);

        } catch (Exception e) {
            SecurityContextHolder.clearContext();
        }

        filterChain.doFilter(request, response);
    }
}
