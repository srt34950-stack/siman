//+------------------------------------------------------------------+
//|                                         PriceActionAnalyzer.mqh  |
//|                    Price Action & Market Structure Analysis      |
//+------------------------------------------------------------------+
#property strict

#include "Config.mqh"

//+------------------------------------------------------------------+
//| Candle Pattern Types                                             |
//+------------------------------------------------------------------+
enum ENUM_CANDLE_PATTERN
  {
   PATTERN_NONE = 0,
   PATTERN_PIN_BAR_BULL = 1,
   PATTERN_PIN_BAR_BEAR = 2,
   PATTERN_ENGULFING_BULL = 3,
   PATTERN_ENGULFING_BEAR = 4,
   PATTERN_INSIDE_BAR = 5,
   PATTERN_OUTSIDE_BAR = 6,
   PATTERN_DOJI = 7,
   PATTERN_HAMMER = 8,
   PATTERN_SHOOTING_STAR = 9,
   PATTERN_MORNING_STAR = 10,
   PATTERN_EVENING_STAR = 11,
   PATTERN_THREE_WHITE_SOLDIERS = 12,
   PATTERN_THREE_BLACK_CROWS = 13
  };

enum ENUM_ORDER_BLOCK_TYPE
  {
   OB_NONE = 0,
   OB_BULLISH = 1,
   OB_BEARISH = 2
  };

enum ENUM_FVG_TYPE
  {
   FVG_NONE = 0,
   FVG_BULLISH = 1,
   FVG_BEARISH = 2
  };

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
struct CANDLE_INFO
  {
   double open;
   double high;
   double low;
   double close;
   double body_size;
   double upper_wick;
   double lower_wick;
   double range;
   bool   is_bullish;
   bool   is_bearish;
   bool   is_doji;
   ENUM_CANDLE_PATTERN pattern;
  };

struct ORDER_BLOCK
  {
   ENUM_ORDER_BLOCK_TYPE type;
   double price_top;
   double price_bottom;
   double open_price;
   double close_price;
   datetime time;
   bool is_tested;
   bool is_valid;
   int  strength; // 1-10
  };

struct FAIR_VALUE_GAP
  {
   ENUM_FVG_TYPE type;
   double top_price;
   double bottom_price;
   datetime time;
   bool is_filled;
   bool is_valid;
  };

struct SWING_POINT
  {
   double price;
   int    index;
   datetime time;
   bool   is_high;
   bool   is_confirmed;
  };

//+------------------------------------------------------------------+
//| Price Action Analyzer Class                                      |
//+------------------------------------------------------------------+
class PriceActionAnalyzer
  {
private:
   //--- Market data
   static double s_open[];
   static double s_high[];
   static double s_low[];
   static double s_close[];
   static datetime s_time[];
   static int s_bars_loaded;
   
   //--- Analysis results
   static MARKET_STRUCTURE s_market_structure;
   static CANDLE_INFO s_current_candle;
   static CANDLE_INFO s_prev_candle;
   static CANDLE_INFO s_prev2_candle;
   
   //--- Swing points
   static SWING_POINT s_swings_high[];
   static SWING_POINT s_swings_low[];
   static int s_swing_count_high;
   static int s_swing_count_low;
   
   //--- Order blocks
   static ORDER_BLOCK s_bullish_ob;
   static ORDER_BLOCK s_bearish_ob;
   static bool s_has_bullish_ob;
   static bool s_has_bearish_ob;
   
   //--- Fair value gaps
   static FAIR_VALUE_GAP s_bullish_fvg;
   static FAIR_VALUE_GAP s_bearish_fvg;
   static bool s_has_bullish_fvg;
   static bool s_has_bearish_fvg;
   
   //--- Key levels
   static double s_resistance_levels[];
   static double s_support_levels[];
   static int s_resistance_count;
   static int s_support_count;
   
   //--- Initialization
   static bool s_initialized;
   static int s_lookback_period;

public:
   //--- Initialization
   static bool Initialize();
   static void Cleanup();
   
   //--- Update analysis
   static bool Update();
   
   //--- Get results
   static MARKET_STRUCTURE GetMarketStructure() { return s_market_structure; }
   static CANDLE_INFO GetCurrentCandle() { return s_current_candle; }
   static CANDLE_INFO GetPrevCandle() { return s_prev_candle; }
   static CANDLE_INFO GetPrev2Candle() { return s_prev2_candle; }
   
   //--- Swing points
   static double GetLastSwingHigh() { return s_market_structure.last_swing_high; }
   static double GetLastSwingLow() { return s_market_structure.last_swing_low; }
   static double GetPrevSwingHigh() { return s_market_structure.previous_swing_high; }
   static double GetPrevSwingLow() { return s_market_structure.previous_swing_low; }
   
   //--- Order blocks
   static bool HasBullishOB() { return s_has_bullish_ob; }
   static bool HasBearishOB() { return s_has_bearish_ob; }
   static double GetBullishOBPrice() { return s_bullish_ob.price_bottom; }
   static double GetBearishOBPrice() { return s_bearish_ob.price_top; }
   static ORDER_BLOCK GetBullishOB() { return s_bullish_ob; }
   static ORDER_BLOCK GetBearishOB() { return s_bearish_ob; }
   
   //--- Fair Value Gaps
   static bool HasBullishFVG() { return s_has_bullish_fvg; }
   static bool HasBearishFVG() { return s_has_bearish_fvg; }
   static FAIR_VALUE_GAP GetBullishFVG() { return s_bullish_fvg; }
   static FAIR_VALUE_GAP GetBearishFVG() { return s_bearish_fvg; }
   
   //--- Pattern recognition
   static ENUM_CANDLE_PATTERN GetCurrentPattern() { return s_current_candle.pattern; }
   static bool IsBullishPattern(ENUM_CANDLE_PATTERN pattern);
   static bool IsBearishPattern(ENUM_CANDLE_PATTERN pattern);
   
   //--- Key levels
   static double GetNearestResistance(double price);
   static double GetNearestSupport(double price);
   static bool IsNearResistance(double price, double tolerance_atr = 0.5);
   static bool IsNearSupport(double price, double tolerance_atr = 0.5);
   
   //--- Market structure helpers
   static bool IsHigherHigh();
   static bool IsHigherLow();
   static bool IsLowerHigh();
   static bool IsLowerLow();
   static bool IsBreakoutBullish();
   static bool IsBreakoutBearish();
   static bool IsReversalBullish();
   static bool IsReversalBearish();
   
   //--- Candle analysis
   static double GetCandleBodySize(int index);
   static double GetCandleRange(int index);
   static double GetUpperWick(int index);
   static double GetLowerWick(int index);
   static bool IsStrongBullishCandle(int index);
   static bool IsStrongBearishCandle(int index);
   static bool IsDoji(int index, double threshold = 0.1);
   
   //--- Volume analysis (if available)
   static bool IsVolumeIncreasing();
   static bool IsVolumeDecreasing();

private:
   //--- Helper functions
   static bool LoadMarketData();
   static void AnalyzeCandles();
   static void DetectCandlePatterns();
   static void FindSwingPoints();
   static void DetectOrderBlocks();
   static void DetectFairValueGaps();
   static void AnalyzeMarketStructure();
   static void CalculateKeyLevels();
   static CANDLE_INFO AnalyzeCandle(int index);
   static bool IsSwingHigh(int index, int lookback);
   static bool IsSwingLow(int index, int lookback);
   static double CalculateSwingStrength(int index, bool is_high);
  };

//+------------------------------------------------------------------+
//| Static member definitions                                        |
//+------------------------------------------------------------------+
double PriceActionAnalyzer::s_open[];
double PriceActionAnalyzer::s_high[];
double PriceActionAnalyzer::s_low[];
double PriceActionAnalyzer::s_close[];
datetime PriceActionAnalyzer::s_time[];
int PriceActionAnalyzer::s_bars_loaded = 0;

MARKET_STRUCTURE PriceActionAnalyzer::s_market_structure;
CANDLE_INFO PriceActionAnalyzer::s_current_candle;
CANDLE_INFO PriceActionAnalyzer::s_prev_candle;
CANDLE_INFO PriceActionAnalyzer::s_prev2_candle;

SWING_POINT PriceActionAnalyzer::s_swings_high[];
SWING_POINT PriceActionAnalyzer::s_swings_low[];
int PriceActionAnalyzer::s_swing_count_high = 0;
int PriceActionAnalyzer::s_swing_count_low = 0;

ORDER_BLOCK PriceActionAnalyzer::s_bullish_ob;
ORDER_BLOCK PriceActionAnalyzer::s_bearish_ob;
bool PriceActionAnalyzer::s_has_bullish_ob = false;
bool PriceActionAnalyzer::s_has_bearish_ob = false;

FAIR_VALUE_GAP PriceActionAnalyzer::s_bullish_fvg;
FAIR_VALUE_GAP PriceActionAnalyzer::s_bearish_fvg;
bool PriceActionAnalyzer::s_has_bullish_fvg = false;
bool PriceActionAnalyzer::s_has_bearish_fvg = false;

double PriceActionAnalyzer::s_resistance_levels[];
double PriceActionAnalyzer::s_support_levels[];
int PriceActionAnalyzer::s_resistance_count = 0;
int PriceActionAnalyzer::s_support_count = 0;

bool PriceActionAnalyzer::s_initialized = false;
int PriceActionAnalyzer::s_lookback_period = 50;

//+------------------------------------------------------------------+
//| Initialize Price Action Analyzer                                 |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::Initialize()
  {
   s_lookback_period = Config::GetSwingLookback();
   
   //--- Load initial market data
   if(!LoadMarketData())
     {
      Print("PriceActionAnalyzer: Failed to load market data");
      return false;
     }
   
   //--- Perform initial analysis
   AnalyzeCandles();
   FindSwingPoints();
   
   if(Config::GetUseOrderBlocks())
     {
      DetectOrderBlocks();
     }
   
   if(Config::GetUseFairValueGaps())
     {
      DetectFairValueGaps();
     }
   
   AnalyzeMarketStructure();
   CalculateKeyLevels();
   
   s_initialized = true;
   Print("PriceActionAnalyzer: Initialized successfully");
   Print("PriceActionAnalyzer: Structure: ", EnumToString(s_market_structure.structure_type),
         " | Swing H: ", s_market_structure.last_swing_high,
         " | Swing L: ", s_market_structure.last_swing_low);
   
   return true;
  }

//+------------------------------------------------------------------+
//| Load Market Data                                                 |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::LoadMarketData()
  {
   int required_bars = s_lookback_period + 10;
   
   ArrayResize(s_open, required_bars);
   ArrayResize(s_high, required_bars);
   ArrayResize(s_low, required_bars);
   ArrayResize(s_close, required_bars);
   ArrayResize(s_time, required_bars);
   
   int copied = CopyRates(_Symbol, PERIOD_M1, 0, required_bars, s_time, s_open, s_high, s_low, s_close, NULL);
   
   if(copied <= 0)
     {
      Print("PriceActionAnalyzer: Failed to copy rates. Error: ", GetLastError());
      return false;
     }
   
   s_bars_loaded = copied;
   
   //--- Reverse arrays so index 0 = current bar (standard MT5 behavior)
   //--- CopyRates already returns data with index 0 = current bar
   
   return true;
  }

//+------------------------------------------------------------------+
//| Update Analysis                                                  |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::Update()
  {
   if(!s_initialized)
     {
      return false;
     }
   
   //--- Reload latest data
   if(!LoadMarketData())
     {
      return false;
     }
   
   //--- Re-analyze
   AnalyzeCandles();
   FindSwingPoints();
   
   if(Config::GetUseOrderBlocks())
     {
      DetectOrderBlocks();
     }
   
   if(Config::GetUseFairValueGaps())
     {
      DetectFairValueGaps();
     }
   
   AnalyzeMarketStructure();
   CalculateKeyLevels();
   
   return true;
  }

//+------------------------------------------------------------------+
//| Analyze Candles                                                  |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::AnalyzeCandles()
  {
   if(s_bars_loaded < 3) return;
   
   s_current_candle = AnalyzeCandle(0);
   s_prev_candle = AnalyzeCandle(1);
   s_prev2_candle = AnalyzeCandle(2);
   
   DetectCandlePatterns();
  }

//+------------------------------------------------------------------+
//| Analyze Single Candle                                            |
//+------------------------------------------------------------------+
CANDLE_INFO PriceActionAnalyzer::AnalyzeCandle(int index)
  {
   CANDLE_INFO candle;
   
   if(index >= s_bars_loaded)
     {
      ZeroMemory(candle);
      return candle;
     }
   
   candle.open = s_open[index];
   candle.high = s_high[index];
   candle.low = s_low[index];
   candle.close = s_close[index];
   
   candle.body_size = MathAbs(candle.close - candle.open);
   candle.range = candle.high - candle.low;
   
   if(candle.range > 0)
     {
      candle.upper_wick = candle.high - MathMax(candle.open, candle.close);
      candle.lower_wick = MathMin(candle.open, candle.close) - candle.low;
     }
   else
     {
      candle.upper_wick = 0;
      candle.lower_wick = 0;
     }
   
   candle.is_bullish = candle.close > candle.open;
   candle.is_bearish = candle.close < candle.open;
   candle.is_doji = (candle.range > 0) && (candle.body_size / candle.range < 0.1);
   
   candle.pattern = PATTERN_NONE;
   
   return candle;
  }

//+------------------------------------------------------------------+
//| Detect Candle Patterns                                           |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::DetectCandlePatterns()
  {
   //--- Current candle patterns
   CANDLE_INFO c0 = s_current_candle;
   CANDLE_INFO c1 = s_prev_candle;
   CANDLE_INFO c2 = s_prev2_candle;
   
   double atr = IndicatorsManager::GetATR14();
   double min_body = atr * 0.3; // Minimum body size for significant patterns
   
   //--- Pin Bar / Hammer / Shooting Star
   if(c0.range > 0)
     {
      double body_ratio = c0.body_size / c0.range;
      double upper_wick_ratio = c0.upper_wick / c0.range;
      double lower_wick_ratio = c0.lower_wick / c0.range;
      
      //--- Bullish Pin Bar / Hammer
      if(c0.is_bullish && lower_wick_ratio > 0.6 && upper_wick_ratio < 0.2 && body_ratio < 0.3)
        {
         s_current_candle.pattern = PATTERN_PIN_BAR_BULL;
        }
      //--- Bearish Pin Bar / Shooting Star
      else if(c0.is_bearish && upper_wick_ratio > 0.6 && lower_wick_ratio < 0.2 && body_ratio < 0.3)
        {
         s_current_candle.pattern = PATTERN_PIN_BAR_BEAR;
        }
      //--- Doji
      else if(c0.is_doji)
        {
         s_current_candle.pattern = PATTERN_DOJI;
        }
     }
   
   //--- Engulfing Patterns (need previous candle)
   if(s_bars_loaded >= 2)
     {
      //--- Bullish Engulfing
      if(c1.is_bearish && c0.is_bullish &&
         c0.open < c1.close && c0.close > c1.open &&
         c0.body_size > c1.body_size * 1.1)
        {
         s_current_candle.pattern = PATTERN_ENGULFING_BULL;
        }
      //--- Bearish Engulfing
      else if(c1.is_bullish && c0.is_bearish &&
              c0.open > c1.close && c0.close < c1.open &&
              c0.body_size > c1.body_size * 1.1)
        {
         s_current_candle.pattern = PATTERN_ENGULFING_BEAR;
        }
      //--- Inside Bar
      else if(c0.high <= c1.high && c0.low >= c1.low)
        {
         s_current_candle.pattern = PATTERN_INSIDE_BAR;
        }
      //--- Outside Bar
      else if(c0.high >= c1.high && c0.low <= c1.low && c0.body_size > c1.body_size)
        {
         s_current_candle.pattern = PATTERN_OUTSIDE_BAR;
        }
     }
   
   //--- Three Candle Patterns
   if(s_bars_loaded >= 3)
     {
      //--- Morning Star
      if(c2.is_bearish && c2.body_size > min_body &&
         c1.body_size < c2.body_size * 0.3 &&  // Small middle candle (doji/spinning top)
         c0.is_bullish && c0.body_size > min_body &&
         c0.close > (c2.open + c2.close) / 2)  // Close above midpoint of first candle
        {
         s_current_candle.pattern = PATTERN_MORNING_STAR;
        }
      //--- Evening Star
      else if(c2.is_bullish && c2.body_size > min_body &&
              c1.body_size < c2.body_size * 0.3 &&
              c0.is_bearish && c0.body_size > min_body &&
              c0.close < (c2.open + c2.close) / 2)
        {
         s_current_candle.pattern = PATTERN_EVENING_STAR;
        }
      //--- Three White Soldiers
      else if(c2.is_bullish && c1.is_bullish && c0.is_bullish &&
              c1.close > c2.close && c0.close > c1.close &&
              c1.open > c2.open && c1.open < c2.close &&
              c0.open > c1.open && c0.open < c1.close)
        {
         s_current_candle.pattern = PATTERN_THREE_WHITE_SOLDIERS;
        }
      //--- Three Black Crows
      else if(c2.is_bearish && c1.is_bearish && c0.is_bearish &&
              c1.close < c2.close && c0.close < c1.close &&
              c1.open < c2.open && c1.open > c2.close &&
              c0.open < c1.open && c0.open > c1.close)
        {
         s_current_candle.pattern = PATTERN_THREE_BLACK_CROWS;
        }
     }
  }

//+------------------------------------------------------------------+
//| Find Swing Points                                                |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::FindSwingPoints()
  {
   int lookback = 5; // 5 bars on each side for swing detection
   int min_swing_bars = 3; // Minimum bars between swings
   
   ArrayResize(s_swings_high, s_bars_loaded);
   ArrayResize(s_swings_low, s_bars_loaded);
   
   s_swing_count_high = 0;
   s_swing_count_low = 0;
   
   double last_swing_high_price = 0;
   double last_swing_low_price = 0;
   int last_swing_high_index = -min_swing_bars;
   int last_swing_low_index = -min_swing_bars;
   
   for(int i = lookback; i < s_bars_loaded - lookback; i++)
     {
      //--- Check for Swing High
      if(IsSwingHigh(i, lookback))
        {
         //--- Filter: minimum distance from last swing high
         if(i - last_swing_high_index >= min_swing_bars)
           {
            double strength = CalculateSwingStrength(i, true);
            if(strength > 0.5) // Minimum strength threshold
              {
               s_swings_high[s_swing_count_high].price = s_high[i];
               s_swings_high[s_swing_count_high].index = i;
               s_swings_high[s_swing_count_high].time = s_time[i];
               s_swings_high[s_swing_count_high].is_high = true;
               s_swings_high[s_swing_count_high].is_confirmed = (i > 2); // Confirmed if not current/recent
               
               last_swing_high_price = s_high[i];
               last_swing_high_index = i;
               s_swing_count_high++;
              }
           }
        }
      
      //--- Check for Swing Low
      if(IsSwingLow(i, lookback))
        {
         if(i - last_swing_low_index >= min_swing_bars)
           {
            double strength = CalculateSwingStrength(i, false);
            if(strength > 0.5)
              {
               s_swings_low[s_swing_count_low].price = s_low[i];
               s_swings_low[s_swing_count_low].index = i;
               s_swings_low[s_swing_count_low].time = s_time[i];
               s_swings_low[s_swing_count_low].is_high = false;
               s_swings_low[s_swing_count_low].is_confirmed = (i > 2);
               
               last_swing_low_price = s_low[i];
               last_swing_low_index = i;
               s_swing_count_low++;
              }
           }
        }
     }
   
   //--- Update market structure with latest swings
   if(s_swing_count_high > 0)
     {
      s_market_structure.last_swing_high = s_swings_high[0].price;
      s_market_structure.candles_since_swing_high = s_swings_high[0].index;
     }
   
   if(s_swing_count_low > 0)
     {
      s_market_structure.last_swing_low = s_swings_low[0].price;
      s_market_structure.candles_since_swing_low = s_swings_low[0].index;
     }
   
   if(s_swing_count_high > 1)
     {
      s_market_structure.previous_swing_high = s_swings_high[1].price;
     }
   
   if(s_swing_count_low > 1)
     {
      s_market_structure.previous_swing_low = s_swings_low[1].price;
     }
  }

//+------------------------------------------------------------------+
//| Check Swing High                                                 |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::IsSwingHigh(int index, int lookback)
  {
   if(index < lookback || index >= s_bars_loaded - lookback)
     {
      return false;
     }
   
   double high = s_high[index];
   
   for(int i = 1; i <= lookback; i++)
     {
      if(s_high[index - i] >= high || s_high[index + i] >= high)
        {
         return false;
        }
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Check Swing Low                                                  |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::IsSwingLow(int index, int lookback)
  {
   if(index < lookback || index >= s_bars_loaded - lookback)
     {
      return false;
     }
   
   double low = s_low[index];
   
   for(int i = 1; i <= lookback; i++)
     {
      if(s_low[index - i] <= low || s_low[index + i] <= low)
        {
         return false;
        }
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Calculate Swing Strength                                         |
//+------------------------------------------------------------------+
double PriceActionAnalyzer::CalculateSwingStrength(int index, bool is_high)
  {
   double atr = IndicatorsManager::GetATR14();
   if(atr == 0) return 0;
   
   int lookback = 10;
   int start = MathMax(0, index - lookback);
   int end = MathMin(s_bars_loaded - 1, index + lookback);
   
   int touches = 0;
   double level = is_high ? s_high[index] : s_low[index];
   double tolerance = atr * 0.2;
   
   for(int i = start; i <= end; i++)
     {
      if(i == index) continue;
      
      double price = is_high ? s_high[i] : s_low[i];
      if(MathAbs(price - level) <= tolerance)
        {
         touches++;
        }
     }
   
   //--- Strength based on touches and clarity
   double strength = MathMin(1.0, touches / 5.0);
   
   //--- Bonus for clean swings (no overlap)
   bool clean = true;
   for(int i = 1; i <= 3; i++)
     {
      if(index - i >= 0 && index + i < s_bars_loaded)
        {
         if(is_high)
           {
            if(s_high[index - i] > level || s_high[index + i] > level) clean = false;
           }
         else
           {
            if(s_low[index - i] < level || s_low[index + i] < level) clean = false;
           }
        }
     }
   
   if(clean) strength += 0.2;
   
   return MathMin(1.0, strength);
  }

//+------------------------------------------------------------------+
//| Detect Order Blocks                                              |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::DetectOrderBlocks()
  {
   //--- Bullish Order Block: Last bearish candle before a strong bullish move
   //--- Bearish Order Block: Last bullish candle before a strong bearish move
   
   double atr = IndicatorsManager::GetATR14();
   double min_move = atr * 1.5;
   
   s_has_bullish_ob = false;
   s_has_bearish_ob = false;
   
   //--- Look for bullish OB (last down candle before up move)
   for(int i = 1; i < MathMin(20, s_bars_loaded); i++)
     {
      CANDLE_INFO c = AnalyzeCandle(i);
      CANDLE_INFO c_next = AnalyzeCandle(i - 1);
      
      //--- Check if current is bearish and next few are strongly bullish
      if(c.is_bearish && c.body_size > atr * 0.3)
        {
         //--- Check next 3 candles for strong bullish move
         double move_up = 0;
         int bullish_count = 0;
         
         for(int j = 1; j <= 3 && (i - j) >= 0; j++)
           {
            CANDLE_INFO cn = AnalyzeCandle(i - j);
            if(cn.is_bullish) bullish_count++;
            move_up += cn.close - cn.open;
           }
         
         if(bullish_count >= 2 && move_up > min_move)
           {
            s_bullish_ob.type = OB_BULLISH;
            s_bullish_ob.price_top = c.high;
            s_bullish_ob.price_bottom = c.low;
            s_bullish_ob.open_price = c.open;
            s_bullish_ob.close_price = c.close;
            s_bullish_ob.time = s_time[i];
            s_bullish_ob.is_tested = false;
            s_bullish_ob.is_valid = true;
            s_bullish_ob.strength = (int)MathMin(10, bullish_count * 3 + move_up / atr);
            
            s_has_bullish_ob = true;
            
            //--- Check if OB has been tested
            double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            if(current_price <= s_bullish_ob.price_top && current_price >= s_bullish_ob.price_bottom)
              {
               s_bullish_ob.is_tested = true;
              }
            
            break; // Take the most recent valid OB
           }
        }
     }
   
   //--- Look for bearish OB (last up candle before down move)
   for(int i = 1; i < MathMin(20, s_bars_loaded); i++)
     {
      CANDLE_INFO c = AnalyzeCandle(i);
      CANDLE_INFO c_next = AnalyzeCandle(i - 1);
      
      if(c.is_bullish && c.body_size > atr * 0.3)
        {
         double move_down = 0;
         int bearish_count = 0;
         
         for(int j = 1; j <= 3 && (i - j) >= 0; j++)
           {
            CANDLE_INFO cn = AnalyzeCandle(i - j);
            if(cn.is_bearish) bearish_count++;
            move_down += cn.open - cn.close;
           }
         
         if(bearish_count >= 2 && move_down > min_move)
           {
            s_bearish_ob.type = OB_BEARISH;
            s_bearish_ob.price_top = c.high;
            s_bearish_ob.price_bottom = c.low;
            s_bearish_ob.open_price = c.open;
            s_bearish_ob.close_price = c.close;
            s_bearish_ob.time = s_time[i];
            s_bearish_ob.is_tested = false;
            s_bearish_ob.is_valid = true;
            s_bearish_ob.strength = (int)MathMin(10, bearish_count * 3 + move_down / atr);
            
            s_has_bearish_ob = true;
            
            double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            if(current_price >= s_bearish_ob.price_bottom && current_price <= s_bearish_ob.price_top)
              {
               s_bearish_ob.is_tested = true;
              }
            
            break;
           }
        }
     }
   
   //--- Update market structure
   s_market_structure.bullish_order_block_price = s_has_bullish_ob ? s_bullish_ob.price_bottom : 0;
   s_market_structure.bearish_order_block_price = s_has_bearish_ob ? s_bearish_ob.price_top : 0;
   s_market_structure.has_bullish_ob = s_has_bullish_ob;
   s_market_structure.has_bearish_ob = s_has_bearish_ob;
  }

//+------------------------------------------------------------------+
//| Detect Fair Value Gaps                                           |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::DetectFairValueGaps()
  {
   //--- FVG: Gap between candle 1 high/low and candle 3 high/low
   //--- Bullish FVG: Candle 1 low > Candle 3 high (gap up)
   //--- Bearish FVG: Candle 1 high < Candle 3 low (gap down)
   
   s_has_bullish_fvg = false;
   s_has_bearish_fvg = false;
   
   for(int i = 2; i < MathMin(30, s_bars_loaded); i++)
     {
      //--- Bullish FVG
      if(s_low[i - 2] > s_high[i]) // Gap between candle i (3 bars ago) low and candle i-2 (current) high
        {
         double gap_size = s_low[i - 2] - s_high[i];
         double atr = IndicatorsManager::GetATR14();
         
         if(gap_size > atr * 0.2) // Minimum gap size
           {
            s_bullish_fvg.type = FVG_BULLISH;
            s_bullish_fvg.top_price = s_low[i - 2];
            s_bullish_fvg.bottom_price = s_high[i];
            s_bullish_fvg.time = s_time[i - 1]; // Middle candle time
            s_bullish_fvg.is_filled = false;
            s_bullish_fvg.is_valid = true;
            
            //--- Check if filled
            double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            if(current_price <= s_bullish_fvg.bottom_price)
              {
               s_bullish_fvg.is_filled = true;
              }
            
            s_has_bullish_fvg = true;
            break;
           }
        }
      
      //--- Bearish FVG
      if(s_high[i - 2] < s_low[i]) // Gap down
        {
         double gap_size = s_low[i] - s_high[i - 2];
         double atr = IndicatorsManager::GetATR14();
         
         if(gap_size > atr * 0.2)
           {
            s_bearish_fvg.type = FVG_BEARISH;
            s_bearish_fvg.top_price = s_low[i];
            s_bearish_fvg.bottom_price = s_high[i - 2];
            s_bearish_fvg.time = s_time[i - 1];
            s_bearish_fvg.is_filled = false;
            s_bearish_fvg.is_valid = true;
            
            double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            if(current_price >= s_bearish_fvg.top_price)
              {
               s_bearish_fvg.is_filled = true;
              }
            
            s_has_bearish_fvg = true;
            break;
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Analyze Market Structure                                         |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::AnalyzeMarketStructure()
  {
   //--- Default
   s_market_structure.structure_type = STRUCTURE_UNKNOWN;
   s_market_structure.is_breakout = false;
   s_market_structure.is_reversal = false;
   s_market_structure.trend_strength = 0;
   
   if(s_swing_count_high < 2 || s_swing_count_low < 2)
     {
      return;
     }
   
   double hh = s_market_structure.last_swing_high;
   double hl = s_market_structure.last_swing_low;
   double phh = s_market_structure.previous_swing_high;
   double phl = s_market_structure.previous_swing_low;
   
   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = IndicatorsManager::GetATR14();
   
   //--- Check for Uptrend: Higher Highs and Higher Lows
   bool higher_high = hh > phh;
   bool higher_low = hl > phl;
   
   //--- Check for Downtrend: Lower Highs and Lower Lows
   bool lower_high = hh < phh;
   bool lower_low = hl < phl;
   
   //--- Determine structure type
   if(higher_high && higher_low)
     {
      s_market_structure.structure_type = STRUCTURE_UPTREND;
      s_market_structure.trend_strength = 70;
      
      //--- Check for bullish breakout
      if(current_price > hh + atr * 0.2)
        {
         s_market_structure.structure_type = STRUCTURE_BREAKOUT_BULL;
         s_market_structure.is_breakout = true;
         s_market_structure.trend_strength = 85;
        }
     }
   else if(lower_high && lower_low)
     {
      s_market_structure.structure_type = STRUCTURE_DOWNTREND;
      s_market_structure.trend_strength = 70;
      
      //--- Check for bearish breakout
      if(current_price < hl - atr * 0.2)
        {
         s_market_structure.structure_type = STRUCTURE_BREAKOUT_BEAR;
         s_market_structure.is_breakout = true;
         s_market_structure.trend_strength = 85;
        }
     }
   else if((higher_high && lower_low) || (lower_high && higher_low))
     {
      //--- Expanding triangle / volatile
      s_market_structure.structure_type = STRUCTURE_RANGING;
      s_market_structure.trend_strength = 30;
     }
   else
     {
      //--- Check for ranging
      double range_size = hh - hl;
      if(range_size < atr * 3)
        {
         s_market_structure.structure_type = STRUCTURE_RANGING;
         s_market_structure.trend_strength = 20;
        }
      else
        {
         s_market_structure.structure_type = STRUCTURE_RANGING;
         s_market_structure.trend_strength = 40;
        }
     }
   
   //--- Check for Reversals
   //--- Bullish Reversal: Downtrend + Break of Lower High + Higher Low forming
   if(s_market_structure.structure_type == STRUCTURE_DOWNTREND)
     {
      //--- Price breaks above recent lower high
      if(current_price > hh && hl > phl)
        {
         s_market_structure.structure_type = STRUCTURE_REVERSAL_BULL;
         s_market_structure.is_reversal = true;
         s_market_structure.trend_strength = 60;
        }
     }
   
   //--- Bearish Reversal: Uptrend + Break of Higher Low + Lower High forming
   if(s_market_structure.structure_type == STRUCTURE_UPTREND)
     {
      if(current_price < hl && hh < phh)
        {
         s_market_structure.structure_type = STRUCTURE_REVERSAL_BEAR;
         s_market_structure.is_reversal = true;
         s_market_structure.trend_strength = 60;
        }
     }
  }

//+------------------------------------------------------------------+
//| Calculate Key Levels                                             |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::CalculateKeyLevels()
  {
   //--- Resistance: Swing highs
   //--- Support: Swing lows
   
   ArrayResize(s_resistance_levels, s_swing_count_high);
   ArrayResize(s_support_levels, s_swing_count_low);
   
   s_resistance_count = 0;
   s_support_count = 0;
   
   //--- Collect resistance levels (swing highs)
   for(int i = 0; i < s_swing_count_high; i++)
     {
      if(s_swings_high[i].is_confirmed)
        {
         s_resistance_levels[s_resistance_count] = s_swings_high[i].price;
         s_resistance_count++;
        }
     }
   
   //--- Collect support levels (swing lows)
   for(int i = 0; i < s_swing_count_low; i++)
     {
      if(s_swings_low[i].is_confirmed)
        {
         s_support_levels[s_support_count] = s_swings_low[i].price;
         s_support_count++;
        }
     }
   
   //--- Add order block levels
   if(s_has_bullish_ob)
     {
      //--- Bullish OB acts as support
      if(s_support_count < 20)
        {
         s_support_levels[s_support_count] = s_bullish_ob.price_bottom;
         s_support_count++;
        }
     }
   
   if(s_has_bearish_ob)
     {
      //--- Bearish OB acts as resistance
      if(s_resistance_count < 20)
        {
         s_resistance_levels[s_resistance_count] = s_bearish_ob.price_top;
         s_resistance_count++;
        }
     }
  }

//+------------------------------------------------------------------+
//| Get Nearest Resistance                                           |
//+------------------------------------------------------------------+
double PriceActionAnalyzer::GetNearestResistance(double price)
  {
   double nearest = 0;
   double min_dist = DBL_MAX;
   
   for(int i = 0; i < s_resistance_count; i++)
     {
      double level = s_resistance_levels[i];
      if(level > price)
        {
         double dist = level - price;
         if(dist < min_dist)
           {
            min_dist = dist;
            nearest = level;
           }
        }
     }
   
   return nearest;
  }

//+------------------------------------------------------------------+
//| Get Nearest Support                                              |
//+------------------------------------------------------------------+
double PriceActionAnalyzer::GetNearestSupport(double price)
  {
   double nearest = 0;
   double min_dist = DBL_MAX;
   
   for(int i = 0; i < s_support_count; i++)
     {
      double level = s_support_levels[i];
      if(level < price)
        {
         double dist = price - level;
         if(dist < min_dist)
           {
            min_dist = dist;
            nearest = level;
           }
        }
     }
   
   return nearest;
  }

//+------------------------------------------------------------------+
//| Is Near Resistance                                               |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::IsNearResistance(double price, double tolerance_atr)
  {
   double atr = IndicatorsManager::GetATR14();
   if(atr == 0) return false;
   
   double tolerance = atr * tolerance_atr;
   
   for(int i = 0; i < s_resistance_count; i++)
     {
      if(MathAbs(s_resistance_levels[i] - price) <= tolerance)
        {
         return true;
        }
     }
   
   return false;
  }

//+------------------------------------------------------------------+
//| Is Near Support                                                  |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::IsNearSupport(double price, double tolerance_atr)
  {
   double atr = IndicatorsManager::GetATR14();
   if(atr == 0) return false;
   
   double tolerance = atr * tolerance_atr;
   
   for(int i = 0; i < s_support_count; i++)
     {
      if(MathAbs(s_support_levels[i] - price) <= tolerance)
        {
         return true;
        }
     }
   
   return false;
  }

//+------------------------------------------------------------------+
//| Market Structure Helpers                                         |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::IsHigherHigh()
  {
   return s_market_structure.last_swing_high > s_market_structure.previous_swing_high;
  }

bool PriceActionAnalyzer::IsHigherLow()
  {
   return s_market_structure.last_swing_low > s_market_structure.previous_swing_low;
  }

bool PriceActionAnalyzer::IsLowerHigh()
  {
   return s_market_structure.last_swing_high < s_market_structure.previous_swing_high;
  }

bool PriceActionAnalyzer::IsLowerLow()
  {
   return s_market_structure.last_swing_low < s_market_structure.previous_swing_low;
  }

bool PriceActionAnalyzer::IsBreakoutBullish()
  {
   return s_market_structure.structure_type == STRUCTURE_BREAKOUT_BULL;
  }

bool PriceActionAnalyzer::IsBreakoutBearish()
  {
   return s_market_structure.structure_type == STRUCTURE_BREAKOUT_BEAR;
  }

bool PriceActionAnalyzer::IsReversalBullish()
  {
   return s_market_structure.structure_type == STRUCTURE_REVERSAL_BULL;
  }

bool PriceActionAnalyzer::IsReversalBearish()
  {
   return s_market_structure.structure_type == STRUCTURE_REVERSAL_BEAR;
  }

//+------------------------------------------------------------------+
//| Candle Analysis Helpers                                          |
//+------------------------------------------------------------------+
double PriceActionAnalyzer::GetCandleBodySize(int index)
  {
   if(index >= 0 && index < s_bars_loaded)
     {
      return MathAbs(s_close[index] - s_open[index]);
     }
   return 0;
  }

double PriceActionAnalyzer::GetCandleRange(int index)
  {
   if(index >= 0 && index < s_bars_loaded)
     {
      return s_high[index] - s_low[index];
     }
   return 0;
  }

double PriceActionAnalyzer::GetUpperWick(int index)
  {
   if(index >= 0 && index < s_bars_loaded)
     {
      return s_high[index] - MathMax(s_open[index], s_close[index]);
     }
   return 0;
  }

double PriceActionAnalyzer::GetLowerWick(int index)
  {
   if(index >= 0 && index < s_bars_loaded)
     {
      return MathMin(s_open[index], s_close[index]) - s_low[index];
     }
   return 0;
  }

bool PriceActionAnalyzer::IsStrongBullishCandle(int index)
  {
   if(index >= 0 && index < s_bars_loaded)
     {
      double body = GetCandleBodySize(index);
      double range = GetCandleRange(index);
      double atr = IndicatorsManager::GetATR14();
      
      return (s_close[index] > s_open[index]) && 
             (body > atr * 0.5) && 
             (body / range > 0.6);
     }
   return false;
  }

bool PriceActionAnalyzer::IsStrongBearishCandle(int index)
  {
   if(index >= 0 && index < s_bars_loaded)
     {
      double body = GetCandleBodySize(index);
      double range = GetCandleRange(index);
      double atr = IndicatorsManager::GetATR14();
      
      return (s_close[index] < s_open[index]) && 
             (body > atr * 0.5) && 
             (body / range > 0.6);
     }
   return false;
  }

bool PriceActionAnalyzer::IsDoji(int index, double threshold)
  {
   if(index >= 0 && index < s_bars_loaded)
     {
      double body = GetCandleBodySize(index);
      double range = GetCandleRange(index);
      
      return (range > 0) && (body / range < threshold);
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Volume Analysis                                                  |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::IsVolumeIncreasing()
  {
   long vol[];
   if(CopyRealVolume(_Symbol, PERIOD_M1, 0, 3, vol) > 0)
     {
      return vol[0] > vol[1] && vol[1] > vol[2];
     }
   return false;
  }

bool PriceActionAnalyzer::IsVolumeDecreasing()
  {
   long vol[];
   if(CopyRealVolume(_Symbol, PERIOD_M1, 0, 3, vol) > 0)
     {
      return vol[0] < vol[1] && vol[1] < vol[2];
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Pattern Type Helpers                                             |
//+------------------------------------------------------------------+
bool PriceActionAnalyzer::IsBullishPattern(ENUM_CANDLE_PATTERN pattern)
  {
   switch(pattern)
     {
      case PATTERN_PIN_BAR_BULL:
      case PATTERN_ENGULFING_BULL:
      case PATTERN_HAMMER:
      case PATTERN_MORNING_STAR:
      case PATTERN_THREE_WHITE_SOLDIERS:
         return true;
     }
   return false;
  }

bool PriceActionAnalyzer::IsBearishPattern(ENUM_CANDLE_PATTERN pattern)
  {
   switch(pattern)
     {
      case PATTERN_PIN_BAR_BEAR:
      case PATTERN_ENGULFING_BEAR:
      case PATTERN_SHOOTING_STAR:
      case PATTERN_EVENING_STAR:
      case PATTERN_THREE_BLACK_CROWS:
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void PriceActionAnalyzer::Cleanup()
  {
   ArrayFree(s_open);
   ArrayFree(s_high);
   ArrayFree(s_low);
   ArrayFree(s_close);
   ArrayFree(s_time);
   
   ArrayFree(s_swings_high);
   ArrayFree(s_swings_low);
   
   ArrayFree(s_resistance_levels);
   ArrayFree(s_support_levels);
   
   s_initialized = false;
   Print("PriceActionAnalyzer: Cleaned up");
  }
//+------------------------------------------------------------------+