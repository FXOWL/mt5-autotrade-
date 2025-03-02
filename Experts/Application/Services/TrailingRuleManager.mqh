//+------------------------------------------------------------------+
//|                                       TrailingRuleManager.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

#include "..\..\Domain\ITrailingRule.mqh"

//+------------------------------------------------------------------+
//| トレーリングルールを管理するクラス                                 |
//+------------------------------------------------------------------+
class TrailingRuleManager
{
private:
    ITrailingRule* m_rules[];      // 登録されたルールの配列
    string         m_ruleNames[];  // ルールの名前
    int            m_ruleCount;    // 登録されたルールの数
    ITrailingRule* m_activeRule;   // 現在アクティブなルール

public:
    // コンストラクタ
    TrailingRuleManager()
    {
        m_ruleCount = 0;
        m_activeRule = NULL;
    }
    
    // デストラクタ - すべてのルールを解放
    ~TrailingRuleManager()
    {
        for(int i = 0; i < m_ruleCount; i++)
        {
            if(m_rules[i] != NULL)
            {
                delete m_rules[i];
                m_rules[i] = NULL;
            }
        }
    }
    
    // 新しいルールを登録
    void RegisterRule(ITrailingRule* rule, string ruleName)
    {
        // 配列のサイズを拡張
        ArrayResize(m_rules, m_ruleCount + 1);
        ArrayResize(m_ruleNames, m_ruleCount + 1);
        
        // ルールと名前を登録
        m_rules[m_ruleCount] = rule;
        m_ruleNames[m_ruleCount] = ruleName;
        
        // アクティブルールが設定されていない場合は、最初に登録されたルールをアクティブに
        if(m_ruleCount == 0 && m_activeRule == NULL)
        {
            m_activeRule = rule;
        }
        
        m_ruleCount++;
    }
    
    // ルール名からルールを取得
    ITrailingRule* GetRule(string ruleName)
    {
        for(int i = 0; i < m_ruleCount; i++)
        {
            if(m_ruleNames[i] == ruleName)
            {
                return m_rules[i];
            }
        }
        
        return NULL;
    }
    
    // アクティブなルールを設定
    void SetActiveRule(string ruleName)
    {
        ITrailingRule* rule = GetRule(ruleName);
        if(rule != NULL)
        {
            m_activeRule = rule;
        }
    }
    
    // 現在アクティブなルールを取得
    ITrailingRule* GetActiveRule()
    {
        return m_activeRule;
    }
    
    // 登録されているルールの名前を取得
    string GetRegisteredRuleNames()
    {
        string result = "";
        for(int i = 0; i < m_ruleCount; i++)
        {
            result += m_ruleNames[i];
            if(i < m_ruleCount - 1)
            {
                result += ",";
            }
        }
        
        return result;
    }
}; 