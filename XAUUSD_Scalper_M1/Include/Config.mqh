//+------------------------------------------------------------------+
//|                                              Config.mqh          |
//|                    Configuration and Input Parameters            |
//+------------------------------------------------------------------+
#property strict

//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_TREND_DIRECTION
  {
   TREND_UNKNOWN = 0,
   TREND_BULLISH = 1,
   TREND_BEARISH = 2,
   TREND_NEUTRAL = 3
  };

enum ENUM_MARKET_STRUCTURE_TYPE
  {
   STRUCTURE_UNKNOWN = 0,
   STRUCTURE_UPTREND = 1,        // Higher highs, higher lows
   STRUCTURE_DOWNTREND = 2,      // Lower highs, lower lows
   STRUCTURE_RANGING = 3,        // Sideways
   STRUCTURE_BREAKOUT_BULL = 4,  // Bullish breakout
   STRUCTURE_BREAKOUT_BEAR = 5,  // Bearish breakout
   STRUCTURE_REVERSAL_BULL = 6,  // Bullish reversal
   STRUCTURE_REVERSAL_BEAR = 7   // Bearish reversal
  };

enum ENUM_ENTRY_TYPE
  {
   ENTRY_NONE = 0,
   ENTRY_BUY = 1,
   ENTRY_SELL = 2
  };

enum ENUM_SIGNAL_STRENGTH
  {
   SIGNAL_WEAK = 1,
   SIGNAL_MODERATE = 2,
   SIGNAL_STRONG = 3,
   SIGNAL_VERY_STRONG = 4
  };

enum ENUM_RISK_METHOD
  {
   RISK_FIXED_LOT = 0,        // Fixed lot size
   RISK_PERCENT_EQUITY = 1,   // Percentage of equity
   RISK_PERCENT_BALANCE = 2,  // Percentage of balance
   RISK_KELLY = 3,            // Kelly criterion
   RISK_ATR_BASED = 4         // ATR-based position sizing
  };

enum ENUM_TRAILING_METHOD
  {
   TRAIL_NONE = 0,
   TRAIL_ATR = 1,             // ATR-based trailing
   TRAIL_POINTS = 2,          // Fixed points trailing
   TRAIL_MA = 3,              // Moving average trailing
   TRAIL_STRUCTURE = 4        // Market structure trailing
  };

enum ENUM_SESSION_FILTER
  {
   SESSION_ALL = 0,
   SESSION_LONDON = 1,
   SESSION_NEWYORK = 2,
   SESSION_LONDON_NY = 3,     // London + New York overlap
   SESSION_ASIAN = 4,
   SESSION_CUSTOM = 5
  };

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
struct ENTRY_SIGNAL
  {
   ENUM_ENTRY_TYPE      type;
   ENUM_SIGNAL_STRENGTH strength;
   double               entry_price;
   double               stop_loss;
   double               take_profit;
   double               atr_value;
   double               risk_reward_ratio;
   string               comment;
   datetime             signal_time;
   bool                 is_valid;
  };

struct MARKET_STRUCTURE
  {
   ENUM_MARKET_STRUCTURE_TYPE structure_type;
   double                     last_swing_high;
   double                     last_swing_low;
   double                     previous_swing_high;
   double                     previous_swing_low;
   double                     bullish_order_block_price;
   double                     bearish_order_block_price;
   bool                       has_bullish_ob;
   bool                       has_bearish_ob;
   bool                       is_breakout;
   bool                       is_reversal;
   int                        candles_since_swing_high;
   int                        candles_since_swing_low;
   double                     trend_strength;  // 0-100
  };

struct RISK_PARAMS
  {
   double     risk_percent;
   double     max_daily_loss_percent;
   double     max_account_drawdown_percent;
   int        max_open_positions;
   double     min_risk_reward_ratio;
   double     max_spread_points;
   ENUM_RISK_METHOD risk_method;
   double     fixed_lot_size;
   double     atr_multiplier_sl;
   double     atr_multiplier_tp;
   bool       use_break_even;
   double     break_even_trigger_atr;
   double     break_even_offset_atr;
   bool       use_trailing_stop;
   ENUM_TRAILING_METHOD trailing_method;
   double     trailing_atr_multiplier;
   int        trailing_points;
   int        trailing_ma_period;
  };

struct TRADING_SESSION
  {
   ENUM_SESSION_FILTER session_filter;
   int    london_open_hour;
   int    london_close_hour;
   int    ny_open_hour;
   int    ny_close_hour;
   int    asian_open_hour;
   int    asian_close_hour;
   bool   avoid_news_high_impact;
   bool   avoid_news_medium_impact;
   int    minutes_before_news;
   int    minutes_after_news;
  };

//+------------------------------------------------------------------+
//| Config Class                                                     |
//+------------------------------------------------------------------+
class Config
  {
private:
   //--- General Settings
   static bool              s_enabled;
   static string            s_ea_name;
   static int               s_magic_number;
   static bool              s_show_dashboard;
   
   //--- Risk Management
   static RISK_PARAMS       s_risk_params;
   
   //--- Trading Sessions
   static TRADING_SESSION   s_trading_session;
   
   //--- Indicator Settings
   static int               s_ema50_period;
   static int               s_ema200_period;
   static int               s_rsi_period;
   static int               s_atr_period;
   static ENUM_MA_METHOD    s_ema_method;
   static ENUM_APPLIED_PRICE s_applied_price;
   
   //--- Signal Settings
   static bool              s_require_trend_alignment;
   static bool              s_require_rsi_confirmation;
   static double            s_rsi_overbought;
   static double            s_rsi_oversold;
   static double            s_rsi_neutral_zone;
   static bool              s_require_price_action_confirmation;
   static int               s_swing_lookback;
   static bool              s_use_order_blocks;
   static bool              s_use_fair_value_gaps;
   
   //--- Spread & Volatility
   static double            s_max_spread_points;
   static double            s_min_atr_threshold;
   static double            s_max_atr_threshold;
   
   //--- Position Management
   static bool              s_allow_multiple_entries;
   static int               s_max_entries_per_direction;
   static double            s_min_distance_between_entries_atr;
   static bool              s_allow_hedging;
   
   //--- Time Settings
   static bool              s_use_server_time;
   static int               s_timezone_offset;
   
   //--- Testing & Debug
   static bool              s_debug_mode;
   static bool              s_log_signals;
   static bool              s_log_trades;

public:
   //--- Initialization
   static bool Initialize(const string symbol, const ENUM_TIMEFRAMES timeframe);
   
   //--- General Getters
   static bool GetEnabled() { return s_enabled; }
   static void SetEnabled(bool value) { s_enabled = value; }
   static string GetEAName() { return s_ea_name; }
   static int GetMagicNumber() { return s_magic_number; }
   static bool GetShowDashboard() { return s_show_dashboard; }
   
   //--- Risk Getters
   static double GetRiskPercent() { return s_risk_params.risk_percent; }
   static double GetMaxDailyLossPercent() { return s_risk_params.max_daily_loss_percent; }
   static double GetMaxAccountDrawdownPercent() { return s_risk_params.max_account_drawdown_percent; }
   static int GetMaxOpenPositions() { return s_risk_params.max_open_positions; }
   static double GetMinRiskRewardRatio() { return s_risk_params.min_risk_reward_ratio; }
   static double GetMaxSpreadPoints() { return s_risk_params.max_spread_points; }
   static ENUM_RISK_METHOD GetRiskMethod() { return s_risk_params.risk_method; }
   static double GetFixedLotSize() { return s_risk_params.fixed_lot_size; }
   static double GetATRMultiplierSL() { return s_risk_params.atr_multiplier_sl; }
   static double GetATRMultiplierTP() { return s_risk_params.atr_multiplier_tp; }
   static bool GetUseBreakEven() { return s_risk_params.use_break_even; }
   static double GetBreakEvenTriggerATR() { return s_risk_params.break_even_trigger_atr; }
   static double GetBreakEvenOffsetATR() { return s_risk_params.break_even_offset_atr; }
   static bool GetUseTrailingStop() { return s_risk_params.use_trailing_stop; }
   static ENUM_TRAILING_METHOD GetTrailingMethod() { return s_risk_params.trailing_method; }
   static double GetTrailingATRMultiplier() { return s_risk_params.trailing_atr_multiplier; }
   static int GetTrailingPoints() { return s_risk_params.trailing_points; }
   static int GetTrailingMAPeriod() { return s_risk_params.trailing_ma_period; }
   
   //--- Session Getters
   static ENUM_SESSION_FILTER GetSessionFilter() { return s_trading_session.session_filter; }
   static bool IsTradingTime();
   static bool GetAvoidNewsHighImpact() { return s_trading_session.avoid_news_high_impact; }
   static bool GetAvoidNewsMediumImpact() { return s_trading_session.avoid_news_medium_impact; }
   static int GetMinutesBeforeNews() { return s_trading_session.minutes_before_news; }
   static int GetMinutesAfterNews() { return s_trading_session.minutes_after_news; }
   
   //--- Indicator Getters
   static int GetEMA50Period() { return s_ema50_period; }
   static int GetEMA200Period() { return s_ema200_period; }
   static int GetRSIPeriod() { return s_rsi_period; }
   static int GetATRPeriod() { return s_atr_period; }
   static ENUM_MA_METHOD GetEMAAethod() { return s_ema_method; }
   static ENUM_APPLIED_PRICE GetAppliedPrice() { return s_applied_price; }
   
   //--- Signal Getters
   static bool GetRequireTrendAlignment() { return s_require_trend_alignment; }
   static bool GetRequireRSIConfirmation() { return s_require_rsi_confirmation; }
   static double GetRSIOverbought() { return s_rsi_overbought; }
   static double GetRSIOversold() { return s_rsi_oversold; }
   static double GetRSINeutralZone() { return s_rsi_neutral_zone; }
   static bool GetRequirePriceActionConfirmation() { return s_require_price_action_confirmation; }
   static int GetSwingLookback() { return s_swing_lookback; }
   static bool GetUseOrderBlocks() { return s_use_order_blocks; }
   static bool GetUseFairValueGaps() { return s_use_fair_value_gaps; }
   
   //--- Spread & Volatility Getters
   static double GetMinATRThreshold() { return s_min_atr_threshold; }
   static double GetMaxATRThreshold() { return s_max_atr_threshold; }
   
   //--- Position Management Getters
   static bool GetAllowNewEntries() { return s_allow_multiple_entries; }
   static int GetMaxEntriesPerDirection() { return s_max_entries_per_direction; }
   static double GetMinDistanceBetweenEntriesATR() { return s_min_distance_between_entries_atr; }
   static bool GetAllowHedging() { return s_allow_hedging; }
   
   //--- Debug Getters
   static bool GetDebugMode() { return s_debug_mode; }
   static bool GetLogSignals() { return s_log_signals; }
   static bool GetLogTrades() { return s_log_trades; }
   
   //--- Min Margin Level
   static double GetMinMarginLevel() { return 200.0; } // Minimum 200% margin level
   
   //--- Setters for runtime modification
   static void SetRiskPercent(double value) { s_risk_params.risk_percent = value; }
   static void SetMaxSpreadPoints(double value) { s_risk_params.max_spread_points = value; }
   static void SetMaxOpenPositions(int value) { s_risk_params.max_open_positions = value; }
  };

//+------------------------------------------------------------------+
//| Input Parameters (visible in EA settings)                        |
//+------------------------------------------------------------------+
input group "=== GENERAL SETTINGS ==="
input bool      InpEnabled             = true;        // Enable EA
input string    InpEAName              = "XAUUSD_Scalper_M1"; // EA Name
input int       InpMagicNumber         = 20241125;    // Magic Number
input bool      InpShowDashboard       = true;        // Show Dashboard on Chart

input group "=== RISK MANAGEMENT ==="
input ENUM_RISK_METHOD InpRiskMethod   = RISK_PERCENT_EQUITY; // Risk Calculation Method
input double    InpRiskPercent         = 1.0;         // Risk Per Trade (%)
input double    InpMaxDailyLossPercent = 5.0;         // Max Daily Loss (%)
input double    InpMaxAccountDDPercent = 15.0;        // Max Account Drawdown (%)
input int       InpMaxOpenPositions    = 5;           // Max Open Positions
input double    InpMinRiskReward       = 1.5;         // Minimum Risk:Reward Ratio
input double    InpFixedLotSize        = 0.01;        // Fixed Lot Size (if Fixed Lot method)
input double    InpATRMultiplierSL     = 1.5;         // ATR Multiplier for Stop Loss
input double    InpATRMultiplierTP     = 2.5;         // ATR Multiplier for Take Profit

input group "=== BREAK EVEN & TRAILING ==="
input bool      InpUseBreakEven        = true;        // Use Break Even
input double    InpBETriggerATR        = 1.0;         // BE Trigger (ATR multiplier)
input double    InpBEOffsetATR         = 0.3;         // BE Offset (ATR multiplier)
input bool      InpUseTrailingStop     = true;        // Use Trailing Stop
input ENUM_TRAILING_METHOD InpTrailMethod = TRAIL_ATR; // Trailing Method
input double    InpTrailingATRMult     = 1.0;         // Trailing ATR Multiplier
input int       InpTrailingPoints      = 200;         // Trailing Points (if Points method)
input int       InpTrailingMAPeriod    = 20;          // Trailing MA Period (if MA method)

input group "=== TRADING SESSIONS ==="
input ENUM_SESSION_FILTER InpSessionFilter = SESSION_LONDON_NY; // Trading Session Filter
input int       InpLondonOpenHour      = 8;           // London Open Hour (GMT)
input int       InpLondonCloseHour     = 17;          // London Close Hour (GMT)
input int       InpNYOpenHour          = 13;          // NY Open Hour (GMT)
input int       InpNYCloseHour         = 22;          // NY Close Hour (GMT)
input int       InpAsianOpenHour       = 0;           // Asian Open Hour (GMT)
input int       InpAsianCloseHour      = 9;           // Asian Close Hour (GMT)
input bool      InpAvoidNewsHigh       = true;        // Avoid High Impact News
input bool      InpAvoidNewsMedium     = false;       // Avoid Medium Impact News
input int       InpMinBeforeNews       = 30;          // Minutes Before News
input int       InpMinAfterNews        = 30;          // Minutes After News

input group "=== INDICATOR SETTINGS ==="
input int       InpEMA50Period         = 50;          // EMA 50 Period (M1)
input int       InpEMA200Period        = 200;         // EMA 200 Period (M5)
input int       InpRSIPeriod           = 14;          // RSI Period
input int       InpATRPeriod           = 14;          // ATR Period
input ENUM_MA_METHOD InpEMAAethod      = MODE_EMA;    // MA Method
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Applied Price

input group "=== SIGNAL CONFIRMATION ==="
input bool      InpRequireTrendAlign   = true;        // Require M1+M5 Trend Alignment
input bool      InpRequireRSIConfirm   = true;        // Require RSI Confirmation
input double    InpRSIOverbought       = 70.0;        // RSI Overbought Level
input double    InpRSIOversold         = 30.0;        // RSI Oversold Level
input double    InpRSINeutralZone      = 10.0;        // RSI Neutral Zone (±50)
input bool      InpRequirePAConfirm    = true;        // Require Price Action Confirmation
input int       InpSwingLookback       = 50;          // Swing Lookback Period
input bool      InpUseOrderBlocks      = true;        // Use Order Blocks
input bool      InpUseFVG              = true;        // Use Fair Value Gaps

input group "=== SPREAD & VOLATILITY FILTERS ==="
input double    InpMaxSpreadPoints     = 30.0;        // Max Spread (points)
input double    InpMinATRThreshold     = 0.0;         // Min ATR Threshold (0 = disabled)
input double    InpMaxATRThreshold     = 0.0;         // Max ATR Threshold (0 = disabled)

input group "=== POSITION MANAGEMENT ==="
input bool      InpAllowMultipleEntries = true;       // Allow Multiple Entries
input int       InpMaxEntriesPerDir    = 3;           // Max Entries Per Direction
input double    InpMinDistBetweenEntriesATR = 0.5;    // Min Distance Between Entries (ATR)
input bool      InpAllowHedging        = false;       // Allow Hedging

input group "=== TIME SETTINGS ==="
input bool      InpUseServerTime       = true;        // Use Server Time
input int       InpTimezoneOffset      = 0;           // Timezone Offset (hours)

input group "=== DEBUG & LOGGING ==="
input bool      InpDebugMode           = false;       // Debug Mode
input bool      InpLogSignals          = true;        // Log Signals
input bool      InpLogTrades           = true;        // Log Trades

//+------------------------------------------------------------------+
//| Initialize Configuration                                         |
//+------------------------------------------------------------------+
bool Config::Initialize(const string symbol, const ENUM_TIMEFRAMES timeframe)
  {
   //--- General
   s_enabled         = InpEnabled;
   s_ea_name         = InpEAName;
   s_magic_number    = InpMagicNumber;
   s_show_dashboard  = InpShowDashboard;
   
   //--- Risk Parameters
   s_risk_params.risk_method            = InpRiskMethod;
   s_risk_params.risk_percent           = InpRiskPercent;
   s_risk_params.max_daily_loss_percent = InpMaxDailyLossPercent;
   s_risk_params.max_account_drawdown_percent = InpMaxAccountDDPercent;
   s_risk_params.max_open_positions     = InpMaxOpenPositions;
   s_risk_params.min_risk_reward_ratio  = InpMinRiskReward;
   s_risk_params.max_spread_points      = InpMaxSpreadPoints;
   s_risk_params.fixed_lot_size         = InpFixedLotSize;
   s_risk_params.atr_multiplier_sl      = InpATRMultiplierSL;
   s_risk_params.atr_multiplier_tp      = InpATRMultiplierTP;
   s_risk_params.use_break_even         = InpUseBreakEven;
   s_risk_params.break_even_trigger_atr = InpBETriggerATR;
   s_risk_params.break_even_offset_atr  = InpBEOffsetATR;
   s_risk_params.use_trailing_stop      = InpUseTrailingStop;
   s_risk_params.trailing_method        = InpTrailMethod;
   s_risk_params.trailing_atr_multiplier = InpTrailingATRMult;
   s_risk_params.trailing_points        = InpTrailingPoints;
   s_risk_params.trailing_ma_period     = InpTrailingMAPeriod;
   
   //--- Trading Session
   s_trading_session.session_filter     = InpSessionFilter;
   s_trading_session.london_open_hour   = InpLondonOpenHour;
   s_trading_session.london_close_hour  = InpLondonCloseHour;
   s_trading_session.ny_open_hour       = InpNYOpenHour;
   s_trading_session.ny_close_hour      = InpNYCloseHour;
   s_trading_session.asian_open_hour    = InpAsianOpenHour;
   s_trading_session.asian_close_hour   = InpAsianCloseHour;
   s_trading_session.avoid_news_high_impact = InpAvoidNewsHigh;
   s_trading_session.avoid_news_medium_impact = InpAvoidNewsMedium;
   s_trading_session.minutes_before_news = InpMinBeforeNews;
   s_trading_session.minutes_after_news  = InpMinAfterNews;
   
   //--- Indicators
   s_ema50_period     = InpEMA50Period;
   s_ema200_period    = InpEMA200Period;
   s_rsi_period       = InpRSIPeriod;
   s_atr_period       = InpATRPeriod;
   s_ema_method       = InpEMAAethod;
   s_applied_price    = InpAppliedPrice;
   
   //--- Signal Confirmation
   s_require_trend_alignment       = InpRequireTrendAlign;
   s_require_rsi_confirmation      = InpRequireRSIConfirm;
   s_rsi_overbought                = InpRSIOverbought;
   s_rsi_oversold                  = InpRSIOversold;
   s_rsi_neutral_zone              = InpRSINeutralZone;
   s_require_price_action_confirmation = InpRequirePAConfirm;
   s_swing_lookback                = InpSwingLookback;
   s_use_order_blocks              = InpUseOrderBlocks;
   s_use_fair_value_gaps           = InpUseFVG;
   
   //--- Spread & Volatility
   s_min_atr_threshold = InpMinATRThreshold;
   s_max_atr_threshold = InpMaxATRThreshold;
   
   //--- Position Management
   s_allow_multiple_entries          = InpAllowMultipleEntries;
   s_max_entries_per_direction       = InpMaxEntriesPerDir;
   s_min_distance_between_entries_atr = InpMinDistBetweenEntriesATR;
   s_allow_hedging                   = InpAllowHedging;
   
   //--- Time
   s_use_server_time  = InpUseServerTime;
   s_timezone_offset  = InpTimezoneOffset;
   
   //--- Debug
   s_debug_mode  = InpDebugMode;
   s_log_signals = InpLogSignals;
   s_log_trades  = InpLogTrades;
   
   //--- Validation
   if(s_risk_params.risk_percent <= 0 || s_risk_params.risk_percent > 100)
     {
      Print("Config: Invalid risk percent: ", s_risk_params.risk_percent);
      return false;
     }
   
   if(s_risk_params.max_daily_loss_percent <= 0 || s_risk_params.max_daily_loss_percent > 100)
     {
      Print("Config: Invalid max daily loss percent: ", s_risk_params.max_daily_loss_percent);
      return false;
     }
   
   if(s_risk_params.max_open_positions <= 0)
     {
      Print("Config: Invalid max open positions: ", s_risk_params.max_open_positions);
      return false;
     }
   
   if(s_ema50_period <= 0 || s_ema200_period <= 0)
     {
      Print("Config: Invalid EMA periods");
      return false;
     }
   
   if(s_rsi_period <= 0)
     {
      Print("Config: Invalid RSI period");
      return false;
     }
   
   if(s_atr_period <= 0)
     {
      Print("Config: Invalid ATR period");
      return false;
     }
   
   //--- Adjust spread for 5-digit brokers
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   if(digits == 3 || digits == 5)
     {
      s_risk_params.max_spread_points *= 10;
     }
   
   Print("Config: Initialized successfully");
   Print("Config: Risk Method: ", EnumToString(s_risk_params.risk_method), 
         " | Risk %: ", s_risk_params.risk_percent,
         " | Max Daily Loss: ", s_risk_params.max_daily_loss_percent, "%");
   Print("Config: Max Spread: ", s_risk_params.max_spread_points, " points");
   Print("Config: EMA50: ", s_ema50_period, " | EMA200: ", s_ema200_period);
   Print("Config: RSI: ", s_rsi_period, " | ATR: ", s_atr_period);
   
   return true;
  }

//+------------------------------------------------------------------+
//| Check if current time is within trading session                  |
//+------------------------------------------------------------------+
bool Config::IsTradingTime()
  {
   //--- Get current time
   datetime current_time = TimeCurrent();
   MqlDateTime dt;
   TimeCurrent(dt);
   
   int current_hour = dt.hour;
   int current_min = dt.min;
   int current_day = dt.day_of_week; // 0=Sunday, 6=Saturday
   
   //--- No trading on weekends
   if(current_day == 0 || current_day == 6)
     {
      return false;
     }
   
   //--- Check session filter
   switch(s_trading_session.session_filter)
     {
      case SESSION_ALL:
         return true;
         
      case SESSION_LONDON:
         return (current_hour >= s_trading_session.london_open_hour && 
                 current_hour < s_trading_session.london_close_hour);
         
      case SESSION_NEWYORK:
         return (current_hour >= s_trading_session.ny_open_hour && 
                 current_hour < s_trading_session.ny_close_hour);
         
      case SESSION_LONDON_NY:
         //--- London session OR New York session OR overlap
         bool in_london = (current_hour >= s_trading_session.london_open_hour && 
                          current_hour < s_trading_session.london_close_hour);
         bool in_ny = (current_hour >= s_trading_session.ny_open_hour && 
                       current_hour < s_trading_session.ny_close_hour);
         return (in_london || in_ny);
         
      case SESSION_ASIAN:
         return (current_hour >= s_trading_session.asian_open_hour && 
                 current_hour < s_trading_session.asian_close_hour);
         
      case SESSION_CUSTOM:
         //--- Custom logic can be added here
         return true;
         
      default:
         return true;
     }
  }
//+------------------------------------------------------------------+