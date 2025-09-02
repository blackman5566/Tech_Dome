//
//  SpeedTester.swift
//  jstest
//
//  Created by 許佳豪 on 2025/9/2.
//

import Foundation

let coinImgs: [String] = [
    "https://assets.coingecko.com/coins/images/1/small/bitcoin.png",
    "https://assets.coingecko.com/coins/images/279/small/ethereum.png",
    "https://assets.coingecko.com/coins/images/7310/small/cro_token_logo.png",
    "https://assets.coingecko.com/coins/images/4128/small/solana.png",
]

// 單筆結果
struct SpeedResult: Codable, Equatable {
    let domain: String       // 這裡用 URL 字串當作 domain
    let timeMS: Int
}

/// 使用原生 URLSession；避免快取以免影響測速.
actor SpeedTester {
    private var results: [SpeedResult] = []

    // 無快取 session，避免快取讓時間失真
    private lazy var session: URLSession = {
        // 無痕模式, 它不會寫 cookies、憑證、cache 到磁碟。
        let c = URLSessionConfiguration.ephemeral
        // 強制忽略 cache，每次都去要新資料
        c.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        // 完全關閉 URLCache，確保 session 裡沒有快取。
        c.urlCache = nil
        return URLSession(configuration: c)
    }()

    /// 1)  背景請求圖片，回傳下載毫秒數
    func downloadImg(domainURL: URL) async -> Double {
        var req = URLRequest(url: domainURL)
        
        // 強制這個 request 要繞過 本地快取 (URLCache)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        
        // 跟 伺服器 / 中間層 (CDN, Proxy) 說「請不要給我快取資料」。
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // 再加一個「隨機 header」，讓 CDN 覺得每次請求都不一樣，這樣它就不會命中快取。
        req.setValue(UUID().uuidString, forHTTPHeaderField: "X-Bypass-Cache")
        
        // 開始時間
        let start = DispatchTime.now()
        do {
            _ = try await session.data(for: req)   // 讀完整個 body，不存檔
            
            // 結束時間
            let end = DispatchTime.now()
            
            // uptimeNanoseconds → 取得「從開機到現在」的時間，單位是奈秒（ns）。
            // &- → 算出結束時間減去開始時間，得到「花費的奈秒數」。
            // 1_000_000.0 → 把奈秒轉換成毫秒 (ms)。
            let ms = Double(end.uptimeNanoseconds &- start.uptimeNanoseconds) / 1_000_000.0
            return ms
        } catch {
            return .infinity // 失敗視為極慢
        }
    }

    /// 儲存並依時間排序
    func set(domain: String, timeMS: Double) {
        // 去掉小數點，存成整數毫秒
        let t = Int(timeMS.rounded())
        
        // 直接新增
        results.append(SpeedResult(domain: domain, timeMS: t))
        
        // 照時間排序（由小到大）
        results.sort { $0.timeMS < $1.timeMS }
    }

    /// 取出（回傳 JSON 字串）
    func get() -> String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? enc.encode(results), let s = String(data: data, encoding: .utf8) {
            return s
        }
        return "[]"
    }

    /// 一次跑完一組 URL（併發執行）
    func runAll(items: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for urlStr in items {
                group.addTask {
                    guard let domainURL = URL(string: urlStr) else { return }
                    let ms = await self.downloadImg(domainURL: domainURL)
                    await self.set(domain: urlStr, timeMS: ms)
                }
            }
        }
    }
}


//使用方式
//let tester = SpeedTester()
//Task {
//    await tester.runAll(items: coinImgs)
//    let json = await tester.get()
//    print(json)
//}
