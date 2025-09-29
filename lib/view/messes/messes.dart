import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:voxbox/functions/styles.dart';
import 'package:voxbox/models/messe.dart';
import 'package:voxbox/services/api_response.dart';
import 'package:voxbox/services/messe_service.dart';
import 'package:voxbox/view/messes/add_messe.dart';

class MessesScreen extends StatefulWidget {
  const MessesScreen({super.key});

  @override
  State<MessesScreen> createState() => _MessesScreenState();
}

class _MessesScreenState extends State<MessesScreen> {
  List<Messe> messes = [];
  bool loading = false;
  bool syncing = false;

  @override
  void initState() {
    super.initState();
    loadMessess();
  }

  Future<void> loadMessess() async {
    setState(() {
      loading = true;
    });

    ApiResponse response = await MesseService.getMessess();
    
    setState(() {
      loading = false;
      if (response.error == null) {
        messes = response.data as List<Messe>;
      }
    });
  }

  Future<void> syncMessess() async {
    setState(() {
      syncing = true;
    });

    await MesseService.syncMessess();
    await loadMessess();

    setState(() {
      syncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Synchronisation terminée'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messes"),
        backgroundColor: theme,
        foregroundColor: Colors.white,
        actions: [
          if (syncing)
            Padding(
              padding: EdgeInsets.all(16.0),
              child: SpinKitCircle(
                color: Colors.white,
                size: 20.0,
              ),
            ),
          IconButton(
            onPressed: syncing ? null : syncMessess,
            icon: Icon(Icons.sync),
            tooltip: 'Synchroniser',
          ),
        ],
      ),
      body: loading
          ? Center(
              child: SpinKitCircle(
                color: theme,
                size: 50.0,
              ),
            )
          : messes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucune messe disponible',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ajoutez votre première messe !',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16.0),
                  itemCount: messes.length,
                  itemBuilder: (context, index) {
                    Messe messe = messes[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme,
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          messe.title ?? 'Sans titre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(messe.description ?? ''),
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16),
                                SizedBox(width: 4),
                                Text(messe.date ?? ''),
                                SizedBox(width: 16),
                                Icon(Icons.person, size: 16),
                                SizedBox(width: 4),
                                Text(messe.voicePart ?? ''),
                              ],
                            ),
                            if (messe.status == 'pending')
                              Container(
                                margin: EdgeInsets.only(top: 4),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'En attente de synchronisation',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Ouvrir les détails de la messe
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddMesseScreen()),
          );
          if (result == true) {
            await loadMessess();
          }
        },
        backgroundColor: theme,
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}