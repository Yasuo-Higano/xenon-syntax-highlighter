// xenon文法（セクション・デフォルト値・複雑な型・複雑な型のnullable・アノテーション対応）

Program  = _ statements:(Statement / Section / TopLevelDeclaration / EmptyLine)* _ { 
            // 最上位のセクションと宣言を保持し、階層構造を作る
            const filteredStatements = statements.filter(s => s !== null);
            const topLevelItems = [];
            const parentLevels = {}; // レベルごとの親セクション参照
            
            // TopLevelDeclarationを処理するために暗黙的なルートセクションを作成
            let implicitRootSection = null;
            
            for (const item of filteredStatements) {
              // TopLevelDeclarationの場合、暗黙的なrootセクションに追加
              if (item.type === "Declaration") {
                if (!implicitRootSection) {
                  implicitRootSection = {
                    type: "Section",
                    level: 0,
                    label: "root",
                    path: ["root"],
                    items: []
                  };
                  topLevelItems.push(implicitRootSection);
                }
                implicitRootSection.items.push(item);
                continue;
              }
              
              // セクション以外はそのままトップレベルアイテムに追加
              if (item.type !== "Section") {
                topLevelItems.push(item);
                continue;
              }
              
              // セクションの場合、レベルに基づいて階層構造に組み込む
              const level = item.level;
              
              if (level === 1) {
                // トップレベルのセクション
                topLevelItems.push(item);
                parentLevels[1] = item;
              } else {
                // 親セクションを見つける
                const parentLevel = level - 1;
                const parent = parentLevels[parentLevel];
                
                if (parent) {
                  // 親セクションに子セクションとして追加
                  if (!parent.sections) parent.sections = [];
                  parent.sections.push(item);
                  
                  // パス情報を更新
                  item.path = [...parent.path, item.label];
                } else {
                  // 親が見つからなければトップレベルとして扱う
                  topLevelItems.push(item);
                }
              }
              
              // 現在のレベルの親として登録
              parentLevels[level] = item;
              
              // 子レベルの親情報をクリア
              for (let i = level + 1; i <= 10; i++) {
                delete parentLevels[i];
              }
            }
            
            return {type:"Program", body:topLevelItems};
          }

Statement = EnumDef / UnionDef / TypeDef / Comment

EmptyLine = Newline { return null; }

TopLevelDeclaration = decl:Declaration _ { return decl; }

Comment
  = '//' text:(!Newline .)* Newline? { // 行末の Newline を消費。元は _ '//' text:(!Newline .)* Newline
      return { type: "Comment", text: text.map(t => t[1]).join("") };
    }

// 区切り文字
separator
  = _ (',' / '|') _ 

UnionSeparator = spacing '|' spacing
EnumSeparator  = spacing (',' / '|') spacing

// 区切り文字を0個以上 -> 任意個の空白・改行・コメントに変更
spacing
  = (Newline / Comment / __ )*

EnumDef  = 'defenum' __ name:Identifier __ '=' spacing first:Identifier
            rest:( EnumSeparator Identifier )*
            spacing {
              return {type:"EnumDef", name, values:[first,...rest.map(r => r[1])]}
            }

UnionDef = 'defunion' __ name:Identifier __ '=' spacing first:Identifier
             rest:( UnionSeparator Identifier )*
             spacing {
               return {type:"UnionDef", name, types:[first,...rest.map(r => r[1])]}
             }

TypeDef  = 'deftype' __ name:Identifier _ '(' _
            spacing
            fields:TypeFieldList?
            spacing
            ')' _ {
              return {type:"TypeDef", name, fields:fields || []}
            }

TypeFieldList
  = head:TypeField
    tail:( _ ',' spacing TypeField )* // フィールド区切りをここで明確に処理
    // Optional trailing comma は一旦削除
    {
      const fields = [head];
      if (tail && tail.length > 0) {
        tail.forEach(t => fields.push(t[3])); 
      }
      return fields;
    }

Annotation
  = '@' id:Identifier { return id; }
  / '@' id:Identifier '(' params:(StringLiteral / Identifier) ')' { 
      return { name: id, params }; 
    }

AnnotationList
  = annotations:(a:Annotation _ { return a; })* { // アノテーションの後にオプショナルなスペースを許容
      return annotations; 
    }

TypeField = _ annotations:AnnotationList
            name:Identifier _ ':' _ fieldType:Type defaultVal:TypeDefault? _ // 末尾の spacing を _ に変更
            {
              return {
                name, 
                fieldType, 
                default: defaultVal,
                annotations: annotations
              }
            }

TypeDefault = _ '=' _ value:Value { return value; }

Type 
  = nullable_generic:(GenericType '?') {
      const genericType = nullable_generic[0];
      return { ...genericType, nullable: true };
    }
  / nullable_id:(Identifier '?') {
      return { name: nullable_id[0], nullable: true };
    }
  / generic:GenericType { return generic; }
  / id:Identifier {
      return { name: id, nullable: false };
    }

GenericType
  = 'list' '<' innerType:Type '>' { return { kind: "list", inner: innerType }; }
  / 'map' '<' key:Type ',' _ val:Type '>' { return { kind: "map", key, value: val }; }

// セクション対応
Section
  = heading:SectionHeading _ decls:Declaration* {
      return { 
        type: "Section", 
        level: heading.level, 
        label: heading.label,
        path: [heading.label],
        items: decls
      };
    }

SectionHeading
  = hashes:'#'+ __ label:Identifier _ Newline {
      return { 
        level: hashes.length, 
        label
      };
    }

Declaration
  = annotations:AnnotationList // AnnotationList と name の間の spacing を削除
    name:Identifier _ '(' _
    spacing
    fields:KeyValuePairList?
    spacing
    ')' spacing {
      const result = { type: "Declaration", name };
      if (annotations && annotations.length > 0) {
        result.annotations = annotations;
      }
      if (fields && fields.length > 0) {
        result.fields = fields;
      } else {
        result.fields = [];
      }
      return result;
    }

KeyValuePairList
  = head:KeyValuePair 
    tail:( _ ',' spacing KeyValuePair )* // TypeFieldList と同様にカンマ区切りを明確化
    (_ ',' _ )? // Optional trailing comma
    {
      const pairs = [head];
      if (tail && tail.length > 0) {
        tail.forEach(t => pairs.push(t[3])); // t[3] is KeyValuePair
      }
      return pairs;
    }

KeyValuePair = 
               name:Identifier _ ':' _ value:Value {
                 return {name, value}
               }

Value = NullLiteral / BooleanLiteral / FloatLiteral / IntLiteral / StringLiteral / BinaryLiteral / ListLiteral / MapLiteral / NestedDeclaration / IdentifierLiteral

BooleanLiteral
  = 'true' { return true; } 
  / 'false' { return false; }

NullLiteral
  = 'null' { return null; }

IntLiteral
  = sign:'-'? hex:("0x"i [0-9a-fA-F]+) { // 16進数 (0x or 0X)
      const numString = hex[1].join("");
      const value = parseInt(numString, 16);
      return sign ? -value : value;
    }
  / sign:'-'? dec:([0-9]+) { // 10進数
      const value = parseInt(dec.join(""), 10);
      return sign ? -value : value;
    }

FloatLiteral = sign:'-'? intPart:([0-9]+) '.' fracPart:([0-9]+) { 
    const value = parseFloat(intPart.join("") + "." + fracPart.join(""));
    return sign ? -value : value;
  }

StringLiteral
  = TripleDoubleQuotedString / TripleSingleQuotedString / DoubleQuotedString / SingleQuotedString
  
TripleDoubleQuotedString 
  = '"""' chars:(!'"""' .)* '"""' { 
      return chars.map(c => c[1]).join(""); 
    }
    
TripleSingleQuotedString 
  = "'''" chars:(!"'''" .)* "'''" { 
      return chars.map(c => c[1]).join(""); 
    }
    
DoubleQuotedString       
  = '"' chars:(!'"' EscapableChar)* '"' { 
      return chars.map(c => c[1]).join(""); 
    }
    
SingleQuotedString       
  = "'" chars:(!"'" EscapableChar)* "'" { 
      return chars.map(c => c[1]).join(""); 
    }

// エスケープシーケンスの処理
EscapableChar
  = "\\" seq:EscapeSequence { return seq; }
  / . { return text(); }

EscapeSequence
  = "\"" { return "\""; }
  / "'" { return "'"; }
  / "\\" { return "\\"; }
  / "n" { return "\n"; }
  / "r" { return "\r"; }
  / "t" { return "\t"; }
  / "b" { return "\b"; }
  / "f" { return "\f"; }

// バイナリリテラル
BinaryLiteral
  = '<<' _ 
    elements:(BinaryElementList / _) 
    _ '>>' {
      return {
        type: "BinaryLiteral",
        elements: elements && Array.isArray(elements) ? elements.filter(e => e !== null) : []
      };
    }

BinaryElementList
  = first:BinaryElement 
    rest:(_ ',' _ BinaryElement)* {
      return [first, ...rest.map(r => r[3])].filter(e => e !== null);
    }

BinaryElement
  = ByteValue
  / EncodedString
  / Comment { return null; }

ByteValue
  = value:([0-9]+) {
      const num = parseInt(value.join(""), 10);
      if (num < 0 || num > 255) {
        error(`バイト値は0-255の範囲でなければなりません: ${num}`);
      }
      return {
        type: "Byte",
        value: num
      };
    }

EncodedString
  = str:StringLiteral encoding:EncodingType? {
      return {
        type: "EncodedString",
        value: str,
        encoding: encoding || "utf8"
      };
    }

EncodingType
  = '/' encoding:('utf8' / 'hex' / 'base32' / 'base64') {
      return encoding;
    }

ListLiteral
  = '[' spacing
    head:Value?
    tail:( _ ',' spacing Value )* // カンマ区切りを明確化
    (_ ',' _ )? // Optional trailing comma
    spacing ']' {
      if (!head) return [];
      const values = [head];
      if (tail && tail.length > 0) {
        tail.forEach(t => values.push(t[3])); // t[3] is Value
      }
      return values;
    }

MapLiteral
  = '{' spacing
    first:MapPair?
    rest:( _ ',' spacing MapPair )* // カンマ区切りを明確化
    (_ ',' _ )? // Optional trailing comma
    spacing '}' {
      if (!first) return {}; 
      const obj = { [first.key]: first.value };
      if (rest && rest.length > 0) {
        rest.forEach(r => {
          const pair = r[3]; // r[3] is MapPair
          obj[pair.key] = pair.value;
        });
      }
      return obj;
    }

MapPair = key:StringLiteral _ ':' _ value:Value {
      return { key, value };
    }

IdentifierLiteral = id:Identifier { return {type:"Identifier", value:id}; }

Identifier = !Reserved first:[a-zA-Z_] rest:[a-zA-Z0-9_]* { return first + rest.join("") }
Reserved = ('deftype' / 'defenum' / 'defunion' / 'list' / 'map' / 'true' / 'false' / 'null') !([a-zA-Z0-9_])

Digit     = [0-9]
HexDigit  = [0-9a-fA-F]
Newline   = '\n' / '\r\n'
_         = [ \t]*
__        = [ \t]+

// ネストされた宣言型のための定義
NestedDeclaration 
  = annotations:AnnotationList // AnnotationList と name の間の spacing を削除
    name:Identifier _ '(' _
    spacing
    fields:KeyValuePairList?
    spacing
    ')' {
      const result = { type: "Declaration", name };
      if (annotations && annotations.length > 0) {
        result.annotations = annotations;
      }
      if (fields && fields.length > 0) {
        result.fields = fields;
      } else {
        result.fields = [];
      }
      return result;
    } 