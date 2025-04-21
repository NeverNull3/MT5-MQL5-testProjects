//+------------------------------------------------------------------+
//|                                               FractalSweepEA.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>

#include <Lessons/IAmFractal.mqh>;

enum POSITION_DIRECTION
{
   LONG,
   SHORT
};
enum STOPLOSS_TYPE
{
   FIXED,
   STRUCTURE,
   TRAILING
};
//============<INPUTS>============

sinput string s1; //-----------POSITION PROPERTIES-------------

input double RiskRatio = 1.0; //Risk ratio, %

input ulong _magic = 1337; //Magic number

input STOPLOSS_TYPE _slType = FIXED;

sinput string s2; //------Fixed Stop-loss------

input double TpSize = 260; //Take-profit size(pips)

input double SlSize = 130; //Stop-loss size(pips)

sinput string s3; //------Structure Stop-loss------

input int SlLookBackBars = 20; 

input double TpMultiplier = 2; 

sinput string s4; //------Trailing Stop-loss------

input double startSlSize = 130;//Start Sl size(pips)

sinput string s5; //-----------FRACTAL SWEEP STRATEGY PROPERTIES-------------

input int FractalPeriod = 5; //Fractal forming period

input int LookBackBars = 10; 


sinput string s6; //-----------DRAWING PROPERTIES-------------

input bool DrawFractals = true;

input int MaxFractalsDrawn = 60; 

//============<VARIABLES>============

//-----------Position Properties-------------
ulong _currentPositionTicket = 0;

double ask = 0;

double bid = 0;

POSITION_DIRECTION _posDir = LONG;

CTrade trade;

//-----------Fractal Sweep Strategy Properties-------------
IAmFractal _currentFractal;

IAmFractal _fractals[];

MqlRates bars[];

MqlRates barsToOpenTrade[];
//-----------Drawing Properties-------------

bool _drawFractals = true;

int _drawnFractals = 0;

//============<Logic>============

int OnInit()
{
   if(!DrawFractals){
      _drawFractals = false; 
   }
   
   ArrayResize(_fractals, 0);
   ArraySetAsSeries(_fractals, true);
  
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   
   
}

void OnTick()
{
   if(IsPositionOpen(_Symbol)){
      TrailingStoploss(_currentPositionTicket);
      return;
   }
   
   FindFractals();
   
   FindPosition();
}
//-----------Position Properties-------------
void FindPosition(){
   if(Bars(_Symbol, PERIOD_CURRENT) < 6)
        return;
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 2, barsToOpenTrade);
  

   for(int i=ArraySize(_fractals);i>=1;i--)
   {
      //Candle closes swith sweep of fractal
      if(_fractals[i-1]._isfractalActual
       && _fractals[i-1]._fractalDirection == FRAC_HIGH
       && barsToOpenTrade[0].high > _fractals[i-1]._fractalPrice
       && barsToOpenTrade[0].open <_fractals[i-1]._fractalPrice
       && barsToOpenTrade[0].close <_fractals[i-1]._fractalPrice){
         //SELL
         Print("SELL!");
         Sell();
         _fractals[i-1]._isfractalActual = false;
         continue;
      }
      else if(_fractals[i-1]._isfractalActual
       && _fractals[i-1]._fractalDirection == FRAC_LOW
       && barsToOpenTrade[0].low < _fractals[i-1]._fractalPrice
       && barsToOpenTrade[0].close > _fractals[i-1]._fractalPrice
       && barsToOpenTrade[0].open > _fractals[i-1]._fractalPrice){
         //BUY
         Print("BUY!");
         Buy();
         _fractals[i-1]._isfractalActual = false;
       }
      else if(_fractals[i-1]._isfractalActual
       && _fractals[i-1]._fractalDirection == FRAC_LOW
       && barsToOpenTrade[0].close < _fractals[i-1]._fractalPrice
       && barsToOpenTrade[0].open > _fractals[i-1]._fractalPrice){
         _fractals[i-1]._isfractalActual = false;
      }
      else if(_fractals[i-1]._isfractalActual
       && _fractals[i-1]._fractalDirection == FRAC_HIGH
       && barsToOpenTrade[0].close > _fractals[i-1]._fractalPrice
       && barsToOpenTrade[0].open < _fractals[i-1]._fractalPrice){
         _fractals[i-1]._isfractalActual = false;
      }
      
   }
}

void Buy(){
   ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   
   double slPrice = 0;
   double tpPrice = 0;
   double _lots = 0;
   
   switch(_slType)
   {
      case FIXED:
         slPrice = ask - SlSize * _Point;
         tpPrice = ask + TpSize * _Point;
         _lots = (AccountInfoDouble(ACCOUNT_BALANCE)*(RiskRatio/100))/(SlSize);
         break;
      case STRUCTURE:
         slPrice = iLow(_Symbol, PERIOD_CURRENT, iLowest(_Symbol,PERIOD_CURRENT, MODE_LOW, SlLookBackBars, 1));
         tpPrice = ask + (ask - slPrice) * TpMultiplier;
         _lots = (AccountInfoDouble(ACCOUNT_BALANCE)*(RiskRatio/100))/((ask-slPrice)*100000); //1 lot size = 100000
         break;
      case TRAILING:
         slPrice = ask - startSlSize * _Point;
         _lots = (AccountInfoDouble(ACCOUNT_BALANCE)*(RiskRatio/100))/startSlSize;
         break; 
   }
   _lots = NormalizeDouble(_lots, 2);
   if(trade.Buy(_lots, _Symbol, ask, slPrice, tpPrice)){
      _posDir = LONG;
   }
   else{
      Print("Error BUY: ", trade.ResultRetcodeDescription());
   }
   
}
void Sell(){
   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   
   double slPrice = 0;
   double tpPrice = 0;
   double _lots = 0;
   
   switch(_slType)
   {
      case FIXED:
         slPrice = bid + SlSize * _Point;
         tpPrice = bid - TpSize * _Point;
         _lots = (AccountInfoDouble(ACCOUNT_BALANCE)*(RiskRatio/100))/SlSize;
        break;
        
      case STRUCTURE:
         slPrice = iHigh(_Symbol, PERIOD_CURRENT, iHighest(_Symbol,PERIOD_CURRENT, MODE_HIGH, SlLookBackBars, 1));
         Print(slPrice);
         tpPrice = bid - (slPrice-bid) * TpMultiplier;
         _lots = (AccountInfoDouble(ACCOUNT_BALANCE)*(RiskRatio/100))/((slPrice-bid)*100000); //1 lot size = 100000
      break;
      case TRAILING:
         slPrice = bid + startSlSize * _Point;
         _lots = (AccountInfoDouble(ACCOUNT_BALANCE)*(RiskRatio/100))/startSlSize;
         break;
   }
   Print(_lots);
   _lots = NormalizeDouble(_lots, 2);
   if(trade.Sell(_lots, _Symbol, bid, slPrice, tpPrice)){
      _posDir = SHORT;
   }
   else{
      Print("Error SELL: ", trade.ResultRetcodeDescription());
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
void TrailingStoploss(int positionTicket){

   if(_slType == TRAILING){
      if(_posDir == LONG){
         double sl = iLow(_Symbol, PERIOD_CURRENT, 1);
         double posSl = PositionGetDouble(POSITION_SL);
         double posTp = PositionGetDouble(POSITION_TP);
         if(sl > posSl)
            trade.PositionModify(positionTicket,sl,posTp);
      }
      else
        {
         double sl = iHigh(_Symbol, PERIOD_CURRENT, 1);
         double posSl = PositionGetDouble(POSITION_SL);
         double posTp = PositionGetDouble(POSITION_TP);
         if(sl < posSl)
            trade.PositionModify(positionTicket,sl,posTp);
        }
   }
}
//-----------Fractal Sweep Strategy Properties-------------
void FindFractals(){
   
   if(Bars(_Symbol, PERIOD_CURRENT) < 6)
        return;
   CopyRates(_Symbol, PERIOD_CURRENT, 1, LookBackBars+3, bars);
   
   for(int i=LookBackBars;i>=2;i--)
   {
     if(i + 2 >= Bars(_Symbol, PERIOD_CURRENT)){
      continue;
     }
      double high1 = bars[i + 2].high;
      double high2 = bars[i + 1].high;
      double high3 = bars[i].high;
      double high4 = bars[i - 1].high;
      double high5 = bars[i - 2].high;

      double low1 = bars[i + 2].low;
      double low2 = bars[i + 1].low;
      double low3 = bars[i].low;
      double low4 = bars[i - 1].low;
      double low5 = bars[i - 2].low;
      //UP FRACTALS
      if(high3 > high1 && high3 > high2 && high3 > high4 && high3 > high5)
      {
         if(!IsFractalStored(_fractals, high3))
         {
            Print("New UPfractal: " + "Time: " + bars[i].time + " Price: " + high3 );
            
            _currentFractal._fractalDirection = FRAC_HIGH;
            _currentFractal._fractalPrice = high3;
            _currentFractal._isfractalActual = true;
            
            ArrayResize(_fractals, ArraySize(_fractals) + 1);
            _fractals[ArraySize(_fractals) - 1] = _currentFractal;
            
            Print("Current size of Fractals: " + ArraySize(_fractals));
            
            //Draw UpFractal:
            string upArrowName = "UpFractal_" + IntegerToString(bars[i].time);
            DrawFractalArrow(upArrowName, bars[i].time, high3 + 10 * _Point, clrRed, 0);
         }
      }
      //DOWN FRACTALS
      if(low3 < low1 && low3 < low2 && low3 < low4 && low3 < low5)
      {
         if(!IsFractalStored(_fractals, low3))
         {
            Print("New Downfractal: " + "Time: " + bars[i].time + " Price: " + low3);
            
            _currentFractal._fractalDirection = FRAC_LOW;
            _currentFractal._fractalPrice = low3;
            _currentFractal._isfractalActual = true;
            
            ArrayResize(_fractals, ArraySize(_fractals) + 1);
            _fractals[ArraySize(_fractals) - 1] = _currentFractal;
            Print("Current size of Fractals: " + ArraySize(_fractals));

            //Draw DownFractal:
            string downArrowName = "DownFractal_" + IntegerToString(bars[i].time);
            DrawFractalArrow(downArrowName, bars[i].time, low3 - 10 * _Point, clrLime, 1);
         }
      }
   }

}
bool IsFractalStored(IAmFractal &arr[], double value)
{
   for(int i = 0; i < ArraySize(arr); i++)
   {
      if(arr[i]._fractalPrice == value){
         return true;
      }
   }
   return false;
}


//-----------Drawing Properties-------------
void DrawFractalArrow(string name, datetime time, double price, color clr, int direction)
{
   // direction: 0 = down (above high), 1 = up (below low)
   if(_drawnFractals >= MaxFractalsDrawn){
      return;
   }
   if(ObjectFind(0, name) != -1)
      ObjectDelete(0, name);
   
   ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   
   if(direction == 0)
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 234); // Down arrow
   else
      ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 233); // Up arrow
   _drawnFractals++;
}
