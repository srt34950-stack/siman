//+------------------------------------------------------------------+
//|                                           IndicatorsManager.mqh  |
//|                    Multi-Timeframe Indicator Management          |
//+------------------------------------------------------------------+
#property strict

#include <Indicators\Indicators.mqh>

//+------------------------------------------------------------------+
//| Indicators Manager Class                                         |
//+------------------------------------------------------------------+
class IndicatorsManager
  {
private:
   //--- Indicator handles
   static int s_ema50_m1_handle;
   static int s_ema200_m5_handle;
   static int s_rsi14_m1_handle;
   static int s_atr14_m1_handle;
   
   //--- Indicator buffers
   static double s_ema50_m1_buffer[];
   static double s_ema200_m5_buffer[];
   static double s_rsi14_m1_buffer[];
   static double s_atr14_m1_buffer[];
   
   //--- Current values
   static double s_ema50_m1_current;
   static double s_ema200_m5_current;
   static double s_rsi14_current;
   static double s_atr14_current;
   
   //--- Previous values for crossover detection
   static double s_ema50_m1_prev;
   static double s_ema200_m5_prev;
   static double s_rsi14_prev;
   
   //--- Trend direction
   static ENUM_TREND_DIRECTION s_trend_m1;
   static ENUM_TREND_DIRECTION s_trend_m5;
   
   //--- Initialization flags
   static bool s_initialized;
   
   //--- Symbol and timeframe info
   static string s_symbol;
   static ENUM_TIMEFRAMES s_timeframe_m1;
   static ENUM_TIMEFRAMES s_timeframe_m5;

public:
   //--- Initialization
   static bool Initialize();
   static void Cleanup();
   
   //--- Update indicators
   static bool Update();
   
   //--- Get current values
   static double GetEMA50_M1() { return s_ema50_m1_current; }
   static double GetEMA200_M5() { return s_ema200_m5_current; }
   static double GetRSI14() { return s_rsi14_current; }
   static double GetATR14() { return s_atr14_current; }
   
   //--- Get trend direction
   static ENUM_TREND_DIRECTION GetTrendDirection_M1() { return s_trend_m1; }
   static ENUM_TREND_DIRECTION GetTrendDirection_M5() { return s_trend_m5; }
   
   //--- Get previous values
   static double GetEMA50_M1_Prev() { return s_ema50_m1_prev; }
   static double GetEMA200_M5_Prev() { return s_ema200_m5_prev; }
   static double GetRSI14_Prev() { return s_rsi14_prev; }
   
   //--- Check crossovers
   static bool IsEMA50CrossUp_M1() { return s_ema50_m1_prev < s_ema50_m1_current; }
   static bool IsEMA50CrossDown_M1() { return s_ema50_m1_prev > s_ema50_m1_current; }
   static bool IsPriceAboveEMA50_M1() { return SymbolInfoDouble(s_symbol, SYMBOL_BID) > s_ema50_m1_current; }
   static bool IsPriceBelowEMA50_M1() { return SymbolInfoDouble(s_symbol, SYMBOL_BID) < s_ema50_m1_current; }
   static bool IsPriceAboveEMA200_M5() { return SymbolInfoDouble(s_symbol, SYMBOL_BID) > s_ema200_m5_current; }
   static bool IsPriceBelowEMA200_M5() { return SymbolInfoDouble(s_symbol, SYMBOL_BID) < s_ema200_m5_current; }
   
   //--- RSI levels
   static bool IsRSIOverbought() { return s_rsi14_current >= Config::GetRSIOverbought(); }
   static bool IsRSIOversold() { return s_rsi14_current <= Config::GetRSIOversold(); }
   static bool IsRSINeutral() { return s_rsi14_current > (50 - Config::GetRSINeutralZone()) && s_rsi14_current < (50 + Config::GetRSINeutralZone()); }
   static bool IsRSIRising() { return s_rsi14_current > s_rsi14_prev; }
   static bool IsRSIFalling() { return s_rsi14_current < s_rsi14_prev; }
   
   //--- ATR analysis
   static bool IsVolatilityNormal() 
     {
      double atr = s_atr14_current;
      double min_atr = Config::GetMinATRThreshold();
      double max_atr = Config::GetMaxATRThreshold();
      
      if(min_atr > 0 && atr < min_atr) return false;
      if(max_atr > 0 && atr > max_atr) return false;
      return true;
     }
   
   static double GetATRInPoints() { return s_atr14_current / _Point; }
   
   //--- Trend alignment
   static bool IsTrendAlignedBullish() 
     {
      return (s_trend_m1 == TREND_BULLISH || s_trend_m1 == TREND_NEUTRAL) && s_trend_m5 == TREND_BULLISH;
     }
   
   static bool IsTrendAlignedBearish() 
     {
      return (s_trend_m1 == TREND_BEARISH || s_trend_m1 == TREND_NEUTRAL) && s_trend_m5 == TREND_BEARISH;
     }
   
   static bool IsTrendStrongBullish() 
     {
      return s_trend_m1 == TREND_BULLISH && s_trend_m5 == TREND_BULLISH;
     }
   
   static bool IsTrendStrongBearish() 
     {
      return s_trend_m1 == TREND_BEARISH && s_trend_m5 == TREND_BEARISH;
     }
   
   //--- Debug
   static void PrintIndicatorValues();

private:
   //--- Helper functions
   static bool CreateIndicators();
   static bool CopyIndicatorData();
   static void CalculateTrendDirection();
   static double GetPriceForTimeframe(ENUM_TIMEFRAMES timeframe);
  };

//+------------------------------------------------------------------+
//| Static member definitions                                        |
//+------------------------------------------------------------------+
int IndicatorsManager::s_ema50_m1_handle = INVALID_HANDLE;
int IndicatorsManager::s_ema200_m5_handle = INVALID_HANDLE;
int IndicatorsManager::s_rsi14_m1_handle = INVALID_HANDLE;
int IndicatorsManager::s_atr14_m1_handle = INVALID_HANDLE;

double IndicatorsManager::s_ema50_m1_buffer[];
double IndicatorsManager::s_ema200_m5_buffer[];
double IndicatorsManager::s_rsi14_m1_buffer[];
double IndicatorsManager::s_atr14_m1_buffer[];

double IndicatorsManager::s_ema50_m1_current = 0;
double IndicatorsManager::s_ema200_m5_current = 0;
double IndicatorsManager::s_rsi14_current = 50;
double IndicatorsManager::s_atr14_current = 0;

double IndicatorsManager::s_ema50_m1_prev = 0;
double IndicatorsManager::s_ema200_m5_prev = 0;
double IndicatorsManager::s_rsi14_prev = 50;

ENUM_TREND_DIRECTION IndicatorsManager::s_trend_m1 = TREND_UNKNOWN;
ENUM_TREND_DIRECTION IndicatorsManager::s_trend_m5 = TREND_UNKNOWN;

bool IndicatorsManager::s_initialized = false;
string IndicatorsManager::s_symbol = "";
ENUM_TIMEFRAMES IndicatorsManager::s_timeframe_m1 = PERIOD_M1;
ENUM_TIMEFRAMES IndicatorsManager::s_timeframe_m5 = PERIOD_M5;

//+------------------------------------------------------------------+
//| Initialize Indicators                                            |
//+------------------------------------------------------------------+
bool IndicatorsManager::Initialize()
  {
   s_symbol = _Symbol;
   s_timeframe_m1 = PERIOD_M1;
   s_timeframe_m5 = PERIOD_M5;
   
   //--- Create indicator handles
   if(!CreateIndicators())
     {
      Print("IndicatorsManager: Failed to create indicators");
      return false;
     }
   
   //--- Initial data copy
   if(!CopyIndicatorData())
     {
      Print("IndicatorsManager: Failed to copy initial indicator data");
      return false;
     }
   
   //--- Calculate initial trend direction
   CalculateTrendDirection();
   
   s_initialized = true;
   Print("IndicatorsManager: Initialized successfully");
   Print("IndicatorsManager: EMA50(M1)=", s_ema50_m1_current, " EMA200(M5)=", s_ema200_m5_current, 
         " RSI14=", s_rsi14_current, " ATR14=", s_atr14_current);
   
   return true;
  }

//+------------------------------------------------------------------+
//| Create Indicator Handles                                         |
//+------------------------------------------------------------------+
bool IndicatorsManager::CreateIndicators()
  {
   //--- EMA 50 on M1
   s_ema50_m1_handle = iMA(s_symbol, s_timeframe_m1, Config::GetEMA50Period(), 0, 
                           Config::GetEMAAethod(), Config::GetAppliedPrice());
   if(s_ema50_m1_handle == INVALID_HANDLE)
     {
      Print("IndicatorsManager: Failed to create EMA50 M1 handle. Error: ", GetLastError());
      return false;
     }
   
   //--- EMA 200 on M5
   s_ema200_m5_handle = iMA(s_symbol, s_timeframe_m5, Config::GetEMA200Period(), 0, 
                            Config::GetEMAAethod(), Config::GetAppliedPrice());
   if(s_ema200_m5_handle == INVALID_HANDLE)
     {
      Print("IndicatorsManager: Failed to create EMA200 M5 handle. Error: ", GetLastError());
      return false;
     }
   
   //--- RSI 14 on M1
   s_rsi14_m1_handle = iRSI(s_symbol, s_timeframe_m1, Config::GetRSIPeriod(), Config::GetAppliedPrice());
   if(s_rsi14_m1_handle == INVALID_HANDLE)
     {
      Print("IndicatorsManager: Failed to create RSI14 M1 handle. Error: ", GetLastError());
      return false;
     }
   
   //--- ATR 14 on M1
   s_atr14_m1_handle = iATR(s_symbol, s_timeframe_m1, Config::GetATRPeriod());
   if(s_atr14_m1_handle == INVALID_HANDLE)
     {
      Print("IndicatorsManager: Failed to create ATR14 M1 handle. Error: ", GetLastError());
      return false;
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Copy Indicator Data                                              |
//+------------------------------------------------------------------+
bool IndicatorsManager::CopyIndicatorData()
  {
   //--- Resize buffers
   ArrayResize(s_ema50_m1_buffer, 3);
   ArrayResize(s_ema200_m5_buffer, 3);
   ArrayResize(s_rsi14_m1_buffer, 3);
   ArrayResize(s_atr14_m1_buffer, 3);
   
   //--- Copy EMA 50 M1 (current, previous, 2 bars ago)
   if(CopyBuffer(s_ema50_m1_handle, 0, 0, 3, s_ema50_m1_buffer) <= 0)
     {
      Print("IndicatorsManager: Failed to copy EMA50 M1 buffer. Error: ", GetLastError());
      return false;
     }
   
   //--- Copy EMA 200 M5
   if(CopyBuffer(s_ema200_m5_handle, 0, 0, 3, s_ema200_m5_buffer) <= 0)
     {
      Print("IndicatorsManager: Failed to copy EMA200 M5 buffer. Error: ", GetLastError());
      return false;
     }
   
   //--- Copy RSI 14 M1
   if(CopyBuffer(s_rsi14_m1_handle, 0, 0, 3, s_rsi14_m1_buffer) <= 0)
     {
      Print("IndicatorsManager: Failed to copy RSI14 M1 buffer. Error: ", GetLastError());
      return false;
     }
   
   //--- Copy ATR 14 M1
   if(CopyBuffer(s_atr14_m1_handle, 0, 0, 3, s_atr14_m1_buffer) <= 0)
     {
      Print("IndicatorsManager: Failed to copy ATR14 M1 buffer. Error: ", GetLastError());
      return false;
     }
   
   //--- Store previous values before updating current
   s_ema50_m1_prev = s_ema50_m1_current;
   s_ema200_m5_prev = s_ema200_m5_current;
   s_rsi14_prev = s_rsi14_current;
   
   //--- Update current values (index 0 = current forming bar, index 1 = closed bar)
   //--- Use index 1 for closed bar values to avoid repainting
   s_ema50_m1_current = s_ema50_m1_buffer[1];
   s_ema200_m5_current = s_ema200_m5_buffer[1];
   s_rsi14_current = s_rsi14_m1_buffer[1];
   s_atr14_current = s_atr14_m1_buffer[1];
   
   //--- Validate values
   if(s_ema50_m1_current == 0 || s_ema200_m5_current == 0 || s_rsi14_current == 0 || s_atr14_current == 0)
     {
      if(Config::GetDebugMode())
        {
         Print("IndicatorsManager: Warning - Some indicator values are zero");
        }
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Update Indicators                                                |
//+------------------------------------------------------------------+
bool IndicatorsManager::Update()
  {
   if(!s_initialized)
     {
      return false;
     }
   
   if(!CopyIndicatorData())
     {
      return false;
     }
   
   CalculateTrendDirection();
   
   return true;
  }

//+------------------------------------------------------------------+
//| Calculate Trend Direction                                        |
//+------------------------------------------------------------------+
void IndicatorsManager::CalculateTrendDirection()
  {
   double price = GetPriceForTimeframe(s_timeframe_m1);
   
   //--- M1 Trend: Price vs EMA50 + EMA50 slope
   double ema50_slope = s_ema50_m1_buffer[1] - s_ema50_m1_buffer[2];
   
   if(price > s_ema50_m1_current && ema50_slope > 0)
     {
      s_trend_m1 = TREND_BULLISH;
     }
   else if(price < s_ema50_m1_current && ema50_slope < 0)
     {
      s_trend_m1 = TREND_BEARISH;
     }
   else if(MathAbs(price - s_ema50_m1_current) < s_atr14_current * 0.5)
     {
      s_trend_m1 = TREND_NEUTRAL;
     }
   else
     {
      //--- Determine by slope if price is close to EMA
      if(ema50_slope > 0)
        s_trend_m1 = TREND_BULLISH;
      else if(ema50_slope < 0)
        s_trend_m1 = TREND_BEARISH;
      else
        s_trend_m1 = TREND_NEUTRAL;
     }
   
   //--- M5 Trend: Price vs EMA200 + EMA200 slope
   double price_m5 = GetPriceForTimeframe(s_timeframe_m5);
   double ema200_slope = s_ema200_m5_buffer[1] - s_ema200_m5_buffer[2];
   
   if(price_m5 > s_ema200_m5_current && ema200_slope > 0)
     {
      s_trend_m5 = TREND_BULLISH;
     }
   else if(price_m5 < s_ema200_m5_current && ema200_slope < 0)
     {
      s_trend_m5 = TREND_BEARISH;
     }
   else if(MathAbs(price_m5 - s_ema200_m5_current) < s_atr14_current * 1.0)
     {
      s_trend_m5 = TREND_NEUTRAL;
     }
   else
     {
      if(ema200_slope > 0)
        s_trend_m5 = TREND_BULLISH;
      else if(ema200_slope < 0)
        s_trend_m5 = TREND_BEARISH;
      else
        s_trend_m5 = TREND_NEUTRAL;
     }
  }

//+------------------------------------------------------------------+
//| Get Price for Timeframe                                          |
//+------------------------------------------------------------------+
double IndicatorsManager::GetPriceForTimeframe(ENUM_TIMEFRAMES timeframe)
  {
   double close[];
   if(CopyClose(s_symbol, timeframe, 0, 1, close) > 0)
     {
      return close[0];
     }
   return SymbolInfoDouble(s_symbol, SYMBOL_BID);
  }

//+------------------------------------------------------------------+
//| Cleanup Indicators                                               |
//+------------------------------------------------------------------+
void IndicatorsManager::Cleanup()
  {
   if(s_ema50_m1_handle != INVALID_HANDLE)
     {
      IndicatorRelease(s_ema50_m1_handle);
      s_ema50_m1_handle = INVALID_HANDLE;
     }
   
   if(s_ema200_m5_handle != INVALID_HANDLE)
     {
      IndicatorRelease(s_ema200_m5_handle);
      s_ema200_m5_handle = INVALID_HANDLE;
     }
   
   if(s_rsi14_m1_handle != INVALID_HANDLE)
     {
      IndicatorRelease(s_rsi14_m1_handle);
      s_rsi14_m1_handle = INVALID_HANDLE;
     }
   
   if(s_atr14_m1_handle != INVALID_HANDLE)
     {
      IndicatorRelease(s_atr14_m1_handle);
      s_atr14_m1_handle = INVALID_HANDLE;
     }
   
   ArrayFree(s_ema50_m1_buffer);
   ArrayFree(s_ema200_m5_buffer);
   ArrayFree(s_rsi14_m1_buffer);
   ArrayFree(s_atr14_m1_buffer);
   
   s_initialized = false;
   Print("IndicatorsManager: Cleaned up");
  }

//+------------------------------------------------------------------+
//| Print Indicator Values (Debug)                                   |
//+------------------------------------------------------------------+
void IndicatorsManager::PrintIndicatorValues()
  {
   Print("=== INDICATOR VALUES ===");
   Print("EMA50 M1: Current=", s_ema50_m1_current, " Prev=", s_ema50_m1_prev);
   Print("EMA200 M5: Current=", s_ema200_m5_current, " Prev=", s_ema200_m5_prev);
   Print("RSI14: Current=", s_rsi14_current, " Prev=", s_rsi14_prev);
   Print("ATR14: Current=", s_atr14_current);
   Print("Trend M1: ", EnumToString(s_trend_m1));
   Print("Trend M5: ", EnumToString(s_trend_m5));
   Print("Price vs EMA50: ", (SymbolInfoDouble(s_symbol, SYMBOL_BID) > s_ema50_m1_current ? "ABOVE" : "BELOW"));
   Print("Price vs EMA200: ", (SymbolInfoDouble(s_symbol, SYMBOL_BID) > s_ema200_m5_current ? "ABOVE" : "BELOW"));
   Print("RSI State: ", (IsRSIOverbought() ? "OVERBOUGHT" : (IsRSIOversold() ? "OVERSOLD" : (IsRSINeutral() ? "NEUTRAL" : "TRENDING"))));
   Print("Volatility: ", (IsVolatilityNormal() ? "NORMAL" : "ABNORMAL"));
   Print("=========================");
  }
//+------------------------------------------------------------------+