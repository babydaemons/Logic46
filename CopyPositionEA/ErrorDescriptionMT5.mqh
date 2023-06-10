//+------------------------------------------------------------------+
//|                                          ErrorDescriptionMT5.mqh |
//|                                    Copyright 2022, atelierlapin. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, YUSUKE."
#property strict

//+------------------------------------------------------------------+
//| 現在発生しているエラーのエラーメッセージを返します。             |
//+------------------------------------------------------------------+
string ErrorDescription() {
    return ErrorDescription(GetLastError());
}

//+------------------------------------------------------------------+
//| エラーコードをエラーメッセージに変換します。                     |
//+------------------------------------------------------------------+
string ErrorDescription(int error_code) {
    string error_string = "";
    switch (error_code) {
    case ERR_SUCCESS:
        error_string = "操作が正常に完了しました。";
        break;
    case ERR_INTERNAL_ERROR:
        error_string = "予期しない内部エラー。";
        break;
    case ERR_WRONG_INTERNAL_PARAMETER:
        error_string = "クライアント端末関数の内部呼び出しでの不正なパラメータ。";
        break;
    case ERR_INVALID_PARAMETER:
        error_string = "システム関数呼び出し時の不正なパラメータ。";
        break;
    case ERR_NOT_ENOUGH_MEMORY:
        error_string = "システム関数の実行に不充分なメモリ。";
        break;
    case ERR_STRUCT_WITHOBJECTS_ORCLASS:
        error_string = "構造体に、文字列、及び/または動的な配列及び/またはそのようなオブジェクトの構造体及び/またはクラスが含まれます。";
        break;
    case ERR_INVALID_ARRAY:
        error_string = "型やサイズが不正な配列、または動的配列内に損傷を受けたオブジェクト。";
        break;
    case ERR_ARRAY_RESIZE_ERROR:
        error_string = "配列の移転に不充分なメモリ、または静的配列のサイズを変更する試み。";
        break;
    case ERR_STRING_RESIZE_ERROR:
        error_string = "文字列の再配置に不充分なメモリ。";
        break;
    case ERR_NOTINITIALIZED_STRING:
        error_string = "初期化されていない文字列。";
        break;
    case ERR_INVALID_DATETIME:
        error_string = "無効な日付/時刻。";
        break;
    case ERR_ARRAY_BAD_SIZE:
        error_string = "配列の要素数の合計は 2,147,483,647を超えることは出来ません。";
        break;
    case ERR_INVALID_POINTER:
        error_string = "不正なポインタ。";
        break;
    case ERR_INVALID_POINTER_TYPE:
        error_string = "不正なポインタ型。";
        break;
    case ERR_FUNCTION_NOT_ALLOWED:
        error_string = "関数呼び出しの許可がありません。";
        break;
    case ERR_RESOURCE_NAME_DUPLICATED:
        error_string = "同一の動的及び静的リソース名。";
        break;
    case ERR_RESOURCE_NOT_FOUND:
        error_string = "この名称のリソースがEX5で見つかりません。";
        break;
/*
    case ERR_RESOURCE_UNSUPPOTED_TYPE:
        error_string = "リソースタイプがサポートされていないかサイズが 16 MB を超えます。";
        break;
*/
    case ERR_RESOURCE_NAME_IS_TOO_LONG:
        error_string = "リソース名が 63 字を超えます。";
        break;
    case ERR_MATH_OVERFLOW:
        error_string = "数学関数の計算時にオーバーフローが発生 ";
        break;
    case ERR_SLEEP_ERROR:
        error_string = "Sleep()呼び出しが終了日より後です。";
        break;
    case ERR_PROGRAM_STOPPED:
        error_string = "テストは外部から強制停止されました。例は、最適化の中断、視覚的テストウィンドウの終了、テストエージェントの停止です。";
        break;
    case ERR_CHART_WRONG_ID:
        error_string = "不正なチャート識別子。";
        break;
    case ERR_CHART_NO_REPLY:
        error_string = "チャートが応答しません。";
        break;
    case ERR_CHART_NOT_FOUND:
        error_string = "チャートが見つかりません。";
        break;
    case ERR_CHART_NO_EXPERT:
        error_string = "イベントを処理出来るエキスパートアドバイザーがチャートに不在。";
        break;
    case ERR_CHART_CANNOT_OPEN:
        error_string = "チャートオープンエラー。";
        break;
    case ERR_CHART_CANNOT_CHANGE:
        error_string = "銘柄と期間の変更に失敗。";
        break;
    case ERR_CHART_WRONG_PARAMETER:
        error_string = "チャート操作の関数のパラメータ値のエラー。";
        break;
    case ERR_CHART_CANNOT_CREATE_TIMER:
        error_string = "タイマー作成に失敗。";
        break;
    case ERR_CHART_WRONG_PROPERTY:
        error_string = "不正なチャートプロパティ識別子。";
        break;
    case ERR_CHART_SCREENSHOT_FAILED:
        error_string = "スクリーンショット作成エラー。";
        break;
    case ERR_CHART_NAVIGATE_FAILED:
        error_string = "チャートナビゲートエラー。";
        break;
    case ERR_CHART_TEMPLATE_FAILED:
        error_string = "テンプレート適用エラー。";
        break;
    case ERR_CHART_WINDOW_NOT_FOUND:
        error_string = "指標を含むサブウィンドウが不在。";
        break;
    case ERR_CHART_INDICATOR_CANNOT_ADD:
        error_string = "指標をチャートに追加するのに失敗。";
        break;
    case ERR_CHART_INDICATOR_CANNOT_DEL:
        error_string = "指標をチャートから削除するのに失敗。";
        break;
    case ERR_CHART_INDICATOR_NOT_FOUND:
        error_string = "指標が指定されたチャートに不在。";
        break;
    case ERR_OBJECT_ERROR:
        error_string = "グラフィックオブジェクト操作エラー。";
        break;
    case ERR_OBJECT_NOT_FOUND:
        error_string = "グラフィックオブジェクトが見つかりません。";
        break;
    case ERR_OBJECT_WRONG_PROPERTY:
        error_string = "グラフィックオブジェクトプロパティの不正な ID。";
        break;
    case ERR_OBJECT_GETDATE_FAILED:
        error_string = "値に対応する日付の取得が不可能。";
        break;
    case ERR_OBJECT_GETVALUE_FAILED:
        error_string = "日付に対応する値の取得が不可能。";
        break;
    case ERR_MARKET_UNKNOWN_SYMBOL:
        error_string = "未知のシンボル。";
        break;
    case ERR_MARKET_NOT_SELECTED:
        error_string = "「気配値表示」でシンボルが未選択。";
        break;
    case ERR_MARKET_WRONG_PROPERTY:
        error_string = "シンボルプロパティの不正な識別子。";
        break;
    case ERR_MARKET_LASTTIME_UNKNOWN:
        error_string = "最後のティックの時間が未知（ティック不在）。";
        break;
    case ERR_MARKET_SELECT_ERROR:
        error_string = "「気配値表示」のシンボル追加・削除に失敗。";
        break;
    case ERR_HISTORY_NOT_FOUND:
        error_string = "リクエストされた履歴が見つかりません。";
        break;
    case ERR_HISTORY_WRONG_PROPERTY:
        error_string = "不正な履歴プロパティ識別子。";
        break;
    case ERR_HISTORY_TIMEOUT:
        error_string = "履歴リクエストがタイムアウトしました。";
        break;
    case ERR_HISTORY_BARS_LIMIT:
        error_string = "要求されたバーの数が端末の設定によって制限されています。";
        break;
    case ERR_HISTORY_LOAD_ERRORS:
        error_string = "履歴を読み込む際に複数のエラーが生成されました。";
        break;
    case ERR_HISTORY_SMALL_BUFFER:
        error_string = "受信する配列が小さすぎて、リクエストされたすべてのデータを格納できません。";
        break;
    case ERR_GLOBALVARIABLE_NOT_FOUND:
        error_string = "クライアント端末のグローバル変数が見つかりません。";
        break;
    case ERR_GLOBALVARIABLE_EXISTS:
        error_string = "同名のクライアント端末のグローバル変数が既存。";
        break;
    case ERR_GLOBALVARIABLE_NOT_MODIFIED:
        error_string = "グローバル変数が変更されていない";
        break;
    case ERR_GLOBALVARIABLE_CANNOTREAD:
        error_string = "グローバル変数値を持つファイルの読み取りが不可能";
        break;
    case ERR_GLOBALVARIABLE_CANNOTWRITE:
        error_string = "グローバル変数値を持つファイルの書き込みが不可能";
        break;
    case ERR_MAIL_SEND_FAILED:
        error_string = "メール送信に失敗。";
        break;
    case ERR_PLAY_SOUND_FAILED :
        error_string = "音の再生に失敗。";
        break;
    case ERR_MQL5_WRONG_PROPERTY :
        error_string = "プログラムプロパティの不正な識別子。";
        break;
    case ERR_TERMINAL_WRONG_PROPERTY:
        error_string = "端末プロパティの不正な識別子。";
        break;
    case ERR_FTP_SEND_FAILED:
        error_string = "FTP でのファイル送信に失敗。";
        break;
    case ERR_NOTIFICATION_SEND_FAILED:
        error_string = "通知送信に失敗。";
        break;
    case ERR_NOTIFICATION_WRONG_PARAMETER:
        error_string = "通知送信に無効なパラメータ（空の文字列か NULL ）が SendNotification() 関数に渡されました。";
        break;
    case ERR_NOTIFICATION_WRONG_SETTINGS:
        error_string = "端末内の不正な通知の設定（IDの未指定か、許可の無設定）。";
        break;
    case ERR_NOTIFICATION_TOO_FREQUENT:
        error_string = "頻繁過ぎる通知の送信。";
        break;
    case ERR_FTP_NOSERVER:
        error_string = "FTPサーバが指定されていません。";
        break;
    case ERR_FTP_NOLOGIN:
        error_string = "FTPログインが指定されていません。";
        break;
    case ERR_FTP_FILE_ERROR:
        error_string = "FTPサーバに送信するファイルがMQL5\\Filesディレクトリで見つかりません。";
        break;
    case ERR_FTP_CONNECT_FAILED:
        error_string = "FTP接続に失敗しました。";
        break;
    case ERR_FTP_CHANGEDIR:
        error_string = "サーバでFTPパスが見つかりません。";
        break;
    case 4524 /*ERR_FTP_CLOSED*/:
        error_string = "FTP接続が閉じられました。";
        break;
    case ERR_BUFFERS_NO_MEMORY:
        error_string = "指標バッファ配布に不充分なメモリ。";
        break;
    case ERR_BUFFERS_WRONG_INDEX:
        error_string = "不正な指標バッファインデックス。";
        break;
    case ERR_CUSTOM_WRONG_PROPERTY:
        error_string = "不正なカスタム指標プロパティ識別子。";
        break;
    case ERR_ACCOUNT_WRONG_PROPERTY:
        error_string = "不正な口座プロパティ識別子。";
        break;
    case ERR_TRADE_WRONG_PROPERTY:
        error_string = "不正な取引プロパティ識別子。";
        break;
    case ERR_TRADE_DISABLED:
        error_string = "エキスパートアドバイザーでの取引が許可されていません。";
        break;
    case ERR_TRADE_POSITION_NOT_FOUND:
        error_string = "ポジションが見つかりません。";
        break;
    case ERR_TRADE_ORDER_NOT_FOUND:
        error_string = "注文が見つかりません。";
        break;
    case ERR_TRADE_DEAL_NOT_FOUND:
        error_string = "約定が見つかりません。";
        break;
    case ERR_TRADE_SEND_FAILED:
        error_string = "取引リクエスト送信に失敗。";
        break;
    case ERR_TRADE_CALC_FAILED:
        error_string = "利益または証拠金の計算に失敗";
        break;
    case ERR_INDICATOR_UNKNOWN_SYMBOL:
        error_string = "未知のシンボル。";
        break;
    case ERR_INDICATOR_CANNOT_CREATE:
        error_string = "指標作成が不可。";
        break;
    case ERR_INDICATOR_NO_MEMORY:
        error_string = "指標追加に不充分なメモリ。";
        break;
    case ERR_INDICATOR_CANNOT_APPLY:
        error_string = "指標の他の指標への適用は不可。";
        break;
    case ERR_INDICATOR_CANNOT_ADD:
        error_string = "指標をチャートに適用するのに失敗。";
        break;
    case ERR_INDICATOR_DATA_NOT_FOUND:
        error_string = "リクエストされたデータが見つかりません。";
        break;
    case ERR_INDICATOR_WRONG_HANDLE:
        error_string = "不正な指標ハンドル。";
        break;
    case ERR_INDICATOR_WRONG_PARAMETERS:
        error_string = "指標作成時の不正なパラメータ数。";
        break;
    case ERR_INDICATOR_PARAMETERS_MISSING:
        error_string = "指標作成時にパラメータ型が不在。";
        break;
    case ERR_INDICATOR_CUSTOM_NAME:
        error_string = "配列の最初のパラメータは、カスタム指標の名称でなければなりません。";
        break;
    case ERR_INDICATOR_PARAMETER_TYPE:
        error_string = "指標作成時の配列内の無効なパラメータ型。";
        break;
    case ERR_INDICATOR_WRONG_INDEX:
        error_string = "リクエストされた指標バッファの不正なインデックス。";
        break;
    case ERR_BOOKS_CANNOT_ADD:
        error_string = "板情報の追加が不可能。";
        break;
    case ERR_BOOKS_CANNOT_DELETE:
        error_string = "板情報の削除が不可能。";
        break;
    case ERR_BOOKS_CANNOT_GET:
        error_string = "板情報データ取得が不可能。";
        break;
    case ERR_BOOKS_CANNOT_SUBSCRIBE:
        error_string = "板情報から新規データを取得するのにサブスクライブ中にエラーが発生。";
        break;
    case ERR_TOO_MANY_FILES:
        error_string = "64 を超えるファイルを同時に開く事は不可能。";
        break;
    case ERR_WRONG_FILENAME:
        error_string = "無効なファイル名。";
        break;
    case ERR_TOO_LONG_FILENAME:
        error_string = "長すぎるファイル名。";
        break;
    case ERR_CANNOT_OPEN_FILE:
        error_string = "ファイルオープンエラー。";
        break;
    case ERR_FILE_CACHEBUFFER_ERROR:
        error_string = "読み込みのためにキャッシュに出来るメモリが不足。";
        break;
    case ERR_CANNOT_DELETE_FILE:
        error_string = "ファイル削除エラー。";
        break;
    case ERR_INVALID_FILEHANDLE:
        error_string = "このハンドルを使用したファイルは閉じられた、または、初めから開けられませんでした。";
        break;
    case ERR_WRONG_FILEHANDLE:
        error_string = "不正なファイルハンドル。";
        break;
    case ERR_FILE_NOTTOWRITE:
        error_string = "ファイルは書き込むために開かれる必要があります。";
        break;
    case ERR_FILE_NOTTOREAD:
        error_string = "ファイルは読み込むために開かれる必要があります。";
        break;
    case ERR_FILE_NOTBIN:
        error_string = "ファイルはバイナリとして開かれる必要があります。";
        break;
    case ERR_FILE_NOTTXT:
        error_string = "ファイルはテキストとして開かれる必要があります。";
        break;
    case ERR_FILE_NOTTXTORCSV:
        error_string = "ファイルはテキストまたは CSV として開かれる必要があります。";
        break;
    case ERR_FILE_NOTCSV:
        error_string = "ファイルは CSV として開かれる必要があります。";
        break;
    case ERR_FILE_READERROR:
        error_string = "ファイル読み込みエラー。";
        break;
    case ERR_FILE_BINSTRINGSIZE:
        error_string = "ファイルがバイナリとしてオープンされたため、文字列のサイズ指定が必要。";
        break;
    case ERR_INCOMPATIBLE_FILE:
        error_string = "文字列配列はテキストファイル、他の配列は バイナリファイルでなければいけません。";
        break;
    case ERR_FILE_IS_DIRECTORY:
        error_string = "これはファイルではなくディレクトリです。";
        break;
    case ERR_FILE_NOT_EXIST:
        error_string = "ファイルが不在。";
        break;
    case ERR_FILE_CANNOT_REWRITE:
        error_string = "ファイルの書き換えが不可。";
        break;
    case ERR_WRONG_DIRECTORYNAME:
        error_string = "不正なディレクトリ名。";
        break;
    case ERR_DIRECTORY_NOT_EXIST:
        error_string = "ディレクトリ不在。";
        break;
    case ERR_FILE_ISNOT_DIRECTORY:
        error_string = "これはディレクトリではなくファイルです。";
        break;
    case ERR_CANNOT_DELETE_DIRECTORY:
        error_string = "ディレクトリを削除に失敗。";
        break;
    case ERR_CANNOT_CLEAN_DIRECTORY:
        error_string = "ディレクトリのクリアに失敗（おそらく1つ以上のファイルがブロックされ、除去操作が失敗）。";
        break;
    case ERR_FILE_WRITEERROR:
        error_string = "ファイルへのリソースの書き込みに失敗。";
        break;
    case ERR_FILE_ENDOFFILE:
        error_string = "ファイルの終わりに達する為、CSVファイル(FileReadString、FileReadNumber、FileReadDatetime、FileReadBool)から次のデータを読み取ることができませんでした。";
        break;
    case ERR_NO_STRING_DATE:
        error_string = "文字列内に日付なし。";
        break;
    case ERR_WRONG_STRING_DATE:
        error_string = "文字列で不正な日付。";
        break;
    case ERR_WRONG_STRING_TIME:
        error_string = "文字列内の不正な時刻。";
        break;
    case ERR_STRING_TIME_ERROR:
        error_string = "文字列から日付への変換エラー。";
        break;
    case ERR_STRING_OUT_OF_MEMORY:
        error_string = "文字列に不充分なメモリ。";
        break;
    case ERR_STRING_SMALL_LEN:
        error_string = "予想より短い文字列。";
        break;
    case ERR_STRING_TOO_BIGNUMBER:
        error_string = "大きすぎて ULONG_MAX を超える数。";
        break;
    case ERR_WRONG_FORMATSTRING:
        error_string = "無効なフォーマットストリング。";
        break;
    case ERR_TOO_MANY_FORMATTERS:
        error_string = "フォーマット指定子数がパラメータ数を超過。";
        break;
    case ERR_TOO_MANY_PARAMETERS:
        error_string = "パラメータ数がフォーマット指定子数を超過。";
        break;
    case ERR_WRONG_STRING_PARAMETER:
        error_string = "損傷した文字列型のパラメータ。";
        break;
    case ERR_STRINGPOS_OUTOFRANGE:
        error_string = "位置が文字列の範囲外。";
        break;
    case ERR_STRING_ZEROADDED:
        error_string = "文字列の末尾に 0 が追加されました（無効な操作）。";
        break;
    case ERR_STRING_UNKNOWNTYPE:
        error_string = "文字列への変換時の未知なデータ型。";
        break;
    case ERR_WRONG_STRING_OBJECT:
        error_string = "破損した文字列オブジェクト。";
        break;
    case ERR_INCOMPATIBLE_ARRAYS:
        error_string = "互換性のない配列の複製。文字列配列は文字列配列、数値配列は数値配列のみに複製することが出来ます。";
        break;
    case ERR_SMALL_ASSERIES_ARRAY:
        error_string = "受け取り側の配列は AS_SERIES として宣言されていて、サイズが不充分です。";
        break;
    case ERR_SMALL_ARRAY:
        error_string = "配列が小さすぎ、開始位置が配列の外側にあります。";
        break;
    case ERR_ZEROSIZE_ARRAY:
        error_string = "長さゼロの配列。";
        break;
    case ERR_NUMBER_ARRAYS_ONLY:
        error_string = "数値配列のみ可。";
        break;
    case ERR_ONEDIM_ARRAYS_ONLY:
        error_string = "1 次元配列のみが可。";
        break;
    case ERR_SERIES_ARRAY:
        error_string = "時系列は使用不可。";
        break;
    case ERR_DOUBLE_ARRAY_ONLY:
        error_string = "double 型の配列のみ可。";
        break;
    case ERR_FLOAT_ARRAY_ONLY:
        error_string = "float 型の配列のみ可。";
        break;
    case ERR_LONG_ARRAY_ONLY:
        error_string = "long 型の配列のみ可。";
        break;
    case ERR_INT_ARRAY_ONLY:
        error_string = "int 型の配列のみ可。";
        break;
    case ERR_SHORT_ARRAY_ONLY:
        error_string = "short 型の配列のみ可。";
        break;
    case ERR_CHAR_ARRAY_ONLY:
        error_string = "char 型の配列のみ可。";
        break;
    case ERR_STRING_ARRAY_ONLY:
        error_string = "文字列配列のみ";
        break;
    case ERR_OPENCL_NOT_SUPPORTED:
        error_string = "OpenCL 関数がこのコンピューターでサポートされていません。";
        break;
    case ERR_OPENCL_INTERNAL:
        error_string = "OpenCL実行中中に内部エラー発生。";
        break;
    case ERR_OPENCL_INVALID_HANDLE:
        error_string = "無効なOpenCL ハンドル。";
        break;
    case ERR_OPENCL_CONTEXT_CREATE:
        error_string = "OpenCL コンテキスト作成に失敗。";
        break;
    case ERR_OPENCL_QUEUE_CREATE:
        error_string = "OpenCL の実行キューの作成に失敗。";
        break;
    case ERR_OPENCL_PROGRAM_CREATE :
        error_string = "OpenCL プログラムのコンパイル中にエラー発生。";
        break;
    case ERR_OPENCL_TOO_LONG_KERNEL_NAME:
        error_string = "カーネル名が長すぎます(OpenCL カーネル)。";
        break;
    case ERR_OPENCL_KERNEL_CREATE :
        error_string = "OpenCL カーネル作成エラー。";
        break;
    case ERR_OPENCL_SET_KERNEL_PARAMETER:
        error_string = "OpenCL カーネルパラメータ設定中にエラー発生。";
        break;
    case ERR_OPENCL_EXECUTE:
        error_string = "OpenCL プログラムランタイムエラー。";
        break;
    case ERR_OPENCL_WRONG_BUFFER_SIZE:
        error_string = "OpenCL バッファの無効なサイズ。";
        break;
    case ERR_OPENCL_WRONG_BUFFER_OFFSET:
        error_string = "OpenCL バッファ内の無効なオフセット。";
        break;
    case ERR_OPENCL_BUFFER_CREATE:
        error_string = "OpenCL バッファの作成に失敗。";
        break;
    case ERR_OPENCL_TOO_MANY_OBJECTS:
        error_string = "OpenCLオブジェクトが多すぎる";
        break;
    case ERR_OPENCL_SELECTDEVICE:
        error_string = "OpenCLデバイス選択エラー";
        break;
    case ERR_DATABASE_INTERNAL:
        error_string = "内部データベースエラー";
        break;
    case ERR_DATABASE_INVALID_HANDLE:
        error_string = "無効なデータベースハンドル";
        break;
    case ERR_DATABASE_TOO_MANY_OBJECTS:
        error_string = "Databaseオブジェクトの最大数を超えました";
        break;
    case ERR_DATABASE_CONNECT:
        error_string = "データベース接続エラー";
        break;
    case ERR_DATABASE_EXECUTE:
        error_string = "要求実行エラー";
        break;
    case ERR_DATABASE_PREPARE:
        error_string = "要求生成エラー";
        break;
    case ERR_DATABASE_NO_MORE_DATA:
        error_string = "読み込むデータがありません";
        break;
    case ERR_DATABASE_STEP:
        error_string = "次の要求エントリに移動できませんでした";
        break;
    case ERR_DATABASE_NOT_READY:
        error_string = "要求結果を読み取るためのデータはまだ準備できていません";
        break;
    case ERR_DATABASE_BIND_PARAMETERS:
        error_string = "SQL要求へのパラメーターの自動置換に失敗しました";
        break;
    case ERR_WEBREQUEST_INVALID_ADDRESS:
        error_string = "無効な URL。";
        break;
    case ERR_WEBREQUEST_CONNECT_FAILED:
        error_string = "指定された URL への接続に失敗。";
        break;
    case ERR_WEBREQUEST_TIMEOUT:
        error_string = "タイムアウトを超過。";
        break;
    case ERR_WEBREQUEST_REQUEST_FAILED:
        error_string = "HTTP リクエストに失敗。";
        break;
    case ERR_NETSOCKET_INVALIDHANDLE:
        error_string = "関数に無効なソケットハンドルが渡されました。";
        break;
    case ERR_NETSOCKET_TOO_MANY_OPENED:
        error_string = "開いているソケットが多すぎます(最高128)。";
        break;
    case ERR_NETSOCKET_CANNOT_CONNECT:
        error_string = "遠隔ホストに接続できません。";
        break;
    case ERR_NETSOCKET_IO_ERROR:
        error_string = "ソケットからデータを送受信できません。";
        break;
    case ERR_NETSOCKET_HANDSHAKE_FAILED:
        error_string = "安全な接続を確立できません(TLSハンドシェイク)。";
        break;
    case ERR_NETSOCKET_NO_CERTIFICATE:
        error_string = "接続を保護する証明書に関するデータがありません。";
        break;
    case ERR_NOT_CUSTOM_SYMBOL:
        error_string = "カスタムシンボルが指定されていません。";
        break;
    case ERR_CUSTOM_SYMBOL_WRONG_NAME:
        error_string = "カスタムシンボル名が無効です。シンボル名には、句読点、スペース、特殊文字以外のラテン文字を含めることができます";
        break;
    case ERR_CUSTOM_SYMBOL_NAME_LONG:
        error_string = "カスタムシンボル名が長すぎます。シンボル名の長さは、末尾の0文字を含んで32文字を超えてはなりません。";
        break;
    case ERR_CUSTOM_SYMBOL_PATH_LONG:
        error_string = "カスタムシンボルのパスが長すぎます。パスの長さは\"Custom\"、シンボル名、グループセパレータ、および末尾の0を含んで128文字を超えてはなりません。";
        break;
    case ERR_CUSTOM_SYMBOL_EXIST:
        error_string = "同じ名称のカスタムシンボルが既存。";
        break;
    case ERR_CUSTOM_SYMBOL_ERROR:
        error_string = "カスタムシンボルの作成、削除または変更中にエラーが発生。";
        break;
    case ERR_CUSTOM_SYMBOL_SELECTED:
        error_string = "板情報で選択されたカスタムシンボルを削除しようとしています。";
        break;
    case ERR_CUSTOM_SYMBOL_PROPERTY_WRONG:
        error_string = "カスタムシンボルプロパティが無効。";
        break;
    case ERR_CUSTOM_SYMBOL_PARAMETER_ERROR:
        error_string = "カスタムシンボルのプロパティを設定している際のパラメータが不正。";
        break;
    case ERR_CUSTOM_SYMBOL_PARAMETER_LONG:
        error_string = "カスタムシンボルのプロパティを設定する際に文字列パラメータが長すぎます。";
        break;
    case ERR_CUSTOM_TICKS_WRONG_ORDER:
        error_string = "配列内のティックが時間順でありません";
        break;
    case ERR_CALENDAR_MORE_DATA:
        error_string = "配列サイズがすべての値の説明を受け取るには不十分です";
        break;
    case ERR_CALENDAR_TIMEOUT:
        error_string = "リクエストの制限時間を超えました";
        break;
    case ERR_CALENDAR_NO_DATA:
        error_string = "国が見つかりません";
        break;
    case ERR_DATABASE_ERROR  :
        error_string = "一般的なエラー";
        break;
    case ERR_DATABASE_ABORT:
        error_string = "コールバックルーチンが中止を要求しました";
        break;
    case ERR_DATABASE_BUSY:
        error_string = "データベースファイルがロックされています";
        break;
    case ERR_DATABASE_LOCKED:
        error_string = "データベーステーブルがロックされています<分節 2781";
        break;
    case ERR_DATABASE_NOMEM:
        error_string = "操作を完了するためのメモリが不足しています";
        break;
    case ERR_DATABASE_READONLY:
        error_string = "読み取り専用データベースへの書き込みが試みされました";
        break;
    case 5609 /*ERR_DATABASE_INTERRUPT*/:
        error_string = "操作がsqlite3_interrupt()によって終了されました";
        break;
    case ERR_DATABASE_IOERR:
        error_string = "ディスクI/Oエラー";
        break;
    case ERR_DATABASE_CORRUPT:
        error_string = "データベースディスクイメージが破損しています";
        break;
    case 5612 /*ERR_DATABASE_NOTFOUND*/:
        error_string = "sqlite3_file_control()に不明な操作コードがあります";
        break;
    case ERR_DATABASE_FULL:
        error_string = "データベースがいっぱいのため、挿入に失敗しました";
        break;
    case ERR_DATABASE_CANTOPEN:
        error_string = "データベースファイルを開くことができません";
        break;
    case ERR_DATABASE_PROTOCOL:
        error_string = "データベースロックプロトコルエラー";
        break;
    case 5616 /*ERR_DATABASE_EMPTY*/:
        error_string = "内部使用のみ";
        break;
    case ERR_DATABASE_SCHEMA:
        error_string = "データベーススキーマが変更されました";
        break;
    case ERR_DATABASE_TOOBIG:
        error_string = "文字列またはBLOBがサイズ制限を超えています";
        break;
    case ERR_DATABASE_CONSTRAINT:
        error_string = "制約違反による中止";
        break;
    case ERR_DATABASE_MISMATCH:
        error_string = "データ型の不一致";
        break;
    case ERR_DATABASE_MISUSE:
        error_string = "ライブラリが正しく使用されていません";
        break;
    case 5622 /*ERR_DATABASE_NOLFS*/:
        error_string = "ホストでサポートされていないOS機能を使用しています";
        break;
    case ERR_DATABASE_AUTH:
        error_string = "承認が拒否されました";
        break;
    case 5624 /*ERR_DATABASE_FORMAT*/:
        error_string = "ERR_DATABASE_FORMAT";
        break;
    case ERR_DATABASE_RANGE:
        error_string = "バインドパラメータエラー、不正なインデックス";
        break;
    case ERR_DATABASE_NOTADB:
        error_string = "データベースファイルではないファイルが開かれました";
        break;
    case ERR_USER_ERROR_FIRST:
        error_string = "ユーザ定義エラ―はこのコードで始まります。";
        break;
    default:
        error_string = "未知のエラー";
        break;
    }
    return StringFormat("%s(%d)", error_string, error_code);
}
//+------------------------------------------------------------------+
