import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Map the string icon keys used by seed data to Lucide icons.
/// Kept small + explicit so we can extend it as the app grows.
class AppIcons {
  static IconData byKey(String key) {
    switch (key) {
      case 'home':         return LucideIcons.home;
      case 'check':        return LucideIcons.check;
      case 'checkCircle':  return LucideIcons.checkCircle;
      case 'wallet':       return LucideIcons.wallet;
      case 'calendar':     return LucideIcons.calendar;
      case 'more':         return LucideIcons.moreHorizontal;
      case 'plus':         return LucideIcons.plus;
      case 'dumbbell':     return LucideIcons.dumbbell;
      case 'camera':       return LucideIcons.camera;
      case 'flame':        return LucideIcons.flame;
      case 'bell':         return LucideIcons.bell;
      case 'search':       return LucideIcons.search;
      case 'settings':     return LucideIcons.settings;
      case 'chev':         return LucideIcons.chevronRight;
      case 'arrowUp':      return LucideIcons.arrowUp;
      case 'arrowDown':    return LucideIcons.arrowDown;
      case 'trendUp':      return LucideIcons.trendingUp;
      case 'trendDown':    return LucideIcons.trendingDown;
      case 'clock':        return LucideIcons.clock;
      case 'image':        return LucideIcons.image;
      case 'note':         return LucideIcons.fileText;
      case 'link':         return LucideIcons.link;
      case 'lock':         return LucideIcons.lock;
      case 'user':         return LucideIcons.user;
      case 'sparkle':      return LucideIcons.sparkles;
      case 'close':        return LucideIcons.x;
      case 'droplet':      return LucideIcons.droplet;
      case 'heart':        return LucideIcons.heart;
      case 'utensils':     return LucideIcons.utensils;
      case 'gift':         return LucideIcons.gift;
      case 'refresh':      return LucideIcons.refreshCw;
      case 'cloud':        return LucideIcons.cloud;
      default:             return LucideIcons.circle;
    }
  }
}
