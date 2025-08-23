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
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: snapshot.data!.docs.map((e) {
                    final room = Room.fromDocument(e);
                    if (room.shouldBeDeleted) {
                      e.reference.delete();
                    }
                    if (room.shouldBeHidden) {
                      return const SizedBox.shrink();
                    }
                    return ElevatedButton(
                        onPressed: () async {
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
                        child: Text(
                            "${room.players.firstOrNull?.substring(0, 8)}'s Room (${room.players.length}/2)"));
                  }).toList(),
                ),
              );
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
