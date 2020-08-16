/**
 * @file
 * Implements ZigZag strategy based on the ZigZag indicator.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_ZigZag.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT float ZigZag_LotSize = 0;                        // Lot size
INPUT int ZigZag_SignalOpenMethod = 0;                 // Signal open method (0-31)
INPUT float ZigZag_SignalOpenLevel = 0.00000000;       // Signal open level
INPUT int ZigZag_SignalOpenFilterMethod = 0.00000000;  // Signal open filter method
INPUT int ZigZag_SignalOpenBoostMethod = 0.00000000;   // Signal open boost method
INPUT int ZigZag_SignalCloseMethod = 0;                // Signal close method (0-31)
INPUT float ZigZag_SignalCloseLevel = 0.00000000;      // Signal close level
INPUT int ZigZag_PriceLimitMethod = 0;                 // Price limit method
INPUT float ZigZag_PriceLimitLevel = 0;                // Price limit level
INPUT int ZigZag_TickFilterMethod = 0;                 // Tick filter method
INPUT float ZigZag_MaxSpread = 6.0;                    // Max spread to trade (pips)
INPUT int ZigZag_Shift = 0;                            // Shift (relative to the current bar)
INPUT string __ZigZag_Indi_ZigZag_Parameters__ =
    "-- ZigZag strategy: ZigZag indicator params --";  // >>> ZigZag strategy: ZigZag indicator <<<
INPUT int ZigZag_Depth = 0;                            // Depth
INPUT int ZigZag_Deviation = 0;                        // Deviation
INPUT int ZigZag_Backstep = 0;                         // Deviation

// Structs.

// Defines struct with default user indicator values.
struct Indi_ZigZag_Params_Defaults : ZigZagParams {
  Indi_ZigZag_Params_Defaults() : ZigZagParams(::ZigZag_Depth, ::ZigZag_Deviation, ::ZigZag_Backstep) {}
} indi_zigzag_defaults;

// Defines struct to store indicator parameter values.
struct Indi_ZigZag_Params : public ZigZagParams {
  // Struct constructors.
  void Indi_ZigZag_Params(ZigZagParams &_params, ENUM_TIMEFRAMES _tf) : ZigZagParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_ZigZag_Params_Defaults : StgParams {
  Stg_ZigZag_Params_Defaults()
      : StgParams(::ZigZag_SignalOpenMethod, ::ZigZag_SignalOpenFilterMethod, ::ZigZag_SignalOpenLevel,
                  ::ZigZag_SignalOpenBoostMethod, ::ZigZag_SignalCloseMethod, ::ZigZag_SignalCloseLevel,
                  ::ZigZag_PriceLimitMethod, ::ZigZag_PriceLimitLevel, ::ZigZag_TickFilterMethod, ::ZigZag_MaxSpread,
                  ::ZigZag_Shift) {}
} stg_zigzag_defaults;

// Struct to define strategy parameters to override.
struct Stg_ZigZag_Params : StgParams {
  Indi_ZigZag_Params iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_ZigZag_Params(Indi_ZigZag_Params &_iparams, StgParams &_sparams)
      : iparams(indi_zigzag_defaults, _iparams.tf), sparams(stg_zigzag_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_H8.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_ZigZag : public Strategy {
 public:
  Stg_ZigZag(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_ZigZag *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Indi_ZigZag_Params _indi_params(indi_zigzag_defaults, _tf);
    StgParams _stg_params(stg_zigzag_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Indi_ZigZag_Params>(_indi_params, _tf, indi_zigzag_m1, indi_zigzag_m5, indi_zigzag_m15,
                                        indi_zigzag_m30, indi_zigzag_h1, indi_zigzag_h4, indi_zigzag_h8);
      SetParamsByTf<StgParams>(_stg_params, _tf, stg_zigzag_m1, stg_zigzag_m5, stg_zigzag_m15, stg_zigzag_m30,
                               stg_zigzag_h1, stg_zigzag_h4, stg_zigzag_h8);
    }
    // Initialize indicator.
    ZigZagParams zigzag_params(_indi_params);
    _stg_params.SetIndicator(new Indi_ZigZag(_indi_params));
    // Initialize strategy parameters.
    _stg_params.GetLog().SetLevel(_log_level);
    _stg_params.SetMagicNo(_magic_no);
    _stg_params.SetTf(_tf, _Symbol);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_ZigZag(_stg_params, "ZigZag");
    _stg_params.SetStops(_strat, _strat);
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Indi_ZigZag *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    double curr_buff = _indi[CURR].value[ZIGZAG_BUFFER];
    double prev_buff = _indi[PREV].value[ZIGZAG_BUFFER];
    double pprev_buff = _indi[PPREV].value[ZIGZAG_BUFFER];
    double curr_hmap = _indi[CURR].value[ZIGZAG_HIGHMAP];
    double prev_hmap = _indi[PREV].value[ZIGZAG_HIGHMAP];
    double pprev_hmap = _indi[PPREV].value[ZIGZAG_HIGHMAP];
    double curr_lmap = _indi[CURR].value[ZIGZAG_LOWMAP];
    double prev_lmap = _indi[PREV].value[ZIGZAG_LOWMAP];
    double pprev_lmap = _indi[PPREV].value[ZIGZAG_LOWMAP];
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result = (_indi[CURR].value[ZIGZAG_BUFFER] > 0 && _indi.GetLow(CURR) < _indi[CURR].value[ZIGZAG_BUFFER]) ||
                    (_indi[PREV].value[ZIGZAG_BUFFER] > 0 && _indi.GetLow(PREV) < _indi[PREV].value[ZIGZAG_BUFFER]) ||
                    (_indi[PPREV].value[ZIGZAG_BUFFER] > 0 && _indi.GetLow(PPREV) < _indi[PPREV].value[ZIGZAG_BUFFER]);
          if (METHOD(_method, 0))
            _result &= _indi[CURR].value[ZIGZAG_HIGHMAP] > 0 && _indi.GetLow(PREV) < _indi[CURR].value[ZIGZAG_HIGHMAP];
          if (METHOD(_method, 1))
            _result &= _indi[CURR].value[ZIGZAG_LOWMAP] > 0 && _indi.GetLow(PREV) < _indi[CURR].value[ZIGZAG_LOWMAP];
          break;
        case ORDER_TYPE_SELL:
          _result = (_indi[CURR].value[ZIGZAG_BUFFER] > 0 && _indi.GetHigh(CURR) > _indi[CURR].value[ZIGZAG_BUFFER]) ||
                    (_indi[PREV].value[ZIGZAG_BUFFER] > 0 && _indi.GetHigh(PREV) > _indi[PREV].value[ZIGZAG_BUFFER]) ||
                    (_indi[PPREV].value[ZIGZAG_BUFFER] > 0 && _indi.GetHigh(PPREV) > _indi[PPREV].value[ZIGZAG_BUFFER]);
          if (METHOD(_method, 0))
            _result &= _indi[CURR].value[ZIGZAG_HIGHMAP] > 0 && _indi.GetLow(PREV) > _indi[CURR].value[ZIGZAG_HIGHMAP];
          if (METHOD(_method, 1))
            _result &= _indi[CURR].value[ZIGZAG_LOWMAP] > 0 && _indi.GetLow(PREV) > _indi[CURR].value[ZIGZAG_LOWMAP];
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_ZigZag *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 0:
          _result = _indi[CURR].value[ZIGZAG_BUFFER];
          _result += _trail * _direction;
          break;
        case 1:
          _result = _indi[CURR].value[ZIGZAG_HIGHMAP];
          _result += _trail * _direction;
          break;
        case 2:
          _result = _indi[CURR].value[ZIGZAG_LOWMAP];
          _result += _trail * _direction;
          break;
        case 3:
          // @todo: Add min, but avoid zeros.
          _result =
              _direction > 0 ? _indi[CURR].value.GetMaxDbl(_indi.GetIDataType()) : _indi[CURR].value[ZIGZAG_BUFFER];
          _result += _trail * _direction;
          break;
        case 4: {
          int _bar_count = (int)_level * 10;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
          break;
        }
      }
    }
    return (float)_result;
  }
};
