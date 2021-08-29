/**
 * @file
 * Implements ZigZag strategy based on the ZigZag indicator.
 */

// User input params.
INPUT_GROUP("ZigZag strategy: strategy params");
INPUT float ZigZag_LotSize = 0;                // Lot size
INPUT int ZigZag_SignalOpenMethod = 0;         // Signal open method (-127-127)
INPUT float ZigZag_SignalOpenLevel = 0.0f;     // Signal open level
INPUT int ZigZag_SignalOpenFilterMethod = 32;  // Signal open filter method
INPUT int ZigZag_SignalOpenFilterTime = 9;     // Signal open filter time
INPUT int ZigZag_SignalOpenBoostMethod = 0;    // Signal open boost method
INPUT int ZigZag_SignalCloseMethod = 0;        // Signal close method (-127-127)
INPUT int ZigZag_SignalCloseFilter = 32;       // Signal close filter (-127-127)
INPUT float ZigZag_SignalCloseLevel = 0.0f;    // Signal close level
INPUT int ZigZag_PriceStopMethod = 1;          // Price stop method (0-127)
INPUT float ZigZag_PriceStopLevel = 0;         // Price stop level
INPUT int ZigZag_TickFilterMethod = 28;        // Tick filter method
INPUT float ZigZag_MaxSpread = 4.0;            // Max spread to trade (pips)
INPUT short ZigZag_Shift = 0;                  // Shift (relative to the current bar)
INPUT float ZigZag_OrderCloseLoss = 0;         // Order close loss
INPUT float ZigZag_OrderCloseProfit = 0;       // Order close profit
INPUT int ZigZag_OrderCloseTime = -30;         // Order close time in mins (>0) or bars (<0)
INPUT_GROUP("ZigZag strategy: ZigZag indicator params");
INPUT int ZigZag_Indi_ZigZag_Depth = 2;      // Depth
INPUT int ZigZag_Indi_ZigZag_Deviation = 1;  // Deviation
INPUT int ZigZag_Indi_ZigZag_Backstep = 1;   // Backstep
INPUT int ZigZag_Indi_ZigZag_Shift = 0;      // Shift

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
                  ::ZigZag_SignalOpenBoostMethod, ::ZigZag_SignalCloseMethod, ::ZigZag_SignalCloseFilter,
                  ::ZigZag_SignalCloseLevel, ::ZigZag_PriceStopMethod, ::ZigZag_PriceStopLevel,
                  ::ZigZag_TickFilterMethod, ::ZigZag_MaxSpread, ::ZigZag_Shift) {
    Set(STRAT_PARAM_LS, ZigZag_LotSize);
    Set(STRAT_PARAM_OCL, ZigZag_OrderCloseLoss);
    Set(STRAT_PARAM_OCP, ZigZag_OrderCloseProfit);
    Set(STRAT_PARAM_OCT, ZigZag_OrderCloseTime);
    Set(STRAT_PARAM_SOFT, ZigZag_SignalOpenFilterTime);
  }
} stg_zigzag_defaults;

// Struct to define strategy parameters to override.
struct Stg_ZigZag_Params : StgParams {
  ZigZagParams iparams;
  StgParams sparams;

  // Struct constructors.
  Stg_ZigZag_Params(ZigZagParams &_iparams, StgParams &_sparams)
      : iparams(indi_zigzag_defaults, _iparams.tf.GetTf()), sparams(stg_zigzag_defaults) {
    iparams = _iparams;
    sparams = _sparams;
  }
};

#ifdef __config__
// Loads pair specific param values.
#include "config/H1.h"
#include "config/H4.h"
#include "config/H8.h"
#include "config/M1.h"
#include "config/M15.h"
#include "config/M30.h"
#include "config/M5.h"
#endif

class Stg_ZigZag : public Strategy {
 public:
  Stg_ZigZag(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_ZigZag *Init(ENUM_TIMEFRAMES _tf = NULL) {
    // Initialize strategy initial values.
    ZigZagParams _indi_params(indi_zigzag_defaults, _tf);
    StgParams _stg_params(stg_zigzag_defaults);
#ifdef __config__
    SetParamsByTf<ZigZagParams>(_indi_params, _tf, indi_zigzag_m1, indi_zigzag_m5, indi_zigzag_m15, indi_zigzag_m30,
                                indi_zigzag_h1, indi_zigzag_h4, indi_zigzag_h8);
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_zigzag_m1, stg_zigzag_m5, stg_zigzag_m15, stg_zigzag_m30,
                             stg_zigzag_h1, stg_zigzag_h4, stg_zigzag_h8);
#endif
    // Initialize indicator.
    ZigZagParams zigzag_params(_indi_params);
    _stg_params.SetIndicator(new Indi_ZigZag(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams;
    Strategy *_strat = new Stg_ZigZag(_stg_params, _tparams, _cparams, "ZigZag");
    return _strat;
  }

  /**
   * Check strategy's opening signal.
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Indi_ZigZag *_indi = GetIndicator();
    bool _result =
        _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift) + _indi.GetFlag(INDI_ENTRY_FLAG_IS_VALID, _shift + 2);
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    IndicatorSignal _signals = _indi.GetSignals(4, _shift);
    float _hm = (float)fmax4(_indi[_shift][(int)ZIGZAG_HIGHMAP], _indi[_shift + 1][(int)ZIGZAG_HIGHMAP],
                             _indi[_shift + 2][(int)ZIGZAG_HIGHMAP], _indi[_shift + 4][(int)ZIGZAG_HIGHMAP]);
    float _lm = (float)fmin4(_indi[_shift][(int)ZIGZAG_LOWMAP], _indi[_shift + 1][(int)ZIGZAG_LOWMAP],
                             _indi[_shift + 2][(int)ZIGZAG_LOWMAP], _indi[_shift + 4][(int)ZIGZAG_LOWMAP]);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result &= _hm > 0 && Open[_shift] < _hm;
        _result &= _lm == 0;
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
      case ORDER_TYPE_SELL:
        _result &= _lm > 0 && Open[_shift] > _lm;
        _result &= _hm == 0;
        _result &= _method > 0 ? _signals.CheckSignals(_method) : _signals.CheckSignalsAll(-_method);
        break;
    }
    return _result;
  }
};
