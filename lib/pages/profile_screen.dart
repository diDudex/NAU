import 'package:flutter/material.dart';
import 'package:nau/pages/perfilconfig.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/auth/auth_services.dart';
import '../services/auth/database/database_provider.dart';
import 'document_page.dart';

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
  UserProfile? userData;
  String currentUserId = AuthService().getCurrentUid();

  //loading...
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    //getUserData();
    loadUser();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadUser() async {
    //obtener informacion del usuario
    userData = await databaseProvider.userProfile(widget.uid);
    //finalizar la carga
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _handleRefresh() async {
    await loadUser();
  }

  //build de la interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_isLoading || userData == null ? '' : userData!.name),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: userData == null
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DocumentPage(
                          userId: currentUserId,
                          userData: userData!.toMap(),
                        ),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: userData == null
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PerfilConfig(
                          userId: currentUserId,
                          userData: userData!.toMap(),
                        ),
                      ),
                    );

                    if (result == true) {
                      await loadUser(); // <- esta debe ser tu función para recargar los datos
                    }
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Importante para permitir el gesto de deslizamiento y actualizar
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : userData != null
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 70,
                                backgroundColor:
                                    const Color.fromARGB(255, 187, 184, 184),
                                backgroundImage:
                                    (userData!.profilePic.isNotEmpty)
                                        ? NetworkImage(userData!.profilePic)
                                        : null,
                                child: (userData!.profilePic.isEmpty)
                                    ? const Icon(Icons.person,
                                        size: 70, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 30),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //Nickname
                                    Text(
                                      '@${userData!.username}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    //Nivel de cuenta
                                    Text(
                                      "Nivel:",
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    //Wallet
                                    Text(
                                      "Wallet:",
                                      style: TextStyle(
                                        fontSize: 15,
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
                          if (userData!.bio.isNotEmpty) ...[
                            Text(
                              userData!.bio,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                          const Divider(),
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Actividades'),
                              Tab(text: 'Recomendaciones'),
                            ],
                          ),
                          SizedBox(
                            height:
                                400, // Ajusta este valor según lo que quieras
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
                    )
                  : const Center(
                      child: Text("No se encontraron datos de usuario")),
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
