#!/bin/sh
# GUT テストをヘッドレスで実行する。GODOT 環境変数で実行ファイルを上書き可能。
# コンパイルエラーのテストスクリプトを GUT は警告だけでスキップするため、それも失敗扱いにする。
GODOT="${GODOT:-C:/Tools/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")" || exit 1

# class_name のグローバル登録を更新する
"$GODOT" --headless --import >/dev/null 2>&1

LOG=$(mktemp)
"$GODOT" --headless -s addons/gut/gut_cmdln.gd "$@" 2>&1 | tee "$LOG"
STATUS=$?
if grep -qE "Ignoring script|Parse Error" "$LOG"; then
	echo "!!! コンパイルエラーのためスキップされたテストスクリプトがあります !!!"
	STATUS=1
fi
grep -q "All tests passed" "$LOG" || STATUS=1
rm -f "$LOG"
exit $STATUS
