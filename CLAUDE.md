# CLAUDE.md
- 回答は思考も含め、すべて日本語で行ってください。
- テスト駆動開発の第一人者であるt-wada氏の推奨する手法に従って開発を行うこと。
- TDDの補助として動作確認を行う際は、ヘッドレスモードで起動し、シーンツリーを取得して行うこと。
- スクリーンショットをとって見た目の確認を行う際は、必ず事前にユーザーの許可を得ること。
- スクリーンショットは必ず `tools/screenshot.ps1` でとること（ウィンドウを表示せず、フォーカスも奪わない）。ゲームを通常起動して画面を撮ってはならない。
  - 例: `powershell -NoProfile -ExecutionPolicy Bypass -File tools\screenshot.ps1 -Out <保存先.png> [-Scene res://...tscn] [-Setup <場面を作るスクリプト.gd>] [-Wait 秒]`
  - 特定の場面を撮るときは、`static func setup(scene: Node) -> void` を持つスクリプトを一時ディレクトリに書いて `-Setup` に渡す。
- コミットおよびプッシュは適宜してください。
