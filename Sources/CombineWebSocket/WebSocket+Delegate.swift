//
//  WebSocket+Delegate.swift
//  combine-websocket
//
//  Created by tutuzhou on 2025/10/12.
//
import Foundation
import LoggingKit
import WebSocketKit
import NIOCore

@available(macOS 12, *)
extension WebSocket {
    
    /// 连接上了
    /// - Parameter ws: websocket对象
    func setupWebSocket(ws: WebSocketKit.WebSocket) async {
        self.ws = ws
        _state = .connected
        configWebSocket()
        self.onOpenPublisher.send()
    }
    
    /// 详细配置回调的方法
    func configWebSocket() {
        logInfo("websocket\(url?.absoluteString ?? "")连接成功")
        ws?.pingInterval = TimeAmount.minutes(3)
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
