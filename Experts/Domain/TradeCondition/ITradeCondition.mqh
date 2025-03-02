//+------------------------------------------------------------------+
//|                                             ITradeCondition.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"

/**
 * @brief 取引条件のインターフェース
 */
class ITradeCondition
{
public:
    /**
     * @brief 取引条件を満たしているかチェック
     * @param symbol 通貨ペア
     * @param timeframe 時間枠
     * @return bool 条件を満たしていればtrue
     */
    virtual bool Check(const string symbol, const ENUM_TIMEFRAMES timeframe) = 0;
    
    /**
     * @brief 条件を満たさなかった場合のメッセージを取得
     * @return string 条件を満たさなかった理由のメッセージ
     */
    virtual string GetFailureMessage() = 0;
}; 