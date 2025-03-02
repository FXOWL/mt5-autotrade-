//+------------------------------------------------------------------+
//|                                          PositionCondition.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"

#include "ITradeCondition.mqh"
#include <Trade\PositionInfo.mqh>

/**
 * @brief ポジション条件クラス
 */
class CPositionCondition : public ITradeCondition
{
private:
    int m_maxPositions;        // 最大同時ポジション数
    int m_magicNumber;         // マジックナンバー
    string m_failureMessage;   // 条件不成立時のメッセージ
    CPositionInfo m_position;  // ポジション情報

public:
    /**
     * @brief コンストラクタ
     * @param maxPositions 最大同時ポジション数
     * @param magicNumber マジックナンバー
     */
    CPositionCondition(const int maxPositions, const int magicNumber)
        : m_maxPositions(maxPositions), m_magicNumber(magicNumber), m_failureMessage("") {}
    
    /**
     * @brief 現在のポジション数が条件を満たしているかチェック
     * @param symbol 通貨ペア
     * @param timeframe 時間枠（使用しない）
     * @return bool ポジション数が上限以下ならtrue
     */
    bool Check(const string symbol, const ENUM_TIMEFRAMES timeframe)
    {
        int currentPositions = CalculateCurrentPositions(symbol);
        
        if(currentPositions < m_maxPositions)
            return true;
            
        m_failureMessage = StringFormat(
            "保有ポジション数が上限に達しています。| 上限: %d | 現在: %d",
            m_maxPositions, currentPositions
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
     * @brief 現在のポジション数を計算
     * @param symbol 通貨ペア
     * @return int ポジション数
     */
    int CalculateCurrentPositions(const string symbol)
    {
        int count = 0;
        int total = PositionsTotal();
        
        for(int i = 0; i < total; i++)
        {
            if(m_position.SelectByIndex(i))
            {
                // 同じ通貨ペアとマジックナンバーのポジションのみカウント
                if(m_position.Symbol() == symbol && m_position.Magic() == m_magicNumber)
                {
                    count++;
                }
            }
        }
        
        return count;
    }
}; 