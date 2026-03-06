package com.horecastock.api.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;
import java.util.List;
import java.util.UUID;

@Entity
@Data
@Table(name = "proveedores")
public class Proveedor {

    @Id
    @GeneratedValue
    private UUID id;

    private String nombre;
    private String telefono;
    private String email;
    private String direccion;

    @OneToMany(mappedBy = "proveedor", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<Pedido> pedidos;
}
