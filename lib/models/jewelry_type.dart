import 'package:flutter/material.dart';

enum JewelryType {
  earrings,
  necklace,
  ring,
  bangle,
  nosePin,
  chain;

  String get displayName {
    switch (this) {
      case JewelryType.earrings:
        return 'Earrings';
      case JewelryType.necklace:
        return 'Necklace';
      case JewelryType.ring:
        return 'Ring';
      case JewelryType.bangle:
        return 'Bangle / Bracelet';
      case JewelryType.nosePin:
        return 'Nose Pin';
      case JewelryType.chain:
        return 'Chain';
    }
  }

  String get targetAnchor {
    switch (this) {
      case JewelryType.earrings:
        return 'ears';
      case JewelryType.necklace:
        return 'neck';
      case JewelryType.ring:
        return 'finger';
      case JewelryType.bangle:
        return 'wrist';
      case JewelryType.nosePin:
        return 'nose';
      case JewelryType.chain:
        return 'neck/body';
    }
  }

  String get description {
    switch (this) {
      case JewelryType.earrings:
        return 'Flagship AI placement on left & right ears';
      case JewelryType.necklace:
        return 'Precise alignment around neck & collarbone';
      case JewelryType.ring:
        return 'Finger positioning and lighting estimation';
      case JewelryType.bangle:
        return 'Wrist placement with realistic reflections';
      case JewelryType.nosePin:
        return 'Subtle facial landmark nose pin fitting';
      case JewelryType.chain:
        return 'Neck and upper torso chain contouring';
    }
  }

  IconData get iconData {
    switch (this) {
      case JewelryType.earrings:
        return Icons.auto_awesome;
      case JewelryType.necklace:
        return Icons.all_inclusive;
      case JewelryType.ring:
        return Icons.verified;
      case JewelryType.bangle:
        return Icons.circle_outlined;
      case JewelryType.nosePin:
        return Icons.flare;
      case JewelryType.chain:
        return Icons.link;
    }
  }
}
