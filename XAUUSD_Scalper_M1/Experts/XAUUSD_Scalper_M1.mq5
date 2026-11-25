//+------------------------------------------------------------------+
//|                                             XAUUSD_Scalper_M1.mq5 |
//|                    Professional Gold Scalping EA for M1 Timeframe |
//|                                                                  |
//|  Features:                                                       |
//|  - Multi-timeframe analysis (M1 + M5)                           |
//|  - EMA 50 (M1) + EMA 200 (M5) trend alignment                   |
//|  - RSI 14 momentum confirmation                                  |
//|  - ATR 14 volatility filtering                                   |
//|  - Price action & market structure analysis                      |
//|  - Spread filter for high spread protection                      |
//|  - Confluence-based entry system                                 |
//|  - Advanced risk management & position sizing                    |
//|  - Trailing stop, break-even, and loss protection                |
//+------------------------------------------------------------------+
#property copyright "Professional MQL5 Developer"
#property link      ""
#property version   "2.0.0"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Indicators\Indicators.mqh>

//--- Custom includes
#include "Include\Config.mqh"
#include "Include\IndicatorsManager.mqh"
#include "Include\PriceActionAnalyzer.mqh"
#include "Include\SignalGenerator.mqh"
#include "Include\RiskManager.mqh"
#include "Include\TradeExecutor.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   string ea_name = Config::GetEAName();
   
   //--- Initialize configuration
   if(!Config::Initialize(_Symbol, PERIOD_M1))
     {
      Print(ea_name, ": Failed to initialize configuration");
      return(INIT_FAILED);
     }
   
   //--- Initialize indicators manager
   if(!IndicatorsManager::Initialize())
     {
      Print(ea_name, ": Failed to initialize indicators");
      return(INIT_FAILED);
     }
   
   //--- Initialize price action analyzer
   if(!PriceActionAnalyzer::Initialize())
     {
      Print(ea_name, ": Failed to initialize price action analyzer");
      return(INIT_FAILED);
     }
   
   //--- Initialize signal generator
   if(!SignalGenerator::Initialize())
     {
      Print(ea_name, ": Failed to initialize signal generator");
      return(INIT_FAILED);
     }
   
   //--- Initialize risk manager
   if(!RiskManager::Initialize())
     {
      Print(ea_name, ": Failed to initialize risk manager");
      return(INIT_FAILED);
     }
   
   //--- Initialize trade executor
   if(!TradeExecutor::Initialize())
     {
      Print(ea_name, ": Failed to initialize trade executor");
      return(INIT_FAILED);
     }
   
   //--- Verify symbol is XAUUSD or gold variant
   if(!SymbolIsGold())
     {
      Print(ea_name, ": Warning - This EA is optimized for XAUUSD/GOLD. Current symbol: ", _Symbol);
     }
   
   //--- Check spread filter
   double current_spread = SymbolInfoDouble(_Symbol, SYMBOL_SPREAD) * _Point;
   double max_spread = Config::GetMaxSpreadPoints();
   if(current_spread > max_spread)
     {
      Print(ea_name, ": Warning - Current spread (", current_spread, ") exceeds maximum allowed (", max_spread, ")");
     }
   
   Print(ea_name, ": Successfully initialized on ", _Symbol, " M1");
   Print(ea_name, ": Spread: ", current_spread, " points | Max Spread: ", max_spread, " points");
   Print(ea_name, ": Risk per trade: ", Config::GetRiskPercent(), "% | Max Daily Loss: ", Config::GetMaxDailyLossPercent(), "%");
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //--- Cleanup indicators
   IndicatorsManager::Cleanup();
   
   //--- Cleanup price action analyzer
   PriceActionAnalyzer::Cleanup();
   
   //--- Cleanup signal generator
   SignalGenerator::Cleanup();
   
   //--- Cleanup risk manager
   RiskManager::Cleanup();
   
   //--- Cleanup trade executor
   TradeExecutor::Cleanup();
   
   Print("XAUUSD_Scalper_M1: Deinitialized. Reason: ", EnumToString((ENUM_DEINIT_REASON)reason));
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //--- Check if trading is allowed
   if(!IsTradeAllowed())
     {
      return;
     }
   
   //--- Update all indicators
   if(!IndicatorsManager::Update())
     {
      return;
     }
   
   //--- Update price action analysis
   if(!PriceActionAnalyzer::Update())
     {
      return;
     }
   
   //--- Check spread filter
   if(!CheckSpreadFilter())
     {
      return;
     }
   
   //--- Check daily loss limit
   if(!RiskManager::CheckDailyLossLimit())
     {
      Print("XAUUSD_Scalper_M1: Daily loss limit reached. No new trades allowed.");
      return;
     }
   
   //--- Manage existing positions (trailing, break-even, etc.)
   TradeExecutor::ManagePositions();
   
   //--- Check for new entry signals
   if(Config::GetAllowNewEntries())
     {
      ENTRY_SIGNAL signal = SignalGenerator::GetEntrySignal();
      
      if(signal.type != ENTRY_NONE)
        {
         //--- Calculate position size
         double lot_size = RiskManager::CalculatePositionSize(signal);
         
         if(lot_size > 0)
           {
            //--- Execute trade
            bool result = TradeExecutor::OpenPosition(signal, lot_size);
            
            if(result)
              {
               Print("XAUUSD_Scalper_M1: Position opened - ", EnumToString(signal.type), 
                     " | Lot: ", lot_size, " | Price: ", signal.entry_price,
                     " | SL: ", signal.stop_loss, " | TP: ", signal.take_profit);
              }
           }
        }
     }
   
   //--- Update dashboard/visual info
   UpdateDashboard();
  }

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
  {
   //--- Check if EA is enabled
   if(!Config::GetEnabled())
     {
      return false;
     }
   
   //--- Check trading hours
   if(!Config::IsTradingTime())
     {
      return false;
     }
   
   //--- Check if we have too many open positions
   if(TradeExecutor::GetOpenPositionsCount() >= Config::GetMaxOpenPositions())
     {
      return false;
     }
   
   //--- Check account status
   if(!CheckAccountStatus())
     {
      return false;
     }
   
   //--- Check if market is open
   if(!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_FULL)
     {
      return false;
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Check account status                                             |
//+------------------------------------------------------------------+
bool CheckAccountStatus()
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   
   //--- Check margin level
   if(margin_level > 0 && margin_level < Config::GetMinMarginLevel())
     {
      Print("XAUUSD_Scalper_M1: Margin level too low: ", margin_level, "%");
      return false;
     }
   
   //--- Check drawdown
   double drawdown_percent = ((balance - equity) / balance) * 100;
   if(drawdown_percent > Config::GetMaxAccountDrawdownPercent())
     {
      Print("XAUUSD_Scalper_M1: Account drawdown exceeded: ", drawdown_percent, "%");
      return false;
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Check spread filter                                              |
//+------------------------------------------------------------------+
bool CheckSpreadFilter()
  {
   double current_spread = SymbolInfoDouble(_Symbol, SYMBOL_SPREAD) * _Point;
   double max_spread = Config::GetMaxSpreadPoints();
   
   if(current_spread > max_spread)
     {
      static datetime last_warning = 0;
      datetime current_time = TimeCurrent();
      
      if(current_time - last_warning > 60) // Warning once per minute
        {
         Print("XAUUSD_Scalper_M1: Spread too high - Current: ", current_spread, " | Max: ", max_spread);
         last_warning = current_time;
        }
      return false;
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Check if symbol is gold                                          |
//+------------------------------------------------------------------+
bool SymbolIsGold()
  {
   string symbol_name = StringUpper(_Symbol);
   
   //--- Common gold symbol variations
   string gold_symbols[] = {"XAUUSD", "GOLD", "XAUUSDT", "XAUUSD.", "GOLD.", "XAUUSDm", "GOLDm"};
   
   for(int i = 0; i < ArraySize(gold_symbols); i++)
     {
      if(StringFind(symbol_name, gold_symbols[i]) >= 0)
        {
         return true;
        }
     }
   
   //--- Check symbol description
   string description = StringUpper(SymbolInfoString(_Symbol, SYMBOL_DESCRIPTION));
   if(StringFind(description, "GOLD") >= 0 || StringFind(description, "XAU") >= 0)
     {
      return true;
     }
   
   return false;
  }

//+------------------------------------------------------------------+
//| Update dashboard information                                     |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   if(!Config::GetShowDashboard())
     {
      return;
     }
   
   static datetime last_update = 0;
   datetime current_time = TimeCurrent();
   
   //--- Update dashboard every second
   if(current_time - last_update < 1)
     {
      return;
     }
   
   last_update = current_time;
   
   //--- Get current indicator values
   double ema50_m1 = IndicatorsManager::GetEMA50_M1();
   double ema200_m5 = IndicatorsManager::GetEMA200_M5();
   double rsi14 = IndicatorsManager::GetRSI14();
   double atr14 = IndicatorsManager::GetATR14();
   
   //--- Get trend direction
   ENUM_TREND_DIRECTION trend_m1 = IndicatorsManager::GetTrendDirection_M1();
   ENUM_TREND_DIRECTION trend_m5 = IndicatorsManager::GetTrendDirection_M5();
   
   //--- Get price action info
   MARKET_STRUCTURE ms = PriceActionAnalyzer::GetMarketStructure();
   
   //--- Create dashboard text
   string dashboard = "";
   dashboard += "=== XAUUSD SCALPER M1 DASHBOARD ===\n";
   dashboard += "Symbol: " + _Symbol + " | Timeframe: M1\n";
   dashboard += "----------------------------------------\n";
   dashboard += "EMA 50 (M1): " + DoubleToString(ema50_m1, _Digits) + "\n";
   dashboard += "EMA 200 (M5): " + DoubleToString(ema200_m5, _Digits) + "\n";
   dashboard += "RSI 14: " + DoubleToString(rsi14, 2) + "\n";
   dashboard += "ATR 14: " + DoubleToString(atr14, _Digits) + "\n";
   dashboard += "----------------------------------------\n";
   dashboard += "Trend M1: " + EnumToString(trend_m1) + "\n";
   dashboard += "Trend M5: " + EnumToString(trend_m5) + "\n";
   dashboard += "Market Structure: " + EnumToString(ms.structure_type) + "\n";
   dashboard += "Last Swing High: " + DoubleToString(ms.last_swing_high, _Digits) + "\n";
   dashboard += "Last Swing Low: " + DoubleToString(ms.last_swing_low, _Digits) + "\n";
   dashboard += "----------------------------------------\n";
   dashboard += "Spread: " + IntegerToString((int)(SymbolInfoDouble(_Symbol, SYMBOL_SPREAD))) + " pts\n";
   dashboard += "Open Positions: " + IntegerToString(TradeExecutor::GetOpenPositionsCount()) + "\n";
   dashboard += "Daily P/L: " + DoubleToString(RiskManager::GetDailyProfitLoss(), 2) + "\n";
   dashboard += "Account DD: " + DoubleToString(((AccountInfoDouble(ACCOUNT_BALANCE) - AccountInfoDouble(ACCOUNT_EQUITY)) / AccountInfoDouble(ACCOUNT_BALANCE)) * 100, 2) + "%\n";
   
   //--- Display on chart
   Comment(dashboard);
  }

//+------------------------------------------------------------------+
//| Timer function for periodic tasks                                |
//+------------------------------------------------------------------+
void OnTimer()
  {
   //--- Daily reset check
   RiskManager::CheckDailyReset();
   
   //--- Update indicators on timer as backup
   IndicatorsManager::Update();
  }

//+------------------------------------------------------------------+
//| Chart event handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   //--- Handle keyboard shortcuts for manual control
   if(id == CHARTEVENT_KEYDOWN)
     {
      switch((int)lparam)
        {
         case KEY_F1:  // Toggle EA enabled
            Config::SetEnabled(!Config::GetEnabled());
            Print("XAUUSD_Scalper_M1: EA ", (Config::GetEnabled() ? "ENABLED" : "DISABLED"));
            break;
            
         case KEY_F2:  // Close all positions
            TradeExecutor::CloseAllPositions();
            Print("XAUUSD_Scalper_M1: All positions closed manually");
            break;
            
         case KEY_F3:  // Print detailed status
            PrintDetailedStatus();
            break;
        }
     }
  }

//+------------------------------------------------------------------+
//| Print detailed status to log                                     |
//+------------------------------------------------------------------+
void PrintDetailedStatus()
  {
   Print("=== DETAILED STATUS ===");
   Print("Symbol: ", _Symbol);
   Print("Timeframe: M1");
   Print("Bid: ", SymbolInfoDouble(_Symbol, SYMBOL_BID), " | Ask: ", SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   Print("Spread: ", (int)SymbolInfoDouble(_Symbol, SYMBOL_SPREAD), " points");
   Print("EMA 50 (M1): ", IndicatorsManager::GetEMA50_M1());
   Print("EMA 200 (M5): ", IndicatorsManager::GetEMA200_M5());
   Print("RSI 14: ", IndicatorsManager::GetRSI14());
   Print("ATR 14: ", IndicatorsManager::GetATR14());
   Print("Trend M1: ", EnumToString(IndicatorsManager::GetTrendDirection_M1()));
   Print("Trend M5: ", EnumToString(IndicatorsManager::GetTrendDirection_M5()));
   
   MARKET_STRUCTURE ms = PriceActionAnalyzer::GetMarketStructure();
   Print("Market Structure: ", EnumToString(ms.structure_type));
   Print("Swing High: ", ms.last_swing_high, " | Swing Low: ", ms.last_swing_low);
   Print("Bullish OB: ", ms.bullish_order_block_price, " | Bearish OB: ", ms.bearish_order_block_price);
   
   Print("Open Positions: ", TradeExecutor::GetOpenPositionsCount());
   Print("Daily P/L: ", RiskManager::GetDailyProfitLoss());
   Print("Account Balance: ", AccountInfoDouble(ACCOUNT_BALANCE));
   Print("Account Equity: ", AccountInfoDouble(ACCOUNT_EQUITY));
   Print("Margin Level: ", AccountInfoDouble(ACCOUNT_MARGIN_LEVEL), "%");
   Print("========================");
  }

//+------------------------------------------------------------------+
//| Trade transaction handler                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   //--- Handle trade events
   TradeExecutor::OnTradeTransaction(trans, request, result);
  }

//+------------------------------------------------------------------+
//| Book event handler (depth of market)                             |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
   //--- Not used in this EA
  }

//+------------------------------------------------------------------+
//| Timer event handler (for OnTimer)                                |
//+------------------------------------------------------------------+
void OnTimerEvent()
  {
   OnTimer();
  }
//+------------------------------------------------------------------+