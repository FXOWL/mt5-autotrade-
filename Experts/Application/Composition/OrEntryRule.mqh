//+------------------------------------------------------------------+
//|                                               OrEntryRule.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

#include "CompositeEntryRule.mqh"
#include "..\..\Domain\Entry\Price\MABuyStrategy.mqh"
#include "..\..\Domain\Entry\Price\MASellStrategy.mqh"

//+------------------------------------------------------------------+
//| いずれかのルールが満たされた場合にエントリーする複合ルール      |
//+------------------------------------------------------------------+
class OrEntryRule : public CompositeEntryRule
{
public:
    // コンストラクタ
    OrEntryRule(ENUM_ORDER_TYPE orderType) : CompositeEntryRule(orderType) {}
    
    // エントリー条件の評価（いずれかのルールが満たされた場合にtrue）
    bool ShouldEnter(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        if(m_ruleCount == 0)
            return false;
            
        // いずれかのルールをチェック
        for(int i = 0; i < m_ruleCount; i++)
        {
            // MABuyStrategyやMASellStrategyなどの具体的なクラスを想定
            // 実際にはルールの型に応じたキャストが必要
            if(m_rules[i] != NULL && ((MABuyStrategy*)m_rules[i]).ShouldEnter(symbol, timeframe))
                return true;
        }
        
        return false;
    }
}; 