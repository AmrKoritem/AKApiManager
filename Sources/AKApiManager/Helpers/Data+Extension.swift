//
//  Data+Extension.swift
//  AKApiManager
//
//  Created by Amr Koritem on 11/03/2023.
//

import Foundation

extension Data {
    var printable: [String: Any]? {
        let jsonObject = try? JSONSerialization.jsonObject(with: self, options: .allowFragments)
        return jsonObject.flatMap { $0 as? [String: Any] }
    }
}
