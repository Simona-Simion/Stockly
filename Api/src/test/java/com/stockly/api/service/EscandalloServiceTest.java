package com.stockly.api.service;

import com.stockly.api.exception.ResourceNotFoundException;
import com.stockly.api.exception.StockInsuficienteException;
import com.stockly.api.model.LineaReceta;
import com.stockly.api.model.MovimientoStock;
import com.stockly.api.model.Producto;
import com.stockly.api.model.Receta;
import com.stockly.api.repository.MovimientoStockRepository;
import com.stockly.api.repository.ProductoRepository;
import com.stockly.api.service.impl.EscandalloServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Tests unitarios del módulo de escandallo.
 *
 * Se usa @ExtendWith(MockitoExtension.class) para tests puros con Mockito,
 * sin levantar el contexto de Spring ni conectarse a ninguna base de datos.
 * Cada dependencia del servicio se sustituye por un "mock" (objeto falso)
 * que devuelve los datos que nosotros controlamos.
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("EscandalloService — Tests unitarios")
class EscandalloServiceTest {

    // ─── Mocks de las dependencias ───────────────────────────────────────────────
    // Mockito crea objetos falsos que simulan ProductoRepository y los demás.
    // Ninguna de estas llamadas toca una base de datos real.
    @Mock
    private ProductoRepository productoRepository;

    @Mock
    private MovimientoStockRepository movimientoStockRepository;

    @Mock
    private AlertaService alertaService;

    // ─── Clase bajo test ─────────────────────────────────────────────────────────
    // @InjectMocks crea una instancia real de EscandalloServiceImpl e inyecta
    // automáticamente los mocks anteriores en sus campos.
    @InjectMocks
    private EscandalloServiceImpl escandalloService;

    // ─── Datos de prueba reutilizables ───────────────────────────────────────────
    private Producto ron;
    private Producto cocaCola;
    private Receta cubaLibre;

    /**
     * Se ejecuta antes de CADA test. Prepara los datos de prueba desde cero
     * para que un test no afecte al siguiente.
     *
     * Escenario base:
     *   Cuba Libre = 5cl Ron (stock: 1L) + 20cl Coca-Cola (stock: 2L)
     */
    @BeforeEach
    void setUp() {
        // Ingrediente 1: Ron Bacardí con 1 litro disponible
        ron = new Producto();
        ron.setId(UUID.randomUUID());
        ron.setNombre("Ron Bacardí");
        ron.setStockActual(1.0);
        ron.setStockMinimo(0.2);

        // Ingrediente 2: Coca-Cola con 2 litros disponibles
        cocaCola = new Producto();
        cocaCola.setId(UUID.randomUUID());
        cocaCola.setNombre("Coca-Cola");
        cocaCola.setStockActual(2.0);
        cocaCola.setStockMinimo(0.5);

        // Línea 1 de la receta: 0.05L de Ron por unidad vendida
        LineaReceta lineaRon = new LineaReceta();
        lineaRon.setProducto(ron);
        lineaRon.setCantidad(0.05);

        // Línea 2 de la receta: 0.20L de Coca-Cola por unidad vendida
        LineaReceta lineaCola = new LineaReceta();
        lineaCola.setProducto(cocaCola);
        lineaCola.setCantidad(0.20);

        // Receta Cuba Libre con sus dos ingredientes
        cubaLibre = new Receta();
        cubaLibre.setId(UUID.randomUUID());
        cubaLibre.setNombre("Cuba Libre");
        cubaLibre.setPrecioVenta(6.0);
        cubaLibre.setActivo(true);
        cubaLibre.setLineas(List.of(lineaRon, lineaCola));

        // Configurar los mocks para devolver el objeto guardado sin error
        lenient().when(productoRepository.save(any(Producto.class))).thenAnswer(inv -> inv.getArgument(0));
        lenient().when(movimientoStockRepository.save(any(MovimientoStock.class))).thenAnswer(inv -> inv.getArgument(0));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // TEST 1 — Caso feliz: venta correcta con stock suficiente
    // ─────────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Venta correcta: el stock de todos los ingredientes baja exactamente")
    void ventaCorrecta_debeDescontarStockDeTodosLosIngredientes() {

        // GIVEN (dado que)
        // El setup ya prepara Ron con 1L y Coca-Cola con 2L.
        // Vamos a vender 2 Cuba Libres:
        //   Ron necesario:      0.05L × 2 = 0.10L   → stock restante: 0.90L
        //   Coca-Cola necesaria: 0.20L × 2 = 0.40L  → stock restante: 1.60L

        // WHEN (cuando)
        escandalloService.aplicarEscandallo(cubaLibre, 2, "MANUAL");

        // THEN (entonces)

        // El stock del Ron debe haber bajado de 1.0 a 0.90
        // (usamos delta 0.001 para tolerancia de punto flotante)
        assertEquals(0.90, ron.getStockActual(), 0.001,
                "El stock del Ron debe ser 0.90L tras vender 2 Cuba Libres");

        // El stock de la Coca-Cola debe haber bajado de 2.0 a 1.60
        assertEquals(1.60, cocaCola.getStockActual(), 0.001,
                "El stock de la Coca-Cola debe ser 1.60L tras vender 2 Cuba Libres");

        // Se deben haber guardado exactamente 2 productos (uno por ingrediente)
        verify(productoRepository, times(2)).save(any(Producto.class));

        // Se deben haber registrado exactamente 2 movimientos de stock
        verify(movimientoStockRepository, times(2)).save(any(MovimientoStock.class));

        // Se debe haber comprobado el stock mínimo de cada ingrediente
        verify(alertaService, times(2)).comprobarStockMinimo(any(Producto.class));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // TEST 2 — Stock insuficiente: no se modifica ningún stock
    // ─────────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Stock insuficiente: se rechaza la venta y ningún stock es modificado")
    void stockInsuficiente_debeRechazarVentaYNoModificarNingunStock() {

        // GIVEN (dado que)
        // El Ron solo tiene 0.02L, pero una Cuba Libre necesita 0.05L → insuficiente.
        // La Coca-Cola tiene stock de sobra (2L para 0.20L necesarios).
        ron.setStockActual(0.02);

        // WHEN + THEN (cuando se intenta vender, entonces explota)
        StockInsuficienteException excepcion = assertThrows(
                StockInsuficienteException.class,
                () -> escandalloService.aplicarEscandallo(cubaLibre, 1, "MANUAL"),
                "Debe lanzar StockInsuficienteException cuando un ingrediente no tiene stock"
        );

        // El mensaje de error debe identificar al producto problemático
        assertTrue(excepcion.getMessage().contains("Ron Bacardí"),
                "El mensaje de error debe mencionar el producto sin stock");

        // LO MÁS IMPORTANTE: ningún productoRepository.save() debe haberse llamado.
        // Esto demuestra que la validación en FASE 1 funcionó y el stock
        // de la Coca-Cola tampoco fue modificado, aunque tenía stock suficiente.
        verify(productoRepository, never()).save(any(Producto.class));

        // Tampoco debe haberse registrado ningún movimiento de stock
        verify(movimientoStockRepository, never()).save(any(MovimientoStock.class));

        // Ni comprobado alertas
        verify(alertaService, never()).comprobarStockMinimo(any(Producto.class));
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // TEST 3 — Ingrediente inexistente: excepción controlada, no NullPointerException
    // ─────────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("Ingrediente inexistente: se lanza ResourceNotFoundException")
    void ingredienteInexistente_debeLanzarExcepcion() {

        // GIVEN (dado que)
        // Una receta tiene un ingrediente con producto = null.
        // Esto puede ocurrir si hay datos corruptos en la BD
        // (una LineaReceta con un producto_id que no existe).
        LineaReceta lineaRota = new LineaReceta();
        lineaRota.setProducto(null);   // el producto no existe en BD
        lineaRota.setCantidad(0.05);

        Receta recetaRota = new Receta();
        recetaRota.setNombre("Receta con ingrediente perdido");
        recetaRota.setLineas(List.of(lineaRota));

        // WHEN + THEN (cuando se intenta aplicar el escandallo)
        // Debe lanzar ResourceNotFoundException, NO un NullPointerException genérico.
        // Esto comprueba que el servicio hace una validación defensiva del dato nulo
        // en lugar de explotar sin control.
        assertThrows(
                ResourceNotFoundException.class,
                () -> escandalloService.aplicarEscandallo(recetaRota, 1, "MANUAL"),
                "Debe lanzar ResourceNotFoundException si un ingrediente tiene producto null"
        );

        // Y no debe haberse guardado nada en ningún repositorio
        verify(productoRepository, never()).save(any(Producto.class));
        verify(movimientoStockRepository, never()).save(any(MovimientoStock.class));
    }
}
