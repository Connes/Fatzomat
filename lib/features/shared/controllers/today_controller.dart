import '../../../core/controllers/async_controller.dart';
import '../../../data/cache/offline_cache.dart';
import '../../../data/models/today_plan.dart';
import '../../../data/repositories/personal_today_repository.dart';

class TodayController extends AsyncController<TodayPlan> {
  final PersonalTodayRepository repository;
  final OfflineCache cache;
  bool servedFromCache = false;

  TodayController({PersonalTodayRepository? repository, OfflineCache? cache})
      : repository = repository ?? PersonalTodayRepository(),
        cache = cache ?? OfflineCache();

  @override
  Future<TodayPlan?> fetch() async {
    try {
      final plan = await repository.todayPlan();
      servedFromCache = false;
      await cache.writeToday(plan == null ? null : _toCacheMap(plan));
      return plan;
    } catch (error) {
      final cached = await cache.readToday();
      if (cached != null) {
        servedFromCache = true;
        return TodayPlan.fromMap(cached);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _toCacheMap(TodayPlan plan) => {
        'id': plan.id,
        'recipe_id': plan.recipeId,
        'decision_type': plan.decisionType,
        'decision_value': plan.decisionValue,
        'status': plan.status,
        'servings': plan.servings,
        'recipes': {
          'name': plan.name,
          'description': plan.description,
          'image_url': plan.imageUrl,
          'image_path': plan.imagePath,
        },
      };
}
