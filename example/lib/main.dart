import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:devlens/devlens.dart';

// ============================================================================
// THAT'S ALL YOU NEED TO SETUP DEVLENS!
// ============================================================================

final dio = Dio()..interceptors.add(DevLensDioInterceptor());

void main() {
  DevLens.init();
  runApp(
    DevLensOverlay(
      enabled: kDebugMode,
      child: const MyApp(),
    ),
  );
}

// ============================================================================
// YOUR EXISTING APP CODE - NO CHANGES NEEDED!
// ============================================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevLens Example',
      theme: ThemeData.dark(),
      home: const OrdersScreen(),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    // Simulate API call - DevLens captures this automatically!
    await Future.delayed(const Duration(milliseconds: 500));

    // In real app, this would be: await dio.get('/orders')
    DevLens.instance.recordRequest(NetworkDataRecord(
      id: '1',
      method: 'GET',
      url: Uri.parse('https://api.example.com/orders'),
      statusCode: 200,
      responseBody: {
        'orders': [
          {
            'id': '001',
            'numCommande': 1234,
            'montant': 150.500,
            'statut': 'livrée',
            'client': {'nom': 'Ahmed', 'prenom': 'Ben Ali'},
            'items': [
              {'designation': 'Pizza Margherita', 'prix': 25.000, 'quantite': 2},
              {'designation': 'Coca Cola', 'prix': 3.500, 'quantite': 3},
            ],
          },
          {
            'id': '002',
            'numCommande': 1235,
            'montant': 89.000,
            'statut': 'en cours de préparation',
            'client': {'nom': 'Fatma', 'prenom': 'Trabelsi'},
            'items': [
              {'designation': 'Salade César', 'prix': 18.000, 'quantite': 1},
            ],
          },
          {
            'id': '003',
            'numCommande': 1236,
            'montant': 245.750,
            'statut': 'annulée',
            'client': {'nom': 'Mohamed', 'prenom': 'Gharbi'},
            'items': [
              {'designation': 'Steak Frites', 'prix': 45.000, 'quantite': 2},
              {'designation': 'Tiramisu', 'prix': 12.500, 'quantite': 4},
            ],
          },
        ],
      },
      timestamp: DateTime.now(),
      duration: const Duration(milliseconds: 234),
    ));

    setState(() {
      orders = [
        Order(id: '001', numCommande: 1234, montant: 150.500, statut: 'livrée', clientNom: 'Ben Ali Ahmed'),
        Order(id: '002', numCommande: 1235, montant: 89.000, statut: 'en cours de préparation', clientNom: 'Trabelsi Fatma'),
        Order(id: '003', numCommande: 1236, montant: 245.750, statut: 'annulée', clientNom: 'Gharbi Mohamed'),
      ];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('DevLens Demo'),
                  content: const Text(
                    'Hold the MOUSE WHEEL BUTTON and hover over any data in the table to see the network response!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('GOT IT'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildOrdersTable(),
    );
  }

  Widget _buildOrdersTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mouse, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Hold MOUSE WHEEL and hover over any cell to inspect its network data!',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[900]),
              columns: const [
                DataColumn(label: Text('Order #')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Client')),
              ],
              // NO WRAPPERS NEEDED! Just your normal DataRows!
              rows: orders.map((order) => DataRow(
                cells: [
                  DataCell(Text(
                    '#${order.numCommande}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  DataCell(Text(
                    '${order.montant.toStringAsFixed(3)} DT',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )),
                  DataCell(_buildStatusChip(order.statut)),
                  DataCell(Text(order.clientNom)),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'livrée':
        color = Colors.green;
        break;
      case 'en cours de préparation':
        color = Colors.orange;
        break;
      case 'annulée':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class Order {
  final String id;
  final int numCommande;
  final double montant;
  final String statut;
  final String clientNom;

  Order({
    required this.id,
    required this.numCommande,
    required this.montant,
    required this.statut,
    required this.clientNom,
  });
}