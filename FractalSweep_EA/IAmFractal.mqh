//+------------------------------------------------------------------+
//|                                                   IAmFractal.mqh |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
enum FRACTAL_DIRECTION
{
   FRAC_HIGH,
   FRAC_LOW
};

class IAmFractal{
   public:
      FRACTAL_DIRECTION _fractalDirection;
      double _fractalPrice;
      bool _isfractalActual;
   
}