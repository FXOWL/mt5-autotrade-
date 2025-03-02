//+------------------------------------------------------------------+
//|                                    TradeConditionService.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"

#include "../../Domain/TradeCondition/ITradeCondition.mqh"

/**
 * @brief 取引条件サービス
 * 複数の取引条件を管理し、すべての条件を評価する
 */
class CTradeConditionService
{
private:
    // 取引条件の配列
    ITradeCondition *m_conditions[];
    // 最後に失敗した条件のメッセージ
    string m_lastFailureMessage;

public:
    /**
     * @brief デストラクタ
     * 登録されたすべての条件を解放
     */
    ~CTradeConditionService()
    {
        int size = ArraySize(m_conditions);
        for(int i = 0; i < size; i++)
        {
            if(CheckPointer(m_conditions[i]) != POINTER_INVALID)
            {
                delete m_conditions[i];
                m_conditions[i] = NULL;
            }
        }
        ArrayFree(m_conditions);
    }
    
    /**
     * @brief 取引条件を追加
     * @param condition 取引条件
     */
    void AddCondition(ITradeCondition *condition)
    {
        int size = ArraySize(m_conditions);
        ArrayResize(m_conditions, size + 1);
        m_conditions[size] = condition;
    }
    
    /**
     * @brief すべての条件をチェック
     * @param symbol 通貨ペア
     * @param timeframe 時間枠
     * @return bool すべての条件を満たしていればtrue
     */
    bool CheckAllConditions(const string symbol, const ENUM_TIMEFRAMES timeframe)
    {
        int size = ArraySize(m_conditions);
        if(size == 0)
            return true;  // 条件がなければ常にtrue
            
        for(int i = 0; i < size; i++)
        {
            if(!m_conditions[i].Check(symbol, timeframe))
            {
                // 条件を満たさない場合はメッセージを保存して失敗を返す
                m_lastFailureMessage = m_conditions[i].GetFailureMessage();
                PrintFormat("取引条件チェック失敗: %s", m_lastFailureMessage);
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * @brief 最後に失敗した条件のメッセージを取得
     * @return string 失敗メッセージ
     */
    string GetLastFailureMessage() const
    {
        return m_lastFailureMessage;
    }
}; 