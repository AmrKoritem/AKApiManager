//
//  UploadRequest.swift
//  AKApiManager
//
//  Created by Amr Koritem on 18/02/2023.
//

import Foundation

/// Upload request inputs.
public struct UploadRequest {
    let url: String
    let data: Data
    let fileName: String
    let mimeType: String
    let progressHandler: ResponseHandlers.Progress?

    public init(
        url: String,
        data: Data,
        fileName: String,
        mimeType: String,
        progressHandler: ResponseHandlers.Progress? = nil
    ) {
        self.url = url
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
        self.progressHandler = progressHandler
    }
}
