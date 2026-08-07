# 🍅 Purple Tomato — Full Repository Audit & Master Action Plan

> **Audit Date:** August 2026  
> **Repository:** `Purple tomato - Repo`  
> **Status Summary:** All 9 Audit & Architectural Remediation Phases Completed ✅

---

## 📊 Master Tabular Action Plan & Audit Matrix

| Category | Item ID | Specific Requirement / Audit Finding | Implementation Details & File Target | Status | Priority |
|---|---|---|---|---|---|
| **Security** | `SEC-01` | Secret keys hardcoded in `api_config.dart` | Removed keys; load dynamically via `.env` & `--dart-define` ([api_config.dart](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/core/config/api_config.dart)) | Completed ✅ | P0 |
| **Security** | `SEC-02` | Upstox OAuth access token stored unencrypted in Hive | Migrated token persistence to `flutter_secure_storage` ([upstox_auth_provider.dart](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/core/providers/upstox_auth_provider.dart)) | Completed ✅ | P0 |
| **Security** | `SEC-03` | `.env` files risking accidental git check-in | Added `.env`, `.env.local`, `.env.production` to `.gitignore` & provided `.env.example` | Completed ✅ | P0 |
| **Code Quality** | `QUAL-01` | Raw `print()` statements redacting tokens & suppressing lints | Created [`AppLogger`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/core/utils/app_logger.dart); replaced all ~50+ `print()` calls in `lib/` | Completed ✅ | P1 |
| **Code Quality** | `QUAL-02` | Linter rules suppressed in `analysis_options.yaml` | Re-enabled `avoid_print`, `implicit-casts: false`, and `implicit-dynamic: false` | Completed ✅ | P1 |
| **Architecture** | `ARCH-01` | Type-first folder layout creating high coupling | Refactored layout to feature-first pattern (`lib/features/`, `lib/core/`, `lib/domain/`) | Completed ✅ | P1 |
| **Architecture** | `ARCH-02` | Global error handling missing for uncaught async errors | Registered `FlutterError.onError` and `PlatformDispatcher.onError` handlers in [`main.dart`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/main.dart) | Completed ✅ | P1 |
| **Navigation** | `NAV-01` | Direct URL entry on `/stock` crashed due to null `state.extra` | Refactored route path to `/stock/:symbol` with dynamic fallback parsing in [`app_router.dart`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/core/router/app_router.dart) | Completed ✅ | P0 |
| **Refactoring** | `REF-01` | `StockDetailScreen` monolithic size (>800 lines) | Extracted [`TradeExecutionSheet`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/features/market/widgets/trade_execution_sheet.dart) component widget | Completed ✅ | P1 |
| **Refactoring** | `REF-02` | `AdvisorScreen` inline chat bubble rendering | Extracted [`AiInsightCard`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/features/advisor/widgets/ai_insight_card.dart) with attachment badges & SEBI disclaimers | Completed ✅ | P1 |
| **AI Advisor** | `AI-01` | AI responses lacked user portfolio context & quick actions | Added quick action chips, injected wallet/holdings context into Gemini prompt templates | Completed ✅ | P1 |
| **UX & Web** | `UX-01` | Mobile-first layout stretched awkwardly across desktop monitors | Defined layout breakpoints (`600px`, `900px`, `1200px`) in [`app_theme.dart`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/shared/theme/app_theme.dart) & centered home containers | Completed ✅ | P2 |
| **Engine** | `ENG-01` | Virtual trading engine limited to instant market orders | Implemented **Limit Orders**, **Stop-Loss Triggers**, and automated price matching engine in [`portfolio_provider.dart`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/lib/core/providers/portfolio_provider.dart) | Completed ✅ | P1 |
| **Cloud Security** | `CLOUD-01` | Web JS bundle embeds `--dart-define` secret keys | Created TypeScript Supabase Edge Function ([`upstox-oauth`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/supabase/functions/upstox-oauth/index.ts)) to proxy code exchange | Completed ✅ | P1 |
| **CI/CD** | `CICD-01` | Web deployment script relies on manual invocation | Created GitHub Actions CI/CD workflow ([`deploy-web.yml`](file:///Users/Ashish/Documents/Git%20repo/Purple%20tomato%20-%20Repo/purple-tomato/.github/workflows/deploy-web.yml)) running analysis, tests, and web build | Completed ✅ | P2 |
| **Testing** | `TEST-01` | Zero test coverage for domain models & UI widgets | Wrote unit/widget tests for `Wallet`, `AppLogger`, `UpstoxService`, `GeminiService`, `pending_order_test.dart`, `supabase_edge_gateway_test.dart`, `TradeExecutionSheet`, and `AiInsightCard` | Completed ✅ | P1 |

---

## 📌 Verification Commands
To verify the health and status of the repository:

1. **Static Analysis Check:**
   ```bash
   flutter analyze
   ```
2. **Execute Full Test Suite:**
   ```bash
   flutter test
   ```
3. **Run Local Web Server:**
   ```bash
   python3 -m http.server 8000 --directory build/web
   ```
