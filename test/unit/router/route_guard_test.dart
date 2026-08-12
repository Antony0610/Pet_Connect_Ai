import 'package:flutter_test/flutter_test.dart';
import 'package:petconnect_ai/core/theme/portal_theme.dart';
import 'package:petconnect_ai/features/auth/domain/entities/user_profile.dart';
import 'package:petconnect_ai/router/route_guard.dart';
import 'package:petconnect_ai/router/route_paths.dart';

void main() {
  group('RouteGuard Unit Tests', () {
    test('portalHome maps AppPortal roles to correct portal home routes', () {
      expect(
        RouteGuard.portalHome(AppPortal.petOwner),
        RoutePaths.ownerHome,
      );
      expect(
        RouteGuard.portalHome(AppPortal.veterinarian),
        RoutePaths.vetHome,
      );
      expect(
        RouteGuard.portalHome(AppPortal.volunteerRescue),
        RoutePaths.rescueHome,
      );
      expect(
        RouteGuard.portalHome(AppPortal.administrator),
        RoutePaths.adminHome,
      );
    });

    test(
        'AppPortalExtension converts to and from database role strings correctly',
        () {
      expect(AppPortal.petOwner.toDbRole(), 'pet_owner');
      expect(AppPortal.veterinarian.toDbRole(), 'veterinarian');
      expect(AppPortal.volunteerRescue.toDbRole(), 'volunteer_rescue');
      expect(AppPortal.administrator.toDbRole(), 'administrator');

      expect(AppPortalExtension.fromDbRole('pet_owner'), AppPortal.petOwner);
      expect(
          AppPortalExtension.fromDbRole('veterinarian'), AppPortal.veterinarian);
      expect(AppPortalExtension.fromDbRole('volunteer_rescue'),
          AppPortal.volunteerRescue);
      expect(AppPortalExtension.fromDbRole('administrator'),
          AppPortal.administrator);
      expect(AppPortalExtension.fromDbRole(null), AppPortal.petOwner);
      expect(AppPortalExtension.fromDbRole('unknown'), AppPortal.petOwner);
    });
  });
}
