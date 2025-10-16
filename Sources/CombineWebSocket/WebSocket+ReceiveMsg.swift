//
//  WebSocket+Delegate.swift
//  combine-websocket
//
//  Created by tutuzhou on 2025/10/12.
//
import Foundation
import LoggingKit

// MARK: receive
extension WebSocket {
    func didReceive(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.onDataPublisher.send(data)
            logTrace("收到string:\(string)")
        }
    }
    
    func didReceive(_ data: Data) {
        self.onDataPublisher.send(data)
        logTrace("收到data: \(String(data: data, encoding: .utf8) ?? "")")
    }
    
    func didReceivePong() {
        logInfo("收到pong")
        self.onPongPublisher.send()
    }
    
    func didReceivePing() {
        logInfo("收到ping")
        Task {
            try await sendPong()
        }
    }
    
    func didClose(code: Int, reason: String? = nil) {
        _state = .closed
        logError("WS\(url?.absoluteString ?? "")已关闭：\(code) \(reason ?? "")")
        self.onClosePublisher.send((code, reason))
        reConnectDelay()
    }
}
