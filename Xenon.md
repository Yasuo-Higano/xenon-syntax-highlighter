# 🧬 Xenon DSL 仕様書 ver 0.5.0

## 概要

Xenon は、関数呼び出し風の記法を用いて構造化データを簡潔に定義するDSLです。
`#` を用いたセクションラベルでリストを定義します。

---

## 🏷 キーワード（予約語）

以下の語は識別子として使用できません：

```
deftype, defenum, defunion, list, map, true, false, null
```

---

## 💬 コメント

* 行頭に `//` を記述（前に空白があってもOK）

```xenon
// コメントです
deftype User(name: string)
```

## ブロックコメント

/* */
/** **/
/*** ***/
/**** ****/
- 連続する*の個数が一致する必要があります。
- コメントはプリプロセッサーで処理されるため、pegjsでは処理する必要はありません。

---

## 🔤 型定義

### 列挙型（Enum）

```xenon
defenum Role = Admin | User | Guest
```

* 列挙値は縦書きや区切り文字（`|`）で区切ることができます

### 共用型（Union）

```xenon
defunion Item = Text | Image | Audio
```

* 共用型も列挙型と同様に縦書きや区切り文字で表現可能です

### 通常型（Type）

```xenon
deftype User(name: string, age: int?)
```

* `?` を付けることで nullable 型
* デフォルト値の指定も可能：

```xenon
deftype User(name: string = "anonymous", age: int = 0)
```

* フィールドの区切りには`,`または改行が使えます：

```xenon
deftype User(
  id: int, 
  name: string = "unnamed", 
  role: Role = User
)
```

---

## 🧩 型システム

### プリミティブ型

* `int`, `float`, `bool`, `string`, `binary`

### Nullable型

* 例：`int?`, `string?`

### ジェネリック型

* `list<int>` - リスト型
* `map<string, string>` - マップ型（キーと値の型を指定）

```xenon
deftype Request(
  url: string, 
  method: string = "GET", 
  headers: map<string, string> = {}
)
```

---

## 🏷 セクションラベル構文

### セクション記法（`#`）でリストを定義

```xenon
# Users
User(name: "Alice", age: 30)
User(name: "Bob", age: 25)

## Admins
User(name: "Carol", age: 40)
```

* `#`, `##`, `###` による階層を表現可能
* セクションの中は宣言のリスト
* セクションはネストでき、パスとして参照可能（例: `Users.Admins`）

### セクション階層例

```xenon
# Definitions
Info(name: "xenon", version: "0.1.0")

## Members
User(id: 1, name: "Alice")
User(id: 2, name: "Bob", role: Admin)

## Plugins
Plugin(name: "PluginA", version: "1.0.0")
```

* この例では `Definitions` セクションの下に `Members` と `Plugins` サブセクションがあります

---

## 🧾 リテラル

### 整数 / 浮動小数点数

```xenon
42
0xdeadbeef
3.1415
```

### 真偽値 / Null

```xenon
true
false
null
```

### 文字列リテラル

```xenon
"abc"        // 二重引用符
'abc'        // 単一引用符
"""
複数行の
テキスト
"""          // 三重二重引用符（複数行）
'''
複数行の
テキスト
'''          // 三重単一引用符（複数行）
```

* 単一引用符と二重引用符ではエスケープが必要：
  * `\"` - 二重引用符内の引用符
  * `\'` - 単一引用符内の引用符
  * `\\` - バックスラッシュ
  * `\n` - 改行
  * `\r` - キャリッジリターン
  * `\t` - タブ
  * `\b` - バックスペース
  * `\f` - フォームフィード

* 三重引用符では複数行テキストとエスケープなしに特殊文字を含められます

### バイナリリテラル

バイナリデータは `<<` と `>>` で囲まれたデータで表現します。複数の異なるエンコーディングのデータを混在させることができます。

```xenon
// 基本的なバイナリリテラル
<<1, 2, 3, 4, 5>>  // 数値の配列

// 混合エンコーディングのバイナリリテラル
<<
  1, 2, 3,                // 数値（バイト）
  "UTF8文字列",            // UTF-8文字列
  "0123ABCDEF"/hex,      // 16進数エンコーディング
  "BASE32DATA"/base32,   // Base32エンコーディング
  "BASE64DATA"/base64    // Base64エンコーディング
>>
```

* サポートされるエンコーディング形式：
  * `/utf8` または指定なし - UTF-8文字列（デフォルト）
  * `/hex` - 16進数エンコード
  * `/base32` - Base32エンコード
  * `/base64` - Base64エンコード
* 整数値は0-255の範囲の単一バイト値として扱われます
* バイナリデータは複数行で記述可能で、カンマで区切ります
* 各要素の前後の空白は無視されます

### リスト / マップ

```xenon
[1, 2, 3]
{
  "key": "value", 
  "count": 42
}
```

* リストとマップは複数行で記述可能：

```xenon
[
  "item1",
  "item2"
]

{
  "Content-Type": "application/json",
  "Authorization": "Bearer TOKEN"
}
```

---

## ✨ 複数行表現

全ての要素は複数行で記述可能です：

```xenon
deftype Plugin(
  name: string, 
  version: string, 
  depends: list<string> = []
)

User(
  id: 2, 
  name: "Bob", 
  role: Admin
)
```

---

## ✨ アノテーション

```xenon
deftype User(
  @id id: int,
  @range(0, 150) age: int = 30
)
```

使用例：

* `@id`, `@range`, `@default`, `@readonly`, `@deprecated("理由")` など

---

## ✅ 文法の特徴

| 項目      | 内容                           |
| ------- | ---------------------------- |
| 宣言   | `TypeName(key: value, ...)`  |
| 階層表現    | セクションラベルで可能                  |
| AST変換   | 容易（JSON・Prolog・YAMLなど）       |
| インデント制御 | **不要**（`@@INDENT@@`などは廃止）    |
| パーサー構築  | PEG.js / peggy / Ohm-js に最適化 |

---

## �� 例：完全な定義

```xenon
defenum Role = Admin | User

deftype Info(
  name: string,
  version: string,
  metas: map<string, string> = {}
)

deftype User(
  id: int,
  name: string = "unnamed",
  role: Role = User
)

deftype BinaryData(
  name: string,
  data: binary = <<1, 2, 3>>
)

# Definitions
Info(name: "xenon", version: "0.1.0", metas: {
  "description": "Xenon is a tool for building and managing plugins.",
  "author": "John Doe",
  "license": "MIT"
})

## Members
User(id: 1, name: "Alice")
User(
  id: 2, 
  name: "Bob", 
  role: Admin
)

## Binary Examples
BinaryData(
  name: "mixed", 
  data: <<
    1, 2, 3, 
    "文字列データ", 
    "0123456789ABCDEF"/hex,
    "BASE64ENCODED"/base64
  >>
)
```

---

