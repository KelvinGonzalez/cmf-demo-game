import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

const gridSize = 10;
var gridColors = <Color>[
  Colors.pink.shade300,
  Colors.red.shade700,
  Colors.orange.shade800,
  Colors.amber,
  Colors.lime.shade700,
  Colors.green.shade700,
  Colors.cyan.shade300,
  Colors.blue,
  Colors.purple
];
const choiceSize = 3;
const requiredPlayers = 2;

Color get randomColor => gridColors[Random().nextInt(gridColors.length)];

class Room {
  final List<String> players;
  final GameState state;
  final Timestamp createdAt;

  bool get shouldBeHidden =>
      players.length >= requiredPlayers ||
      players.isEmpty ||
      createdAt
              .toDate()
              .add(const Duration(minutes: 15))
              .compareTo(DateTime.now()) <
          0;

  bool get shouldBeDeleted =>
      players.isEmpty ||
      createdAt
              .toDate()
              .add(const Duration(days: 1))
              .compareTo(DateTime.now()) <
          0;

  const Room(
      {required this.players, required this.state, required this.createdAt});

  factory Room.fromDocument(DocumentSnapshot document) => Room(
      players: List<String>.from(document.get("players")),
      state:
          GameState.fromJson(Map<String, dynamic>.from(document.get("state"))),
      createdAt: document.get("createdAt") ?? Timestamp.now());

  void saveState(DocumentReference reference) =>
      reference.update({"state": state.toJson()});

  bool chooseColor(int colorIndex, String player, DocumentReference reference) {
    if (players[state.turn] != player) return false;
    state.selectedColor = colorIndex;
    saveState(reference);
    return true;
  }

  int scanArea(
      int row, int col, Color selectedColor, Set<(int, int)> positions) {
    if (row < 0 ||
        row >= gridSize ||
        col < 0 ||
        col >= gridSize ||
        positions.contains((row, col))) {
      return state.turn;
    }

    final gridPiece = state.grid[row][col];
    if (gridPiece.color != selectedColor) return state.turn;

    positions.add((row, col));

    int owner = gridPiece.owner ?? state.turn;
    for (final dir in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final result =
          scanArea(row + dir.$1, col + dir.$2, selectedColor, positions);
      if (result != state.turn) {
        owner = result;
      }
    }
    return owner;
  }

  void claimArea(int row, int col, Color selectedColor) {
    final positions = <(int, int)>{};
    final owner = scanArea(row, col, selectedColor, positions);
    for (final p in positions) {
      state.grid[p.$1][p.$2].owner = owner;
    }
  }

  void paintArea(int row, int col, Color areaColor, Color selectedColor) {
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return;
    if (state.grid[row][col].color != areaColor) return;

    state.grid[row][col].color = selectedColor;

    for (final dir in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      paintArea(row + dir.$1, col + dir.$2, areaColor, selectedColor);
    }
  }

  bool performMove(
      int row, int col, String player, DocumentReference reference) {
    if (players[state.turn] != player) return false;
    final selectedColor = state.selectedColorResult;
    if (selectedColor == null) return false;
    if (state.grid[row][col].color == selectedColor) {
      return false;
    }

    paintArea(row, col, state.grid[row][col].color, selectedColor);
    claimArea(row, col, selectedColor);

    state.turn = (state.turn + 1) % requiredPlayers;
    state.choices[state.selectedColor!] = randomColor;
    state.selectedColor = null;

    saveState(reference);
    return true;
  }

  int? checkWin() {
    final counts = List.filled(requiredPlayers, 0);
    for (final row in state.grid) {
      for (final e in row) {
        if (e.owner == null) return null;
        counts[e.owner!] += 1;
      }
    }
    return counts.indexOf(counts.max);
  }
}

class GameState {
  int turn;
  List<List<GridPiece>> grid;
  List<Color> choices;
  int? selectedColor;

  Color? get selectedColorResult =>
      selectedColor != null ? choices[selectedColor!] : null;

  GameState(
      {required this.turn,
      required this.grid,
      required this.choices,
      required this.selectedColor});

  factory GameState.fromJson(Map<String, dynamic> json) {
    final gridData = List<Map<String, dynamic>>.from(json["grid"])
        .map((e) => GridPiece.fromJson(e))
        .slices(gridSize)
        .toList();
    return GameState(
        turn: json["turn"],
        grid: gridData,
        choices: List<Color>.from(json["choices"].map((e) => gridColors[e])),
        selectedColor: json["selectedColor"]);
  }

  factory GameState.empty() => GameState(
      turn: 0,
      grid: List.generate(
          gridSize,
          (_) => List.generate(
              gridSize, (_) => GridPiece(color: randomColor, owner: null))),
      choices: List.generate(choiceSize, (_) => randomColor),
      selectedColor: null);

  Map<String, dynamic> toJson() => {
        "turn": turn,
        "grid": grid.expand((r) => r.map((e) => e.toJson())).toList(),
        "choices": choices.map((e) => gridColors.indexOf(e)).toList(),
        "selectedColor": selectedColor,
      };
}

class GridPiece {
  Color color;
  int? owner;

  GridPiece({required this.color, required this.owner});

  factory GridPiece.fromJson(Map<String, dynamic> json) =>
      GridPiece(color: gridColors[json["color"]], owner: json["owner"]);

  Map<String, dynamic> toJson() => {
        "color": gridColors.indexOf(color),
        "owner": owner,
      };
}
