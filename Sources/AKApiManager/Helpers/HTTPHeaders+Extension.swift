//
//  HTTPHeaders+Extension.swift
//  AKApiManager
//
//  Created by Amr Koritem on 02/03/2023.
//

import Foundation
import Alamofire

public typealias Headers = HTTPHeaders
public typealias Header = HTTPHeader

extension HTTPHeaders {
    mutating func add(_ headers: HTTPHeaders) {
        headers.forEach { add($0) }
    }

    func added(_ headers: HTTPHeaders) -> HTTPHeaders {
        var newHeaders = self
        newHeaders.add(headers)
        return newHeaders
    }
}
