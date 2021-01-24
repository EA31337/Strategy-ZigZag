/**
 * @file
 * Implements ZigZag strategy based on the ZigZag indicator.
 */

// User input params.
INPUT string __ZigZag_Parameters__ = "-- ZigZag strategy params --";  // >>> ZIGZAG <<<
INPUT float ZigZag_LotSize = 0;                                       // Lot size
INPUT int ZigZag_SignalOpenMethod = 0;                                // Signal open method (0-31)
INPUT float ZigZag_SignalOpenLevel = 0.0f;                            // Signal open level
INPUT int ZigZag_SignalOpenFilterMethod = 1;                          // Signal open filter method
INPUT int ZigZag_SignalOpenBoostMethod = 0;                           // Signal open boost method
INPUT int ZigZag_SignalCloseMethod = 0;                               // Signal close method (0-31)
INPUT float ZigZag_SignalCloseLevel = 0.0f;                           // Signal close level
INPUT int ZigZag_PriceStopMethod = 0;                                 // Price stop method
INPUT float ZigZag_PriceStopLevel = 0;                                // Price stop level
INPUT int ZigZag_TickFilterMethod = 1;                                // Tick filter method
INPUT float ZigZag_MaxSpread = 4.0;                                   // Max spread to trade (pips)
INPUT int ZigZag_Shift = 0;                                           // Shift (relative to the current bar)
INPUT int ZigZag_OrderCloseTime = -20;                                // Order close time in mins (>0) or bars (<0)
INPUT string __ZigZag_Indi_ZigZag_Parameters__ =
    "-- ZigZag strategy: ZigZag indicator params --";  // >>> ZigZag strategy: ZigZag indicator <<<
INPUT int ZigZag_Indi_ZigZag_Depth = 12;               // Depth
INPUT int ZigZag_Indi_ZigZag_Deviation = 5;            // Deviation
INPUT int ZigZag_Indi_ZigZag_Backstep = 3;             // Backstep
INPUT int ZigZag_Indi_ZigZag_Shift = 0;                // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_ZigZag_Params_Defaults : ZigZagParams {
  Indi_ZigZag_Params_Defaults()
      : ZigZagParams(::ZigZag_Indi_ZigZag_Depth, ::ZigZag_Indi_ZigZag_Deviation, ::ZigZag_Indi_ZigZag_Backstep,
                     ::ZigZag_Indi_ZigZag_Shift) {}
} indi_zigzag_defaults;

// Defines struct with default user strategy values.
struct Stg_ZigZag_Params_Defaults : StgParams {
  Stg_ZigZag_Params_Defaults()
      : StgParams(::ZigZag_SignalOpenMethod, ::ZigZag_SignalOpenFilterMethod, ::ZigZag_SignalOpenLevel,
                  ::ZigZag_SignalOpenBoostMethod, ::ZigZag_SignalCloseMethod, ::ZigZag_SignalCloseLevel,
                  ::ZigZag_PriceStopMethod, ::ZigZag_PriceStopLevel, ::ZigZag_TickFilterMethod, ::ZigZag_MaxSpread,
                  ::ZigZag_Shift, ::ZigZag_OrderCloseTime) {}
} stg_zigzag_defaults;

// Struct to define strategy parameters to override.
struct Stg_ZigZag_Params : StgParams {
  ZigZagParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_ZigZag_Params(ZigZagParams &_iparams, StgParams &_sparams)
      : iparams(indi_zigzag_defaults, _iparams.tf), sparams(stg_zigzag_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_ZigZag : public Strategy {
 public:
  Stg_ZigZag(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_ZigZag *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    ZigZagParams _indi_params(indi_zigzag_defaults, _tf);
    StgParams _stg_params(stg_zigzag_defaults);
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<ZigZagParams>(_indi_params, _tf, indi_zigzag_m1, indi_zigzag_m5, indi_zigzag_m15, indi_zigzag_m30,
                                  indi_zigzag_h1, indi_zigzag_h4, indi_zigzag_h8);
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
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_ZigZag *_indi = Data();
    bool _is_valid = _indi[_shift].IsValid() && _indi[_shift + 1].IsValid() && _indi[_shift + 2].IsValid();
    bool _result = _is_valid;
    if (_is_valid) {
      switch (_cmd) {
        case ORDER_TYPE_BUY:
          _result &= _indi.GetMax<double>(_shift, (int)_level + 1) > 0;
          _result &= fmax(_indi[_shift][(int)ZIGZAG_LOWMAP], _indi[_shift + 1][(int)ZIGZAG_LOWMAP]) > 0;
          break;
        case ORDER_TYPE_SELL:
          _result &= _indi.GetMax<double>(_shift, (int)_level + 1) > 0;
          _result &= fmax(_indi[_shift][(int)ZIGZAG_HIGHMAP], _indi[_shift + 1][(int)ZIGZAG_HIGHMAP]) > 0;
          break;
      }
    }
    return _result;
  }

  /**
   * Gets price stop value for profit take or stop loss.
   */
  float PriceStop(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Indi_ZigZag *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    if (_is_valid) {
      switch (_method) {
        case 1:
          _result = _indi[CURR][(int)ZIGZAG_BUFFER];
          _result += _trail * _direction;
          break;
        case 2:
          _result = _indi[CURR][(int)ZIGZAG_HIGHMAP];
          _result += _trail * _direction;
          break;
        case 3:
          _result = _indi[CURR][(int)ZIGZAG_LOWMAP];
          _result += _trail * _direction;
          break;
        case 4:
          // @todo: Add min, but avoid zeros.
          _result = _direction > 0 ? _indi[CURR].GetMax<double>() : _indi[CURR][(int)ZIGZAG_BUFFER];
          _result += _trail * _direction;
          break;
        case 5: {
          int _bar_count = (int)_level * 10;
          _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest<double>(_bar_count))
                                   : _indi.GetPrice(PRICE_LOW, _indi.GetLowest<double>(_bar_count));
          break;
        }
      }
    }
    return (float)_result;
  }
};
