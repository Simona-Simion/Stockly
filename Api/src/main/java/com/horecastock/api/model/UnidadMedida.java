package com.horecastock.api.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Data;
import java.util.List;
import java.util.UUID;

@Entity
@Data
@Table(name = "unidades_medida")
public class UnidadMedida {

    @Id
    @GeneratedValue
    private UUID id;

    private String nombre;

    @OneToMany(mappedBy = "unidadMedida", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonIgnore
    private List<Producto> productos;
}
