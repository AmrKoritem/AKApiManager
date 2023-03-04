//
//  ResponseHandlers.swift
//  AKApiManager
//
//  Created by Amr Koritem on 18/02/2023.
//

import Foundation

/// Handlers used with a request reponse.
public enum ResponseHandlers {
    public typealias Data = (Int?, Foundation.Data?) -> Void
    public typealias Progress = (Foundation.Progress) -> Void
}
