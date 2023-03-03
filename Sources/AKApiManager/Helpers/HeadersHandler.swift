//
//  HeadersHandler.swift
//  AKApiManager
//
//  Created by Amr Koritem on 03/03/2023.
//

import Foundation
import Alamofire

/// Handlers used for request headers.
public enum HeadersHandler {
    public typealias Added = () -> HTTPHeaders?
    public typealias Upload = (String) -> HTTPHeaders
}
