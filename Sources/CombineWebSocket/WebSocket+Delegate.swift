//
//  WebSocket+Delegate.swift
//  combine-websocket
//
//  Created by tutuzhou on 2025/10/12.
//
import Foundation
import LoggingKit

#if canImport(WebSocketKit)
import WebSocketKit
import NIOCore

@available(macOS 12, *)
extension WebSocket {
    
    /// 连接上了
    /// - Parameter ws: websocket对象
    func setupWebSocket(ws: WebSocketKit.WebSocket) async {
        self.ws = ws
        configWebSocket()
        self.onOpenPublisher.send()
    }
    
    /// 详细配置回调的方法
    func configWebSocket() {
        logInfo("websocket连接成功")
        ws?.pingInterval = TimeAmount.minutes(8)
        ws?.onText({ [weak self] (_, string) async in
            self?.didReceive(string)
        })
        ws?.onBinary({ [weak self] (_, buffer) async in
            let data = Data(buffer: buffer)
            self?.didReceive(data)
        })
        ws?.onPong({ [weak self] (_, _) async in
            self?.didReceivePong()
        })
        ws?.onPing({ [weak self] _, _ async in
            self?.didReceivePing()
        })
        ws?.onClose.whenComplete({ [weak self] result in
            var code = -1
            if let closeCode = self?.ws?.closeCode {
                switch closeCode {
                case .normalClosure:
                    code = 1000
                case .goingAway:
                    code = 1001
                case .protocolError:
                    code = 1002
                case .unacceptableData:
                    code = 1003
                case .dataInconsistentWithMessage:
                    code = 1007
                case .policyViolation:
                    code = 1008
                case .messageTooLarge:
                    code = 1009
                case .missingExtension:
                    code = 1010
                case .unexpectedServerError:
                    code = 1011
                default:
                    code = -1
                }
            }
            self?.didClose(code: code)
        })
    }
}
#else
extension WebSocket: URLSessionWebSocketDelegate {
    
    private func receive() async throws {
        guard let task = task else {
            throw WebSocketError.noTask
        }
        guard state == .connected else {
            throw WebSocketError.taskNotRunning
        }
        
        let message = try await task.receive()
        switch message {
        case .string(let string):
            didReceive(string)
        case .data(let data):
            didReceive(data)
        @unknown default:
            logError("task.receive error")
        }
        
        try await receive()
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        logError("didBecomeInvalidWithError:\(error?.localizedDescription ?? "")")
        
        var nsError: NSError
        if let error {
            nsError = error as NSError
        } else {
            nsError = WebSocketError.sessionBecomeInvalid as NSError
        }
        
        didReceiveError(nsError)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        logError("didCompleteWithError:\(error?.localizedDescription ?? "")")
        
        var nsError: NSError
        if let error {
            nsError = error as NSError
        } else {
            nsError = WebSocketError.taskCompletedWithoutError as NSError
        }
        
        didReceiveError(nsError)
    }
    
    public func urlSession(_ session: URLSession,
                           webSocketTask: URLSessionWebSocketTask,
                           didOpenWithProtocol protocol: String?) {
        logInfo("webSocketTask:didOpenWithProtocol:\(`protocol` ?? "")")
        self.onOpenPublisher.send()
        Task {
            do {
                try await self.receive()
            }
            catch {
                logError("读取数据错误：\(error)")
                didReceiveError(error as NSError)
            }
        }
    }
    
    public func urlSession(_ session: URLSession,
                           webSocketTask: URLSessionWebSocketTask,
                           didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                           reason: Data?) {
        logInfo("urlSession:didCloseWith:\(closeCode)")
        var r = ""
        if let d = reason {
            r = String(data: d, encoding: .utf8) ?? ""
        }
        let intCode = closeCode.rawValue
        didClose(code: intCode, reason: r)
    }
}
#endif
