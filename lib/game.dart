import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:highschool_demo_1/models.dart';

class GamePage extends StatelessWidget {
  final DocumentReference reference;
  final String uuid;

  const GamePage({super.key, required this.reference, required this.uuid});

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      onPopInvokedWithResult: (didPop, value) async {
        final delete =
            Room.fromDocument(await reference.get()).players.length <= 1;
        if (!delete) {
          reference.update({
            "players": FieldValue.arrayRemove([uuid]),
            "state": GameState.empty().toJson(),
          });
        } else {
          reference.delete();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("In-Game (${Room.convertIdToCode(reference.id)})"),
        ),
        body: StreamBuilder(
            stream: reference.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.data == null || !snapshot.data!.exists) {
                return const Center(child: CircularProgressIndicator());
              }
              final room = Room.fromDocument(snapshot.data!);
              if (room.players.length < requiredPlayers) {
                return Center(
                  child: Text(
                    "Waiting for players...\n${room.players.length}/$requiredPlayers",
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                final screenSize = MediaQuery.of(context).size;
                final dimension =
                    min(screenSize.width, screenSize.height * 3 / 4);
                final sizePerItem = dimension / (gridSize + 1);
                final icons = [Icons.close, Icons.circle_outlined];
                final textIcons = ["X", "O"];
                final winner = room.checkWin();
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          winner == null
                              ? (room.players[room.state.turn] != uuid
                                  ? "Player ${textIcons[room.state.turn]}'s Turn"
                                  : "It is Your Turn")
                              : (room.players[winner] != uuid
                                  ? "Player ${textIcons[winner]} Wins"
                                  : "You Win"),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: room.state.grid
                              .mapIndexed((i, r) => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: r
                                        .mapIndexed((j, e) => GestureDetector(
                                              onTap: () => winner == null
                                                  ? room.performMove(
                                                      i, j, uuid, reference)
                                                  : null,
                                              child: Container(
                                                width: sizePerItem,
                                                height: sizePerItem,
                                                color: e.color,
                                                child: e.owner != null
                                                    ? Icon(icons[e.owner!])
                                                    : const SizedBox.shrink(),
                                              ),
                                            ))
                                        .toList(),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: room.state.choices
                              .mapIndexed((i, e) => Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: GestureDetector(
                                      onTap: () => winner == null
                                          ? room.chooseColor(i, uuid, reference)
                                          : null,
                                      child: Container(
                                        width: sizePerItem * 1.5,
                                        height: sizePerItem * 1.5,
                                        decoration: BoxDecoration(
                                          color: e,
                                          shape: BoxShape.circle,
                                          border: room.state.selectedColor == i
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 4,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        )
                      ],
                    ),
                  ),
                );
              }
            }),
      ),
    );
  }
}
