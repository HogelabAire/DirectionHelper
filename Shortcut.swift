import Foundation

// ショートカットのデータモデル
struct Shortcut: Codable {
    var name: String   // ショートカットの名前
    var keyword: String // 検索に使用するキーワード
}
