//+------------------------------------------------------------------+
//|                                           TradeExecutor.mqh      |
//|                    Trade Execution & Position Management         |
//+------------------------------------------------------------------+
#property strict

#include <Trade\Trade.mqh>
#include "Config.mqh"
#include "SignalGenerator.mqh"
#include "RiskManager.mqh"

//+------------------------------------------------------------------+
//| Trade Executor Class                                             |
//+------------------------------------------------------------------+
class TradeExecutor
  {
private:
   //--- Trade object
   static CTrade s_trade;
   
   //--- Initialization
   static bool s_initialized;

public:
   //--- Initialization
   static bool Initialize();
   static void Cleanup();
   
   //--- Open Position
   static bool OpenPosition(ENTRY_SIGNAL &signal, double lot_size);
   
   //--- Position Management
   static void ManagePositions();
   static void CloseAllPositions();
   static int GetOpenPositionsCount();
   static int GetBuyPositionsCount();
   static int GetSellPositionsCount();
   
   //--- Trade Transaction Handler
   static void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result);
   
   //--- Trailing Stop Management
   static void UpdateTrailingStops();
   static void ManageBreakEven();
   
   //--- Close Specific Position
   static bool ClosePosition(ulong ticket);
   static bool ClosePositionByType(ENUM_ENTRY_TYPE type);
   
   //--- Statistics
   static double GetTotalProfit();
   static double GetTotalCommission();
   static double GetTotalSwap();

private:
   //--- Helper functions
   static bool PlaceOrder(ENUM_ORDER_TYPE order_type, double price, double volume, 
                          double sl, double tp, string comment);
   static bool ModifyPositionSL(ulong ticket, double new_sl);
   static bool ModifyPositionTP(ulong ticket, double new_tp);
   static double GetPositionOpenPrice(ulong ticket);
   static double GetPositionCurrentPrice(ulong ticket);
   static double GetPositionProfit(ulong ticket);
   static ENUM_POSITION_TYPE GetPositionType(ulong ticket);
   static double GetPositionSL(ulong ticket);
   static double GetPositionTP(ulong ticket);
   static double GetPositionVolume(ulong ticket);
   static bool IsPositionByEA(ulong ticket);
   static string GetPositionComment(ulong ticket);
   static void LogTrade(string action, string type, double price, double volume, double sl, double tp, string comment);
  };

//+------------------------------------------------------------------+
//| Static member definitions                                        |
//+------------------------------------------------------------------+
CTrade TradeExecutor::s_trade;
bool TradeExecutor::s_initialized = false;

//+------------------------------------------------------------------+
//| Initialize Trade Executor                                        |
//+------------------------------------------------------------------+
bool TradeExecutor::Initialize()
  {
   //--- Set trade object properties
   s_trade.SetExpertMagicNumber(Config::GetMagicNumber());
   s_trade.SetDeviationInPoints(10);
   s_trade.SetTypeFilling(ORDER_FILLING_FOK); // Fill or Kill for scalping
   s_trade.SetAsyncMode(false); // Synchronous for reliability
   
   s_initialized = true;
   
   Print("TradeExecutor: Initialized successfully");
   Print("TradeExecutor: Magic Number: ", Config::GetMagicNumber());
   Print("TradeExecutor: Filling Mode: FOK");
   
   return true;
  }

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void TradeExecutor::Cleanup()
  {
   s_initialized = false;
   Print("TradeExecutor: Cleaned up");
  }

//+------------------------------------------------------------------+
//| Open Position                                                    |
//+------------------------------------------------------------------+
bool TradeExecutor::OpenPosition(ENTRY_SIGNAL &signal, double lot_size)
  {
   if(!s_initialized)
     {
      return false;
     }
   
   //--- Check entry tracking
   ENUM_ENTRY_TYPE type = signal.type;
   
   if(type == ENTRY_BUY)
     {
      if(!SignalGenerator::CanAddBuyEntry(signal.entry_price))
        {
         return false;
        }
     }
   else if(type == ENTRY_SELL)
     {
      if(!SignalGenerator::CanAddSellEntry(signal.entry_price))
        {
         return false;
        }
     }
   
   //--- Check max positions
   if(GetOpenPositionsCount() >= Config::GetMaxOpenPositions())
     {
      Print("TradeExecutor: Max open positions reached");
      return false;
     }
   
   //--- Check hedging
   if(!Config::GetAllowHedging())
     {
      if(type == ENTRY_BUY && GetSellPositionsCount() > 0)
        {
         Print("TradeExecutor: Hedging disabled, cannot open BUY with existing SELL positions");
         return false;
        }
      if(type == ENTRY_SELL && GetBuyPositionsCount() > 0)
        {
         Print("TradeExecutor: Hedging disabled, cannot open SELL with existing BUY positions");
         return false;
        }
     }
   
   //--- Normalize prices
   double entry_price = NormalizeDouble(signal.entry_price, _Digits);
   double stop_loss = NormalizeDouble(signal.stop_loss, _Digits);
   double take_profit = NormalizeDouble(signal.take_profit, _Digits);
   
   //--- Determine order type
   ENUM_ORDER_TYPE order_type = (type == ENTRY_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   
   //--- Place order
   bool result = PlaceOrder(order_type, entry_price, lot_size, stop_loss, take_profit, signal.comment);
   
   if(result)
     {
      //--- Track position entry
      SignalGenerator::OnPositionOpened(type, entry_price);
      
      //--- Log trade
      LogTrade("OPEN", EnumToString(type), entry_price, lot_size, stop_loss, take_profit, signal.comment);
      
      Print("TradeExecutor: Position opened - Type: ", EnumToString(type),
            " | Lot: ", lot_size, " | Price: ", entry_price, " | SL: ", stop_loss, " | TP: ", take_profit);
      
      return true;
     }
   else
     {
      Print("TradeExecutor: Failed to open position. Error: ", GetLastError());
      return false;
     }
  }

//+------------------------------------------------------------------+
//| Place Order                                                      |
//+------------------------------------------------------------------+
bool TradeExecutor::PlaceOrder(ENUM_ORDER_TYPE order_type, double price, double volume, 
                                double sl, double tp, string comment)
  {
   //--- Reset last error
   ResetLastError();
   
   //--- Check volume limits
   double min_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vol_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(volume < min_vol) volume = min_vol;
   if(volume > max_vol) volume = max_vol;
   
   //--- Normalize volume to step
   if(vol_step > 0)
     {
      volume = MathFloor(volume / vol_step) * vol_step;
      volume = NormalizeDouble(volume, 2);
     }
   
   //--- Check freeze level
   double freeze_level = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
   
   if(order_type == ORDER_TYPE_BUY)
     {
      if(MathAbs(price - sl) < freeze_level)
        {
         Print("TradeExecutor: SL too close to price (freeze level)");
         return false;
        }
      
      if(tp > 0 && MathAbs(tp - price) < freeze_level)
        {
         Print("TradeExecutor: TP too close to price (freeze level)");
         return false;
        }
      
      if(!s_trade.Buy(volume, _Symbol, price, sl, tp, comment))
        {
         Print("TradeExecutor: Buy order failed. Retcode: ", s_trade.ResultRetcode(), 
               " | Error: ", GetLastError());
         return false;
        }
     }
   else
     {
      if(MathAbs(price - sl) < freeze_level)
        {
         Print("TradeExecutor: SL too close to price (freeze level)");
         return false;
        }
      
      if(tp > 0 && MathAbs(tp - price) < freeze_level)
        {
         Print("TradeExecutor: TP too close to price (freeze level)");
         return false;
        }
      
      if(!s_trade.Sell(volume, _Symbol, price, sl, tp, comment))
        {
         Print("TradeExecutor: Sell order failed. Retcode: ", s_trade.ResultRetcode(), 
               " | Error: ", GetLastError());
         return false;
        }
     }
   
   return true;
  }

//+------------------------------------------------------------------+
//| Manage Positions                                                 |
//+------------------------------------------------------------------+
void TradeExecutor::ManagePositions()
  {
   if(!s_initialized)
     {
      return;
     }
   
   //--- Update trailing stops
   UpdateTrailingStops();
   
   //--- Manage break even
   ManageBreakEven();
  }

//+------------------------------------------------------------------+
//| Update Trailing Stops                                            |
//+------------------------------------------------------------------+
void TradeExecutor::UpdateTrailingStops()
  {
   if(!Config::GetUseTrailingStop())
     {
      return;
     }
   
   //--- Iterate through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket <= 0) continue;
      if(!IsPositionByEA(ticket)) continue;
      
      double current_sl = GetPositionSL(ticket);
      double current_price = GetPositionCurrentPrice(ticket);
      ENUM_POSITION_TYPE pos_type = GetPositionType(ticket);
      
      double new_sl = current_sl;
      bool update = false;
      
      double atr = IndicatorsManager::GetATR14();
      
      switch(Config::GetTrailingMethod())
        {
         case TRAIL_ATR:
           {
            double trail_distance = atr * Config::GetTrailingATRMultiplier();
            
            if(pos_type == POSITION_TYPE_BUY)
              {
               double candidate_sl = current_price - trail_distance;
               if(candidate_sl > current_sl)
                 {
                  new_sl = candidate_sl;
                  update = true;
                 }
              }
            else
              {
               double candidate_sl = current_price + trail_distance;
               if(current_sl == 0 || candidate_sl < current_sl)
                 {
                  new_sl = candidate_sl;
                  update = true;
                 }
              }
           }
           break;
           
         case TRAIL_POINTS:
           {
            int trail_points = Config::GetTrailingPoints();
            double trail_distance = trail_points * _Point;
            
            if(pos_type == POSITION_TYPE_BUY)
              {
               double candidate_sl = current_price - trail_distance;
               if(candidate_sl > current_sl)
                 {
                  new_sl = candidate_sl;
                  update = true;
                 }
              }
            else
              {
               double candidate_sl = current_price + trail_distance;
               if(current_sl == 0 || candidate_sl < current_sl)
                 {
                  new_sl = candidate_sl;
                  update = true;
                 }
              }
           }
           break;
           
         case TRAIL_MA:
           {
            double ema = IndicatorsManager::GetEMA50_M1();
            
            if(pos_type == POSITION_TYPE_BUY)
              {
               if(ema > current_sl)
                 {
                  new_sl = ema;
                  update = true;
                 }
              }
            else
              {
               if(current_sl == 0 || ema < current_sl)
                 {
                  new_sl = ema;
                  update = true;
                 }
              }
           }
           break;
           
         case TRAIL_STRUCTURE:
           {
            if(pos_type == POSITION_TYPE_BUY)
              {
               double swing_low = PriceActionAnalyzer::GetLastSwingLow();
               if(swing_low > 0 && swing_low > current_sl)
                 {
                  new_sl = swing_low - atr * 0.2;
                  update = true;
                 }
              }
            else
              {
               double swing_high = PriceActionAnalyzer::GetLastSwingHigh();
               if(swing_high > 0 && (current_sl == 0 || swing_high < current_sl))
                 {
                  new_sl = swing_high + atr * 0.2;
                  update = true;
                 }
              }
           }
           break;
        }
      
      if(update && new_sl != current_sl && new_sl > 0)
        {
         //--- Check minimum distance (freeze level)
         double freeze_level = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
         
         if(pos_type == POSITION_TYPE_BUY)
           {
            if(current_price - new_sl < freeze_level) continue;
           }
         else
           {
            if(new_sl - current_price < freeze_level) continue;
           }
         
         if(ModifyPositionSL(ticket, new_sl))
           {
            Print("TradeExecutor: Trailing SL updated - Ticket: ", ticket, 
                  " | Old SL: ", current_sl, " | New SL: ", new_sl);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Manage Break Even                                                |
//+------------------------------------------------------------------+
void TradeExecutor::ManageBreakEven()
  {
   if(!Config::GetUseBreakEven())
     {
      return;
     }
   
   double atr = IndicatorsManager::GetATR14();
   double trigger_atr = Config::GetBreakEvenTriggerATR();
   double offset_atr = Config::GetBreakEvenOffsetATR();
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket <= 0) continue;
      if(!IsPositionByEA(ticket)) continue;
      
      double open_price = GetPositionOpenPrice(ticket);
      double current_sl = GetPositionSL(ticket);
      double current_price = GetPositionCurrentPrice(ticket);
      ENUM_POSITION_TYPE pos_type = GetPositionType(ticket);
      
      //--- Skip if already at break even or better
      if(pos_type == POSITION_TYPE_BUY && current_sl >= open_price) continue;
      if(pos_type == POSITION_TYPE_SELL && current_sl <= open_price) continue;
      
      //--- Check if profit reached trigger
      double trigger_distance = atr * trigger_atr;
      bool reached_trigger = false;
      
      if(pos_type == POSITION_TYPE_BUY)
        {
         if(current_price - open_price >= trigger_distance) reached_trigger = true;
        }
      else
        {
         if(open_price - current_price >= trigger_distance) reached_trigger = true;
        }
      
      if(reached_trigger)
        {
         double new_sl = 0;
         
         if(pos_type == POSITION_TYPE_BUY)
           {
            new_sl = open_price + (atr * offset_atr);
           }
         else
           {
            new_sl = open_price - (atr * offset_atr);
           }
         
         new_sl = NormalizeDouble(new_sl, _Digits);
         
         //--- Check freeze level
         double freeze_level = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
         
         if(pos_type == POSITION_TYPE_BUY)
           {
            if(current_price - new_sl < freeze_level) continue;
           }
         else
           {
            if(new_sl - current_price < freeze_level) continue;
           }
         
         if(ModifyPositionSL(ticket, new_sl))
           {
            Print("TradeExecutor: Break Even activated - Ticket: ", ticket, 
                  " | Open: ", open_price, " | New SL: ", new_sl);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Close All Positions                                              |
//+------------------------------------------------------------------+
void TradeExecutor::CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket <= 0) continue;
      if(!IsPositionByEA(ticket)) continue;
      
      ClosePosition(ticket);
     }
  }

//+------------------------------------------------------------------+
//| Close Position                                                   |
//+------------------------------------------------------------------+
bool TradeExecutor::ClosePosition(ulong ticket)
  {
   if(!IsPositionByEA(ticket))
     {
      return false;
     }
   
   ENUM_POSITION_TYPE pos_type = GetPositionType(ticket);
   double volume = GetPositionVolume(ticket);
   
   bool result = s_trade.PositionClose(ticket);
   
   if(result)
     {
      //--- Update entry tracking
      ENUM_ENTRY_TYPE entry_type = (pos_type == POSITION_TYPE_BUY) ? ENTRY_BUY : ENTRY_SELL;
      SignalGenerator::OnPositionClosed(entry_type);
      
      //--- Log trade
      double profit = GetPositionProfit(ticket);
      double price = GetPositionCurrentPrice(ticket);
      LogTrade("CLOSE", EnumToString(pos_type), price, volume, 0, 0, "Close #" + IntegerToString(ticket));
      
      //--- Update daily stats
      if(profit > 0)
        {
         RiskManager::UpdateDailyStats(profit, 0);
        }
      else if(profit < 0)
        {
         RiskManager::UpdateDailyStats(0, MathAbs(profit));
        }
      
      Print("TradeExecutor: Position closed - Ticket: ", ticket, " | Profit: ", profit);
      
      return true;
     }
   else
     {
      Print("TradeExecutor: Failed to close position. Ticket: ", ticket, " | Error: ", GetLastError());
      return false;
     }
  }

//+------------------------------------------------------------------+
//| Close Position by Type                                           |
//+------------------------------------------------------------------+
bool TradeExecutor::ClosePositionByType(ENUM_ENTRY_TYPE type)
  {
   bool any_closed = false;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      
      if(ticket <= 0) continue;
      if(!IsPositionByEA(ticket)) continue;
      
      ENUM_POSITION_TYPE pos_type = GetPositionType(ticket);
      
      bool match = (type == ENTRY_BUY && pos_type == POSITION_TYPE_BUY) ||
                   (type == ENTRY_SELL && pos_type == POSITION_TYPE_SELL);
                   
      if(match)
        {
         if(ClosePosition(ticket))
           {
            any_closed = true;
           }
        }
     }
   
   return any_closed;
  }

//+------------------------------------------------------------------+
//| Get Open Positions Count                                         |
//+------------------------------------------------------------------+
int TradeExecutor::GetOpenPositionsCount()
  {
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsPositionByEA(ticket))
        {
         count++;
        }
     }
   
   return count;
  }

//+------------------------------------------------------------------+
//| Get Buy Positions Count                                          |
//+------------------------------------------------------------------+
int TradeExecutor::GetBuyPositionsCount()
  {
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsPositionByEA(ticket) && GetPositionType(ticket) == POSITION_TYPE_BUY)
        {
         count++;
        }
     }
   
   return count;
  }

//+------------------------------------------------------------------+
//| Get Sell Positions Count                                         |
//+------------------------------------------------------------------+
int TradeExecutor::GetSellPositionsCount()
  {
   int count = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsPositionByEA(ticket) && GetPositionType(ticket) == POSITION_TYPE_SELL)
        {
         count++;
        }
     }
   
   return count;
  }

//+------------------------------------------------------------------+
//| Get Total Profit                                                 |
//+------------------------------------------------------------------+
double TradeExecutor::GetTotalProfit()
  {
   double total = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsPositionByEA(ticket))
        {
         total += GetPositionProfit(ticket);
        }
     }
   
   return total;
  }

//+------------------------------------------------------------------+
//| Get Total Commission                                             |
//+------------------------------------------------------------------+
double TradeExecutor::GetTotalCommission()
  {
   double total = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsPositionByEA(ticket))
        {
         total += PositionGetDouble(POSITION_COMMISSION);
        }
     }
   
   return total;
  }

//+------------------------------------------------------------------+
//| Get Total Swap                                                   |
//+------------------------------------------------------------------+
double TradeExecutor::GetTotalSwap()
  {
   double total = 0;
   
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0 && IsPositionByEA(ticket))
        {
         total += PositionGetDouble(POSITION_SWAP);
        }
     }
   
   return total;
  }

//+------------------------------------------------------------------+
//| On Trade Transaction                                             |
//+------------------------------------------------------------------+
void TradeExecutor::OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   if(!s_initialized) return;
   
   if(Config::GetLogTrades())
     {
      switch(trans.type)
        {
         case TRADE_TRANSACTION_ORDER_ADD:
            Print("TradeExecutor: Order added - Ticket: ", trans.order, " | Price: ", trans.price);
            break;
            
         case TRADE_TRANSACTION_ORDER_DELETE:
            Print("TradeExecutor: Order deleted - Ticket: ", trans.order);
            break;
            
         case TRADE_TRANSACTION_POSITION_OPEN:
            Print("TradeExecutor: Position opened - Ticket: ", trans.position, " | Price: ", trans.price);
            break;
            
         case TRADE_TRANSACTION_POSITION_CLOSE:
            Print("TradeExecutor: Position closed - Ticket: ", trans.position, " | Profit: ", trans.profit);
            
            if(trans.profit > 0)
              {
               RiskManager::UpdateDailyStats(trans.profit, 0);
              }
            else if(trans.profit < 0)
              {
               RiskManager::UpdateDailyStats(0, MathAbs(trans.profit));
              }
            break;
            
         case TRADE_TRANSACTION_POSITION_MODIFY:
            Print("TradeExecutor: Position modified - Ticket: ", trans.position);
            break;
        }
     }
  }

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+
bool TradeExecutor::ModifyPositionSL(ulong ticket, double new_sl)
  {
   new_sl = NormalizeDouble(new_sl, _Digits);
   
   bool result = s_trade.PositionModify(ticket, new_sl, PositionGetDouble(POSITION_TP));
   
   if(!result)
     {
      Print("TradeExecutor: Failed to modify SL. Ticket: ", ticket, " | Error: ", GetLastError());
     }
   
   return result;
 }

bool TradeExecutor::ModifyPositionTP(ulong ticket, double new_tp)
  {
   new_tp = NormalizeDouble(new_tp, _Digits);
   
   bool result = s_trade.PositionModify(ticket, PositionGetDouble(POSITION_SL), new_tp);
   
   if(!result)
     {
      Print("TradeExecutor: Failed to modify TP. Ticket: ", ticket, " | Error: ", GetLastError());
     }
   
   return result;
 }

double TradeExecutor::GetPositionOpenPrice(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      return PositionGetDouble(POSITION_PRICE_OPEN);
     }
   return 0;
 }

double TradeExecutor::GetPositionCurrentPrice(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      return (type == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
     }
   return 0;
 }

double TradeExecutor::GetPositionProfit(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      return PositionGetDouble(POSITION_PROFIT);
     }
   return 0;
 }

ENUM_POSITION_TYPE TradeExecutor::GetPositionType(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      return (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
     }
   return POSITION_TYPE_BUY;
 }

double TradeExecutor::GetPositionSL(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      return PositionGetDouble(POSITION_SL);
     }
   return 0;
 }

double TradeExecutor::GetPositionTP(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      return PositionGetDouble(POSITION_TP);
     }
   return 0;
 }

double TradeExecutor::GetPositionVolume(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      return PositionGetDouble(POSITION_VOLUME);
     }
   return 0;
 }

bool TradeExecutor::IsPositionByEA(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      return PositionGetInteger(POSITION_MAGIC) == Config::GetMagicNumber();
     }
   return false;
 }

string TradeExecutor::GetPositionComment(ulong ticket)
  {
   if(PositionSelectByTicket(ticket))
     {
      return PositionGetString(POSITION_COMMENT);
     }
   return "";
 }

void TradeExecutor::LogTrade(string action, string type, double price, double volume, double sl, double tp, string comment)
  {
   if(!Config::GetLogTrades()) return;
   
   string log = "TRADE | " + action + " | " + type + " | Price: " + DoubleToString(price, _Digits) +
                " | Volume: " + DoubleToString(volume, 2) +
                " | SL: " + DoubleToString(sl, _Digits) +
                " | TP: " + DoubleToString(tp, _Digits) +
                " | " + comment;
   
   Print(log);
 }
//+------------------------------------------------------------------+