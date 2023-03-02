//
//  HeadersHandler.swift
//  AKApiManager
//
//  Created by Amr Koritem on 03/03/2023.
//

import Foundation
import Alamofire

public enum HeadersHandler {
    public typealias Added = () -> HTTPHeaders?
    public typealias Upload = (String) -> HTTPHeaders
}
