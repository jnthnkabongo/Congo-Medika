import 'package:flutter/material.dart';
import 'appel_en_cours.dart';

class AppelVideo extends StatelessWidget {
  final String? meetingId;
  final String? token;
  final String? organizationId;
  final String? targetUserId;
  final String? targetUserRole;
  final String? teleconsultationId;
  final bool isCaller;

  const AppelVideo({
    super.key,
    this.meetingId,
    this.token,
    this.organizationId,
    this.targetUserId,
    this.targetUserRole,
    this.teleconsultationId,
    this.isCaller = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppelEnCours(
      meetingId: meetingId,
      token: token,
      organizationId: organizationId,
      targetUserId: targetUserId,
      targetUserRole: targetUserRole,
      teleconsultationId: teleconsultationId,
      isCaller: isCaller,
      callType: 'video',
    );
  }
}
