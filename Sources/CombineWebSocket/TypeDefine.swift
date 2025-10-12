//
//  File.swift
//  
//
//  Created by zhtg on 2023/3/18.
//

import Foundation

public enum WebSocketError: Error {
    case noTask
    case taskNotRunning
    case sessionBecomeInvalid
    case taskCompletedWithoutError
}

public enum WebSocketState {
    case connecting
    case connected
    case suspended
    case closing
    case closed
}
