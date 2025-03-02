//+------------------------------------------------------------------+
//|                                            SpreadCondition.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"

#include "ITradeCondition.mqh"

/**
 * @brief スプレッド条件クラス
 */
class CSpreadCondition : public ITradeCondition
{
private:
    double m_spreadLimit;     // スプレッド上限（ポイント単位）
    string m_failureMessage;  // 条件不成立時のメッセージ

public:
    /**
     * @brief コンストラクタ
     * @param spreadLimit スプレッド上限値（ポイント単位）
     */
    CSpreadCondition(const double spreadLimit) : m_spreadLimit(spreadLimit), m_failureMessage("") {}
    
    /**
     * @brief 現在のスプレッドが上限値以下かチェック
     * @param symbol 通貨ペア
     * @param timeframe 時間枠（使用しない）
     * @return bool スプレッドが上限値以下ならtrue
     */
    bool Check(const string symbol, const ENUM_TIMEFRAMES timeframe)
    {
        double currentSpread = GetSpread(symbol);
        
        if(currentSpread <= m_spreadLimit)
            return true;
            
        m_failureMessage = StringFormat(
            "市場のスプレッド値が上限値を超えています。| 設定値: %.2f ポイント | 発注時スプレッド: %.2f ポイント",
            m_spreadLimit, currentSpread
        );
        return false;
    }
    
    /**
     * @brief 条件不成立時のメッセージを取得
     * @return string メッセージ
     */
    string GetFailureMessage()
    {
        return m_failureMessage;
    }
    
    /**
     * @brief 現在のスプレッド値をポイント単位で取得
     * @param symbol 通貨ペア
     * @return double スプレッド値（ポイント単位）
     */
    static double GetSpread(const string symbol)
    {
        MqlTick lastTick;
        if(!SymbolInfoTick(symbol, lastTick))
            return 0;
        
        // MQL5の場合はSymbolInfoDoubleでポイント値を取得
        double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
        if(point == 0)
            return 0;
            
        return (lastTick.ask - lastTick.bid) / point;
    }
}; 