/**
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_ZigZag_Params_M15 : IndiZigZagParams {
  Indi_ZigZag_Params_M15() : IndiZigZagParams(indi_zigzag_defaults, PERIOD_M15) {
    backstep = 1;
    depth = 14;
    deviation = 1;
    shift = 0;
  }
} indi_zigzag_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_ZigZag_Params_M15 : StgParams {
  // Struct constructor.
  Stg_ZigZag_Params_M15() : StgParams(stg_zigzag_defaults) {
    lot_size = 0;
    signal_open_method = 2;
    signal_open_level = (float)0.0;
    signal_open_boost = 0;
    signal_close_method = 2;
    signal_close_level = (float)0;
    price_profit_method = 60;
    price_profit_level = (float)6;
    price_stop_method = 60;
    price_stop_level = (float)6;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_zigzag_m15;
