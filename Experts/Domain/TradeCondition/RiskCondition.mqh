//+------------------------------------------------------------------+
//|                                              RiskCondition.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"

#include "ITradeCondition.mqh"
#include <Trade\AccountInfo.mqh>

/**
 * @brief リスク管理条件クラス
 */
class CRiskCondition : public ITradeCondition
{
private:
    double m_maximumRisk;      // 最大リスク率（0-1の間）
    string m_failureMessage;   // 条件不成立時のメッセージ
    CAccountInfo m_account;    // アカウント情報
    
    // 当日の損益をキャッシュ
    double m_todayProfit;
    datetime m_lastCalculationTime;
    
    /**
     * @brief 当日の損益を計算
     * @return double 当日の損益
     */
    double CalculateTodayProfit()
    {
        // 前回計算から1分以内なら、キャッシュ値を返す
        datetime currentTime = TimeCurrent();
        if(m_lastCalculationTime > 0 && currentTime - m_lastCalculationTime < 60)
            return m_todayProfit;
        
        // 当日の開始時刻を取得
        MqlDateTime today;
        TimeToStruct(currentTime, today);
        today.hour = 0;
        today.min = 0;
        today.sec = 0;
        datetime todayStart = StructToTime(today);
        
        // 履歴から当日の損益を計算
        double todayProfit = 0.0;
        
        // 未決済ポジションからの損益
        int totalPositions = PositionsTotal();
        for(int i = 0; i < totalPositions; i++)
        {
            if(PositionSelectByTicket(PositionGetTicket(i)))
            {
                // ポジションのオープン時間が当日内かチェック
                datetime positionTime = (datetime)PositionGetInteger(POSITION_TIME);
                if(positionTime >= todayStart)
                {
                    todayProfit += PositionGetDouble(POSITION_PROFIT);
                }
            }
        }
        
        // 決済済み取引からの損益
        int totalDeals = HistoryDealsTotal();
        HistorySelect(todayStart, currentTime);
        
        for(int i = 0; i < totalDeals; i++)
        {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(dealTicket > 0)
            {
                // 決済時間が当日内かチェック
                datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
                if(dealTime >= todayStart)
                {
                    todayProfit += HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                }
            }
        }
        
        // キャッシュを更新（constメソッド内でメンバー変数を変更するためにconstキャストを使用）
        // MQL5ではconst_castが使えないので、設計を変更
        // m_todayProfitとm_lastCalculationTimeをmutable宣言すれば
        // constメソッド内で変更可能になりますが、ここでは非constメソッドに変更します
        m_todayProfit = todayProfit;
        m_lastCalculationTime = currentTime;
        
        return todayProfit;
    }

public:
    /**
     * @brief コンストラクタ
     * @param maximumRisk 最大リスク率（0-1の間）
     */
    CRiskCondition(const double maximumRisk) 
        : m_maximumRisk(maximumRisk), m_failureMessage(""), m_todayProfit(0.0), m_lastCalculationTime(0) {}
    
    /**
     * @brief リスク条件をチェック
     * @param symbol 通貨ペア（使用しない）
     * @param timeframe 時間枠（使用しない）
     * @return bool リスク条件を満たしていればtrue
     */
    bool Check(const string symbol, const ENUM_TIMEFRAMES timeframe)
    {
        // 当日の損益を計算
        double todayProfit = CalculateTodayProfit();
        
        // 前日の余剰証拠金を基に算出した1日あたりの損失上限額
        double dailyLossLimit = m_account.FreeMargin() * m_maximumRisk;
        
        // 可能な損失額が残っているかチェック
        if((dailyLossLimit + todayProfit) > 0)
            return true;
            
        m_failureMessage = StringFormat(
            "1日の損失上限に達しました。| 損失上限: %.2f | 当日損益: %.2f",
            dailyLossLimit, todayProfit
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
}; 