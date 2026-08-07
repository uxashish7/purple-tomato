# 🚀 Current Sprint Goals & Roadmap

## Sprint Objective
Complete audit remediation, refactor monolithic screen components into feature widgets, fix web deep-linking routing, enforce AI advisor disclaimers, and establish web desktop layout responsiveness.

## Completed Tasks
- [x] **Security Hardening:** Removed hardcoded secrets, migrated tokens to `flutter_secure_storage`, and implemented `.env` runtime definitions.
- [x] **Routing & Deep-Linking:** Implemented `GoRouter` with `/stock/:symbol` parameter-based path routing and fallback state resolution.
- [x] **Component Modularization:** Extracted `TradeExecutionSheet` out of `StockDetailScreen` and `AiInsightCard` out of `AdvisorScreen`.
- [x] **AI Advisor Enhancement:** Added quick prompt chips for instant sector & portfolio analysis and integrated SEBI compliance educational disclaimers.
- [x] **Desktop Responsiveness:** Added layout breakpoints (`600px`, `900px`, `1200px`) in `AppTheme` and centered home dashboard max-width containers.
- [x] **Testing & Verification:** Added unit/widget test coverage for `TradeExecutionSheet`, `AiInsightCard`, `Wallet`, `AppLogger`, `UpstoxService`, `GeminiService`, and `MarketDataProvider`.

## Next Roadmap Goals
- [ ] **CI/CD Automation:** Finalize GitHub Actions workflow for automated testing and Vercel web deployment.
- [ ] **Advanced Trading Orders:** Add limit order matching engine and stop-loss triggers.
- [ ] **Supabase Edge Function Gateway:** Move client-side Upstox OAuth secret exchange to a secure Supabase Edge Function backend.
