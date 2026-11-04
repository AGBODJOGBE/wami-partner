/// Socle partagé des applications WAMI (client, Pro, Business).
///
/// Contenu : design system (tokens, thème, composants), réseau, gestion des
/// erreurs, contrats de cas d'usage et utilitaires. Aucune règle métier
/// propre à une application ne doit vivre ici.
library;

export 'src/config/app_config.dart';
export 'src/data/fake_backend.dart';
export 'src/data/repository_guard.dart';
export 'src/di/service_locator.dart';
export 'src/domain/service_art.dart';
export 'src/error/exceptions.dart';
export 'src/error/failures.dart';
export 'src/network/api_client.dart';
export 'src/network/auth_interceptor.dart';
export 'src/theme/wami_colors.dart';
export 'src/theme/wami_palette.dart';
export 'src/theme/wami_theme.dart';
export 'src/theme/wami_tokens.dart';
export 'src/theme/wami_typography.dart';
export 'src/usecase/usecase.dart';
export 'src/utils/formatters.dart';
export 'src/utils/load_status.dart';
export 'src/utils/result.dart';
export 'src/widgets/glass_card.dart';
export 'src/widgets/partner_widgets.dart';
export 'src/widgets/route_map_view.dart';
export 'src/widgets/wami_background.dart';
export 'src/widgets/wami_basics.dart';
export 'src/widgets/wami_buttons.dart';
export 'src/widgets/wami_live.dart';
export 'src/widgets/wami_scaffold.dart';
export 'src/widgets/wami_selectors.dart';
export 'src/widgets/wami_text_field.dart';
