//+------------------------------------------------------------------+
//|                                         CompositeEntryRule.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"
#property version   "1.00"

// #include <Experts\Domain\IEntryRule.mqh>

//+------------------------------------------------------------------+
//| 複数のエントリールールを組み合わせるための抽象基底クラス        |
//+------------------------------------------------------------------+
class CompositeEntryRule // インターフェース継承を削除
{
protected:
    void *m_rules[];          // エントリールールの配列（void*を使用）
    int    m_ruleCount;       // 登録されたルールの数
    ENUM_ORDER_TYPE m_orderType; // 注文タイプ（買い/売り）
    
public:
    // コンストラクタ
    CompositeEntryRule(ENUM_ORDER_TYPE orderType)
    {
        m_ruleCount = 0;
        m_orderType = orderType;
    }
    
    // デストラクタ
    ~CompositeEntryRule()
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
    
    // ルールを追加するメソッド
    bool AddRule(void *rule)
    {
        if(rule == NULL)
            return false;
            
        int newSize = ArraySize(m_rules) + 1;
        if(ArrayResize(m_rules, newSize) != newSize)
            return false;
            
        m_rules[m_ruleCount++] = rule;
        return true;
    }
    
    // エントリーの方向を返す
    ENUM_ORDER_TYPE GetOrderType() // override削除
    {
        return m_orderType;
    }
    
    // ロット数のデフォルト計算（サブクラスでオーバーライド可能）
    double CalculateLot(string symbol, double accountBalance) // override削除
    {
        // デフォルトのロット計算ロジック
        return 0.01; // 最小ロットを返す
    }
    
    // ストップロスのデフォルト計算（サブクラスでオーバーライド可能）
    double CalculateSL(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice) // override削除
    {
        // デフォルトのSL計算ロジック（例：現在価格から50ポイント）
        double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
        if(orderType == ORDER_TYPE_BUY)
            return entryPrice - 50 * pipValue;
        else
            return entryPrice + 50 * pipValue;
    }
    
    // 利確のデフォルト計算（サブクラスでオーバーライド可能）
    double CalculateTP(string symbol, ENUM_ORDER_TYPE orderType, double entryPrice) // override削除
    {
        // デフォルトのTP計算ロジック（例：現在価格から100ポイント）
        double pipValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
        if(orderType == ORDER_TYPE_BUY)
            return entryPrice + 100 * pipValue;
        else
            return entryPrice - 100 * pipValue;
    }
}; 