import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/proveedor.dart';
import '../../providers/auth_provider.dart';
import '../../providers/proveedor_provider.dart';
import 'proveedor_form_screen.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProveedorProvider>().cargar();
    });
  }

  Future<void> _abrirFormulario() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProveedorFormScreen()),
    );

    if (mounted) {
      context.read<ProveedorProvider>().cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final esAdmin = context.watch<AuthProvider>().esAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () => context.read<ProveedorProvider>().cargar(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (esAdmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _abrirFormulario,
                  icon: const Icon(Icons.add_business),
                  label: const Text('Nuevo proveedor'),
                ),
              ),
            ),
          Expanded(child: _buildLista()),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return Consumer<ProveedorProvider>(
      builder: (context, provider, _) {
        if (provider.cargando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildError(provider.error!);
        }

        if (provider.proveedores.isEmpty) {
          return const Center(
            child: Text(
              'No hay proveedores',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => context.read<ProveedorProvider>().cargar(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.proveedores.length,
            itemBuilder: (context, index) {
              return _ProveedorCard(proveedor: provider.proveedores[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildError(String mensaje) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<ProveedorProvider>().cargar(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _ProveedorCard extends StatelessWidget {
  final Proveedor proveedor;

  const _ProveedorCard({required this.proveedor});

  @override
  Widget build(BuildContext context) {
    final detalles = <Widget>[
      if (proveedor.telefono != null && proveedor.telefono!.isNotEmpty)
        Text(proveedor.telefono!),
      if (proveedor.email != null && proveedor.email!.isNotEmpty)
        Text(proveedor.email!),
      if (proveedor.direccion != null && proveedor.direccion!.isNotEmpty)
        Text(proveedor.direccion!),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.local_shipping_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          proveedor.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: detalles.isEmpty
            ? const Text('Sin datos de contacto')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: detalles,
              ),
      ),
    );
  }
}
