import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Gold for the main pot.
const Color potGold = Color(0xFFE6B422);

/// Silver for the first side pot.
const Color potSilver = Color(0xFFBFC7D1);

/// Bronze for every further side pot.
const Color potBronze = Color(0xFFCD7F32);

/// The colour of a pot by index: main pot gold, second pot silver, every
/// pot after that bronze. Used for the pot pills on the felt and for the
/// winner visuals while that pot is presented.
Color potColor(int index) => switch (index) {
  0 => potGold,
  1 => potSilver,
  _ => potBronze,
};

/// Dark ink that stays readable on all three pot colours.
const Color potInk = Color(0xFF3A2A00);
