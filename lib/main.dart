import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const SoporteApp());
}

class SoporteApp extends StatelessWidget {
  const SoporteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoporteApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const InicioScreen(),
    );
  }
}


class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SoporteApp')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/soporte.png', height: 150),
            const SizedBox(height: 20),
            const Icon(Icons.support_agent, size: 50, color: Colors.blue),
            const SizedBox(height: 10),
            const Text(
              'Gestión de Incidencias Técnicas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Registra y administra los problemas técnicos detectados en los equipos informáticos para facilitar su seguimiento y atención.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegistroIncidenciasScreen()),
                );
              },
              child: const Text('Registrar incidencia'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IncidenciasScreen()),
                );
              },
              child: const Text('Ver incidencias'),
            ),
          ],
        ),
      ),
    );
  }
}


class RegistroIncidenciasScreen extends StatefulWidget {
  final Map? incidenciaExistente;
  const RegistroIncidenciasScreen({super.key, this.incidenciaExistente});

  @override
  State<RegistroIncidenciasScreen> createState() => _RegistroIncidenciasScreenState();
}

class _RegistroIncidenciasScreenState extends State<RegistroIncidenciasScreen> {
  final _formKey = GlobalKey<FormState>();
  final String apiUrl = "http://127.0.0.1:8000/incidencias";

  late TextEditingController nombreCtrl;
  late TextEditingController correoCtrl;
  late TextEditingController equipoCtrl;
  late TextEditingController descCtrl;
  
  String prioridadSel = 'Baja';
  String estadoSel = 'Pendiente';

  @override
  void initState() {
    super.initState();
    final inc = widget.incidenciaExistente;
    nombreCtrl = TextEditingController(text: inc?['nombre_usuario'] ?? '');
    correoCtrl = TextEditingController(text: inc?['correo'] ?? '');
    equipoCtrl = TextEditingController(text: inc?['numero_equipo']?.toString() ?? '');
    descCtrl = TextEditingController(text: inc?['descripcion'] ?? '');
    
    if (inc != null) {
      prioridadSel = inc['prioridad'];
      estadoSel = inc['estado'];
    }
  }

  Future<void> guardarIncidencia() async {
    if (_formKey.currentState!.validate()) {
      final datos = {
        "nombre_usuario": nombreCtrl.text,
        "correo": correoCtrl.text,
        "numero_equipo": int.parse(equipoCtrl.text),
        "descripcion": descCtrl.text,
        "prioridad": prioridadSel,
        "estado": estadoSel
      };

      try {
        http.Response response;
        if (widget.incidenciaExistente == null) {
          response = await http.post(Uri.parse(apiUrl),
              headers: {"Content-Type": "application/json"},
              body: json.encode(datos));
        } else {
          final id = widget.incidenciaExistente!['id'];
          response = await http.put(Uri.parse("$apiUrl/$id"),
              headers: {"Content-Type": "application/json"},
              body: json.encode(datos));
        }

        if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incidencia guardada correctamente')),
            );
            
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error de conexión al guardar la incidencia.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.incidenciaExistente == null ? 'Registrar Incidencia' : 'Editar Incidencia')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre del usuario'),
                validator: (value) => (value == null || value.length < 3) ? 'Obligatorio y mínimo 3 caracteres' : null,
              ),
              TextFormField(
                controller: correoCtrl,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) => (value == null || !value.contains('@') || !value.contains('.')) ? 'Correo inválido (requiere @ y .)' : null,
              ),
              TextFormField(
                controller: equipoCtrl,
                decoration: const InputDecoration(labelText: 'Número de equipo'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Obligatorio';
                  final num = int.tryParse(value);
                  if (num == null || num <= 0) return 'Debe ser numérico y mayor que 0';
                  return null;
                },
              ),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción del problema'),
                validator: (value) => (value == null || value.length < 10) ? 'Obligatorio y mínimo 10 caracteres' : null,
              ),
              DropdownButtonFormField<String>(
                initialValue: prioridadSel,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: ['Baja', 'Media', 'Alta'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => prioridadSel = val!),
              ),
              DropdownButtonFormField<String>(
                initialValue: estadoSel,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: ['Pendiente', 'En proceso', 'Resuelta'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => estadoSel = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: guardarIncidencia,
                child: Text(widget.incidenciaExistente == null ? 'Registrar incidencia' : 'Guardar cambios'),
              )
            ],
          ),
        ),
      ),
    );
  }
}


class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  List incidencias = [];
  final String apiUrl = "http://127.0.0.1:8000/incidencias";

  @override
  void initState() {
    super.initState();
    cargarIncidencias();
  }

  Future<void> cargarIncidencias() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          incidencias = json.decode(response.body);
        });
      }
    } catch (e) {
      // Manejo de error de conexión
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Incidencias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarIncidencias,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: incidencias.length,
        itemBuilder: (context, index) {
          final inc = incidencias[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(inc['nombre_usuario']),
              subtitle: Text("Equipo: ${inc['numero_equipo']} | Prioridad: ${inc['prioridad']} | Estado: ${inc['estado']}"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final actualizar = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DetalleIncidenciaScreen(incidencia: inc)),
                );
                if (actualizar == true) {
                  cargarIncidencias();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class DetalleIncidenciaScreen extends StatelessWidget {
  final Map incidencia;
  const DetalleIncidenciaScreen({super.key, required this.incidencia});

  IconData obtenerIconoPrioridad(String prioridad) {
    if (prioridad == 'Alta') return Icons.error;
    if (prioridad == 'Media') return Icons.warning;
    return Icons.info;
  }

  Future<void> eliminarIncidencia(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar este registro?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      if (context.mounted) {
        final String apiUrl = "http://127.0.0.1:8000/incidencias/${incidencia['id']}";
        await http.delete(Uri.parse(apiUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incidencia eliminada')));
          Navigator.pop(context, true); 
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Incidencia')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(obtenerIconoPrioridad(incidencia['prioridad']), size: 40, color: Colors.blueGrey),
                const SizedBox(width: 15),
                Expanded(child: Text(incidencia['nombre_usuario'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              ],
            ),
            const Divider(height: 30),
            Text('Correo: ${incidencia['correo']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Equipo: ${incidencia['numero_equipo']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Prioridad: ${incidencia['prioridad']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Estado: ${incidencia['estado']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Fecha: ${incidencia['fecha_registro'] ?? "Desconocida"}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text('Descripción:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Text(incidencia['descripcion'], style: const TextStyle(fontSize: 16)),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                  onPressed: () async {
                    final actualizar = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegistroIncidenciasScreen(incidenciaExistente: incidencia)),
                    );
                    if (actualizar == true && context.mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text('Eliminar'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => eliminarIncidencia(context),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}