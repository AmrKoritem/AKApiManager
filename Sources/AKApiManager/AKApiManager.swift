//
//  AKApiManager.swift
//  AKApiManager
//
//  Created by Amr Koritem on 18/02/2023.
//

import Foundation
import Alamofire

public protocol AKApiManagerDelegate: AnyObject {
    /// Determines the criteria for retry attempts of data requests.
    /// Can be used for custom handling of specific response status values. For example: logging out in case of status 401.
    func willRetryFor(dataRequest: DataRequest, statusCode: Int) async -> Bool
    /// Optionally, add a default set of headers to your APIs headers. For example: `"Authorization": "bearer token"`.
    func getAddedHeaders() -> HTTPHeaders?
    /// This handler returns the default headers for upload requests. Change its value according to your business needs.
    func getDefaultUploadHeaders(_ mimeType: String) -> HTTPHeaders
}

public extension AKApiManagerDelegate {
    func getAddedHeaders() -> HTTPHeaders? {
        nil
    }
    func getDefaultUploadHeaders(_ mimeType: String) -> HTTPHeaders {
        HTTPHeaders([
            "Content-Type": mimeType,
            "x-amz-acl": "public-read"
        ])
    }
    func willRetryFor(dataRequest: DataRequest, statusCode: Int) async -> Bool {
        false
    }
}

/// Protocol used for unit testing purposes.
public protocol AKApiManagerProtocol {
    var isConnected: Bool { get }
    var baseUrl: String { get set }
    var delegate: AKApiManagerDelegate? { get set }
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
    /// Base url of your APIs. The url path you provide in the `request(_:completionHandler:)` method will be concatenated to it before being used as the request url.
    public var baseUrl = ""
    /// Optionally, change its value to `true` to see all logs of your API requests.
    public var allowLogs = false
    /// Delegate used for optional customizations.
    public weak var delegate: AKApiManagerDelegate?

    private init() {}

    /// Used to upload any data.
    /// - Parameters:
    ///   - request: Upload request data to be used.
    ///   - completionHandler: Callback to be triggered upon response.
    public func upload(_ request: UploadRequest, completionHandler: @escaping ResponseHandlers.Data) {
        guard isConnected else { return completionHandler(AKApiManager.notConnectedStatus, nil) }
        let uploadHeaders = delegate?.getDefaultUploadHeaders(request.mimeType) ?? HTTPHeaders()
        let headers = delegate?.getAddedHeaders()?.added(uploadHeaders)
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
        let headers = delegate?.getAddedHeaders()?.added(request.headers ?? HTTPHeaders())
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
            Task {
                guard let statusCode = response.response?.statusCode,
                      let isRetry = await self.delegate?.willRetryFor(dataRequest: request, statusCode: statusCode),
                      isRetry else { return }
                self.request(request, completionHandler: completionHandler)
            }
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
    }
    
    /// This method prints logs when running in debug mode.
    func printInDebug(_ string: String) {
        guard allowLogs else { return }
        #if DEBUG
        print(string)
        #endif
    }
}
