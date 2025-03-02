//+------------------------------------------------------------------+
//|                                         SimpleTrailingRule.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

#include "..\..\ITrailingRule.mqh"

//+------------------------------------------------------------------+
//| シンプルなトレーリングストップルールの実装                         |
//+------------------------------------------------------------------+
class SimpleTrailingRule : public ITrailingRule
{
private:
    int m_trailingPips; // トレーリングストップのpips数
    
public:
    // コンストラクタ
    SimpleTrailingRule(int trailingPips = 200)
    {
        m_trailingPips = trailingPips;
    }
    
    // トレーリングストップを適用すべきかどうかを判断
    bool ShouldApplyTrailing(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        // 常にトレーリングを適用（実際の条件はここに実装）
        return true;
    }
    
    // トレーリングストップのストップロス価格を計算
    double CalculateTrailingStopPrice(string symbol, ENUM_ORDER_TYPE orderType, double currentPrice)
    {
        // 現在価格からm_trailingPips離れた位置にトレーリングストップを設定
        double points = SymbolInfoDouble(symbol, SYMBOL_POINT);
        double slDistance = m_trailingPips * points;
        int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        
        if(orderType == ORDER_TYPE_BUY)
            return NormalizeDouble(currentPrice - slDistance, digits);
        else
            return NormalizeDouble(currentPrice + slDistance, digits);
    }
}; 