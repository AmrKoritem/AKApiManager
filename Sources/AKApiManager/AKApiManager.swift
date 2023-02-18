//
//  AKApiManager.swift
//  AKApiManager
//
//  Created by Amr Koritem on 18/02/2023.
//

import Foundation
import Alamofire

public protocol AKApiManagerProtocol {
    var isConnected: Bool { get }
    var baseUrl: String { get set }
    func request(_ request: DataRequest, completionHandler: @escaping ResponseHandlers.Data)
    func upload(_ request: UploadRequest, completionHandler: @escaping ResponseHandlers.Data)
}

public extension AKApiManagerProtocol {
    func request(_ request: DataRequest) async -> (status: Int?, data: Data?)  {
        await withCheckedContinuation { continuation in
            self.request(request) { status, data in
                continuation.resume(returning: (status: status, data: data))
            }
        }
    }

    func upload(_ request: UploadRequest) async -> (status: Int?, data: Data?) {
        await withCheckedContinuation { continuation in
            upload(request) { status, data in
                continuation.resume(returning: (status: status, data: data))
            }
        }
    }
}

public class AKApiManager: AKApiManagerProtocol {
    public static let notConnectedStatus = -1010
    public static let shared = AKApiManager()

    /// Returns true if internet is reachable
    public var isConnected: Bool { NetworkReachabilityManager()?.isReachable ?? false }
    /// Base url of your APIs. The url path you provide in the `request(_:completionHandler:)` method will be concatenated to it before being used as the request url.
    public var baseUrl = ""

    private init() {}

    /// Used to upload any data.
    /// - Parameters:
    ///   - request: Upload request data to be used.
    ///   - completionHandler: Callback to be triggered upon response.
    public func upload(_ request: UploadRequest, completionHandler: @escaping ResponseHandlers.Data) {
        guard isConnected else { return completionHandler(AKApiManager.notConnectedStatus, nil) }
        AF.upload(
            request.data,
            to: request.url,
            method: .put,
            headers: [
                "Content-Type": request.mimeType,
                "x-amz-acl": "public-read"
            ])
        .uploadProgress(closure: { [weak self] progress in
            request.progressHandler?(progress)
            self?.printInDebug("upload progress: \(progress)")
        })
        .responseData { [weak self] response in
            self?.printInDebug("upload url: \(request.url)")
            self?.handleResponse(response: response, completion: completionHandler)
        }
    }
    
    /// Used for any restful api.
    /// - Parameters:
    ///   - request: Data request to be used.
    ///   - completionHandler: Callback to be triggered upon response.
    public func request(_ request: DataRequest, completionHandler: @escaping ResponseHandlers.Data) {
        guard isConnected else { return completionHandler(AKApiManager.notConnectedStatus, nil) }
        let reqUrl = baseUrl.appending(request.url)
        let time1 = Date()
        AF.request(
            reqUrl,
            method: request.method,
            parameters: request.parameters,
            encoding: request.encoding,
            headers: request.headers)
        .responseData { [weak self] response in
            let time2 = Date()
            self?.printInDebug("headers: \(String(describing: request.headers))")
            self?.printInDebug("url: \(reqUrl)")
            self?.printInDebug("type: \(request.method.rawValue)")
            self?.printInDebug("parameters: \(request.parameters ?? [:])")
            self?.printInDebug("encoding: \(request.encoding)")
            self?.printInDebug("requestTime: \(time2.timeIntervalSince1970 - time1.timeIntervalSince1970)")
            self?.handleResponse(response: response, completion: completionHandler)
        }
    }

    private func handleResponse(response: AFDataResponse<Data>, completion: @escaping ResponseHandlers.Data) {
        printInDebug("status: \(String(describing: response.response?.statusCode))")
        switch response.result {
        case .success(let data):
//        if let data = response.data {
//            print("string data: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
//        }
            completion(response.response?.statusCode, data)
            printInDebug("json: \(String(describing: data))")
        case .failure(let error):
            printInDebug("error: \(String(describing: error.errorDescription))")
            if let data = response.data {
                printInDebug("string error: \(String(describing: String(data: data, encoding: String.Encoding.utf8)))")
            }
            completion(response.response?.statusCode, response.data)
            printInDebug("json: \(String(describing: response.data))")
        }
    }
    
    /// This method is marked as _open_ so that you can override it with empty implementation if you don't want to see the printed logs.
    open func printInDebug(_ string: String) {
        #if DEBUG
        print(string)
        #endif
    }
}
