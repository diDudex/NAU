import 'package:flutter/material.dart';
import 'package:nau/pages/perfilconfig.dart';
import 'package:provider/provider.dart';

import '../models/driver.dart'; // Cambié esto para importar DriverProfile
import '../services/auth/auth_services.dart';
import '../services/auth/database/database_provider.dart';

class PerfilScreen extends StatefulWidget {
  //user id
  final String uid;
  const PerfilScreen({super.key, required this.uid});

  @override
  State createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  //providers
  late final listeningProvider = Provider.of<DatabaseProvider>(context);
  late final databaseProvider =
      Provider.of<DatabaseProvider>(context, listen: false);

  late TabController _tabController;

  //user info
  DriverProfile? driverData; // Cambiado a DriverProfile
  String currentDriverId = AuthService().getCurrentUid();

  //loading...
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    //obtener informacion del conductor por uid usando driverProfile
    driverData = await databaseProvider.driverProfile(widget.uid);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    await loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isLoading || driverData == null ? '' : driverData!.name),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: driverData == null
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerfilConfig(
                          driverId: currentDriverId,
                        ),
                      ),
                    );

                    if (result == true) {
                      await loadUser(); // Recargar datos al volver
                    }
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Permite el gesto de refrescar
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : driverData != null
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 70,
                                  backgroundColor:
                                      const Color.fromARGB(255, 187, 184, 184),
                                  backgroundImage: (driverData!.profilePic.isNotEmpty)
                                      ? NetworkImage(driverData!.profilePic)
                                      : null,
                                  child: (driverData!.profilePic.isEmpty)
                                      ? const Icon(Icons.person,
                                          size: 70, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 30),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      //Nickname o nombre de usuario
                                      Text(
                                        '@${driverData!.name}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 19,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                      ),
                      
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            TabBar(
                              controller: _tabController,
                              tabs: const [
                                Tab(text: 'Actividades'),
                                Tab(text: 'Recomendaciones'),
                              ],
                            ),
                            SizedBox(
                              height: 400,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _buildActividadesView(),
                                  _buildRecomendacionesView(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Center(
                      child: Text("No se encontraron datos de usuario"),
                    ),
        ),
      ),
    );
  }

  Widget _buildActividadesView() {
    return const Center(
      child: Text('Actividades'),
    );
  }

  Widget _buildRecomendacionesView() {
    return const Center(
      child: Text('Recomendaciones'),
    );
  }
}
