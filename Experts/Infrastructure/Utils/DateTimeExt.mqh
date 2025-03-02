//+------------------------------------------------------------------+
//|                                                  DateTimeExt.mqh |
//|                            Copyright 2024, Your Company         |
//|                                     https://www.yourwebsite.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Your Company"
#property link      "https://www.yourwebsite.com"

#include <Tools/DateTime.mqh>

/**
 * @brief CDateTimeを拡張し、MT5サーバー時間との変換や日時比較などの機能を追加
 * 継承ではなく複合(composition)パターンを使用
 */
class CDateTimeExt
{
private:
    MqlDateTime m_dt;  // 内部的な日時データ
    
    /**
     * @brief バックテストでの夏時間を判定する
     * @return bool 夏時間ならtrue
     */
    bool IsSummertimeForBackTest();
    
    /**
     * @brief ローカル日時の年のサマータイム開始日時を返す
     * @return CDateTimeExt サマータイム開始日時
     */
    CDateTimeExt SummertimeStartDate();
    
    /**
     * @brief ローカル日時の年のサマータイム終了日時を返す
     * @return CDateTimeExt サマータイム終了日時
     */
    CDateTimeExt SummertimeEndDate();
    
    /**
     * @brief MT5サーバーとローカルPCのシステム時刻のオフセット値を取得する
     * @return int オフセット値（秒）
     */
    int TimeGmtOffsetOfMtSrv();

public:
    /**
     * @brief デフォルトコンストラクタ
     */
    CDateTimeExt() { ZeroMemory(m_dt); }
    
    /**
     * @brief コピーコンストラクタ
     */
    CDateTimeExt(const CDateTimeExt &other) { m_dt = other.m_dt; }
    
    /**
     * @brief MqlDateTimeからのコンストラクタ
     */
    CDateTimeExt(const MqlDateTime &dt) { m_dt = dt; }
    
    /**
     * @brief datetimeからのコンストラクタ
     */
    CDateTimeExt(const datetime time) { TimeToStruct(time, m_dt); }
    
    /**
     * @brief 年を設定
     */
    void Year(const int value) { m_dt.year = value; }
    
    /**
     * @brief 月を設定
     */
    void Mon(const int value) { m_dt.mon = value; }
    
    /**
     * @brief 日を設定
     */
    void Day(const int value) { m_dt.day = value; }
    
    /**
     * @brief 時を設定
     */
    void Hour(const int value) { m_dt.hour = value; }
    
    /**
     * @brief 分を設定
     */
    void Min(const int value) { m_dt.min = value; }
    
    /**
     * @brief 秒を設定
     */
    void Sec(const int value) { m_dt.sec = value; }
    
    /**
     * @brief 指定した日数を加算
     */
    void DayInc(const int days);
    
    /**
     * @brief 指定した日数を減算
     */
    void DayDec(const int days);
    
    /**
     * @brief 年の値を取得
     */
    int Year() const { return m_dt.year; }
    
    /**
     * @brief 月の値を取得
     */
    int Mon() const { return m_dt.mon; }
    
    /**
     * @brief 日の値を取得
     */
    int Day() const { return m_dt.day; }
    
    /**
     * @brief 時の値を取得
     */
    int Hour() const { return m_dt.hour; }
    
    /**
     * @brief 分の値を取得
     */
    int Min() const { return m_dt.min; }
    
    /**
     * @brief 秒の値を取得
     */
    int Sec() const { return m_dt.sec; }
    
    /**
     * @brief 曜日の値を取得
     */
    int DayOfWeek() const { return m_dt.day_of_week; }
    
    /**
     * @brief 月の日数を取得
     */
    int DaysInMonth() const;
    
    /**
     * @brief datetime型へ変換
     */
    datetime DateTime() const 
    { 
        // const_cast が使えないので一時変数を作成
        MqlDateTime temp = m_dt;
        return StructToTime(temp); 
    }
    
    /**
     * @brief datetimeから日付時刻を設定
     */
    void DateTime(const datetime time) { TimeToStruct(time, m_dt); }
    
    /**
     * @brief MqlDateTimeから日付時刻を設定
     */
    void DateTime(const MqlDateTime &dt) { m_dt = dt; }
    
    /**
     * @brief ローカルのシステム時刻からMT5サーバーの時刻に変換し、datetime型で返却
     * @return datetime MT5サーバー時刻
     */
    datetime ToMtServerDateTime();
    
    /**
     * @brief ローカルのシステム時刻からMT5サーバーの時刻に変換し、CDateTimeExt型で返却
     * @return CDateTimeExt MT5サーバー時刻
     */
    CDateTimeExt ToMtServerStruct();
    
    /**
     * @brief 月末日を取得
     * @return CDateTimeExt 月末日のCDateTimeExt
     */
    CDateTimeExt AtEndOfMonth();
    
    /**
     * @brief 日時を文字列形式で返す
     * @param separate 区切り文字（デフォルト "/"）
     * @return string フォーマットされた日時文字列
     */
    string ToStrings(string separate = "/");
    
    // 日時比較メソッド群
    bool Eq(const MqlDateTime &value)
    {
        MqlDateTime temp = value;
        return Eq(StructToTime(temp));
    }

    bool Eq(const datetime value) 
    { 
        return DateTime() == value; 
    }

    bool Gt(const MqlDateTime &value)
    {
        MqlDateTime temp = value;
        return Gt(StructToTime(temp));
    }

    bool Gt(const datetime value) 
    { 
        return DateTime() > value; 
    }

    bool Gte(const MqlDateTime &value)
    {
        MqlDateTime temp = value;
        return Gte(StructToTime(temp));
    }

    bool Gte(const datetime value) 
    { 
        return DateTime() >= value; 
    }

    bool Lt(const MqlDateTime &value)
    {
        MqlDateTime temp = value;
        return Lt(StructToTime(temp));
    }

    bool Lt(const datetime value) 
    { 
        return DateTime() < value; 
    }

    bool Lte(const MqlDateTime &value)
    {
        MqlDateTime temp = value;
        return Lte(StructToTime(temp));
    }

    bool Lte(const datetime value) 
    { 
        return DateTime() <= value; 
    }

    bool Between(const datetime start, const datetime end) 
    { 
        return DateTime() >= start && DateTime() <= end; 
    }

    bool Between(const MqlDateTime &start, const MqlDateTime &end)
    {
        MqlDateTime tempStart = start;
        MqlDateTime tempEnd = end;
        datetime startTime = StructToTime(tempStart);
        datetime endTime = StructToTime(tempEnd);
        return Between(startTime, endTime);
    }
    
    // 曜日判定メソッド群
    bool IsSunday() const { return m_dt.day_of_week == 0; }
    bool IsMonday() const { return m_dt.day_of_week == 1; }
    bool IsTuesday() const { return m_dt.day_of_week == 2; }
    bool IsWednesday() const { return m_dt.day_of_week == 3; }
    bool IsThursday() const { return m_dt.day_of_week == 4; }
    bool IsFriday() const { return m_dt.day_of_week == 5; }
    bool IsSaturday() const { return m_dt.day_of_week == 6; }
    bool IsGotoday() const { return m_dt.day % 5 == 0; }
    
    /**
     * @brief デバッグ情報を出力
     */
    void Debug();
};

//+------------------------------------------------------------------+
//| 実装部                                                           |
//+------------------------------------------------------------------+

void CDateTimeExt::DayInc(const int days)
{
    datetime time = DateTime() + days * 86400; // 1日は86400秒
    DateTime(time);
}

void CDateTimeExt::DayDec(const int days)
{
    datetime time = DateTime() - days * 86400; // 1日は86400秒
    DateTime(time);
}

int CDateTimeExt::DaysInMonth() const
{
    static int days_in_month[12] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
    int year = m_dt.year;
    int month = m_dt.mon;
    
    // 2月でうるう年の場合
    if(month == 2 && ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)))
        return 29;
        
    return days_in_month[month - 1];
}

bool CDateTimeExt::IsSummertimeForBackTest()
{
    datetime start_date = SummertimeStartDate().DateTime();
    datetime end_date = SummertimeEndDate().DateTime();

    return DateTime() >= start_date && DateTime() <= end_date;
}

CDateTimeExt CDateTimeExt::SummertimeStartDate()
{
    CDateTimeExt start_date;
    start_date.DateTime(TimeLocal());
    start_date.Mon(3);
    start_date.Day(1);

    // MqlDateTimeに変換して曜日を取得
    MqlDateTime start_dt;
    TimeToStruct(start_date.DateTime(), start_dt);
    int start_day_of_week = start_dt.day_of_week;
    int start_day = (start_day_of_week == 0) ? 8 : 15 - start_day_of_week;

    start_date.DayInc(start_day - 1);
    start_date.Hour(2);
    start_date.Min(0);
    start_date.Sec(0);
    return start_date;
}

CDateTimeExt CDateTimeExt::SummertimeEndDate()
{
    CDateTimeExt end_date;
    end_date.DateTime(TimeLocal());
    end_date.Mon(11);
    end_date.Day(1);
    
    // MqlDateTimeに変換して曜日を取得
    MqlDateTime end_dt;
    TimeToStruct(end_date.DateTime(), end_dt);
    int end_day_of_week = end_dt.day_of_week;

    int end_day = (end_day_of_week == 0) ? 1 : 8 - end_day_of_week;

    end_date.DayInc(end_day - 1);
    end_date.Hour(2);
    end_date.Min(0);
    end_date.Sec(0);
    return end_date;
}

int CDateTimeExt::TimeGmtOffsetOfMtSrv()
{
    static int gmt2 = -2;
    static int gmt3 = -3;
    int sec_of_hour = 60 * 60;
    int deviation;
    
    if(MQLInfoInteger(MQL_TESTER)) {
        // バックテストではサマータイムの判定が常に冬時間(0)が返されてしまう場合がある
        deviation = IsSummertimeForBackTest() ? gmt3 : gmt2;
    }
    else {
        // サーバー時刻とローカル時刻で数秒ずれてしまうため時間単位に戻してから丸めて修正
        const double offset = double(TimeGMT() - TimeCurrent());
        deviation = int(MathRound(offset / sec_of_hour));
    }

    return deviation * sec_of_hour;
}

datetime CDateTimeExt::ToMtServerDateTime()
{
    return DateTime() - (TimeGmtOffsetOfMtSrv() - TimeGMTOffset());
}

CDateTimeExt CDateTimeExt::ToMtServerStruct()
{
    CDateTimeExt dt;
    dt.DateTime(ToMtServerDateTime());
    return dt;
}

CDateTimeExt CDateTimeExt::AtEndOfMonth()
{
    Day(DaysInMonth());
    
    CDateTimeExt result;
    result.DateTime(DateTime());

    if(result.DayOfWeek() == 6) // SATURDAY
        result.DayDec(1);
    if(result.DayOfWeek() == 0) // SUNDAY
        result.DayDec(2);

    return result;
}

string CDateTimeExt::ToStrings(string separate = "/")
{
    return StringFormat("%04d%s%02d%s%02d %02d:%02d:%02d", 
        m_dt.year, separate, m_dt.mon, separate, m_dt.day, m_dt.hour, m_dt.min, m_dt.sec);
}

void CDateTimeExt::Debug()
{
    Print("Date: ", ToStrings(), " IsServerTime: ", ToMtServerStruct().ToStrings());
} 