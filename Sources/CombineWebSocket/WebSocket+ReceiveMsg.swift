//
//  WebSocket+Delegate.swift
//  combine-websocket
//
//  Created by tutuzhou on 2025/10/12.
//
import Foundation
import LoggingKit

// MARK: receive
#if canImport(WebSocketKit)
@available(macOS 12, *)
#endif
extension WebSocket {
    func didReceive(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.onDataPublisher.send(data)
            logInfo("收到string:\(string)")
        }
    }
    
    func didReceive(_ data: Data) {
        self.onDataPublisher.send(data)
        logInfo("收到data: \(String(data: data, encoding: .utf8) ?? "")")
    }
    
    func didReceivePong() {
        logInfo("收到pong")
        self.onPongPublisher.send()
    }
    
    func didReceivePing() {
#if canImport(WebSocketKit)
        logInfo("收到ping")
        Task {
            try await sendPong()
        }
#endif
    }
    
    func didReceiveError(_ error: NSError) {
        logError("WS收到异常：\(error.code) \(error.localizedDescription)")
        self.onErrorPublisher.send(error)
#if canImport(WebSocketKit)
#else
        task = nil
#endif
        reConnectDelay()
    }
    
    func didClose(code: Int, reason: String? = nil) {
        logError("WS已关闭：\(code) \(reason ?? "")")
        self.onClosePublisher.send((code, reason))
#if canImport(WebSocketKit)
#else
        task = nil
#endif
        reConnectDelay()
    }
}
