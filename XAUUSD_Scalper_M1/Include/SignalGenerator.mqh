//+------------------------------------------------------------------+
//|                                           SignalGenerator.mqh    |
//|                    Confluence-Based Signal Generation            |
//+------------------------------------------------------------------+
#property strict

#include "Config.mqh"
#include "IndicatorsManager.mqh"
#include "PriceActionAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Signal Generator Class                                           |
//+------------------------------------------------------------------+
class SignalGenerator
  {
private:
   //--- Signal state
   static ENTRY_SIGNAL s_last_signal;
   static datetime s_last_signal_time;
   static int s_signals_generated;
   static int s_buy_signals_count;
   static int s_sell_signals_count;
   
   //--- Entry tracking for multiple entries
   static double s_last_buy_price;
   static double s_last_sell_price;
   static int s_current_buy_entries;
   static int s_current_sell_entries;
   
   //--- Signal components scoring
   struct SIGNAL_SCORE
   {
    int trend_score;           // 0-30
    int rsi_score;             // 0-20
    int price_action_score;    // 0-25
    int structure_score;       // 0-15
    int volume_score;          // 0-10
    int total_score;           // 0-100
   };
   
   static bool s_initialized;

public:
   //--- Initialization
   static bool Initialize();
   static void Cleanup();
   
   //--- Get entry signal
   static ENTRY_SIGNAL GetEntrySignal();
   
   //--- Signal tracking
   static void ResetEntryTracking();
   static void OnPositionOpened(ENUM_ENTRY_TYPE type, double price);
   static void OnPositionClosed(ENUM_ENTRY_TYPE type);
   static int GetCurrentBuyEntries() { return s_current_buy_entries; }
   static int GetCurrentSellEntries() { return s_current_sell_entries; }
   static bool CanAddBuyEntry(double current_price);
   static bool CanAddSellEntry(double current_price);
   
   //--- Statistics
   static int GetSignalsGenerated() { return s_signals_generated; }
   static int GetBuySignalsCount() { return s_buy_signals_count; }
   static int GetSellSignalsCount() { return s_sell_signals_count; }

private:
   //--- Signal calculation
   static ENTRY_SIGNAL CalculateBuySignal();
   static ENTRY_SIGNAL CalculateSellSignal();
   static SIGNAL_SCORE CalculateBuyScore();
   static SIGNAL_SCORE CalculateSellScore();
   static ENUM_SIGNAL_STRENGTH ScoreToStrength(int score);
   
   //--- Entry conditions
   static bool CheckTrendAlignmentBuy();
   static bool CheckTrendAlignmentSell();
   static bool CheckRSIConfirmationBuy();
   static bool CheckRSIConfirmationSell();
   static bool CheckPriceActionBuy();
   static bool CheckPriceActionSell();
   static bool CheckStructureBuy();
   static bool CheckStructureSell();
   static bool CheckVolumeBuy();
   static bool CheckVolumeSell();
   
   //--- Risk/Reward calculation
   static double CalculateStopLoss(ENUM_ENTRY_TYPE type, double entry_price, double atr);
   static double CalculateTakeProfit(ENUM_ENTRY_TYPE type, double entry_price, double stop_loss);
   
   //--- Validation
   static bool ValidateSignal(ENTRY_SIGNAL &signal);
  };

//+------------------------------------------------------------------+
//| Static member definitions                                        |
//+------------------------------------------------------------------+
ENTRY_SIGNAL SignalGenerator::s_last_signal;
datetime SignalGenerator::s_last_signal_time = 0;
int SignalGenerator::s_signals_generated = 0;
int SignalGenerator::s_buy_signals_count = 0;
int SignalGenerator::s_sell_signals_count = 0;

double SignalGenerator::s_last_buy_price = 0;
double SignalGenerator::s_last_sell_price = 0;
int SignalGenerator::s_current_buy_entries = 0;
int SignalGenerator::s_current_sell_entries = 0;

bool SignalGenerator::s_initialized = false;

//+------------------------------------------------------------------+
//| Initialize Signal Generator                                      |
//+------------------------------------------------------------------+
bool SignalGenerator::Initialize()
  {
   s_last_signal.type = ENTRY_NONE;
   s_last_signal.strength = SIGNAL_WEAK;
   s_last_signal.is_valid = false;
   s_last_signal_time = 0;
   s_signals_generated = 0;
   s_buy_signals_count = 0;
   s_sell_signals_count = 0;
   
   s_last_buy_price = 0;
   s_last_sell_price = 0;
   s_current_buy_entries = 0;
   s_current_sell_entries = 0;
   
   s_initialized = true;
   Print("SignalGenerator: Initialized successfully");
   
   return true;
  }

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void SignalGenerator::Cleanup()
  {
   s_initialized = false;
   Print("SignalGenerator: Cleaned up");
  }

//+------------------------------------------------------------------+
//| Get Entry Signal                                                 |
//+------------------------------------------------------------------+
ENTRY_SIGNAL SignalGenerator::GetEntrySignal()
  {
   ENTRY_SIGNAL signal;
   signal.type = ENTRY_NONE;
   signal.strength = SIGNAL_WEAK;
   signal.is_valid = false;
   
   if(!s_initialized)
     {
      return signal;
     }
   
   //--- Check if we can take new entries
   if(!Config::GetAllowNewEntries())
     {
      return signal;
     }
   
   //--- Check maximum entries per direction
   if(s_current_buy_entries >= Config::GetMaxEntriesPerDirection() &&
      s_current_sell_entries >= Config::GetMaxEntriesPerDirection())
     {
      return signal;
     }
   
   //--- Calculate buy signal
   ENTRY_SIGNAL buy_signal = CalculateBuySignal();
   
   //--- Calculate sell signal
   ENTRY_SIGNAL sell_signal = CalculateSellSignal();
   
   //--- Select best signal
   if(buy_signal.is_valid && sell_signal.is_valid)
     {
      //--- Both valid, choose stronger one
      if(buy_signal.strength >= sell_signal.strength)
        {
         signal = buy_signal;
        }
      else
        {
         signal = sell_signal;
        }
     }
   else if(buy_signal.is_valid)
     {
      signal = buy_signal;
     }
   else if(sell_signal.is_valid)
     {
      signal = sell_signal;
     }
   
   //--- Validate final signal
   if(signal.is_valid && ValidateSignal(signal))
     {
      s_last_signal = signal;
      s_last_signal_time = TimeCurrent();
      s_signals_generated++;
      
      if(signal.type == ENTRY_BUY)
        {
         s_buy_signals_count++;
        }
      else
        {
         s_sell_signals_count++;
        }
      
      if(Config::GetLogSignals())
        {
         Print("SignalGenerator: ", EnumToString(signal.type), " Signal | Strength: ", EnumToString(signal.strength),
               " | Entry: ", signal.entry_price, " | SL: ", signal.stop_loss, " | TP: ", signal.take_profit,
               " | RR: ", signal.risk_reward_ratio);
        }
     }
   else
     {
      signal.is_valid = false;
     }
   
   return signal;
  }

//+------------------------------------------------------------------+
//| Calculate Buy Signal                                             |
//+------------------------------------------------------------------+
ENTRY_SIGNAL SignalGenerator::CalculateBuySignal()
  {
   ENTRY_SIGNAL signal;
   signal.type = ENTRY_BUY;
   signal.entry_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   signal.signal_time = TimeCurrent();
   signal.is_valid = false;
   
   //--- Check max buy entries
   if(s_current_buy_entries >= Config::GetMaxEntriesPerDirection())
     {
      return signal;
     }
   
   //--- Check minimum distance from last buy entry
   if(s_current_buy_entries > 0 && s_last_buy_price > 0)
     {
      double atr = IndicatorsManager::GetATR14();
      double min_distance = atr * Config::GetMinDistanceBetweenEntriesATR();
      
      if(signal.entry_price - s_last_buy_price < min_distance)
        {
         return signal; // Too close to last entry
        }
     }
   
   //--- Calculate signal score
   SIGNAL_SCORE score = CalculateBuyScore();
   
   //--- Minimum score threshold
   if(score.total_score < 60) // Minimum 60% confluence
     {
      return signal;
     }
   
   signal.strength = ScoreToStrength(score.total_score);
   
   //--- Calculate SL and TP
   double atr = IndicatorsManager::GetATR14();
   signal.atr_value = atr;
   signal.stop_loss = CalculateStopLoss(ENTRY_BUY, signal.entry_price, atr);
   signal.take_profit = CalculateTakeProfit(ENTRY_BUY, signal.entry_price, signal.stop_loss);
   signal.risk_reward_ratio = (signal.take_profit - signal.entry_price) / (signal.entry_price - signal.stop_loss);
   
   //--- Check minimum R:R
   if(signal.risk_reward_ratio < Config::GetMinRiskRewardRatio())
     {
      return signal;
     }
   
   //--- Build comment
   signal.comment = "XAUUSD_Scalper_M1 Buy | Score: " + IntegerToString(score.total_score) + 
                    " | RR: " + DoubleToString(signal.risk_reward_ratio, 2);
   
   signal.is_valid = true;
   
   return signal;
  }

//+------------------------------------------------------------------+
//| Calculate Sell Signal                                            |
//+------------------------------------------------------------------+
ENTRY_SIGNAL SignalGenerator::CalculateSellSignal()
  {
   ENTRY_SIGNAL signal;
   signal.type = ENTRY_SELL;
   signal.entry_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   signal.signal_time = TimeCurrent();
   signal.is_valid = false;
   
   //--- Check max sell entries
   if(s_current_sell_entries >= Config::GetMaxEntriesPerDirection())
     {
      return signal;
     }
   
   //--- Check minimum distance from last sell entry
   if(s_current_sell_entries > 0 && s_last_sell_price > 0)
     {
      double atr = IndicatorsManager::GetATR14();
      double min_distance = atr * Config::GetMinDistanceBetweenEntriesATR();
      
      if(s_last_sell_price - signal.entry_price < min_distance)
        {
         return signal;
        }
     }
   
   //--- Calculate signal score
   SIGNAL_SCORE score = CalculateSellScore();
   
   //--- Minimum score threshold
   if(score.total_score < 60)
     {
      return signal;
     }
   
   signal.strength = ScoreToStrength(score.total_score);
   
   //--- Calculate SL and TP
   double atr = IndicatorsManager::GetATR14();
   signal.atr_value = atr;
   signal.stop_loss = CalculateStopLoss(ENTRY_SELL, signal.entry_price, atr);
   signal.take_profit = CalculateTakeProfit(ENTRY_SELL, signal.entry_price, signal.stop_loss);
   signal.risk_reward_ratio = (signal.entry_price - signal.take_profit) / (signal.stop_loss - signal.entry_price);
   
   //--- Check minimum R:R
   if(signal.risk_reward_ratio < Config::GetMinRiskRewardRatio())
     {
      return signal;
     }
   
   //--- Build comment
   signal.comment = "XAUUSD_Scalper_M1 Sell | Score: " + IntegerToString(score.total_score) + 
                    " | RR: " + DoubleToString(signal.risk_reward_ratio, 2);
   
   signal.is_valid = true;
   
   return signal;
  }

//+------------------------------------------------------------------+
//| Calculate Buy Score                                              |
//+------------------------------------------------------------------+
SignalGenerator::SIGNAL_SCORE SignalGenerator::CalculateBuyScore()
  {
   SIGNAL_SCORE score;
   ZeroMemory(score);
   
   //--- 1. Trend Alignment (0-30 points)
   if(CheckTrendAlignmentBuy())
     {
      score.trend_score = 30;
      
      //--- Bonus for strong alignment
      if(IndicatorsManager::IsTrendStrongBullish())
        {
         score.trend_score = 30;
        }
      else if(IndicatorsManager::IsTrendAlignedBullish())
        {
         score.trend_score = 25;
        }
     }
   else if(IndicatorsManager::GetTrendDirection_M5() == TREND_BULLISH)
     {
      //--- Only M5 bullish
      score.trend_score = 15;
     }
   else if(IndicatorsManager::GetTrendDirection_M1() == TREND_BULLISH)
     {
      //--- Only M1 bullish
      score.trend_score = 10;
     }
   
   //--- 2. RSI Confirmation (0-20 points)
   if(CheckRSIConfirmationBuy())
     {
      score.rsi_score = 20;
      
      //--- Bonus for RSI rising from oversold
      if(IndicatorsManager::GetRSI14() < 40 && IndicatorsManager::IsRSIRising())
        {
         score.rsi_score = 20;
        }
      else if(IndicatorsManager::GetRSI14() > 50 && IndicatorsManager::IsRSIRising())
        {
         score.rsi_score = 15;
        }
     }
   else if(!Config::GetRequireRSIConfirmation())
     {
      score.rsi_score = 10; // Neutral if not required
     }
   
   //--- 3. Price Action (0-25 points)
   if(CheckPriceActionBuy())
     {
      score.price_action_score = 25;
      
      ENUM_CANDLE_PATTERN pattern = PriceActionAnalyzer::GetCurrentPattern();
      
      //--- Strong patterns
      if(pattern == PATTERN_ENGULFING_BULL || pattern == PATTERN_MORNING_STAR || 
         pattern == PATTERN_THREE_WHITE_SOLDIERS)
        {
         score.price_action_score = 25;
        }
      else if(pattern == PATTERN_PIN_BAR_BULL || pattern == PATTERN_HAMMER)
        {
         score.price_action_score = 20;
        }
      else if(pattern == PATTERN_INSIDE_BAR) // Inside bar at support
        {
         score.price_action_score = 15;
        }
     }
   
   //--- 4. Market Structure (0-15 points)
   if(CheckStructureBuy())
     {
      score.structure_score = 15;
      
      ENUM_MARKET_STRUCTURE_TYPE structure = PriceActionAnalyzer::GetMarketStructure().structure_type;
      
      if(structure == STRUCTURE_UPTREND || structure == STRUCTURE_BREAKOUT_BULL)
        {
         score.structure_score = 15;
        }
      else if(structure == STRUCTURE_REVERSAL_BULL)
        {
         score.structure_score = 12;
        }
      else if(PriceActionAnalyzer::HasBullishOB() && !PriceActionAnalyzer::GetBullishOB().is_tested)
        {
         score.structure_score = 10; // Untested order block
        }
      else if(PriceActionAnalyzer::HasBullishFVG() && !PriceActionAnalyzer::GetBullishFVG().is_filled)
        {
         score.structure_score = 10; // Unfilled FVG
        }
     }
   
   //--- 5. Volume (0-10 points)
   if(CheckVolumeBuy())
     {
      score.volume_score = 10;
     }
   else
     {
      score.volume_score = 5; // Neutral
     }
   
   //--- Total
   score.total_score = score.trend_score + score.rsi_score + score.price_action_score + 
                       score.structure_score + score.volume_score;
   
   return score;
  }

//+------------------------------------------------------------------+
//| Calculate Sell Score                                             |
//+------------------------------------------------------------------+
SignalGenerator::SIGNAL_SCORE SignalGenerator::CalculateSellScore()
  {
   SIGNAL_SCORE score;
   ZeroMemory(score);
   
   //--- 1. Trend Alignment (0-30 points)
   if(CheckTrendAlignmentSell())
     {
      score.trend_score = 30;
      
      if(IndicatorsManager::IsTrendStrongBearish())
        {
         score.trend_score = 30;
        }
      else if(IndicatorsManager::IsTrendAlignedBearish())
        {
         score.trend_score = 25;
        }
     }
   else if(IndicatorsManager::GetTrendDirection_M5() == TREND_BEARISH)
     {
      score.trend_score = 15;
     }
   else if(IndicatorsManager::GetTrendDirection_M1() == TREND_BEARISH)
     {
      score.trend_score = 10;
     }
   
   //--- 2. RSI Confirmation (0-20 points)
   if(CheckRSIConfirmationSell())
     {
      score.rsi_score = 20;
      
      if(IndicatorsManager::GetRSI14() > 60 && IndicatorsManager::IsRSIFalling())
        {
         score.rsi_score = 20;
        }
      else if(IndicatorsManager::GetRSI14() < 50 && IndicatorsManager::IsRSIFalling())
        {
         score.rsi_score = 15;
        }
     }
   else if(!Config::GetRequireRSIConfirmation())
     {
      score.rsi_score = 10;
     }
   
   //--- 3. Price Action (0-25 points)
   if(CheckPriceActionSell())
     {
      score.price_action_score = 25;
      
      ENUM_CANDLE_PATTERN pattern = PriceActionAnalyzer::GetCurrentPattern();
      
      if(pattern == PATTERN_ENGULFING_BEAR || pattern == PATTERN_EVENING_STAR || 
         pattern == PATTERN_THREE_BLACK_CROWS)
        {
         score.price_action_score = 25;
        }
      else if(pattern == PATTERN_PIN_BAR_BEAR || pattern == PATTERN_SHOOTING_STAR)
        {
         score.price_action_score = 20;
        }
      else if(pattern == PATTERN_INSIDE_BAR)
        {
         score.price_action_score = 15;
        }
     }
   
   //--- 4. Market Structure (0-15 points)
   if(CheckStructureSell())
     {
      score.structure_score = 15;
      
      ENUM_MARKET_STRUCTURE_TYPE structure = PriceActionAnalyzer::GetMarketStructure().structure_type;
      
      if(structure == STRUCTURE_DOWNTREND || structure == STRUCTURE_BREAKOUT_BEAR)
        {
         score.structure_score = 15;
        }
      else if(structure == STRUCTURE_REVERSAL_BEAR)
        {
         score.structure_score = 12;
        }
      else if(PriceActionAnalyzer::HasBearishOB() && !PriceActionAnalyzer::GetBearishOB().is_tested)
        {
         score.structure_score = 10;
        }
      else if(PriceActionAnalyzer::HasBearishFVG() && !PriceActionAnalyzer::GetBearishFVG().is_filled)
        {
         score.structure_score = 10;
        }
     }
   
   //--- 5. Volume (0-10 points)
   if(CheckVolumeSell())
     {
      score.volume_score = 10;
     }
   else
     {
      score.volume_score = 5;
     }
   
   //--- Total
   score.total_score = score.trend_score + score.rsi_score + score.price_action_score + 
                       score.structure_score + score.volume_score;
   
   return score;
  }

//+------------------------------------------------------------------+
//| Score to Strength                                                |
//+------------------------------------------------------------------+
ENUM_SIGNAL_STRENGTH SignalGenerator::ScoreToStrength(int score)
  {
   if(score >= 90) return SIGNAL_VERY_STRONG;
   if(score >= 75) return SIGNAL_STRONG;
   if(score >= 60) return SIGNAL_MODERATE;
   return SIGNAL_WEAK;
  }

//+------------------------------------------------------------------+
//| Check Trend Alignment - Buy                                      |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckTrendAlignmentBuy()
  {
   if(!Config::GetRequireTrendAlignment())
     {
      return true; // Not required
     }
   
   return IndicatorsManager::IsTrendAlignedBullish();
  }

//+------------------------------------------------------------------+
//| Check Trend Alignment - Sell                                     |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckTrendAlignmentSell()
  {
   if(!Config::GetRequireTrendAlignment())
     {
      return true;
     }
   
   return IndicatorsManager::IsTrendAlignedBearish();
  }

//+------------------------------------------------------------------+
//| Check RSI Confirmation - Buy                                     |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckRSIConfirmationBuy()
  {
   if(!Config::GetRequireRSIConfirmation())
     {
      return true;
     }
   
   double rsi = IndicatorsManager::GetRSI14();
   
   //--- RSI should not be overbought
   if(rsi >= Config::GetRSIOverbought())
     {
      return false;
     }
   
   //--- Prefer RSI rising or in bullish territory
   return (rsi > 50 || (rsi > 30 && IndicatorsManager::IsRSIRising()));
  }

//+------------------------------------------------------------------+
//| Check RSI Confirmation - Sell                                    |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckRSIConfirmationSell()
  {
   if(!Config::GetRequireRSIConfirmation())
     {
      return true;
     }
   
   double rsi = IndicatorsManager::GetRSI14();
   
   //--- RSI should not be oversold
   if(rsi <= Config::GetRSIOversold())
     {
      return false;
     }
   
   //--- Prefer RSI falling or in bearish territory
   return (rsi < 50 || (rsi < 70 && IndicatorsManager::IsRSIFalling()));
  }

//+------------------------------------------------------------------+
//| Check Price Action - Buy                                         |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckPriceActionBuy()
  {
   if(!Config::GetRequirePriceActionConfirmation())
     {
      return true;
     }
   
   ENUM_CANDLE_PATTERN pattern = PriceActionAnalyzer::GetCurrentPattern();
   
   //--- Check for bullish patterns
   if(PriceActionAnalyzer::IsBullishPattern(pattern))
     {
      return true;
     }
   
   //--- Check for price at support with bullish candle
   CANDLE_INFO current = PriceActionAnalyzer::GetCurrentCandle();
   if(current.is_bullish && PriceActionAnalyzer::IsNearSupport(current.close, 0.5))
     {
      return true;
     }
   
   //--- Check for bullish order block test
   if(PriceActionAnalyzer::HasBullishOB())
     {
      ORDER_BLOCK ob = PriceActionAnalyzer::GetBullishOB();
      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      if(current_price >= ob.price_bottom && current_price <= ob.price_top && !ob.is_tested)
        {
         return true;
        }
     }
   
   //--- Check for bullish FVG test
   if(PriceActionAnalyzer::HasBullishFVG())
     {
      FAIR_VALUE_GAP fvg = PriceActionAnalyzer::GetBullishFVG();
      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      if(current_price >= fvg.bottom_price && current_price <= fvg.top_price && !fvg.is_filled)
        {
         return true;
        }
     }
   
   return false;
  }

//+------------------------------------------------------------------+
//| Check Price Action - Sell                                        |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckPriceActionSell()
  {
   if(!Config::GetRequirePriceActionConfirmation())
     {
      return true;
     }
   
   ENUM_CANDLE_PATTERN pattern = PriceActionAnalyzer::GetCurrentPattern();
   
   if(PriceActionAnalyzer::IsBearishPattern(pattern))
     {
      return true;
     }
   
   CANDLE_INFO current = PriceActionAnalyzer::GetCurrentCandle();
   if(current.is_bearish && PriceActionAnalyzer::IsNearResistance(current.close, 0.5))
     {
      return true;
     }
   
   if(PriceActionAnalyzer::HasBearishOB())
     {
      ORDER_BLOCK ob = PriceActionAnalyzer::GetBearishOB();
      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(current_price <= ob.price_top && current_price >= ob.price_bottom && !ob.is_tested)
        {
         return true;
        }
     }
   
   if(PriceActionAnalyzer::HasBearishFVG())
     {
      FAIR_VALUE_GAP fvg = PriceActionAnalyzer::GetBearishFVG();
      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      
      if(current_price <= fvg.top_price && current_price >= fvg.bottom_price && !fvg.is_filled)
        {
         return true;
        }
     }
   
   return false;
  }

//+------------------------------------------------------------------+
//| Check Structure - Buy                                            |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckStructureBuy()
  {
   ENUM_MARKET_STRUCTURE_TYPE structure = PriceActionAnalyzer::GetMarketStructure().structure_type;
   
   //--- Favorable structures for buy
   return (structure == STRUCTURE_UPTREND || 
           structure == STRUCTURE_BREAKOUT_BULL || 
           structure == STRUCTURE_REVERSAL_BULL ||
           structure == STRUCTURE_RANGING); // Ranging can work for mean reversion
  }

//+------------------------------------------------------------------+
//| Check Structure - Sell                                           |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckStructureSell()
  {
   ENUM_MARKET_STRUCTURE_TYPE structure = PriceActionAnalyzer::GetMarketStructure().structure_type;
   
   return (structure == STRUCTURE_DOWNTREND || 
           structure == STRUCTURE_BREAKOUT_BEAR || 
           structure == STRUCTURE_REVERSAL_BEAR ||
           structure == STRUCTURE_RANGING);
  }

//+------------------------------------------------------------------+
//| Check Volume - Buy                                               |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckVolumeBuy()
  {
   //--- Volume increasing on bullish move is good
   return PriceActionAnalyzer::IsVolumeIncreasing();
  }

//+------------------------------------------------------------------+
//| Check Volume - Sell                                              |
//+------------------------------------------------------------------+
bool SignalGenerator::CheckVolumeSell()
  {
   //--- Volume increasing on bearish move is good
   return PriceActionAnalyzer::IsVolumeIncreasing();
  }

//+------------------------------------------------------------------+
//| Calculate Stop Loss                                              |
//+------------------------------------------------------------------+
double SignalGenerator::CalculateStopLoss(ENUM_ENTRY_TYPE type, double entry_price, double atr)
  {
   double atr_mult = Config::GetATRMultiplierSL();
   double sl_distance = atr * atr_mult;
   
   //--- Minimum SL distance (spread + buffer)
   double min_sl = SymbolInfoDouble(_Symbol, SYMBOL_SPREAD) * _Point * 3;
   if(sl_distance < min_sl) sl_distance = min_sl;
   
   if(type == ENTRY_BUY)
     {
      //--- For buy, SL below entry
      //--- Try to place at swing low or order block
      double swing_low = PriceActionAnalyzer::GetLastSwingLow();
      double ob_price = PriceActionAnalyzer::HasBullishOB() ? PriceActionAnalyzer::GetBullishOBPrice() : 0;
      
      double candidate_sl = entry_price - sl_distance;
      
      //--- Use swing low if it's reasonable
      if(swing_low > 0 && swing_low < entry_price && entry_price - swing_low <= sl_distance * 1.5)
        {
         candidate_sl = swing_low - atr * 0.2; // Small buffer below swing low
        }
      //--- Use order block bottom
      else if(ob_price > 0 && ob_price < entry_price && entry_price - ob_price <= sl_distance * 1.5)
        {
         candidate_sl = ob_price - atr * 0.2;
        }
      
      //--- Ensure minimum distance
      if(entry_price - candidate_sl < min_sl)
        {
         candidate_sl = entry_price - min_sl;
        }
      
      return NormalizeDouble(candidate_sl, _Digits);
     }
   else
     {
      //--- For sell, SL above entry
      double swing_high = PriceActionAnalyzer::GetLastSwingHigh();
      double ob_price = PriceActionAnalyzer::HasBearishOB() ? PriceActionAnalyzer::GetBearishOBPrice() : 0;
      
      double candidate_sl = entry_price + sl_distance;
      
      if(swing_high > 0 && swing_high > entry_price && swing_high - entry_price <= sl_distance * 1.5)
        {
         candidate_sl = swing_high + atr * 0.2;
        }
      else if(ob_price > 0 && ob_price > entry_price && ob_price - entry_price <= sl_distance * 1.5)
        {
         candidate_sl = ob_price + atr * 0.2;
        }
      
      if(candidate_sl - entry_price < min_sl)
        {
         candidate_sl = entry_price + min_sl;
        }
      
      return NormalizeDouble(candidate_sl, _Digits);
     }
  }

//+------------------------------------------------------------------+
//| Calculate Take Profit                                            |
//+------------------------------------------------------------------+
double SignalGenerator::CalculateTakeProfit(ENUM_ENTRY_TYPE type, double entry_price, double stop_loss)
  {
   double risk = MathAbs(entry_price - stop_loss);
   double rr = Config::GetMinRiskRewardRatio();
   
   //--- Use ATR-based TP
   double atr = IndicatorsManager::GetATR14();
   double atr_tp = atr * Config::GetATRMultiplierTP();
   
   //--- Use the larger of R:R based or ATR based
   double tp_distance = MathMax(risk * rr, atr_tp);
   
   //--- Check for key levels
   if(type == ENTRY_BUY)
     {
      double resistance = PriceActionAnalyzer::GetNearestResistance(entry_price);
      if(resistance > 0 && resistance - entry_price > risk * 1.0 && resistance - entry_price < tp_distance * 1.5)
        {
         //--- Target just before resistance
         return NormalizeDouble(resistance - atr * 0.3, _Digits);
        }
      
      return NormalizeDouble(entry_price + tp_distance, _Digits);
     }
   else
     {
      double support = PriceActionAnalyzer::GetNearestSupport(entry_price);
      if(support > 0 && entry_price - support > risk * 1.0 && entry_price - support < tp_distance * 1.5)
        {
         return NormalizeDouble(support + atr * 0.3, _Digits);
        }
      
      return NormalizeDouble(entry_price - tp_distance, _Digits);
     }
  }

//+------------------------------------------------------------------+
//| Validate Signal                                                  |
//+------------------------------------------------------------------+
bool SignalGenerator::ValidateSignal(ENTRY_SIGNAL &signal)
  {
   //--- Check spread again
   double spread = SymbolInfoDouble(_Symbol, SYMBOL_SPREAD) * _Point;
   if(spread > Config::GetMaxSpreadPoints())
     {
      return false;
     }
   
   //--- Check SL/TP are valid
   if(signal.type == ENTRY_BUY)
     {
      if(signal.stop_loss >= signal.entry_price) return false;
      if(signal.take_profit <= signal.entry_price) return false;
      
      //--- Check freeze level
      double freeze_level = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
      if(signal.entry_price - signal.stop_loss < freeze_level) return false;
      if(signal.take_profit - signal.entry_price < freeze_level) return false;
     }
   else
     {
      if(signal.stop_loss <= signal.entry_price) return false;
      if(signal.take_profit >= signal.entry_price) return false;
      
      double freeze_level = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
      if(signal.stop_loss - signal.entry_price < freeze_level) return false;
      if(signal.entry_price - signal.take_profit < freeze_level) return false;
     }
   
   //--- Check volatility
   if(!IndicatorsManager::IsVolatilityNormal())
     {
      return false;
     }
   
   //--- Check not too close to session close
   if(!Config::IsTradingTime())
     {
      return false;
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Reset Entry Tracking                                             |
//+------------------------------------------------------------------+
void SignalGenerator::ResetEntryTracking()
  {
   s_current_buy_entries = 0;
   s_current_sell_entries = 0;
   s_last_buy_price = 0;
   s_last_sell_price = 0;
  }

//+------------------------------------------------------------------+
//| On Position Opened                                               |
//+------------------------------------------------------------------+
void SignalGenerator::OnPositionOpened(ENUM_ENTRY_TYPE type, double price)
  {
   if(type == ENTRY_BUY)
     {
      s_current_buy_entries++;
      s_last_buy_price = price;
     }
   else
     {
      s_current_sell_entries++;
      s_last_sell_price = price;
     }
  }

//+------------------------------------------------------------------+
//| On Position Closed                                               |
//+------------------------------------------------------------------+
void SignalGenerator::OnPositionClosed(ENUM_ENTRY_TYPE type)
  {
   if(type == ENTRY_BUY)
     {
      s_current_buy_entries = MathMax(0, s_current_buy_entries - 1);
     }
   else
     {
      s_current_sell_entries = MathMax(0, s_current_sell_entries - 1);
     }
  }

//+------------------------------------------------------------------+
//| Can Add Buy Entry                                                |
//+------------------------------------------------------------------+
bool SignalGenerator::CanAddBuyEntry(double current_price)
  {
   if(s_current_buy_entries >= Config::GetMaxEntriesPerDirection())
     {
      return false;
     }
   
   if(s_current_buy_entries > 0 && s_last_buy_price > 0)
     {
      double atr = IndicatorsManager::GetATR14();
      double min_distance = atr * Config::GetMinDistanceBetweenEntriesATR();
      
      if(current_price - s_last_buy_price < min_distance)
        {
         return false;
        }
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Can Add Sell Entry                                               |
//+------------------------------------------------------------------+
bool SignalGenerator::CanAddSellEntry(double current_price)
  {
   if(s_current_sell_entries >= Config::GetMaxEntriesPerDirection())
     {
      return false;
     }
   
   if(s_current_sell_entries > 0 && s_last_sell_price > 0)
     {
      double atr = IndicatorsManager::GetATR14();
      double min_distance = atr * Config::GetMinDistanceBetweenEntriesATR();
      
      if(s_last_sell_price - current_price < min_distance)
        {
         return false;
        }
     }
   
   return true;
  }
//+------------------------------------------------------------------+