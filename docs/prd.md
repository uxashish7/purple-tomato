# 🍅 Purple Tomato - PRD

## Product Intent
Purple Tomato is an educational, virtual stock trading platform aimed at helping novice investors learn how to trade stocks in the Indian market (NSE/BSE) without risking real money.

## Target Audience
Beginner to intermediate investors who want to test their trading strategies.

## Core Features
1. **Virtual Trading Engine:** Simulate market buys and sells using live prices.
2. **Portfolio Tracking:** View current holdings, P&L (Profit and Loss), and transaction history.
3. **AI Trading Advisor:** Provide users with insights based on market trends and technical analysis via Gemini API.
4. **Market Overview:** View top gainers/losers and major indices (Nifty 50, Sensex).

## AI Context Rules
- **No Financial Advice:** The AI Advisor MUST include disclaimers that its suggestions are for educational purposes only.
- **Data Source:** Rely on Upstox API for primary data, fallback to Yahoo Finance for guest mode.
- **Architecture:** Follow strict separation of concerns (Presentation layer, Domain Models, Core Services).
