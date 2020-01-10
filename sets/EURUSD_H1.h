//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_ZigZag_EURUSD_H1_Params : Stg_ZigZag_Params {
  Stg_ZigZag_EURUSD_H1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H1;
    ZigZag_Period = 2;
    ZigZag_Applied_Price = 3;
    ZigZag_Shift = 0;
    ZigZag_TrailingStopMethod = 6;
    ZigZag_TrailingProfitMethod = 11;
    ZigZag_SignalOpenLevel = 36;
    ZigZag_SignalBaseMethod = 0;
    ZigZag_SignalOpenMethod1 = 195;
    ZigZag_SignalOpenMethod2 = 0;
    ZigZag_SignalCloseLevel = 36;
    ZigZag_SignalCloseMethod1 = 1;
    ZigZag_SignalCloseMethod2 = 0;
    ZigZag_MaxSpread = 6;
  }
};
