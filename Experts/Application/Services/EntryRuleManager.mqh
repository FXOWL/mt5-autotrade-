//+------------------------------------------------------------------+
//|                                        EntryRuleManager.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

// インターフェース依存を削除
// #include <Experts\Domain\IEntryRule.mqh>
#include "..\Composition\AndEntryRule.mqh"
#include "..\Composition\OrEntryRule.mqh"

//+------------------------------------------------------------------+
//| エントリールールを管理するクラス                                 |
//+------------------------------------------------------------------+
class EntryRuleManager
{
private:
    // IEntryRuleの代わりに汎用ポインタを使用
    void     *m_rules[];      // 登録されたルールの配列
    string    m_ruleNames[];  // ルール名の配列
    int       m_ruleCount;    // 登録されたルールの数
    
public:
    // コンストラクタ
    EntryRuleManager()
    {
        m_ruleCount = 0;
    }
    
    // デストラクタ
    ~EntryRuleManager()
    {
        // 登録されたルールを解放
        for(int i = 0; i < m_ruleCount; i++)
        {
            if(m_rules[i] != NULL)
            {
                delete m_rules[i];
                m_rules[i] = NULL;
            }
        }
    }
    
    // 新しいルールを登録 (汎用ポインタを使用)
    bool RegisterRule(void *rule, string ruleName)
    {
        if(rule == NULL)
            return false;
            
        // 同じ名前のルールが既に存在するか確認
        for(int i = 0; i < m_ruleCount; i++)
        {
            if(m_ruleNames[i] == ruleName)
            {
                // 既存のルールを削除
                if(m_rules[i] != NULL)
                {
                    delete m_rules[i];
                    m_rules[i] = NULL;
                }
                
                // 新しいルールを登録
                m_rules[i] = rule;
                return true;
            }
        }
        
        // 配列のサイズを拡張
        int newSize = m_ruleCount + 1;
        if(ArrayResize(m_rules, newSize) != newSize)
            return false;
            
        if(ArrayResize(m_ruleNames, newSize) != newSize)
            return false;
            
        // 新しいルールを登録
        m_rules[m_ruleCount] = rule;
        m_ruleNames[m_ruleCount] = ruleName;
        m_ruleCount++;
        
        return true;
    }
    
    // 名前でルールを取得 (汎用ポインタを返す)
    void* GetRule(string ruleName)
    {
        for(int i = 0; i < m_ruleCount; i++)
        {
            if(m_ruleNames[i] == ruleName)
                return m_rules[i];
        }
        
        return NULL;
    }
    
    // ANDルールを作成（すべての条件を満たす必要がある）
    void* CreateAndRule(string &ruleNames[], ENUM_ORDER_TYPE orderType)
    {
        if(ArraySize(ruleNames) == 0)
            return NULL;
            
        // ANDルールを作成
        AndEntryRule *andRule = new AndEntryRule(orderType);
        
        // 指定された名前のルールを追加
        for(int i = 0; i < ArraySize(ruleNames); i++)
        {
            void *rule = GetRule(ruleNames[i]);
            if(rule != NULL)
            {
                // ダックタイピング的にルールを追加
                andRule.AddRule(rule);
            }
        }
        
        return andRule;
    }
    
    // ORルールを作成（いずれかの条件を満たす必要がある）
    void* CreateOrRule(string &ruleNames[], ENUM_ORDER_TYPE orderType)
    {
        if(ArraySize(ruleNames) == 0)
            return NULL;
            
        // ORルールを作成
        OrEntryRule *orRule = new OrEntryRule(orderType);
        
        // 指定された名前のルールを追加
        for(int i = 0; i < ArraySize(ruleNames); i++)
        {
            void *rule = GetRule(ruleNames[i]);
            if(rule != NULL)
            {
                // ダックタイピング的にルールを追加
                orRule.AddRule(rule);
            }
        }
        
        return orRule;
    }
    
    // 登録されたルールの名前を取得
    void GetRuleNames(string &names[])
    {
        ArrayResize(names, m_ruleCount);
        for(int i = 0; i < m_ruleCount; i++)
        {
            names[i] = m_ruleNames[i];
        }
    }
    
    // 登録されたルールの数を取得
    int GetRuleCount()
    {
        return m_ruleCount;
    }
}; 