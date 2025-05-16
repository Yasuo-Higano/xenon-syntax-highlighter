// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	console.log('Activating Xenon Syntax Highlight extension...');
	
	// 言語ID
	const languageId = 'xenon';
	
	try {
		// 言語IDの手動登録を試みる
		const tmLanguagePath = path.join(context.extensionPath, 'syntaxes', 'xenon.tmLanguage.json');
		console.log(`TextMate文法ファイルのパス: ${tmLanguagePath}`);
		
		// ファイルの存在確認
		if (fs.existsSync(tmLanguagePath)) {
			console.log('TextMate文法ファイルが見つかりました');
			const grammarContent = fs.readFileSync(tmLanguagePath, 'utf8');
			console.log(`文法ファイルサイズ: ${grammarContent.length} バイト`);
		} else {
			console.error('エラー: TextMate文法ファイルが見つかりません');
		}
	
		// TextMate文法の手動登録
		try {
			const selector: vscode.DocumentSelector = { language: languageId, scheme: 'file' };
			console.log(`言語セレクタを登録: ${JSON.stringify(selector)}`);
			
			// 現在のワークスペースのファイルでxenonファイルを検索
			vscode.workspace.findFiles('**/*.xenon').then(
				(files) => {
					console.log(`ワークスペースで見つかった.xenonファイル: ${files.length}件`);
					files.forEach(file => {
						console.log(`  - ${file.fsPath}`);
					});
				},
				(error: Error) => {
					console.error('ファイル検索エラー:', error);
				}
			);
		} catch (error) {
			console.error('言語登録エラー:', error);
		}
	} catch (error) {
		console.error('拡張機能初期化エラー:', error);
	}

	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "xenon-syntax-highlight" is now active!');
	
	// デバッグ情報の追加
	console.log('Xenon言語設定情報:');
	vscode.languages.getLanguages().then(
		(langs) => {
			console.log(`- 登録されている言語一覧:`);
			console.log(langs.join(', '));
			const hasXenon = langs.includes('xenon');
			console.log(`- xenon言語は${hasXenon ? '登録済み' : '未登録'}`);
		},
		(error: Error) => {
			console.error('言語リスト取得エラー:', error);
		}
	);
	
	// ファイル関連付けの確認
	const xenonConfig = vscode.workspace.getConfiguration('files').get('associations');
	console.log(`- files.associations設定: ${JSON.stringify(xenonConfig)}`);
	
	// TextMate文法情報
	console.log(`- 拡張機能のパス: ${context.extensionPath}`);
	console.log(`- シンタックスファイルのパス: ${context.extensionPath}/syntaxes/xenon.tmLanguage.json`);

	// イベントリスナーを追加してドキュメント開閉時のデバッグ
	vscode.workspace.onDidOpenTextDocument(doc => {
		console.log(`ドキュメントが開かれました: ${doc.fileName}, 言語ID: ${doc.languageId}`);
		if (doc.fileName.endsWith('.xenon')) {
			console.log(`Xenonファイルが検出されました: ${doc.fileName}`);
			// 言語IDを強制的に設定
			vscode.languages.setTextDocumentLanguage(doc, languageId).then(newDoc => {
				console.log(`言語IDを設定しました: ${newDoc.languageId}`);
			});
		}
	});
	
	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	const disposable = vscode.commands.registerCommand('xenon-syntax-highlight.helloWorld', () => {
		// The code you place here will be executed every time your command is executed
		// Display a message box to the user
		vscode.window.showInformationMessage('Hello World from Xenon Syntax Highlight!');
	});

	// 言語ID確認コマンドを追加
	const checkLanguageIdCommand = vscode.commands.registerCommand('xenon-syntax-highlight.checkLanguageId', () => {
		const editor = vscode.window.activeTextEditor;
		if (editor) {
			const doc = editor.document;
			vscode.window.showInformationMessage(`Current file: ${doc.fileName}, Language ID: ${doc.languageId}`);
			console.log(`Current file: ${doc.fileName}, Language ID: ${doc.languageId}`);
		} else {
			vscode.window.showInformationMessage('No active editor!');
		}
	});

	context.subscriptions.push(disposable);
	context.subscriptions.push(checkLanguageIdCommand);
}

// This method is called when your extension is deactivated
export function deactivate() {
	console.log('Xenon Syntax Highlight拡張機能が停止しました');
}
