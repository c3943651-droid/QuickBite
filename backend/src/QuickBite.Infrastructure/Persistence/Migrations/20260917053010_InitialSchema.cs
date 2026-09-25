using System;
using Microsoft.EntityFrameworkCore.Migrations;
using QuickBite.Domain.Enums;

#nullable disable

namespace QuickBite.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialSchema : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:estado_pedido", "pendiente,confirmado,preparando,listo,en_camino,entregado,cancelado")
                .Annotation("Npgsql:Enum:estado_repartidor", "disponible,ocupado,inactivo")
                .Annotation("Npgsql:Enum:metodo_pago", "efectivo,tarjeta")
                .Annotation("Npgsql:Enum:rol_usuario", "cliente,administrador,repartidor")
                .Annotation("Npgsql:Enum:tipo_notificacion", "pedido_nuevo,cambio_estado,asignacion,sistema,recordatorio")
                .Annotation("Npgsql:PostgresExtension:pgcrypto", ",,");

            migrationBuilder.CreateTable(
                name: "categorias",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    descripcion = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    orden = table.Column<short>(type: "smallint", nullable: false),
                    activo = table.Column<bool>(type: "boolean", nullable: false),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_categorias", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "configuracion_sistema",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    clave = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    valor = table.Column<string>(type: "text", nullable: false),
                    descripcion = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    editable = table.Column<bool>(type: "boolean", nullable: false),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    actualizado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_configuracion_sistema", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "metodos_pago",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    descripcion = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_metodos_pago", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "usuarios",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    email = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    password_hash = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    telefono = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    rol = table.Column<UserRole>(type: "rol_usuario", nullable: false),
                    activo = table.Column<bool>(type: "boolean", nullable: false),
                    intentos_fallidos = table.Column<short>(type: "smallint", nullable: false),
                    bloqueado_hasta = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ultimo_login = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    actualizado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_usuarios", x => x.id);
                    table.CheckConstraint("CK_usuarios_email", "email ~* '^[^@]+@[^@]+\\.[^@]+$'");
                });

            migrationBuilder.CreateTable(
                name: "productos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    categoria_id = table.Column<Guid>(type: "uuid", nullable: true),
                    nombre = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    descripcion = table.Column<string>(type: "text", nullable: true),
                    precio = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    imagen_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    disponible = table.Column<bool>(type: "boolean", nullable: false),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    actualizado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_productos", x => x.id);
                    table.CheckConstraint("CK_productos_precio", "precio >= 0");
                    table.ForeignKey(
                        name: "fk_productos_categorias_categoria_id",
                        column: x => x.categoria_id,
                        principalTable: "categorias",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "auditoria_acciones",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: true),
                    accion = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    entidad = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    entidad_id = table.Column<Guid>(type: "uuid", nullable: true),
                    detalles = table.Column<string>(type: "jsonb", nullable: true),
                    ip_origen = table.Column<string>(type: "character varying(45)", maxLength: 45, nullable: true),
                    user_agent = table.Column<string>(type: "text", nullable: true),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_auditoria_acciones", x => x.id);
                    table.ForeignKey(
                        name: "fk_auditoria_acciones_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "carritos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: false),
                    actualizado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ultimo_acceso = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    expira_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    estado = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "activo")
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_carritos", x => x.id);
                    table.CheckConstraint("CK_carritos_estado", "estado IN ('activo','abandonado','convertido')");
                    table.ForeignKey(
                        name: "fk_carritos_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "direcciones",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: false),
                    alias = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    calle = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    numero = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    referencia = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    ciudad = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    latitud = table.Column<decimal>(type: "numeric(10,7)", precision: 10, scale: 7, nullable: true),
                    longitud = table.Column<decimal>(type: "numeric(10,7)", precision: 10, scale: 7, nullable: true),
                    es_predeterminada = table.Column<bool>(type: "boolean", nullable: false),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_direcciones", x => x.id);
                    table.ForeignKey(
                        name: "fk_direcciones_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "repartidores",
                columns: table => new
                {
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: false),
                    estado_disponibilidad = table.Column<DeliveryPersonStatus>(type: "estado_repartidor", nullable: false),
                    vehiculo = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    entregas_completadas = table.Column<int>(type: "integer", nullable: false),
                    fecha_alta = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_repartidores", x => x.usuario_id);
                    table.ForeignKey(
                        name: "fk_repartidores_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "tokens_recuperacion_password",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: false),
                    token_hash = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    expira_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    usado = table.Column<bool>(type: "boolean", nullable: false),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_tokens_recuperacion_password", x => x.id);
                    table.ForeignKey(
                        name: "fk_tokens_recuperacion_password_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "tokens_refresco",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: false),
                    token_hash = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    expira_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    revocado = table.Column<bool>(type: "boolean", nullable: false),
                    ip_origen = table.Column<string>(type: "character varying(45)", maxLength: 45, nullable: true),
                    user_agent = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_tokens_refresco", x => x.id);
                    table.ForeignKey(
                        name: "fk_tokens_refresco_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "inventario",
                columns: table => new
                {
                    producto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    stock = table.Column<int>(type: "integer", nullable: false),
                    stock_minimo = table.Column<int>(type: "integer", nullable: false),
                    ultima_actualizacion = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    actualizado_por = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_inventario", x => x.producto_id);
                    table.CheckConstraint("CK_inventario_stock", "stock >= 0");
                    table.ForeignKey(
                        name: "fk_inventario_productos_producto_id",
                        column: x => x.producto_id,
                        principalTable: "productos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_inventario_usuarios_actualizado_por",
                        column: x => x.actualizado_por,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "producto_opciones",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    producto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    precio_adicional = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    activo = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_producto_opciones", x => x.id);
                    table.CheckConstraint("CK_producto_opciones_precio", "precio_adicional >= 0");
                    table.ForeignKey(
                        name: "fk_producto_opciones_productos_producto_id",
                        column: x => x.producto_id,
                        principalTable: "productos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "producto_precios_historicos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    producto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    precio_anterior = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    precio_nuevo = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: true),
                    motivo = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_producto_precios_historicos", x => x.id);
                    table.ForeignKey(
                        name: "fk_producto_precios_historicos_productos_producto_id",
                        column: x => x.producto_id,
                        principalTable: "productos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_producto_precios_historicos_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "carrito_items",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    carrito_id = table.Column<Guid>(type: "uuid", nullable: false),
                    producto_id = table.Column<Guid>(type: "uuid", nullable: false),
                    cantidad = table.Column<short>(type: "smallint", nullable: false),
                    observaciones = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    agregado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_carrito_items", x => x.id);
                    table.CheckConstraint("CK_carrito_items_cantidad", "cantidad > 0");
                    table.ForeignKey(
                        name: "fk_carrito_items_carritos_carrito_id",
                        column: x => x.carrito_id,
                        principalTable: "carritos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_carrito_items_productos_producto_id",
                        column: x => x.producto_id,
                        principalTable: "productos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "pedidos",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    numero_pedido = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    cliente_id = table.Column<Guid>(type: "uuid", nullable: false),
                    repartidor_id = table.Column<Guid>(type: "uuid", nullable: true),
                    direccion_id = table.Column<Guid>(type: "uuid", nullable: true),
                    direccion_entrega_snapshot = table.Column<string>(type: "text", nullable: false),
                    estado = table.Column<OrderStatus>(type: "estado_pedido", nullable: false),
                    metodo_pago = table.Column<PaymentMethodType>(type: "metodo_pago", nullable: false),
                    metodo_pago_id = table.Column<Guid>(type: "uuid", nullable: true),
                    subtotal = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    costo_envio = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    total = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    motivo_cancelacion = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    confirmado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    preparando_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    listo_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    en_camino_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    entregado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    cancelado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    actualizado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_pedidos", x => x.id);
                    table.CheckConstraint("CK_pedidos_costo_envio", "costo_envio >= 0");
                    table.CheckConstraint("CK_pedidos_subtotal", "subtotal >= 0");
                    table.CheckConstraint("CK_pedidos_total", "total >= 0");
                    table.ForeignKey(
                        name: "fk_pedidos_direcciones_direccion_id",
                        column: x => x.direccion_id,
                        principalTable: "direcciones",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_pedidos_metodos_pago_metodo_pago_id",
                        column: x => x.metodo_pago_id,
                        principalTable: "metodos_pago",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_pedidos_repartidores_repartidor_id",
                        column: x => x.repartidor_id,
                        principalTable: "repartidores",
                        principalColumn: "usuario_id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "fk_pedidos_usuarios_cliente_id",
                        column: x => x.cliente_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "carrito_item_opciones",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    carrito_item_id = table.Column<Guid>(type: "uuid", nullable: false),
                    opcion_id = table.Column<Guid>(type: "uuid", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_carrito_item_opciones", x => x.id);
                    table.ForeignKey(
                        name: "fk_carrito_item_opciones_carrito_items_carrito_item_id",
                        column: x => x.carrito_item_id,
                        principalTable: "carrito_items",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_carrito_item_opciones_productos_opciones_opcion_id",
                        column: x => x.opcion_id,
                        principalTable: "producto_opciones",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "notificaciones",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: false),
                    tipo = table.Column<NotificationType>(type: "tipo_notificacion", nullable: false),
                    titulo = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    mensaje = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    pedido_id = table.Column<Guid>(type: "uuid", nullable: true),
                    leido = table.Column<bool>(type: "boolean", nullable: false),
                    leido_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_notificaciones", x => x.id);
                    table.ForeignKey(
                        name: "fk_notificaciones_pedidos_pedido_id",
                        column: x => x.pedido_id,
                        principalTable: "pedidos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_notificaciones_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "pedido_historial_estados",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    pedido_id = table.Column<Guid>(type: "uuid", nullable: false),
                    estado_anterior = table.Column<OrderStatus>(type: "estado_pedido", nullable: true),
                    estado_nuevo = table.Column<OrderStatus>(type: "estado_pedido", nullable: false),
                    usuario_id = table.Column<Guid>(type: "uuid", nullable: true),
                    comentario = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    creado_en = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_pedido_historial_estados", x => x.id);
                    table.ForeignKey(
                        name: "fk_pedido_historial_estados_pedidos_pedido_id",
                        column: x => x.pedido_id,
                        principalTable: "pedidos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_pedido_historial_estados_usuarios_usuario_id",
                        column: x => x.usuario_id,
                        principalTable: "usuarios",
                        principalColumn: "id");
                });

            migrationBuilder.CreateTable(
                name: "pedido_items",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    pedido_id = table.Column<Guid>(type: "uuid", nullable: false),
                    producto_id = table.Column<Guid>(type: "uuid", nullable: true),
                    nombre_producto = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    precio_unitario = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false),
                    cantidad = table.Column<short>(type: "smallint", nullable: false),
                    observaciones = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    subtotal = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_pedido_items", x => x.id);
                    table.CheckConstraint("CK_pedido_items_cantidad", "cantidad > 0");
                    table.CheckConstraint("CK_pedido_items_precio", "precio_unitario >= 0");
                    table.CheckConstraint("CK_pedido_items_subtotal", "subtotal >= 0");
                    table.ForeignKey(
                        name: "fk_pedido_items_pedidos_pedido_id",
                        column: x => x.pedido_id,
                        principalTable: "pedidos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_pedido_items_productos_producto_id",
                        column: x => x.producto_id,
                        principalTable: "productos",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "pedido_item_opciones",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    pedido_item_id = table.Column<Guid>(type: "uuid", nullable: false),
                    nombre_opcion = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    precio_adicional = table.Column<decimal>(type: "numeric(10,2)", precision: 10, scale: 2, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_pedido_item_opciones", x => x.id);
                    table.ForeignKey(
                        name: "fk_pedido_item_opciones_pedido_items_pedido_item_id",
                        column: x => x.pedido_item_id,
                        principalTable: "pedido_items",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_auditoria_entidad",
                table: "auditoria_acciones",
                columns: new[] { "entidad", "entidad_id" });

            migrationBuilder.CreateIndex(
                name: "idx_auditoria_fecha",
                table: "auditoria_acciones",
                column: "creado_en",
                descending: new bool[0]);

            migrationBuilder.CreateIndex(
                name: "idx_auditoria_usuario",
                table: "auditoria_acciones",
                column: "usuario_id");

            migrationBuilder.CreateIndex(
                name: "ix_carrito_item_opciones_carrito_item_id",
                table: "carrito_item_opciones",
                column: "carrito_item_id");

            migrationBuilder.CreateIndex(
                name: "ix_carrito_item_opciones_opcion_id",
                table: "carrito_item_opciones",
                column: "opcion_id");

            migrationBuilder.CreateIndex(
                name: "ix_carrito_items_carrito_id",
                table: "carrito_items",
                column: "carrito_id");

            migrationBuilder.CreateIndex(
                name: "ix_carrito_items_producto_id",
                table: "carrito_items",
                column: "producto_id");

            migrationBuilder.CreateIndex(
                name: "idx_carritos_estado",
                table: "carritos",
                column: "estado");

            migrationBuilder.CreateIndex(
                name: "idx_carritos_expiracion",
                table: "carritos",
                column: "expira_en",
                filter: "estado = 'activo'");

            migrationBuilder.CreateIndex(
                name: "uq_carritos_usuario_id",
                table: "carritos",
                column: "usuario_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "uq_categorias_nombre",
                table: "categorias",
                column: "nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "uq_configuracion_sistema_clave",
                table: "configuracion_sistema",
                column: "clave",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "idx_direcciones_ciudad",
                table: "direcciones",
                column: "ciudad");

            migrationBuilder.CreateIndex(
                name: "uq_direccion_predeterminada_por_usuario",
                table: "direcciones",
                column: "usuario_id",
                unique: true,
                filter: "es_predeterminada = TRUE");

            migrationBuilder.CreateIndex(
                name: "idx_inventario_stock_bajo",
                table: "inventario",
                column: "producto_id",
                filter: "stock <= stock_minimo");

            migrationBuilder.CreateIndex(
                name: "ix_inventario_actualizado_por",
                table: "inventario",
                column: "actualizado_por");

            migrationBuilder.CreateIndex(
                name: "uq_metodos_pago_nombre",
                table: "metodos_pago",
                column: "nombre",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_notificaciones_pedido_id",
                table: "notificaciones",
                column: "pedido_id");

            migrationBuilder.CreateIndex(
                name: "ix_notificaciones_usuario_id",
                table: "notificaciones",
                column: "usuario_id");

            migrationBuilder.CreateIndex(
                name: "ix_pedido_historial_estados_pedido_id",
                table: "pedido_historial_estados",
                column: "pedido_id");

            migrationBuilder.CreateIndex(
                name: "ix_pedido_historial_estados_usuario_id",
                table: "pedido_historial_estados",
                column: "usuario_id");

            migrationBuilder.CreateIndex(
                name: "ix_pedido_item_opciones_pedido_item_id",
                table: "pedido_item_opciones",
                column: "pedido_item_id");

            migrationBuilder.CreateIndex(
                name: "idx_pedido_items_pedido_id",
                table: "pedido_items",
                column: "pedido_id");

            migrationBuilder.CreateIndex(
                name: "idx_pedido_items_producto",
                table: "pedido_items",
                column: "producto_id");

            migrationBuilder.CreateIndex(
                name: "uq_pedido_items_producto",
                table: "pedido_items",
                columns: new[] { "pedido_id", "producto_id" },
                unique: true,
                filter: "producto_id IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "idx_pedidos_cliente",
                table: "pedidos",
                column: "cliente_id");

            migrationBuilder.CreateIndex(
                name: "idx_pedidos_creado",
                table: "pedidos",
                column: "creado_en",
                descending: new bool[0]);

            migrationBuilder.CreateIndex(
                name: "idx_pedidos_estado",
                table: "pedidos",
                column: "estado");

            migrationBuilder.CreateIndex(
                name: "idx_pedidos_estado_fecha",
                table: "pedidos",
                columns: new[] { "estado", "creado_en" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "idx_pedidos_repartidor",
                table: "pedidos",
                column: "repartidor_id");

            migrationBuilder.CreateIndex(
                name: "ix_pedidos_direccion_id",
                table: "pedidos",
                column: "direccion_id");

            migrationBuilder.CreateIndex(
                name: "ix_pedidos_metodo_pago_id",
                table: "pedidos",
                column: "metodo_pago_id");

            migrationBuilder.CreateIndex(
                name: "uq_pedidos_numero",
                table: "pedidos",
                column: "numero_pedido",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_producto_opciones_producto_id",
                table: "producto_opciones",
                column: "producto_id");

            migrationBuilder.CreateIndex(
                name: "ix_producto_precios_historicos_producto_id",
                table: "producto_precios_historicos",
                column: "producto_id");

            migrationBuilder.CreateIndex(
                name: "ix_producto_precios_historicos_usuario_id",
                table: "producto_precios_historicos",
                column: "usuario_id");

            migrationBuilder.CreateIndex(
                name: "idx_productos_categoria_id",
                table: "productos",
                column: "categoria_id");

            migrationBuilder.CreateIndex(
                name: "idx_productos_disponible",
                table: "productos",
                column: "disponible",
                filter: "disponible = TRUE");

            migrationBuilder.CreateIndex(
                name: "idx_productos_precio",
                table: "productos",
                column: "precio");

            migrationBuilder.CreateIndex(
                name: "idx_repartidores_entregas",
                table: "repartidores",
                column: "entregas_completadas",
                descending: new bool[0]);

            migrationBuilder.CreateIndex(
                name: "idx_repartidores_estado",
                table: "repartidores",
                column: "estado_disponibilidad");

            migrationBuilder.CreateIndex(
                name: "ix_tokens_recuperacion_password_usuario_id",
                table: "tokens_recuperacion_password",
                column: "usuario_id");

            migrationBuilder.CreateIndex(
                name: "idx_tokens_refresco_expiracion",
                table: "tokens_refresco",
                column: "expira_en",
                filter: "revocado = FALSE");

            migrationBuilder.CreateIndex(
                name: "idx_tokens_refresco_usuario_id",
                table: "tokens_refresco",
                column: "usuario_id");

            migrationBuilder.CreateIndex(
                name: "idx_usuarios_activo",
                table: "usuarios",
                column: "activo",
                filter: "activo = TRUE");

            migrationBuilder.CreateIndex(
                name: "idx_usuarios_rol",
                table: "usuarios",
                column: "rol");

            migrationBuilder.CreateIndex(
                name: "uq_usuarios_email",
                table: "usuarios",
                column: "email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "auditoria_acciones");

            migrationBuilder.DropTable(
                name: "carrito_item_opciones");

            migrationBuilder.DropTable(
                name: "configuracion_sistema");

            migrationBuilder.DropTable(
                name: "inventario");

            migrationBuilder.DropTable(
                name: "notificaciones");

            migrationBuilder.DropTable(
                name: "pedido_historial_estados");

            migrationBuilder.DropTable(
                name: "pedido_item_opciones");

            migrationBuilder.DropTable(
                name: "producto_precios_historicos");

            migrationBuilder.DropTable(
                name: "tokens_recuperacion_password");

            migrationBuilder.DropTable(
                name: "tokens_refresco");

            migrationBuilder.DropTable(
                name: "carrito_items");

            migrationBuilder.DropTable(
                name: "producto_opciones");

            migrationBuilder.DropTable(
                name: "pedido_items");

            migrationBuilder.DropTable(
                name: "carritos");

            migrationBuilder.DropTable(
                name: "pedidos");

            migrationBuilder.DropTable(
                name: "productos");

            migrationBuilder.DropTable(
                name: "direcciones");

            migrationBuilder.DropTable(
                name: "metodos_pago");

            migrationBuilder.DropTable(
                name: "repartidores");

            migrationBuilder.DropTable(
                name: "categorias");

            migrationBuilder.DropTable(
                name: "usuarios");
        }
    }
}
