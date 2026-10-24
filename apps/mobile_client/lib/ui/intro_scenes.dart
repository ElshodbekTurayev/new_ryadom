import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The three story beats of the launch intro, drawn for the deep-green
/// splash: a neighbourhood shop, a bag of groceries, a courier scooter.
/// Inline SVG like `ui/illustrations.dart` (no asset pipeline, palette-true).
enum IntroScene { shop, bag, delivery }

class IntroSceneArt extends StatelessWidget {
  const IntroSceneArt(this.scene, {super.key, this.size = 220});

  final IntroScene scene;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg(scene), width: size, height: size, fit: BoxFit.contain);
  }
}

const _white = '#FFFFFF';
const _mint = '#D4E7DD';
const _green = '#0F5C45';
const _greenMid = '#5CAE8C';
const _orange = '#FF7A2F';
const _orangeSoft = '#FFC9A8';
const _ink = '#14231C';
const _bread = '#F2C48D';

const _head = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">';
const _tail = '</svg>';
// Soft disc behind every scene + a ground shadow, so the three read as a set.
const _stage = '<circle cx="100" cy="98" r="84" fill="$_white" fill-opacity="0.10"/>'
    '<circle cx="100" cy="98" r="62" fill="$_white" fill-opacity="0.08"/>'
    '<ellipse cx="100" cy="164" rx="62" ry="7" fill="#06382A" fill-opacity="0.35"/>';

String _svg(IntroScene scene) {
  switch (scene) {
    case IntroScene.shop:
      return '$_head$_stage'
          // Building.
          '<rect x="48" y="84" width="104" height="80" rx="6" fill="$_white"/>'
          // Awning: orange/white stripes with a scalloped edge.
          '<path d="M42 66h116l-6 22H48z" fill="$_white"/>'
          '<path d="M42 66h23.2l-3.4 22H48zM88.4 66h23.2l-1.2 22H89.6zM134.8 66H158l-6 22h-13.8z" fill="$_orange"/>'
          '<path d="M48 88a7 7 0 0 0 13.8 0M61.8 88a7 7 0 0 0 13.8 0M75.6 88a7 7 0 0 0 14 0M89.6 88a7 7 0 0 0 13.8 0'
          'M103.4 88a7 7 0 0 0 13.8 0M117.2 88a7 7 0 0 0 14 0M131.2 88a7 7 0 0 0 13.8 0M145 88a7 7 0 0 0 7 7" '
          'fill="$_orangeSoft"/>'
          // Sign board.
          '<rect x="74" y="46" width="52" height="16" rx="8" fill="$_white"/>'
          '<rect x="84" y="52" width="32" height="4" rx="2" fill="$_greenMid"/>'
          // Shop window with goods on two shelves.
          '<rect x="58" y="104" width="50" height="40" rx="4" fill="$_mint"/>'
          '<path d="M58 124h50" stroke="$_greenMid" stroke-width="2.5"/>'
          '<rect x="63" y="110" width="9" height="13" rx="2" fill="$_orange"/>'
          '<rect x="75" y="112" width="8" height="11" rx="2" fill="$_green"/>'
          '<circle cx="93" cy="118" r="5" fill="#E8553A"/>'
          '<rect x="63" y="130" width="14" height="13" rx="2" fill="$_bread"/>'
          '<rect x="81" y="128" width="8" height="15" rx="2" fill="$_white" stroke="$_greenMid" stroke-width="1.5"/>'
          '<circle cx="98" cy="137" r="5" fill="$_greenMid"/>'
          // Door.
          '<rect x="116" y="104" width="26" height="60" rx="4" fill="$_green"/>'
          '<circle cx="136" cy="135" r="2.4" fill="$_white"/>'
          '$_tail';

    case IntroScene.bag:
      return '$_head$_stage'
          // Goods peeking out of the bag (drawn first, bag overlaps them).
          '<rect x="66" y="40" width="16" height="64" rx="8" fill="$_bread" transform="rotate(-14 74 72)"/>'
          '<path d="M67 52l9-2M68 62l9-2M69 72l9-2" stroke="#D9A066" stroke-width="2.5" stroke-linecap="round" transform="rotate(-14 74 72)"/>'
          '<path d="M98 50h24v12l4 8v30h-32V70l4-8z" fill="$_white" stroke="$_mint" stroke-width="2"/>'
          '<rect x="94" y="78" width="32" height="12" fill="$_greenMid"/>'
          '<path d="M98 50h24v-6H98z" fill="$_green"/>'
          '<path d="M128 70c6-14 22-12 22-12s-2 16-18 18" fill="$_greenMid"/>'
          '<path d="M134 64c4 2 7 5 9 9" stroke="$_green" stroke-width="2" stroke-linecap="round" fill="none"/>'
          // Paper bag.
          '<path d="M56 86h88l-6 72a6 6 0 0 1-6 5.5H68a6 6 0 0 1-6-5.5z" fill="$_orangeSoft"/>'
          '<path d="M56 86h88l-1.6 18H57.6z" fill="$_orange"/>'
          '<path d="M80 98c0-14 40-14 40 0" fill="none" stroke="$_white" stroke-width="5" stroke-linecap="round"/>'
          // Apple in front.
          '<circle cx="136" cy="146" r="15" fill="#E8553A"/>'
          '<path d="M136 131c0-5 3-8 7-9" stroke="$_ink" stroke-width="2.5" stroke-linecap="round" fill="none"/>'
          '<path d="M137 129c6-6 13-3 13-3s-4 7-12 5" fill="$_greenMid"/>'
          '<circle cx="131" cy="141" r="4" fill="$_white" fill-opacity="0.45"/>'
          // Brand tag on the bag.
          '<circle cx="100" cy="128" r="13" fill="$_white"/>'
          '<path d="M95 135v-14h6a4.5 4.5 0 0 1 0 9h-6m5 0l5 5" stroke="$_green" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
          '$_tail';

    case IntroScene.delivery:
      return '$_head$_stage'
          // Speed lines.
          '<path d="M22 112h26M14 126h30M26 140h20" stroke="$_white" stroke-opacity="0.55" stroke-width="5" stroke-linecap="round"/>'
          // Location pin the scooter is heading to.
          '<path d="M160 46c-12 0-20 9-20 20 0 15 20 32 20 32s20-17 20-32c0-11-8-20-20-20z" fill="$_orange"/>'
          '<circle cx="160" cy="66" r="7" fill="$_white"/>'
          // Delivery box with the brand mark.
          '<rect x="58" y="84" width="40" height="36" rx="6" fill="$_orange"/>'
          '<rect x="58" y="84" width="40" height="9" rx="4" fill="#E0621B"/>'
          '<path d="M73 111v-13h5a4 4 0 0 1 0 8h-5m4.5 0l4.5 5" stroke="$_white" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
          // Scooter body.
          '<path d="M52 128h70l14-30h10l-12 34a10 10 0 0 1-9.4 6.6H58a6 6 0 0 1-6-6z" fill="$_white"/>'
          '<path d="M136 98l-6-14h-10" stroke="$_white" stroke-width="6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>'
          '<path d="M60 120h40" stroke="$_mint" stroke-width="5" stroke-linecap="round"/>'
          // Wheels.
          '<circle cx="66" cy="146" r="14" fill="$_ink"/><circle cx="66" cy="146" r="5.5" fill="$_mint"/>'
          '<circle cx="140" cy="146" r="14" fill="$_ink"/><circle cx="140" cy="146" r="5.5" fill="$_mint"/>'
          // Headlight beam.
          '<circle cx="144" cy="104" r="4" fill="$_orangeSoft"/>'
          '$_tail';
  }
}
