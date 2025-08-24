import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:highschool_demo_1/game.dart';
import 'package:highschool_demo_1/models.dart';
import 'package:uuid/v4.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Room Select"),
      ),
      body: StreamBuilder(
          stream: db.collection("rooms").snapshots(),
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            } else {
              final rooms = snapshot.data!.docs;
              return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, i) {
                    final e = rooms[i];
                    final room = Room.fromDocument(e);
                    if (room.shouldBeDeleted) {
                      e.reference.delete();
                    }
                    if (room.shouldBeHidden) {
                      return const SizedBox.shrink();
                    }
                    final shape = RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    );
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      elevation: 8,
                      shape: shape,
                      child: ListTile(
                          shape: shape,
                          onTap: () async {
                            final uuid = const UuidV4().generate();
                            await e.reference.update({
                              "players": FieldValue.arrayUnion([uuid])
                            });
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => GamePage(
                                          reference: e.reference,
                                          uuid: uuid,
                                        )));
                          },
                          title: Text(
                            "Room ${Room.convertIdToCode(room.id)} (${room.players.length}/$requiredPlayers)",
                            textAlign: TextAlign.center,
                          )),
                    );
                  });
            }
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final uuid = const UuidV4().generate();
          final reference = await db.collection("rooms").add({
            "players": [uuid],
            "state": GameState.empty().toJson(),
            "createdAt": FieldValue.serverTimestamp(),
          });
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GamePage(
                        reference: reference,
                        uuid: uuid,
                      )));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
