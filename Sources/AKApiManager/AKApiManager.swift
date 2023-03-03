//
//  AKApiManager.swift
//  AKApiManager
//
//  Created by Amr Koritem on 18/02/2023.
//

import Foundation
import Alamofire

/// Protocol used for unit testing purposes.
public protocol AKApiManagerProtocol {
    var isConnected: Bool { get }
    var baseUrl: String { get set }
    var addedHeadersHandler: HeadersHandler.Added { get set }
    var defaultUploadHeadersHandler: HeadersHandler.Upload { get set }
    var statusHandler: ResponseHandlers.Status { get set }
    func request(_ request: DataRequest, completionHandler: @escaping ResponseHandlers.Data)
    func upload(_ request: UploadRequest, completionHandler: @escaping ResponseHandlers.Data)
}

public extension AKApiManagerProtocol {
    @discardableResult func request(_ request: DataRequest) async -> (status: Int?, data: Data?)  {
        await withCheckedContinuation { cont in
            self.request(request) { cont.resume(returning: ($0, $1)) }
        }
    }

    @discardableResult func upload(_ request: UploadRequest) async -> (status: Int?, data: Data?) {
        await withCheckedContinuation { cont in
            upload(request) { cont.resume(returning: ($0, $1)) }
        }
    }

    func request(_ request: DataRequest) {
        self.request(request, completionHandler: { _, _ in })
    }

    func upload(_ request: UploadRequest) {
        upload(request, completionHandler: { _, _ in })
    }
}

/// Api manager is built on top of `Alamofire` to facilitate usage of restful api requests.
public class AKApiManager: AKApiManagerProtocol {
    public static let notConnectedStatus = -1010
    public static let shared = AKApiManager()

    /// Returns true if internet is reachable.
    open var isConnected: Bool {
        NetworkReachabilityManager()?.isReachable ?? false
    }
    /// Custom handling for specific response status values. For example: logging out in case of status 401.
    public var statusHandler: ResponseHandlers.Status = { _, _ in }
    /// Base url of your APIs. The url path you provide in the `request(_:completionHandler:)` method will be concatenated to it before being used as the request url.
    public var baseUrl = ""
    /// Optionally, set this handler to add a default set of headers to your APIs headers. For example: `"Authorization": "bearer token"`.
    public var addedHeadersHandler: HeadersHandler.Added = { nil }
    /// This handler returns the default headers for upload requests. Change its value according to your business needs.
    public var defaultUploadHeadersHandler: HeadersHandler.Upload = {
        HTTPHeaders([
            "Content-Type": $0,
            "x-amz-acl": "public-read"
        ])
    }
    /// Optionally, change its value to `true` to see all logs of your API requests.
    public var allowLogs = false

    private init() {}

    /// Used to upload any data.
    /// - Parameters:
    ///   - request: Upload request data to be used.
    ///   - completionHandler: Callback to be triggered upon response.
    public func upload(_ request: UploadRequest, completionHandler: @escaping ResponseHandlers.Data) {
        guard isConnected else { return completionHandler(AKApiManager.notConnectedStatus, nil) }
        let uploadHeaders = defaultUploadHeadersHandler(request.mimeType)
        let headers = addedHeadersHandler()?.added(uploadHeaders)
        AF.upload(
            request.data,
            to: request.url,
            method: .put,
            headers: headers)
        .uploadProgress(closure: { [weak self] progress in
            request.progressHandler?(progress)
            self?.printInDebug("upload progress: \(progress)")
        })
        .responseData { [weak self] response in
            guard let self = self else { return }
            self.printInDebug("upload url: \(request.url)")
            self.handleResponse(response: response, completion: completionHandler)
        }
    }
    
    /// Used for any restful api.
    /// - Parameters:
    ///   - request: Data request to be used.
    ///   - completionHandler: Callback to be triggered upon response.
    public func request(_ request: DataRequest, completionHandler: @escaping ResponseHandlers.Data) {
        guard isConnected else { return completionHandler(AKApiManager.notConnectedStatus, nil) }
        let headers = addedHeadersHandler()?.added(request.headers ?? HTTPHeaders())
        let reqUrl = baseUrl.appending(request.url)
        let time1 = Date()
        AF.request(
            reqUrl,
            method: request.method,
            parameters: request.parameters,
            encoding: request.encoding,
            headers: headers)
        .responseData { [weak self] response in
            guard let self = self else { return }
            let time2 = Date()
            self.printInDebug("headers: \(String(describing: request.headers))")
            self.printInDebug("url: \(reqUrl)")
            self.printInDebug("type: \(request.method.rawValue)")
            self.printInDebug("parameters: \(request.parameters ?? [:])")
            self.printInDebug("encoding: \(request.encoding)")
            self.printInDebug("requestTime: \(time2.timeIntervalSince1970 - time1.timeIntervalSince1970)")
            self.handleResponse(response: response, completion: completionHandler)
        }
    }

    private func handleResponse(response: AFDataResponse<Data>, completion: @escaping ResponseHandlers.Data) {
        printInDebug("status: \(String(describing: response.response?.statusCode))")
        switch response.result {
        case .success(let data):
//        if let data = response.data {
//            print("string data: \(String(describing: String(data: data, encoding: .utf8)))")
//        }
            completion(response.response?.statusCode, data)
            printInDebug("json: \(String(describing: data))")
        case .failure(let error):
            printInDebug("error: \(String(describing: error.errorDescription))")
            if let data = response.data {
                printInDebug("string error: \(String(describing: String(data: data, encoding: .utf8)))")
            }
            completion(response.response?.statusCode, response.data)
            printInDebug("json: \(String(describing: response.data))")
        }
        guard let url = response.request?.url?.absoluteString.replacingOccurrences(of: baseUrl, with: ""),
              let statusCode = response.response?.statusCode else { return }
        statusHandler(url, statusCode)
    }
    
    /// This method prints logs when running in debug mode.
    func printInDebug(_ string: String) {
        guard allowLogs else { return }
        #if DEBUG
        print(string)
        #endif
    }
}
