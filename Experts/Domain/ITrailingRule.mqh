//+------------------------------------------------------------------+
//|                                                ITrailingRule.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

//+------------------------------------------------------------------+
//| トレーリングストップルールのインターフェース                       |
//+------------------------------------------------------------------+
class ITrailingRule
{
public:
    // 仮想デストラクタ
    virtual ~ITrailingRule() {}
    
    // トレーリングストップを適用すべきかどうかを判断
    virtual bool ShouldApplyTrailing(string symbol, ENUM_TIMEFRAMES timeframe) = 0;
    
    // トレーリングストップのストップロス価格を計算
    virtual double CalculateTrailingStopPrice(string symbol, ENUM_ORDER_TYPE orderType, double currentPrice) = 0;
}; 