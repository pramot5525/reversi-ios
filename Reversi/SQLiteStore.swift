import Foundation
import SQLite3

/// Lightweight SQLite wrapper for local game data persistence.
final class SQLiteStore {
    static let shared = SQLiteStore()

    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Setup

    private func openDatabase() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("reversi.sqlite")
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("SQLite: Failed to open database")
        }
    }

    private func createTables() {
        let sql = """
        CREATE TABLE IF NOT EXISTS player_data (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS unlocked_emoji (
            emoji_id TEXT PRIMARY KEY
        );
        """
        execute(sql)
    }

    // MARK: - Key-Value (coins, totalWins)

    func getInt(forKey key: String) -> Int {
        let sql = "SELECT value FROM player_data WHERE key = ?;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)

        if sqlite3_step(stmt) == SQLITE_ROW,
           let cStr = sqlite3_column_text(stmt, 0) {
            return Int(String(cString: cStr)) ?? 0
        }
        return 0
    }

    func setInt(_ value: Int, forKey key: String) {
        let sql = "INSERT OR REPLACE INTO player_data (key, value) VALUES (?, ?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (String(value) as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }

    // MARK: - Unlocked Emoji

    func loadUnlockedEmojiIDs() -> Set<String> {
        let sql = "SELECT emoji_id FROM unlocked_emoji;"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        var result = Set<String>()
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return result }

        while sqlite3_step(stmt) == SQLITE_ROW {
            if let cStr = sqlite3_column_text(stmt, 0) {
                result.insert(String(cString: cStr))
            }
        }
        return result
    }

    func saveUnlockedEmojiIDs(_ ids: Set<String>) {
        execute("DELETE FROM unlocked_emoji;")

        let sql = "INSERT OR IGNORE INTO unlocked_emoji (emoji_id) VALUES (?);"
        for id in ids {
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { continue }
            sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_step(stmt)
            sqlite3_finalize(stmt)
        }
    }

    func insertUnlockedEmoji(_ id: String) {
        let sql = "INSERT OR IGNORE INTO unlocked_emoji (emoji_id) VALUES (?);"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(stmt, 1, (id as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
    }

    // MARK: - Helpers

    private func execute(_ sql: String) {
        var errMsg: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &errMsg) != SQLITE_OK {
            if let errMsg {
                print("SQLite error: \(String(cString: errMsg))")
                sqlite3_free(errMsg)
            }
        }
    }
}
