//+------------------------------------------------------------------+
//|                                                       IAmFVG.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
enum FVG_DIR
{
   BULLISH,
   BEARISH
};
class IAmFVG
{
   public:
      FVG_DIR _fvgDirection;
      double _fvgLow; 
      double _fvgHigh; 
      bool IsActive;              
};


