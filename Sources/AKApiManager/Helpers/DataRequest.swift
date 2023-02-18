//
//  DataRequest.swift
//  AKApiManager
//
//  Created by Amr Koritem on 18/02/2023.
//

import Foundation
import Alamofire

public struct DataRequest {
    let url: String
    let method: HTTPMethod
    let parameters: Parameters?
    let headers: HTTPHeaders?
    let encoding: ParameterEncoding

    public init(
        url: String,
        method: HTTPMethod,
        parameters: Parameters? = nil,
        headers: HTTPHeaders? = nil,
        encoding: ParameterEncoding? = nil
    ) {
        self.url = url
        self.method = method
        self.parameters = parameters
        self.headers = headers
        if let encoding = encoding {
            self.encoding = encoding
        } else {
            self.encoding = method == .get || method == .patch ? URLEncoding.default : JSONEncoding.default
        }
    }
}
