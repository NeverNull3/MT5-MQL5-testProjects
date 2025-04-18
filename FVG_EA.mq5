//+------------------------------------------------------------------+
//|                                                       FVG_EA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Lessons/IAMFVG.mqh>

enum POSITION_DIRECTION
  {
   LONG,
   SHORT
  };
//++++++++++++++++++++++INPUTS++++++++++++++++++++++
input double Lots = 0.1; //Position size

input double TpPercent = 3.0; //Size of Take profit

input double SlPercent = 1.0; //Size of Stop loss

input ulong _magic = 1337; //Magic number

input int SlLookBackBars = 10; //To find l/h for sl

input int MaxFvgsOnScreen = 20; //Max count of fvgs to work with

input bool EnableTrailingSl = false; //Trailing sl


//++++++++++++++++++++++CLASSES++++++++++++++++++++++
CTrade trade;

//++++++++++++++++++++++ARRAYS++++++++++++++++++++++
IAmFVG fvgs[];

MqlRates bars[];

//++++++++++++++++++++++POSITIONS++++++++++++++++++++++
ulong _currentPositionTicket = 0;

double _currentPositionEntryPrice = 0;

double ask = 0;

double bid = 0;

bool trailingSlEnabled = false;

POSITION_DIRECTION _posDir = LONG;

//++++++++++++++++++++++LOGIC++++++++++++++++++++++
int OnInit()
{
   
   ArrayResize(fvgs, 0);
   ArraySetAsSeries(bars, true);
   return(INIT_SUCCEEDED);
   if(EnableTrailingSl){
      trailingSlEnabled = true;
   }
}

void OnDeinit(const int reason)
{
   
   
}

void OnTick()
{
   if(IsPositionOpen(_Symbol)){
      return;
   }
   
   FindFVG();
   
   OpenPosition();
}

IAmFVG _currentFVG;

void FindFVG(){
   
      if(Bars(_Symbol, PERIOD_CURRENT) < 4)
        return;
      CopyRates(_Symbol, PERIOD_CURRENT, 1, 4, bars);
      
      if(bars[0].low > bars[2].high)
      {
        _currentFVG._fvgDirection = BULLISH;
        
        _currentFVG._fvgLow = bars[2].high;
        _currentFVG._fvgHigh = bars[0].low;
        
        _currentFVG.IsActive = true;
        
        ArrayResize(fvgs, ArraySize(fvgs) + 1);
        fvgs[ArraySize(fvgs) - 1] = _currentFVG;
        
        Print("_currentFVG direction: " + _currentFVG._fvgDirection,"_currentFVG high and low prices: " + _currentFVG._fvgHigh + " " + _currentFVG._fvgLow);
        Print("The bullish FVG Finded" + "time: " + bars[1].time + " High of FVG: " + bars[0].low + " Low of FVG: " + bars[2].high);
        return;
      }
      if(bars[0].high < bars[2].low)
      {
        _currentFVG._fvgDirection = BEARISH;
        
        _currentFVG._fvgLow = bars[0].high;
        _currentFVG._fvgHigh = bars[2].low;
        
        _currentFVG.IsActive = true;
        
        ArrayResize(fvgs, ArraySize(fvgs) + 1);
        fvgs[ArraySize(fvgs) - 1] = _currentFVG;
        
        Print("_currentFVG direction: " + _currentFVG._fvgDirection,"_currentFVG high and low prices: " + _currentFVG._fvgHigh + " " + _currentFVG._fvgLow);
        Print("The bearish FVG Finded " + "time: " + bars[1].time + " High of FVG: " + bars[2].low + " Low of FVG: " + bars[0].high);
      }
      if(ArraySize(fvgs) == 3){
         Print(ArraySize(fvgs));
      }
}


void Buy(){
   ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double slPrice = iLow(_Symbol, PERIOD_CURRENT, iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, SlLookBackBars, 1));
   double tpPrice = 0;
   
   if(TpPercent > 0){
      tpPrice = ask + ((ask-slPrice)*TpPercent);
      
   }
   
   if(trade.Buy(Lots, _Symbol, ask, slPrice, tpPrice)){
      _posDir = LONG;
   }
   else{
      Print("Error BUY: ", trade.ResultRetcodeDescription());
   }
   
}
void Sell(){
   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   
   double slPrice = iHigh(_Symbol, PERIOD_CURRENT, iHighest(_Symbol, PERIOD_CURRENT, MODE_HIGH, SlLookBackBars, 1));
   double tpPrice = 0;
   
   if(TpPercent > 0){
      tpPrice = ask - ((slPrice - ask)*TpPercent);
      
   }

   if(trade.Sell(Lots, _Symbol, bid, slPrice, tpPrice)){
      _posDir = SHORT;
   }
   else{
      Print("Error SELL: ", trade.ResultRetcodeDescription());
   }
  
}

void OpenPosition(){
   if(ArraySize(fvgs)<= MaxFvgsOnScreen){
      ArrayRemove(fvgs, 0, ArraySize(fvgs)-1);
   }

   ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   for(int i=0;i<ArraySize(fvgs);i++)
   {
      if(fvgs[i].IsActive){
         if(fvgs[i]._fvgDirection == BULLISH && bid >= fvgs[i]._fvgLow && bid <= fvgs[i]._fvgHigh){
            Buy();
            fvgs[i].IsActive = false;
            return;
            Print("Size of fvgs: " + ArraySize(fvgs));
         }
         if(fvgs[i]._fvgDirection == BEARISH && ask >= fvgs[i]._fvgLow && ask <= fvgs[i]._fvgHigh){
            Sell();
            fvgs[i].IsActive = false;
            Print("Size of fvgs: " + ArraySize(fvgs));
            return;
         }
      }
   }
}

bool IsPositionOpen(string symbol)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        _currentPositionTicket = PositionGetTicket(i);
        if (PositionGetString(POSITION_SYMBOL) == symbol)
            return true;
    }
    return false;
}

