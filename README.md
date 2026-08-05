# OKUDA STUDIO

AI-assisted creative studio.

## Projects

- 🎮 GAME
- 🎨 ART
- 📱 SNS
- 🏫 SCHOOL

## Goal

Build games, artworks and content with AI agents.

## WindowsでNESゲームを更新して起動する

GitHubでPull RequestをMergeしたあと、Windows 10のローカルPCでは、リポジトリ直下の `更新してゲームを起動.bat` をダブルクリックするとNESゲームを確認できます。

このバッチファイルは次の処理を自動で行います。

1. バッチファイル自身が置かれているOKUDA-STUDIOフォルダを作業場所にする
2. `main` ブランチへ切り替える
3. `git pull origin main` で最新版を取得する
4. Git Bash経由で `make -C projects/nes-block-breaker` を実行してROMをビルドする
5. ビルドされた `projects/nes-block-breaker/build/main.nes` をFCEUXで開く

Git BashはGit for Windowsの一般的なインストール場所から自動検出します。FCEUXも一般的なインストール場所から自動検出し、見つからない場合は `fceux.exe` を選択する画面を表示します。選択したFCEUXのパスは `.fceux_path.txt` に保存されるため、次回以降は再選択せずに起動できます。

途中で失敗した場合はウィンドウを閉じず、日本語のエラーメッセージを表示します。Dropbox内など、パスに日本語や空白が含まれる場所でも動作するように、各パスは引用符付きで処理しています。
