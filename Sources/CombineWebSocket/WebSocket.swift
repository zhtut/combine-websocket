//
//  File.swift
//
//
//  Created by shutut on 2021/9/7.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import CombineX
import WebSocketKit
import NIO
import NIOWebSocket
import NIOPosix

import LoggingKit

/// 使用系统的URLSessionWebSocketTask实现的WebSocket客户端
open class WebSocket: NSObject, @unchecked Sendable {
    
    /// eventLoop组
    var elg = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    
    /// websocket对象
    open var ws: WebSocketKit.WebSocket?
    
    /// url地址
    open var url: URL? {
        didSet {
            if let url {
                if url != request?.url {
                    request = URLRequest(url: url)
                }
            } else {
                request = nil
            }
        }
    }
    
    /// 请求对象
    open var request: URLRequest? {
        didSet {
            if let request {
                if url != request.url {
                    url = request.url
                }
            } else {
                url = nil
            }
        }
    }
    
    open var subscriptionSet = Set<AnyCancellable>()
    
    /// 消息body最大大小
    open var maxMessageSize = 10240
    
    /// 代理
    open var willOpenPublisher = PassthroughSubject<Void, Never>()
    open var onOpenPublisher = PassthroughSubject<Void, Never>()
    open var onPongPublisher = PassthroughSubject<Void, Never>()
    open var onDataPublisher = PassthroughSubject<Data, Never>()
    open var onErrorPublisher = PassthroughSubject<Error, Never>()
    open var onClosePublisher = PassthroughSubject<(Int, String?), Never>()
    
    let delegateQueue = OperationQueue()
    
    private var _state = WebSocketState.closed
    
    /// 连接状态
    public var state: WebSocketState {
        guard let ws else {
            return WebSocketState.closed
        }
        return ws.isClosed ? WebSocketState.closed : _state
    }
    
    /// 自动重连接
    public var isAutoReconnect = true
    
    /// 重连间隔
    public var retryDuration: UInt32 = 1
    
    public init(request: URLRequest? = nil) {
        self.request = request
        super.init()
        setup()
    }
    
    public func setup() {
        
    }
    
    /// 开始连接
    public func open() {
        if state == .connected || state == .connecting {
            logInfo("state为connected，不需要连接")
            return
        }
        self.willOpenPublisher.send()
        guard let request else {
            logError("准备开始连接ws时，没有url request，无法连接")
            return
        }
        
        let urlStr = request.url?.absoluteString
        logInfo("开始连接\(urlStr ?? "")")
        
        guard let urlStr = urlStr else {
            logError("url和request的url都为空，无法连接websocket")
            return
        }
        
        Task {
            var httpHeaders = HTTPHeaders()
            if let requestHeaders = request.allHTTPHeaderFields {
                for (key, value) in requestHeaders {
                    httpHeaders.add(name: key, value: value)
                }
            }
            let config = WebSocketClient.Configuration()
            try await WebSocketKit.WebSocket.connect(to: urlStr,
                                                     headers: httpHeaders,
                                                     configuration: config,
                                                     on: elg,
                                                     onUpgrade: setupWebSocket)
        }
    }
    
    /// 延迟1s后重连
    func reConnectDelay() {
        guard isAutoReconnect else {
            logInfo("ws中断了，不需要重新连接")
            return
        }
        logInfo("尝试重新连接")
        if state == .connected {
            logInfo("当前状态是连接中，不用重连")
            return
        }
        Task {
            sleep(retryDuration)
            self.open()
        }
    }
}
