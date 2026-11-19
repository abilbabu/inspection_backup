/// Helpers for job cards that hold several sequential inspection "rounds".
///
/// Every inspection master carries `vimInspectionRound` (null/missing = 1) and
/// the job card carries `jobInspectionRound` (null = 1) = the active round.
/// Basic/quick masters (`vimInspectionType == 0`) have no round and are always
/// kept. Re-inspection masters share the round of the inspection they re-inspect.
///
/// Workflow logic (form loading, summary, re-inspection) should only ever look
/// at the active round, so callers filter the `inspections` list once with
/// [InspectionRoundHelper.activeRoundInspections] and keep their existing
/// positional / first / last logic unchanged. Old data without rounds is
/// treated as round 1, which gives identical behaviour.
class InspectionRoundHelper {
  InspectionRoundHelper._();

  static int _toInt(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? "") ?? fallback;
  }

  static Map? _masterOf(dynamic inspection) {
    if (inspection is! Map) return null;
    final master = inspection["master"];
    return master is Map ? master : null;
  }

  static bool _isBasic(Map? master) =>
      master != null && _toInt(master["vimInspectionType"], -1) == 0;

  /// Round of a single inspection master (`vimInspectionRound`, default 1).
  static int inspectionRoundOf(Map? master) {
    final round = _toInt(master?["vimInspectionRound"], 1);
    return round > 0 ? round : 1;
  }

  /// Active round: the highest round among non-basic masters, or the job
  /// card's `jobInspectionRound` when that is higher. Defaults to 1.
  static int activeInspectionRound(List inspections, {dynamic jobRound}) {
    int active = _toInt(jobRound, 1);
    if (active < 1) active = 1;
    for (final inspection in inspections) {
      final master = _masterOf(inspection);
      if (master == null || _isBasic(master)) continue;
      final round = inspectionRoundOf(master);
      if (round > active) active = round;
    }
    return active;
  }

  /// Basic masters plus the non-basic masters of the active round, preserving
  /// the original order. Entries without a master map are kept as-is.
  static List activeRoundInspections(List? inspections, {dynamic jobRound}) {
    if (inspections == null || inspections.isEmpty) return inspections ?? [];
    final active = activeInspectionRound(inspections, jobRound: jobRound);
    return inspections.where((inspection) {
      final master = _masterOf(inspection);
      if (master == null || _isBasic(master)) return true;
      return inspectionRoundOf(master) == active;
    }).toList();
  }

  /// Reads the job card's active round from a job list item or an API `data`
  /// map (top level, `jobCard` or `jobcard`).
  static dynamic jobRoundOf(Map? data) {
    if (data == null) return null;
    final jobCard = data["jobCard"] ?? data["jobcard"];
    return data["jobInspectionRound"] ??
        (jobCard is Map ? jobCard["jobInspectionRound"] : null);
  }

  /// First non-basic master of the active round (falls back to the first
  /// master), used to decide which form / inspection type to open.
  static Map? primaryActiveMaster(List? inspections, {dynamic jobRound}) {
    final active = activeRoundInspections(inspections, jobRound: jobRound);
    Map? fallback;
    for (final inspection in active) {
      final master = _masterOf(inspection);
      if (master == null) continue;
      fallback ??= master;
      if (!_isBasic(master)) return master;
    }
    return fallback;
  }
}
