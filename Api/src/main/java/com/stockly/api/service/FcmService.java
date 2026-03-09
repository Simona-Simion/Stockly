package com.stockly.api.service;

import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import com.stockly.api.model.FcmToken;
import com.stockly.api.model.Rol;
import com.stockly.api.repository.FcmTokenRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class FcmService {

    private final FcmTokenRepository fcmTokenRepository;

    // Envía una notificación push a todos los dispositivos de los usuarios ADMIN.
    // Si Firebase no está inicializado (desarrollo sin credenciales) solo hace log.
    public void enviarAAdmins(String titulo, String cuerpo) {
        if (FirebaseApp.getApps().isEmpty()) {
            log.info("[FCM-SIMULADO] {} — {}", titulo, cuerpo);
            return;
        }

        List<FcmToken> tokens = fcmTokenRepository.findAllByUsuarioRol(Rol.ADMIN);

        if (tokens.isEmpty()) {
            log.debug("Sin tokens FCM registrados para ADMIN");
            return;
        }

        for (FcmToken fcmToken : tokens) {
            try {
                Message mensaje = Message.builder()
                        .setToken(fcmToken.getToken())
                        .setNotification(Notification.builder()
                                .setTitle(titulo)
                                .setBody(cuerpo)
                                .build())
                        .build();

                String respuesta = FirebaseMessaging.getInstance().send(mensaje);
                log.debug("FCM enviado a {}: {}", fcmToken.getUsuario().getEmail(), respuesta);

            } catch (Exception e) {
                // Token inválido o expirado → lo elimina para no acumular basura
                log.warn("Token FCM inválido para usuario {}, eliminando: {}",
                        fcmToken.getUsuario().getEmail(), e.getMessage());
                fcmTokenRepository.delete(fcmToken);
            }
        }
    }
}
