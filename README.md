# 🍅 Purple Tomato - Virtual Stock Trading App

Purple Tomato is a virtual stock trading application built with Flutter. It provides users with a risk-free environment to practice trading with real-time market data.

## Features
- **Virtual Portfolio:** Start with ₹10 Lakh in virtual currency.
- **Real-time Data:** Live streaming of market data (NSE/BSE).
- **AI Advisor:** Get AI-powered trading advice (powered by Gemini).
- **OAuth Integration:** Connect with Upstox for real-world trading logic (or use Guest Mode).
- **Modern UI:** Clean, dark-mode focused UI.

## Environment Setup

1. Create a `.env` file in the root directory (use `.env.example` as a template).
2. Add your API keys:
```env
UPSTOX_API_KEY=your_key
UPSTOX_API_SECRET=your_secret
SUPABASE_URL=your_url
SUPABASE_ANON_KEY=your_key
GEMINI_API_KEY=your_key
```
3. Run `flutter pub get` to fetch dependencies.
4. Run `flutter run` to start the application.

## Authentication Flow
The app uses Upstox OAuth for authentication. If you prefer not to log in, you can use the "Continue as Guest" option which bypasses the Upstox requirement and uses public Yahoo Finance data.

## Architecture
- **State Management:** Riverpod
- **Routing:** GoRouter
- **Local Storage:** Hive
- **Backend/DB:** Supabase
