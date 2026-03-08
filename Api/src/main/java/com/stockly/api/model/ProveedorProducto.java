package com.stockly.api.model;

import jakarta.persistence.*;
import lombok.Data;
import java.util.UUID;

@Entity
@Data
@Table(name = "proveedor_productos")
public class ProveedorProducto {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "id_proveedor")
    private UUID idProveedor;

    @Column(name = "id_producto")
    private UUID idProducto;

    private Double precioCompra;
}
