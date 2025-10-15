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
    
    func didReceiveError(_ error: NSError) {
        logError("WS\(url?.absoluteString ?? "")收到异常：\(error.code) \(error.localizedDescription)")
        self.onErrorPublisher.send(error)
        reConnectDelay()
    }
    
    func didClose(code: Int, reason: String? = nil) {
        logError("WS\(url?.absoluteString ?? "")已关闭：\(code) \(reason ?? "")")
        self.onClosePublisher.send((code, reason))
        reConnectDelay()
    }
}
