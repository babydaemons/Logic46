//+------------------------------------------------------------------+
//|                                             ErrorDescription.mqh |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
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
    case 0:
        error_string = "操作が正常に完了しました。";
        break;
    case 4001:
        error_string = "予期しない内部エラー。";
        break;
    case 4002:
        error_string = "クライアント端末関数の内部呼び出しでの不正なパラメータ。";
        break;
    case 4003:
        error_string = "システム関数呼び出し時の不正なパラメータ。";
        break;
    case 4004:
        error_string = "システム関数の実行に不充分なメモリ。";
        break;
    case 4005:
        error_string = "構造体に、文字列、及び/または動的な配列及び/またはそのようなオブジェクトの構造体及び/またはクラスが含まれます。";
        break;
    case 4006:
        error_string = "型やサイズが不正な配列、または動的配列内に損傷を受けたオブジェクト。";
        break;
    case 4007:
        error_string = "配列の移転に不充分なメモリ、または静的配列のサイズを変更する試み。";
        break;
    case 4008:
        error_string = "文字列の再配置に不充分なメモリ。";
        break;
    case 4009:
        error_string = "初期化されていない文字列。";
        break;
    case 4010:
        error_string = "無効な日付/時刻。";
        break;
    case 4011:
        error_string = "配列の要素数の合計は 2,147,483,647を超えることは出来ません。";
        break;
    case 4012:
        error_string = "不正なポインタ。";
        break;
    case 4013:
        error_string = "不正なポインタ型。";
        break;
    case 4014:
        error_string = "関数呼び出しの許可がありません。";
        break;
    case 4015:
        error_string = "同一の動的及び静的リソース名。";
        break;
    case 4016:
        error_string = "この名称のリソースがEX5で見つかりません。";
        break;
    case 4017:
        error_string = "リソースタイプがサポートされていないかサイズが 16 MB を超えます。";
        break;
    case 4018:
        error_string = "リソース名が 63 字を超えます。";
        break;
    case 4019:
        error_string = "数学関数の計算時にオーバーフローが発生";
        break;
    case 4020:
        error_string = "Sleep()呼び出しが終了日より後です。";
        break;
    case 4022:
        error_string = "テストは外部から強制停止されました。例は、最適化の中断、視覚的テストウィンドウの終了、テストエージェントの停止です。";
        break;
    case 4101:
        error_string = "不正なチャート識別子。";
        break;
    case 4102:
        error_string = "チャートが応答しません。";
        break;
    case 4103:
        error_string = "チャートが見つかりません。";
        break;
    case 4104:
        error_string = "イベントを処理出来るエキスパートアドバイザーがチャートに不在。";
        break;
    case 4105:
        error_string = "チャートオープンエラー。";
        break;
    case 4106:
        error_string = "銘柄と期間の変更に失敗。";
        break;
    case 4107:
        error_string = "チャート操作の関数のパラメータ値のエラー。";
        break;
    case 4108:
        error_string = "タイマー作成に失敗。";
        break;
    case 4109:
        error_string = "不正なチャートプロパティ識別子。";
        break;
    case 4110:
        error_string = "スクリーンショット作成エラー。";
        break;
    case 4111:
        error_string = "チャートナビゲートエラー。";
        break;
    case 4112:
        error_string = "テンプレート適用エラー。";
        break;
    case 4113:
        error_string = "指標を含むサブウィンドウが不在。";
        break;
    case 4114:
        error_string = "指標をチャートに追加するのに失敗。";
        break;
    case 4115:
        error_string = "指標をチャートから削除するのに失敗。";
        break;
    case 4116:
        error_string = "指標が指定されたチャートに不在。";
        break;
    case 4201:
        error_string = "グラフィックオブジェクト操作エラー。";
        break;
    case 4202:
        error_string = "グラフィックオブジェクトが見つかりません。";
        break;
    case 4203:
        error_string = "グラフィックオブジェクトプロパティの不正な ID。";
        break;
    case 4204:
        error_string = "値に対応する日付の取得が不可能。";
        break;
    case 4205:
        error_string = "日付に対応する値の取得が不可能。";
        break;
    case 4301:
        error_string = "未知のシンボル。";
        break;
    case 4302:
        error_string = "「気配値表示」でシンボルが未選択。";
        break;
    case 4303:
        error_string = "シンボルプロパティの不正な識別子。";
        break;
    case 4304:
        error_string = "最後のティックの時間が未知（ティック不在）。";
        break;
    case 4305:
        error_string = "「気配値表示」のシンボル追加・削除に失敗。";
        break;
    case 4402:
        error_string = "不正な履歴プロパティ識別子。";
        break;
    case 4403:
        error_string = "履歴リクエストがタイムアウトしました。";
        break;
    case 4404:
        error_string = "要求されたバーの数が端末の設定によって制限されています。";
        break;
    case 4405:
        error_string = "履歴を読み込む際に複数のエラーが生成されました。";
        break;
    case 4407:
        error_string = "受信する配列が小さすぎて、リクエストされたすべてのデータを格納できません。";
        break;
    case 4501:
        error_string = "クライアント端末のグローバル変数が見つかりません。";
        break;
    case 4502:
        error_string = "同名のクライアント端末のグローバル変数が既存。";
        break;
    case 4503:
        error_string = "グローバル変数が変更されていない";
        break;
    case 4504:
        error_string = "グローバル変数値を持つファイルの読み取りが不可能";
        break;
    case 4505:
        error_string = "グローバル変数値を持つファイルの書き込みが不可能";
        break;
    case 4510:
        error_string = "メール送信に失敗。";
        break;
    case 4511:
        error_string = "音の再生に失敗。";
        break;
    case 4512:
        error_string = "プログラムプロパティの不正な識別子。";
        break;
    case 4513:
        error_string = "端末プロパティの不正な識別子。";
        break;
    case 4514:
        error_string = "FTP でのファイル送信に失敗。";
        break;
    case 4515:
        error_string = "通知送信に失敗。";
        break;
    case 4516:
        error_string = "通知送信に無効なパラメータ（空の文字列か NULL ）が SendNotification() 関数に渡されました。";
        break;
    case 4517:
        error_string = "端末内の不正な通知の設定（IDの未指定か、許可の無設定）。";
        break;
    case 4518:
        error_string = "頻繁過ぎる通知の送信。";
        break;
    case 4519:
        error_string = "FTPサーバが指定されていません。";
        break;
    case 4520:
        error_string = "FTPログインが指定されていません。";
        break;
    case 4521:
        error_string = "FTPサーバに送信するファイルがMQL5\\Filesディレクトリで見つかりません。";
        break;
    case 4522:
        error_string = "FTP接続に失敗しました。";
        break;
    case 4523:
        error_string = "サーバでFTPパスが見つかりません。";
        break;
    case 4524:
        error_string = "FTP接続が閉じられました。";
        break;
    case 4601:
        error_string = "指標バッファ配布に不充分なメモリ。";
        break;
    case 4602:
        error_string = "不正な指標バッファインデックス。";
        break;
    case 4603:
        error_string = "不正なカスタム指標プロパティ識別子。";
        break;
    case 4701:
        error_string = "不正な口座プロパティ識別子。";
        break;
    case 4751:
        error_string = "不正な取引プロパティ識別子。";
        break;
    case 4752:
        error_string = "エキスパートアドバイザーでの取引が許可されていません。";
        break;
    case 4753:
        error_string = "ポジションが見つかりません。";
        break;
    case 4754:
        error_string = "注文が見つかりません。";
        break;
    case 4755:
        error_string = "約定が見つかりません。";
        break;
    case 4756:
        error_string = "取引リクエスト送信に失敗。";
        break;
    case 4758:
        error_string = "利益または証拠金の計算に失敗";
        break;
    case 4801:
        error_string = "未知のシンボル。";
        break;
    case 4802:
        error_string = "指標作成が不可。";
        break;
    case 4803:
        error_string = "指標追加に不充分なメモリ。";
        break;
    case 4804:
        error_string = "指標の他の指標への適用は不可。";
        break;
    case 4805:
        error_string = "指標をチャートに適用するのに失敗。";
        break;
    case 4806:
        error_string = "リクエストされたデータが見つかりません。";
        break;
    case 4807:
        error_string = "不正な指標ハンドル。";
        break;
    case 4808:
        error_string = "指標作成時の不正なパラメータ数。";
        break;
    case 4809:
        error_string = "指標作成時にパラメータ型が不在。";
        break;
    case 4810:
        error_string = "配列の最初のパラメータは、カスタム指標の名称でなければなりません。";
        break;
    case 4811:
        error_string = "指標作成時の配列内の無効なパラメータ型。";
        break;
    case 4812:
        error_string = "リクエストされた指標バッファの不正なインデックス。";
        break;
    case 4901:
        error_string = "板情報の追加が不可能。";
        break;
    case 4902:
        error_string = "板情報の削除が不可能。";
        break;
    case 4903:
        error_string = "板情報データ取得が不可能。";
        break;
    case 4904:
        error_string = "板情報から新規データを取得するのにサブスクライブ中にエラーが発生。";
        break;
    case 5001:
        error_string = "64 を超えるファイルを同時に開く事は不可能。";
        break;
    case 5002:
        error_string = "無効なファイル名。";
        break;
    case 5003:
        error_string = "長すぎるファイル名。";
        break;
    case 5004:
        error_string = "ファイルオープンエラー。";
        break;
    case 5005:
        error_string = "読み込みのためにキャッシュに出来るメモリが不足。";
        break;
    case 5006:
        error_string = "ファイル削除エラー。";
        break;
    case 5007:
        error_string = "このハンドルを使用したファイルは閉じられた、または、初めから開けられませんでした。";
        break;
    case 5008:
        error_string = "不正なファイルハンドル。";
        break;
    case 5009:
        error_string = "ファイルは書き込むために開かれる必要があります。";
        break;
    case 5010:
        error_string = "ファイルは読み込むために開かれる必要があります。";
        break;
    case 5011:
        error_string = "ファイルはバイナリとして開かれる必要があります。";
        break;
    case 5012:
        error_string = "ファイルはテキストとして開かれる必要があります。";
        break;
    case 5013:
        error_string = "ファイルはテキストまたは CSV として開かれる必要があります。";
        break;
    case 5014:
        error_string = "ファイルは CSV として開かれる必要があります。";
        break;
    case 5015:
        error_string = "ファイル読み込みエラー。";
        break;
    case 5016:
        error_string = "ファイルがバイナリとしてオープンされたため、文字列のサイズ指定が必要。";
        break;
    case 5017:
        error_string = "文字列配列はテキストファイル、他の配列は バイナリファイルでなければいけません。";
        break;
    case 5018:
        error_string = "これはファイルではなくディレクトリです。";
        break;
    case 5019:
        error_string = "ファイルが不在。";
        break;
    case 5020:
        error_string = "ファイルの書き換えが不可。";
        break;
    case 5021:
        error_string = "不正なディレクトリ名。";
        break;
    case 5022:
        error_string = "ディレクトリ不在。";
        break;
    case 5023:
        error_string = "これはディレクトリではなくファイルです。";
        break;
    case 5024:
        error_string = "ディレクトリを削除に失敗。";
        break;
    case 5025:
        error_string = "ディレクトリのクリアに失敗（おそらく1つ以上のファイルがブロックされ、除去操作が失敗）。";
        break;
    case 5026:
        error_string = "ファイルへのリソースの書き込みに失敗。";
        break;
    case 5027:
        error_string = "ファイルの終わりに達する為、CSVファイル(FileReadString、FileReadNumber、FileReadDatetime、FileReadBool)から次のデータを読み取ることができませんでした。";
        break;
    case 5030:
        error_string = "文字列内に日付なし。";
        break;
    case 5031:
        error_string = "文字列で不正な日付。";
        break;
    case 5032:
        error_string = "文字列内の不正な時刻。";
        break;
    case 5033:
        error_string = "文字列から日付への変換エラー。";
        break;
    case 5034:
        error_string = "文字列に不充分なメモリ。";
        break;
    case 5035:
        error_string = "予想より短い文字列。";
        break;
    case 5036:
        error_string = "大きすぎて ULONG_MAX を超える数。";
        break;
    case 5037:
        error_string = "無効なフォーマットストリング。";
        break;
    case 5038:
        error_string = "フォーマット指定子数がパラメータ数を超過。";
        break;
    case 5039:
        error_string = "パラメータ数がフォーマット指定子数を超過。";
        break;
    case 5040:
        error_string = "損傷した文字列型のパラメータ。";
        break;
    case 5041:
        error_string = "位置が文字列の範囲外。";
        break;
    case 5042:
        error_string = "文字列の末尾に 0 が追加されました（無効な操作）。";
        break;
    case 5043:
        error_string = "文字列への変換時の未知なデータ型。";
        break;
    case 5044:
        error_string = "破損した文字列オブジェクト。";
        break;
    case 5050:
        error_string = "互換性のない配列の複製。文字列配列は文字列配列、数値配列は数値配列のみに複製することが出来ます。";
        break;
    case 5051:
        error_string = "受け取り側の配列は AS_SERIES として宣言されていて、サイズが不充分です。";
        break;
    case 5052:
        error_string = "配列が小さすぎ、開始位置が配列の外側にあります。";
        break;
    case 5053:
        error_string = "長さゼロの配列。";
        break;
    case 5054:
        error_string = "数値配列のみ可。";
        break;
    case 5055:
        error_string = "1 次元配列のみが可。";
        break;
    case 5056:
        error_string = "時系列は使用不可。";
        break;
    case 5057:
        error_string = "double 型の配列のみ可。";
        break;
    case 5058:
        error_string = "float 型の配列のみ可。";
        break;
    case 5059:
        error_string = "long 型の配列のみ可。";
        break;
    case 5060:
        error_string = "int 型の配列のみ可。";
        break;
    case 5061:
        error_string = "short 型の配列のみ可。";
        break;
    case 5062:
        error_string = "char 型の配列のみ可。";
        break;
    case 5063:
        error_string = "文字列配列のみ";
        break;
    case 5100:
        error_string = "OpenCL 関数がこのコンピューターでサポートされていません。";
        break;
    case 5101:
        error_string = "OpenCL実行中中に内部エラー発生。";
        break;
    case 5102:
        error_string = "無効なOpenCL ハンドル。";
        break;
    case 5103:
        error_string = "OpenCL コンテキスト作成に失敗。";
        break;
    case 5104:
        error_string = "OpenCL の実行キューの作成に失敗。";
        break;
    case 5105:
        error_string = "OpenCL プログラムのコンパイル中にエラー発生。";
        break;
    case 5106:
        error_string = "カーネル名が長すぎます(OpenCL カーネル)。";
        break;
    case 5107:
        error_string = "OpenCL カーネル作成エラー。";
        break;
    case 5108:
        error_string = "OpenCL カーネルパラメータ設定中にエラー発生。";
        break;
    case 5109:
        error_string = "OpenCL プログラムランタイムエラー。";
        break;
    case 5110:
        error_string = "OpenCL バッファの無効なサイズ。";
        break;
    case 5111:
        error_string = "OpenCL バッファ内の無効なオフセット。";
        break;
    case 5112:
        error_string = "OpenCL バッファの作成に失敗。";
        break;
    case 5113:
        error_string = "OpenCLオブジェクトが多すぎる";
        break;
    case 5114:
        error_string = "OpenCLデバイス選択エラー";
        break;
    case 5120:
        error_string = "内部データベースエラー";
        break;
    case 5121:
        error_string = "無効なデータベースハンドル";
        break;
    case 5122:
        error_string = "Databaseオブジェクトの最大数を超えました";
        break;
    case 5123:
        error_string = "データベース接続エラー";
        break;
    case 5124:
        error_string = "要求実行エラー";
        break;
    case 5125:
        error_string = "要求生成エラー";
        break;
    case 5126:
        error_string = "読み込むデータがありません";
        break;
    case 5127:
        error_string = "次の要求エントリに移動できませんでした";
        break;
    case 5128:
        error_string = "要求結果を読み取るためのデータはまだ準備できていません";
        break;
    case 5129:
        error_string = "SQL要求へのパラメーターの自動置換に失敗しました";
        break;
    case 5200:
        error_string = "無効な URL。";
        break;
    case 5201:
        error_string = "指定された URL への接続に失敗。";
        break;
    case 5202:
        error_string = "タイムアウトを超過。";
        break;
    case 5203:
        error_string = "HTTP リクエストに失敗。";
        break;
    case 5270:
        error_string = "関数に無効なソケットハンドルが渡されました。";
        break;
    case 5271:
        error_string = "開いているソケットが多すぎます(最高128)。";
        break;
    case 5272:
        error_string = "遠隔ホストに接続できません。";
        break;
    case 5273:
        error_string = "ソケットからデータを送受信できません。";
        break;
    case 5274:
        error_string = "安全な接続を確立できません(TLSハンドシェイク)。";
        break;
    case 5275:
        error_string = "接続を保護する証明書に関するデータがありません。";
        break;
    case 5300:
        error_string = "カスタムシンボルが指定されていません。";
        break;
    case 5301:
        error_string = "カスタムシンボル名が無効です。シンボル名には、句読点、スペース、特殊文字以外のラテン文字を含めることができます。";
        break;
    case 5302:
        error_string = "カスタムシンボル名が長すぎます。シンボル名の長さは、末尾の0文字を含んで32文字を超えてはなりません。";
        break;
    case 5303:
        error_string = "カスタムシンボルのパスが長すぎます。";
        break;
    case 5304:
        error_string = "同じ名称のカスタムシンボルが既存。";
        break;
    case 5305:
        error_string = "カスタムシンボルの作成、削除または変更中にエラーが発生。";
        break;
    case 5306:
        error_string = "板情報で選択されたカスタムシンボルを削除しようとしています。";
        break;
    case 5307:
        error_string = "カスタムシンボルプロパティが無効。";
        break;
    case 5308:
        error_string = "カスタムシンボルのプロパティを設定している際のパラメータが不正。";
        break;
    case 5309:
        error_string = "カスタムシンボルのプロパティを設定する際に文字列パラメータが長すぎます。";
        break;
    case 5310:
        error_string = "配列内のティックが時間順でありません";
        break;
    case 5400:
        error_string = "配列サイズがすべての値の説明を受け取るには不十分です";
        break;
    case 5401:
        error_string = "リクエストの制限時間を超えました";
        break;
    case 5402:
        error_string = "国が見つかりません";
        break;
    case 5601:
        error_string = "一般的なエラー";
        break;
    case 5602:
        error_string = "SQLite内部ロジックエラー";
        break;
    case 5603:
        error_string = "アクセスが拒否されました";
        break;
    case 5604:
        error_string = "コールバックルーチンが中止を要求しました";
        break;
    case 5605:
        error_string = "データベースファイルがロックされています";
        break;
    case 5606:
        error_string = "データベーステーブルがロックされています<分節 2781";
        break;
    case 5607:
        error_string = "操作を完了するためのメモリが不足しています";
        break;
    case 5608:
        error_string = "読み取り専用データベースへの書き込みが試みされました";
        break;
    case 5609:
        error_string = "操作がsqlite3_interrupt()によって終了されました";
        break;
    case 5610:
        error_string = "ディスクI/Oエラー";
        break;
    case 5611:
        error_string = "データベースディスクイメージが破損しています";
        break;
    case 5612:
        error_string = "sqlite3_file_control()に不明な操作コードがあります";
        break;
    case 5613:
        error_string = "データベースがいっぱいのため、挿入に失敗しました";
        break;
    case 5614:
        error_string = "データベースファイルを開くことができません";
        break;
    case 5615:
        error_string = "データベースロックプロトコルエラー";
        break;
    case 5616:
        error_string = "内部使用のみ";
        break;
    case 5617:
        error_string = "データベーススキーマが変更されました";
        break;
    case 5618:
        error_string = "文字列またはBLOBがサイズ制限を超えています";
        break;
    case 5619:
        error_string = "制約違反による中止";
        break;
    case 5620:
        error_string = "データ型の不一致";
        break;
    case 5621:
        error_string = "ライブラリが正しく使用されていません";
        break;
    case 5622:
        error_string = "ホストでサポートされていないOS機能を使用しています";
        break;
    case 5623:
        error_string = "承認が拒否されました";
        break;
    case 5624:
        error_string = "未使用";
        break;
    case 5625:
        error_string = "バインドパラメータエラー、不正なインデックス";
        break;
    case 5626:
        error_string = "データベースファイルではないファイルが開かれました";
        break;
    default:
        error_string = "未知のエラー";
        break;
    }
    return error_string;
}
//+------------------------------------------------------------------+
