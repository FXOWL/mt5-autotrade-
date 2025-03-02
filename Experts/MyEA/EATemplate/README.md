# EATemplate

## 概要
EATemplateは、複数のエントリー条件を柔軟に組み合わせて利用できるMT5用のエキスパートアドバイザー(EA)テンプレートです。依存性の注入パターンとCompositeパターンを使用して、異なる取引戦略を簡単に追加・変更できるように設計されています。

## 特徴
- 買い/売りの条件を複数組み合わせて柔軟に設定可能
- 条件はAND条件(すべての条件を満たす)またはOR条件(いずれかの条件を満たす)で組み合わせ可能
- 戦略ロジックをStrategyディレクトリに分離し、EATemplateはエントリーポイントと依存性注入のみを担当
- エラー処理（特にフィリングモード関連）が組み込み済み
- トレーリングストップの機能も実装

## ディレクトリ構造
```
MQL5/
├── Experts/
│   ├── Strategy/ # 自作EAで使用するトレード条件を格納するディレクトリ
│   │   ├── Buy/ # 買いトレード条件を格納するディレクトリ
│   │   ├── Sell/ # 売りトレード条件を格納するディレクトリ
│   │   ├── Lot/ # ロットの計算方法を格納するディレクトリ
│   │   ├── SL/ # ストップロスの計算方法を格納するディレクトリ
│   │   ├── TP/ # 利確の計算方法を格納するディレクトリ
│   │   ├── Trailing/ # トレーリングストップ条件を格納するディレクトリ
│   ├── MyEA/
│   │   ├── EATemplate/ # このテンプレート
│   │   └── [EAName]/ # このテンプレートをベースに作成したEA
├── Include/
│   └── _MyInclude/ # 自作のインクルードファイル
```

## 使用方法

### 新しいEAの作成
1. EATemplateディレクトリを新しいEA名のディレクトリにコピーします。
2. 新しいディレクトリ内のEATemplate.mq5ファイルを適切な名前に変更します（例：MyStrategyEA.mq5）。
3. ファイル内のEA名などの情報を更新します。

### 戦略の追加
1. 買いトレード条件を実装するには、Strategy/Buy/ディレクトリに新しい戦略クラスを作成します。
2. 売りトレード条件を実装するには、Strategy/Sell/ディレクトリに新しい戦略クラスを作成します。
3. IEntryRuleインターフェースを継承して、必要なメソッドを実装します。

### 基本的な戦略実装例
```cpp
// Strategy/Buy/MACrossEntryRule.mqh
class MACrossEntryRule : public IEntryRule
{
private:
    int m_fastPeriod;
    int m_slowPeriod;
    
public:
    MACrossEntryRule(int fastPeriod, int slowPeriod)
    {
        m_fastPeriod = fastPeriod;
        m_slowPeriod = slowPeriod;
    }
    
    bool ShouldEnter(string symbol, ENUM_TIMEFRAMES timeframe) override
    {
        // 移動平均を取得
        double fastMA = iMA(symbol, timeframe, m_fastPeriod, 0, MODE_SMA, PRICE_CLOSE, 1);
        double slowMA = iMA(symbol, timeframe, m_slowPeriod, 0, MODE_SMA, PRICE_CLOSE, 1);
        
        // 前のバーでのクロスオーバーをチェック
        double prevFastMA = iMA(symbol, timeframe, m_fastPeriod, 0, MODE_SMA, PRICE_CLOSE, 2);
        double prevSlowMA = iMA(symbol, timeframe, m_slowPeriod, 0, MODE_SMA, PRICE_CLOSE, 2);
        
        // ゴールデンクロス
        return (prevFastMA < prevSlowMA && fastMA > slowMA);
    }
    
    ENUM_ORDER_TYPE GetOrderType() override
    {
        return ORDER_TYPE_BUY;
    }
    
    // 他のメソッドも実装...
};
```

### 複数条件の組み合わせ
```cpp
// EAクラス内のRegisterStrategies関数で以下のように組み合わせます
void RegisterStrategies()
{
    // 個別の戦略を登録
    g_ruleManager.RegisterRule(new MACrossEntryRule(10, 20), "MACross");
    g_ruleManager.RegisterRule(new RSIEntryRule(14, 30), "RSI");
    
    // AND条件で組み合わせる（両方の条件を満たすときにエントリー）
    AndEntryRule *andRule = new AndEntryRule(ORDER_TYPE_BUY);
    andRule.AddRule(new MACrossEntryRule(10, 20));
    andRule.AddRule(new RSIEntryRule(14, 30));
    g_ruleManager.RegisterRule(andRule, "MACross_AND_RSI");
    
    // OR条件で組み合わせる（いずれかの条件を満たすときにエントリー）
    OrEntryRule *orRule = new OrEntryRule(ORDER_TYPE_BUY);
    orRule.AddRule(new MACrossEntryRule(10, 20));
    orRule.AddRule(new RSIEntryRule(14, 30));
    g_ruleManager.RegisterRule(orRule, "MACross_OR_RSI");
}
```

### 設定パラメータ
EAの入力パラメータとして、以下の設定を変更できます：
- **EA_Name**: EA名
- **Magic_Number**: マジックナンバー
- **Timeframe**: 時間枠
- **Allow_Buy**: 買いトレードを許可するかどうか
- **Allow_Sell**: 売りトレードを許可するかどうか
- **Use_TrailingStop**: トレーリングストップを使用するかどうか
- **Close_On_Opposite**: 反対方向の条件が満たされたときに決済するかどうか
- **Buy_Rules**: 買い条件の選択
- **Sell_Rules**: 売り条件の選択
- **Trailing_Rules**: トレーリング条件の選択

## 注意事項
- 実際の戦略クラスを作成する際は、バックテストで十分に検証してください。
- フィリングモードの互換性問題に対するコードが含まれていますが、ブローカーによっては追加の調整が必要になる場合があります。
- このテンプレートは教育目的で作成されています。実際のトレードに使用する前に、リスク管理の実装と十分なテストを行ってください。

## ライセンス
このテンプレートは[ライセンス名]の下で提供されています。詳細はLICENSEファイルを参照してください。 