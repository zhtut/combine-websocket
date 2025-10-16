//
//  WebSocket+Send.swift
//  combine-websocket
//
//  Created by tutuzhou on 2025/10/12.
//
import Foundation
import LoggingKit
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: send
extension WebSocket {
    
    /// 关闭连接
    /// - Parameters:
    ///   - closeCode: 关闭的code，可不填
    ///   - reason: 关闭的原因，可不填
    public func close(_ closeCode: URLSessionWebSocketTask.CloseCode = .normalClosure,
                      reason: String? = nil) async throws {
        if state == .connected {
            _state = .closing
            try await ws?.close(code: .init(codeNumber: closeCode.rawValue))
        }
    }
    
    /// 发送字符串
    /// - Parameter string: 要发送的字符串
    public func send(_ string: String) async throws {
        guard state == .connected else {
            logError("连接没有成功，发送失败")
            return
        }
        logInfo("发送string:\(string)")
        try await ws?.send(string)
    }
    
    /// 发送data
    /// - Parameter data: 要发送的data
    public func send(_ data: Data) async throws {
        guard state == .connected else {
            logError("连接没有成功，发送失败")
            return
        }
        logInfo("发送Data:\(data.count)")
        let bytes = [UInt8](data)
        try await ws?.send(bytes)
    }
    
    /// 发送一个ping
    public func sendPing() async throws {
        try await ws?.sendPing()
    }
    
    /// 系统的自己会回pong，连方法都没有给出
    public func sendPong() async throws {
        try await ws?.send(raw: Data(), opcode: .pong, fin: true)
    }
}
