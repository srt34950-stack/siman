//+------------------------------------------------------------------+
//|                                             RiskManager.mqh      |
//|                    Risk Management & Position Sizing             |
//+------------------------------------------------------------------+
#property strict

#include "Config.mqh"
#include "SignalGenerator.mqh"

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
struct DAILY_STATS
  {
   double  starting_balance;
   double  current_balance;
   double  profit_today;
   double  loss_today;
   int     trades_today;
   int     winning_trades;
   int     losing_trades;
   datetime last_reset_date;
   bool    daily_limit_reached;
  };

struct POSITION_RISK
  {
   double  lot_size;
   double  risk_amount;
   double  risk_percent;
   double  stop_distance_points;
   double  risk_reward_ratio;
  };

//+------------------------------------------------------------------+
//| Risk Manager Class                                               |
//+------------------------------------------------------------------+
class RiskManager
  {
private:
   //--- Daily statistics
   static DAILY_STATS s_daily_stats;
   
   //--- Position tracking
   static double s_total_risk_exposure;
   static double s_max_position_size;
   
   //--- Initialization
   static bool s_initialized;

public:
   //--- Initialization
   static bool Initialize();
   static void Cleanup();
   
   //--- Position Sizing
   static double CalculatePositionSize(ENTRY_SIGNAL &signal);
   static double CalculateLotSize(ENUM_RISK_METHOD method, double risk_amount, double stop_distance_points);
   static double GetMaxLotSize();
   static double GetMinLotSize();
   static double GetLotStep();
   
   //--- Daily Limits
   static bool CheckDailyLossLimit();
   static void CheckDailyReset();
   static void UpdateDailyStats(double profit, double loss);
   static double GetDailyProfitLoss() { return s_daily_stats.profit_today - s_daily_stats.loss_today; }
   static int GetTradesToday() { return s_daily_stats.trades_today; }
   static double GetDailyLossPercent() { return s_daily_stats.starting_balance > 0 ? (s_daily_stats.loss_today / s_daily_stats.starting_balance) * 100 : 0; }
   
   //--- Drawdown Checks
   static bool CheckMaxDrawdown();
   static double GetCurrentDrawdownPercent();
   
   //--- Margin Checks
   static bool CheckMarginLevel();
   static double GetMarginLevel();
   
   //--- Position Management
   static bool CanOpenNewPosition();
   static bool IsPositionProfitable(ulong ticket);
   static bool ShouldCloseAtBreakEven(ulong ticket, double current_price);
   static double CalculateBreakEvenPrice(ulong ticket, double open_price);
   
   //--- Trailing Stop
   static bool ShouldUpdateTrailingStop(ulong ticket, double current_price, double current_sl);
   static double CalculateTrailingStop(ulong ticket, double current_price, double current_sl);
   
   //--- Risk Per Trade Info
   static double GetRiskPercent() { return Config::GetRiskPercent(); }

private:
   //--- Helper functions
   static double GetTickSize();
   static double GetPointSize();
   static double NormalizeLotSize(double lots);
   static bool IsNewDay();
   static void LoadDailyStats();
   static void SaveDailyStats();
  };

//+------------------------------------------------------------------+
//| Static member definitions                                        |
//+------------------------------------------------------------------+
DAILY_STATS RiskManager::s_daily_stats;
double RiskManager::s_total_risk_exposure = 0;
double RiskManager::s_max_position_size = 0;
bool RiskManager::s_initialized = false;

//+------------------------------------------------------------------+
//| Initialize Risk Manager                                          |
//+------------------------------------------------------------------+
bool RiskManager::Initialize()
  {
   //--- Load daily stats
   LoadDailyStats();
   
   //--- Get symbol info for lot size limits
   s_max_position_size = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   
   //--- Check max lot size
   if(s_max_position_size <= 0 || s_max_position_size > 100)
     {
      s_max_position_size = 100;
     }
   
   s_total_risk_exposure = 0;
   s_initialized = true;
   
   Print("RiskManager: Initialized successfully");
   Print("RiskManager: Max Lot Size: ", s_max_position_size);
   Print("RiskManager: Starting Balance: ", s_daily_stats.starting_balance);
   Print("RiskManager: Daily P/L: ", s_daily_stats.profit_today - s_daily_stats.loss_today);
   
   return true;
  }

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void RiskManager::Cleanup()
  {
   SaveDailyStats();
   s_initialized = false;
   Print("RiskManager: Cleaned up");
  }

//+------------------------------------------------------------------+
//| Calculate Position Size                                          |
//+------------------------------------------------------------------+
double RiskManager::CalculatePositionSize(ENTRY_SIGNAL &signal)
  {
   if(!s_initialized)
     {
      return 0;
     }
   
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   if(equity <= 0 || balance <= 0)
     {
      Print("RiskManager: Invalid account balance/equity");
      return 0;
     }
   
   //--- Calculate stop distance in points
   double entry_price = signal.entry_price;
   double stop_loss = signal.stop_loss;
   double stop_distance_points = MathAbs(entry_price - stop_loss) / _Point;
   
   if(stop_distance_points <= 0)
     {
      Print("RiskManager: Invalid stop distance");
      return 0;
     }
   
   //--- Calculate risk amount based on method
   double risk_amount = 0;
   ENUM_RISK_METHOD method = Config::GetRiskMethod();
   
   switch(method)
     {
      case RISK_FIXED_LOT:
         //--- Fixed lot size
         risk_amount = Config::GetFixedLotSize() * stop_distance_points * GetTickSize();
         signal.risk_reward_ratio = (signal.take_profit - signal.entry_price) / stop_distance_points;
         return NormalizeLotSize(Config::GetFixedLotSize());
         
      case RISK_PERCENT_EQUITY:
         {
          double risk_percent = Config::GetRiskPercent();
          risk_amount = equity * (risk_percent / 100.0);
          break;
         }
         
      case RISK_PERCENT_BALANCE:
         {
          double risk_percent = Config::GetRiskPercent();
          risk_amount = balance * (risk_percent / 100.0);
          break;
         }
         
      case RISK_ATR_BASED:
         {
          //--- ATR-based: risk a fixed number of ATRs
          double atr_risk = signal.atr_value * Config::GetATRMultiplierSL();
          risk_amount = equity * 0.01; // 1% base risk
          break;
         }
         
      case RISK_KELLY:
         {
          //--- Kelly Criterion (simplified)
          double win_rate = 0.5; // Default 50%
          double avg_win = signal.risk_reward_ratio > 0 ? signal.risk_reward_ratio : 1.0;
          double avg_loss = 1.0;
          
          double kelly_percent = (win_rate * avg_win - (1 - win_rate) * avg_loss) / avg_win;
          kelly_percent = MathMax(0, MathMin(kelly_percent, 0.25)); // Cap at 25%
          
          risk_amount = equity * kelly_percent;
          break;
         }
         
      default:
         risk_amount = equity * (Config::GetRiskPercent() / 100.0);
         break;
     }
   
   //--- Cap risk amount
   double max_risk_amount = equity * (Config::GetMaxDailyLossPercent() / 100.0);
   if(risk_amount > max_risk_amount)
     {
      risk_amount = max_risk_amount;
     }
   
   //--- Calculate lot size
   double lots = CalculateLotSize(method, risk_amount, stop_distance_points);
   
   //--- Normalize lot size
   lots = NormalizeLotSize(lots);
   
   //--- Validate against limits
   double min_lot = GetMinLotSize();
   double max_lot = GetMaxLotSize();
   
   if(lots < min_lot)
     {
      if(Config::GetDebugMode())
        {
         Print("RiskManager: Calculated lot ", lots, " below minimum ", min_lot);
        }
      return 0; // Cannot trade below minimum
     }
   
   if(lots > max_lot)
     {
      lots = max_lot;
     }
   
   //--- Check total exposure
   double current_exposure = s_total_risk_exposure + lots;
   double max_exposure = Config::GetMaxOpenPositions() * max_lot;
   if(current_exposure > max_exposure)
     {
      lots = max_exposure - s_total_risk_exposure;
      lots = NormalizeLotSize(lots);
      
      if(lots < min_lot)
        {
         return 0;
        }
     }
   
   //--- Update signal with risk info
   signal.risk_reward_ratio = (signal.take_profit - signal.entry_price) / stop_distance_points;
   
   Print("RiskManager: Calculated lot size: ", lots, " | Risk amount: ", risk_amount, 
         " | Stop distance: ", stop_distance_points, " points");
   
   return lots;
  }

//+------------------------------------------------------------------+
//| Calculate Lot Size                                               |
//+------------------------------------------------------------------+
double RiskManager::CalculateLotSize(ENUM_RISK_METHOD method, double risk_amount, double stop_distance_points)
  {
   double tick_size = GetTickSize();
   double point_size = GetPointSize();
   
   if(tick_size <= 0 || point_size <= 0 || stop_distance_points <= 0)
     {
      return 0;
     }
   
   //--- Lot size = Risk Amount / (Stop Distance * Tick Size)
   double lots = risk_amount / (stop_distance_points * tick_size);
   
   return lots;
  }

//+------------------------------------------------------------------+
//| Normalize Lot Size                                               |
//+------------------------------------------------------------------+
double RiskManager::NormalizeLotSize(double lots)
  {
   double min_lot = GetMinLotSize();
   double max_lot = GetMaxLotSize();
   double lot_step = GetLotStep();
   
   if(lot_step <= 0) lot_step = 0.01;
   
   //--- Round to lot step
   lots = MathFloor(lots / lot_step) * lot_step;
   
   //--- Clamp to min/max
   if(lots < min_lot) lots = min_lot;
   if(lots > max_lot) lots = max_lot;
   
   return NormalizeDouble(lots, 2);
  }

//+------------------------------------------------------------------+
//| Get Min Lot Size                                                 |
//+------------------------------------------------------------------+
double RiskManager::GetMinLotSize()
  {
   double min_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   return min_vol > 0 ? min_vol : 0.01;
  }

//+------------------------------------------------------------------+
//| Get Max Lot Size                                                 |
//+------------------------------------------------------------------+
double RiskManager::GetMaxLotSize()
  {
   return s_max_position_size;
  }

//+------------------------------------------------------------------+
//| Get Lot Step                                                     |
//+------------------------------------------------------------------+
double RiskManager::GetLotStep()
  {
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   return step > 0 ? step : 0.01;
  }

//+------------------------------------------------------------------+
//| Get Tick Size                                                    |
//+------------------------------------------------------------------+
double RiskManager::GetTickSize()
  {
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   return tick > 0 ? tick : _Point;
  }

//+------------------------------------------------------------------+
//| Get Point Size                                                   |
//+------------------------------------------------------------------+
double RiskManager::GetPointSize()
  {
   return _Point;
  }

//+------------------------------------------------------------------+
//| Check Daily Loss Limit                                           |
//+------------------------------------------------------------------+
bool RiskManager::CheckDailyLossLimit()
  {
   if(!s_initialized)
     {
      return true;
     }
   
   CheckDailyReset();
   
   //--- Check if daily loss limit reached
   double daily_loss_percent = GetDailyLossPercent();
   
   if(daily_loss_percent >= Config::GetMaxDailyLossPercent())
     {
      if(!s_daily_stats.daily_limit_reached)
        {
         s_daily_stats.daily_limit_reached = true;
         Print("RiskManager: DAILY LOSS LIMIT REACHED: ", daily_loss_percent, "% >= ", 
               Config::GetMaxDailyLossPercent(), "%");
        }
      return false;
     }
   
   s_daily_stats.daily_limit_reached = false;
   return true;
  }

//+------------------------------------------------------------------+
//| Check Daily Reset                                                |
//+------------------------------------------------------------------+
void RiskManager::CheckDailyReset()
  {
   if(IsNewDay())
     {
      //--- Save previous day stats
      SaveDailyStats();
      
      //--- Reset for new day
      s_daily_stats.starting_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      s_daily_stats.current_balance = s_daily_stats.starting_balance;
      s_daily_stats.profit_today = 0;
      s_daily_stats.loss_today = 0;
      s_daily_stats.trades_today = 0;
      s_daily_stats.winning_trades = 0;
      s_daily_stats.losing_trades = 0;
      s_daily_stats.daily_limit_reached = false;
      s_daily_stats.last_reset_date = TimeCurrent();
      
      Print("RiskManager: Daily stats reset. New starting balance: ", s_daily_stats.starting_balance);
     }
  }

//+------------------------------------------------------------------+
//| Is New Day                                                       |
//+------------------------------------------------------------------+
bool RiskManager::IsNewDay()
  {
   datetime current_date = TimeCurrent();
   MqlDateTime dt_current;
   TimeToStruct(current_date, dt_current);
   
   MqlDateTime dt_last;
   TimeToStruct(s_daily_stats.last_reset_date, dt_last);
   
   return (dt_current.year != dt_last.year || 
           dt_current.mon != dt_last.mon || 
           dt_current.day != dt_last.day);
  }

//+------------------------------------------------------------------+
//| Load Daily Stats                                                 |
//+------------------------------------------------------------------+
void RiskManager::LoadDailyStats()
  {
   //--- Try to load from global variables
   long handle = GlobalVariableGet(Config::GetEAName() + "_DailyStats");
   
   if(handle > 0)
     {
      //--- In a real implementation, you'd deserialize from file or global variable
      //--- For now, initialize fresh
     }
   
   //--- Initialize fresh
   s_daily_stats.starting_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   s_daily_stats.current_balance = s_daily_stats.starting_balance;
   s_daily_stats.profit_today = 0;
   s_daily_stats.loss_today = 0;
   s_daily_stats.trades_today = 0;
   s_daily_stats.winning_trades = 0;
   s_daily_stats.losing_trades = 0;
   s_daily_stats.daily_limit_reached = false;
   s_daily_stats.last_reset_date = TimeCurrent();
  }

//+------------------------------------------------------------------+
//| Save Daily Stats                                                 |
//+------------------------------------------------------------------+
void RiskManager::SaveDailyStats()
  {
   //--- Save to file for persistence
   int file_handle = FileOpen("RiskManager_DailyStats_" + _Symbol + ".csv", FILE_CSV | FILE_WRITE | FILE_COMMON);
   
   if(file_handle > 0)
     {
      FileWrite(file_handle, TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS));
      FileWrite(file_handle, s_daily_stats.starting_balance);
      FileWrite(file_handle, s_daily_stats.profit_today);
      FileWrite(file_handle, s_daily_stats.loss_today);
      FileWrite(file_handle, s_daily_stats.trades_today);
      FileWrite(file_handle, s_daily_stats.winning_trades);
      FileWrite(file_handle, s_daily_stats.losing_trades);
      FileClose(file_handle);
     }
  }

//+------------------------------------------------------------------+
//| Update Daily Stats                                               |
//+------------------------------------------------------------------+
void RiskManager::UpdateDailyStats(double profit, double loss)
  {
   s_daily_stats.trades_today++;
   
   if(profit > 0)
     {
      s_daily_stats.profit_today += profit;
      s_daily_stats.winning_trades++;
     }
   else if(loss > 0)
     {
      s_daily_stats.loss_today += loss;
      s_daily_stats.losing_trades++;
     }
   
   s_daily_stats.current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
  }

//+------------------------------------------------------------------+
//| Check Max Drawdown                                               |
//+------------------------------------------------------------------+
bool RiskManager::CheckMaxDrawdown()
  {
   double dd_percent = GetCurrentDrawdownPercent();
   
   if(dd_percent >= Config::GetMaxAccountDrawdownPercent())
     {
      Print("RiskManager: MAX DRAWDOWN REACHED: ", dd_percent, "% >= ", 
            Config::GetMaxAccountDrawdownPercent(), "%");
      return false;
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Get Current Drawdown Percent                                     |
//+------------------------------------------------------------------+
double RiskManager::GetCurrentDrawdownPercent()
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if(balance <= 0) return 0;
   
   double dd = ((balance - equity) / balance) * 100;
   return MathMax(0, dd);
  }

//+------------------------------------------------------------------+
//| Check Margin Level                                               |
//+------------------------------------------------------------------+
bool RiskManager::CheckMarginLevel()
  {
   double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   
   if(margin_level > 0 && margin_level < Config::GetMinMarginLevel())
     {
      Print("RiskManager: Margin level too low: ", margin_level, "%");
      return false;
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Get Margin Level                                                 |
//+------------------------------------------------------------------+
double RiskManager::GetMarginLevel()
  {
   return AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
  }

//+------------------------------------------------------------------+
//| Can Open New Position                                            |
//+------------------------------------------------------------------+
bool RiskManager::CanOpenNewPosition()
  {
   //--- Check daily loss limit
   if(!CheckDailyLossLimit())
     {
      return false;
     }
   
   //--- Check max drawdown
   if(!CheckMaxDrawdown())
     {
      return false;
     }
   
   //--- Check margin level
   if(!CheckMarginLevel())
     {
      return false;
     }
   
   //--- Check max positions
   //--- This is checked in the main EA
   
   return true;
  }

//+------------------------------------------------------------------+
//| Is Position Profitable                                           |
//+------------------------------------------------------------------+
bool RiskManager::IsPositionProfitable(ulong ticket)
  {
   //--- Implemented in TradeExecutor
   return false;
  }

//+------------------------------------------------------------------+
//| Should Close at Break Even                                       |
//+------------------------------------------------------------------+
bool RiskManager::ShouldCloseAtBreakEven(ulong ticket, double current_price)
  {
   if(!Config::GetUseBreakEven())
     {
      return false;
     }
   
   //--- Implemented in TradeExecutor with position info
   return false;
  }

//+------------------------------------------------------------------+
//| Calculate Break Even Price                                       |
//+------------------------------------------------------------------+
double RiskManager::CalculateBreakEvenPrice(ulong ticket, double open_price)
  {
   double atr = IndicatorsManager::GetATR14();
   double offset = atr * Config::GetBreakEvenOffsetATR();
   
   //--- Implemented in TradeExecutor
   return open_price;
  }

//+------------------------------------------------------------------+
//| Should Update Trailing Stop                                      |
//+------------------------------------------------------------------+
bool RiskManager::ShouldUpdateTrailingStop(ulong ticket, double current_price, double current_sl)
  {
   if(!Config::GetUseTrailingStop())
     {
      return false;
     }
   
   double atr = IndicatorsManager::GetATR14();
   double trailing_distance = atr * Config::GetTrailingATRMultiplier();
   
   //--- Implemented in TradeExecutor
   return false;
  }

//+------------------------------------------------------------------+
//| Calculate Trailing Stop                                          |
//+------------------------------------------------------------------+
double RiskManager::CalculateTrailingStop(ulong ticket, double current_price, double current_sl)
  {
   double atr = IndicatorsManager::GetATR14();
   double trailing_distance = atr * Config::GetTrailingATRMultiplier();
   
   //--- Implemented in TradeExecutor
   return current_sl;
  }
//+------------------------------------------------------------------+