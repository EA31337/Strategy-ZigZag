//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_ZigZag_EURUSD_M15_Params : Stg_ZigZag_Params {
  Stg_ZigZag_EURUSD_M15_Params() {
    symbol = "EURUSD";
    tf = PERIOD_M15;
    ZigZag_Depth = 0;
    ZigZag_Deviation = 0;
    ZigZag_Backstep = 0;
    ZigZag_Shift = 0;
    ZigZag_SignalOpenMethod = -63;
    ZigZag_SignalOpenLevel = 36;
    ZigZag_SignalCloseMethod = 1;
    ZigZag_SignalCloseLevel = 36;
    ZigZag_PriceLimitMethod = 0;
    ZigZag_PriceLimitLevel = 0;
    ZigZag_MaxSpread = 4;
  }
} stg_zigzag_m15;
