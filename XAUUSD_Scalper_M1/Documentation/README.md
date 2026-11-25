# XAUUSD Scalper M1 - Professional MQL5 Expert Advisor

## Overview

Professional Gold (XAUUSD) scalping Expert Advisor for MetaTrader 5 on M1 timeframe. The EA performs comprehensive market analysis before opening any trade - no random entries.

## Project Structure

```
XAUUSD_Scalper_M1/
├── Experts/
│   └── XAUUSD_Scalper_M1.mq5          # Main EA file
├── Include/
│   ├── Config.mqh                      # Configuration & input parameters
│   ├── IndicatorsManager.mqh           # Indicator management (EMA, RSI, ATR)
│   ├── PriceActionAnalyzer.mqh         # Price action & market structure analysis
│   ├── SignalGenerator.mqh             # Confluence-based signal generation
│   ├── RiskManager.mqh                 # Risk management & position sizing
│   └── TradeExecutor.mqh               # Trade execution & position management
└── Documentation/
    ├── دليل_التشغيل_والتجربة.md       # Arabic user guide
    └── README.md                       # This file
```

## Trading Strategy

### Indicators Used

| Indicator | Timeframe | Purpose |
|-----------|-----------|---------|
| EMA 50 | M1 | Short-term trend direction |
| EMA 200 | M5 | Overall trend direction |
| RSI 14 | M1 | Momentum analysis |
| ATR 14 | M1 | Volatility measurement, SL/TP calculation |

### Entry Conditions (Confluence-Based)

**BUY Signal:**
1. M5 trend: Bullish (price above EMA 200)
2. M1 trend: Bullish or Neutral (price above EMA 50)
3. RSI: Not overbought (< 70), rising or neutral
4. Price action: Bullish candlestick pattern or at support level
5. Market structure: Uptrend, bullish breakout, or bullish reversal
6. Spread: Within maximum allowed limit
7. Risk:Reward ratio: Minimum 1.5

**SELL Signal:**
1. M5 trend: Bearish (price below EMA 200)
2. M1 trend: Bearish or Neutral (price below EMA 50)
3. RSI: Not oversold (> 30), falling or neutral
4. Price action: Bearish candlestick pattern or at resistance level
5. Market structure: Downtrend, bearish breakout, or bearish reversal
6. Spread: Within maximum allowed limit
7. Risk:Reward ratio: Minimum 1.5

## Risk Management

- **Position Sizing**: % of equity, % of balance, fixed lot, ATR-based, or Kelly criterion
- **Stop Loss**: ATR-based (1.5× ATR default) with swing low/high adjustment
- **Take Profit**: ATR-based (2.5× ATR default) or at key resistance/support
- **Break Even**: Auto-activation at 1× ATR profit with 0.3× ATR offset
- **Trailing Stop**: ATR, Points, Moving Average, or Market Structure methods
- **Max Daily Loss**: 5% of balance
- **Max Account Drawdown**: 15% of balance
- **Max Open Positions**: 5
- **Max Spread Filter**: 30 points
- **Min Margin Level**: 200%

## Installation

1. Copy the `XAUUSD_Scalper_M1` folder to your MT5 `MQL5\Experts\` directory
2. Open MetaTrader 5, navigate to Navigator → Expert Advisors
3. Drag `XAUUSD_Scalper_M1` onto an XAUUSD M1 chart
4. Enable "Algo Trading" in the terminal
5. Review input parameters and click OK

## Strategy Tester Setup

1. Open Strategy Tester (Ctrl+R)
2. Select Expert Advisor: `XAUUSD_Scalper_M1`
3. Select Symbol: `XAUUSD` (or XAUUSDm)
4. Select Timeframe: `M1`
5. Select Model: `Every tick` (most accurate for scalping)
6. Select Date Range: Last 3-6 months recommended
7. Initial Deposit: $10,000 (or appropriate for your risk settings)
8. Leverage: 1:100 or 1:500

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| F1 | Enable/Disable EA |
| F2 | Close all positions |
| F3 | Print detailed status to log |

## Key Files

- `XAUUSD_Scalper_M1.mq5` - Main entry point, OnInit/OnTick/OnDeinit
- `Config.mqh` - All input parameters and configuration class
- `IndicatorsManager.mqh` - Multi-timeframe indicator handling
- `PriceActionAnalyzer.mqh` - Candlestick patterns, swing points, order blocks, FVG
- `SignalGenerator.mqh` - Confluence scoring system (0-100 points)
- `RiskManager.mqh` - Position sizing, daily limits, drawdown protection
- `TradeExecutor.mqh` - Order placement, position management, trailing stops

## License

For educational and personal use. Test on demo account before live trading.

---

**Version**: 2.0.0  
**Platform**: MetaTrader 5  
**Language**: MQL5