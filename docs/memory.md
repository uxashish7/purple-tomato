# 🧠 Architecture Decisions Log

## 1. State Management
- **Decision:** Riverpod
- **Reasoning:** Superior to Provider for combining states, compile-time safety, and testability.

## 2. Routing
- **Decision:** GoRouter
- **Reasoning:** Supports deep linking out-of-the-box, strongly typed route names, and robust auth redirection via `redirect` callbacks. We implemented a bypass `isGuestModeProvider` for guest access.

## 3. Directory Structure
- **Decision:** Feature-first approach (`lib/features/`) mixed with core shared services (`lib/core/`). Domain models moved to `lib/domain/`.
- **Reasoning:** Scales better than type-first (all screens in one folder). Makes feature isolation easier.

## 4. API Security
- **Decision:** Environment variables via `.env` files and `flutter_dotenv` (or `--dart-define`).
- **Reasoning:** Prevents leaking API keys (Upstox, Supabase, Gemini) into version control.

## 5. Screen Splitting
- **Decision:** Keep screens under 300 lines by extracting large components into `features/market/widgets/`.
- **Reasoning:** Improves readability and allows widgets to be tested independently.

## 6. Error Handling
- **Decision:** Dedicated `core/errors/` with specific `AppException` types and a unified `Failure` model.
- **Reasoning:** Ensures API and internal errors are consistently surfaced to the UI without leaking stack traces.
