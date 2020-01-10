//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements ZigZag strategy based on the ZigZag indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_ZigZag.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
string __ZigZag_Parameters__ = "-- ZigZag strategy params --";  // >>> ZIGZAG <<<
int ZigZag_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
int ZigZag_Depth = 0;      // Depth
int ZigZag_Deviation = 0;  // Deviation
int ZigZag_Backstep = 0;   // Deviation
int ZigZag_Shift = 0;      // Shift (relative to the current bar)
ENUM_TRAIL_TYPE ZigZag_TrailingStopMethod = 22;                // Trail stop method
ENUM_TRAIL_TYPE ZigZag_TrailingProfitMethod = 1;               // Trail profit method
double ZigZag_SignalOpenLevel = 0.00000000;                    // Signal open level
int ZigZag1_SignalBaseMethod = 0;                              // Signal base method (0-31)
int ZigZag1_OpenCondition1 = 0;                                // Open condition 1 (0-1023)
int ZigZag1_OpenCondition2 = 0;                                // Open condition 2 (0-)
ENUM_MARKET_EVENT ZigZag1_CloseCondition = C_ZIGZAG_BUY_SELL;  // Close condition for M1
double ZigZag_MaxSpread = 6.0;                                 // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_ZigZag_Params : Stg_Params {
  unsigned int ZigZag_Period;
  ENUM_APPLIED_PRICE ZigZag_Applied_Price;
  int ZigZag_Shift;
  ENUM_TRAIL_TYPE ZigZag_TrailingStopMethod;
  ENUM_TRAIL_TYPE ZigZag_TrailingProfitMethod;
  double ZigZag_SignalOpenLevel;
  long ZigZag_SignalBaseMethod;
  long ZigZag_SignalOpenMethod1;
  long ZigZag_SignalOpenMethod2;
  double ZigZag_SignalCloseLevel;
  ENUM_MARKET_EVENT ZigZag_SignalCloseMethod1;
  ENUM_MARKET_EVENT ZigZag_SignalCloseMethod2;
  double ZigZag_MaxSpread;

  // Constructor: Set default param values.
  Stg_ZigZag_Params()
      : ZigZag_Period(::ZigZag_Period),
        ZigZag_Applied_Price(::ZigZag_Applied_Price),
        ZigZag_Shift(::ZigZag_Shift),
        ZigZag_TrailingStopMethod(::ZigZag_TrailingStopMethod),
        ZigZag_TrailingProfitMethod(::ZigZag_TrailingProfitMethod),
        ZigZag_SignalOpenLevel(::ZigZag_SignalOpenLevel),
        ZigZag_SignalBaseMethod(::ZigZag_SignalBaseMethod),
        ZigZag_SignalOpenMethod1(::ZigZag_SignalOpenMethod1),
        ZigZag_SignalOpenMethod2(::ZigZag_SignalOpenMethod2),
        ZigZag_SignalCloseLevel(::ZigZag_SignalCloseLevel),
        ZigZag_SignalCloseMethod1(::ZigZag_SignalCloseMethod1),
        ZigZag_SignalCloseMethod2(::ZigZag_SignalCloseMethod2),
        ZigZag_MaxSpread(::ZigZag_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_ZigZag : public Strategy {
 public:
  Stg_ZigZag(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_ZigZag *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_ZigZag_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_ZigZag_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_ZigZag_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_ZigZag_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_ZigZag_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_ZigZag_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_ZigZag_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    ZigZag_Params adx_params(_params.ZigZag_Period, _params.ZigZag_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_ZigZag);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_ZigZag(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.ZigZag_SignalBaseMethod, _params.ZigZag_SignalOpenMethod1,
                       _params.ZigZag_SignalOpenMethod2, _params.ZigZag_SignalCloseMethod1,
                       _params.ZigZag_SignalCloseMethod2, _params.ZigZag_SignalOpenLevel,
                       _params.ZigZag_SignalCloseLevel);
    sparams.SetStops(_params.ZigZag_TrailingProfitMethod, _params.ZigZag_TrailingStopMethod);
    sparams.SetMaxSpread(_params.ZigZag_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_ZigZag(sparams, "ZigZag");
    return _strat;
  }

  /**
   * Check if ZigZag indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double zigzag_0 = ((Indi_ZigZag *)this.Data()).GetValue(0);
    double zigzag_1 = ((Indi_ZigZag *)this.Data()).GetValue(1);
    double zigzag_2 = ((Indi_ZigZag *)this.Data()).GetValue(2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        /*
          bool _result = ZigZag_0[LINE_LOWER] != 0.0 || ZigZag_1[LINE_LOWER] != 0.0 || ZigZag_2[LINE_LOWER] != 0.0;
          if (METHOD(_signal_method, 0)) _result &= Open[CURR] > Close[CURR];
          if (METHOD(_signal_method, 1)) _result &= !ZigZag_On_Sell(tf);
          if (METHOD(_signal_method, 2)) _result &= ZigZag_On_Buy(fmin(period + 1, M30));
          if (METHOD(_signal_method, 3)) _result &= ZigZag_On_Buy(M30);
          if (METHOD(_signal_method, 4)) _result &= ZigZag_2[LINE_LOWER] != 0.0;
          if (METHOD(_signal_method, 5)) _result &= !ZigZag_On_Sell(M30);
          */
        break;
      case ORDER_TYPE_SELL:
        /*
          bool _result = ZigZag_0[LINE_UPPER] != 0.0 || ZigZag_1[LINE_UPPER] != 0.0 || ZigZag_2[LINE_UPPER] != 0.0;
          if (METHOD(_signal_method, 0)) _result &= Open[CURR] < Close[CURR];
          if (METHOD(_signal_method, 1)) _result &= !ZigZag_On_Buy(tf);
          if (METHOD(_signal_method, 2)) _result &= ZigZag_On_Sell(fmin(period + 1, M30));
          if (METHOD(_signal_method, 3)) _result &= ZigZag_On_Sell(M30);
          if (METHOD(_signal_method, 4)) _result &= ZigZag_2[LINE_UPPER] != 0.0;
          if (METHOD(_signal_method, 5)) _result &= !ZigZag_On_Buy(M30);
          */
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
