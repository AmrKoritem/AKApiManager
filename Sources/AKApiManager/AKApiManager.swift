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
    /// Determines the criteria for retry attempts of upload requests.
    /// Can be used for custom handling of specific response status values. For example: logging out in case of status 401.
    func willRetryFor(uploadRequest: UploadRequest, statusCode: Int) async -> Bool
    /// Optionally, add a default set of headers to your APIs headers. For example: `"Authorization": "bearer token"`.
    func getAddedHeaders() -> Headers?
    /// This handler returns the default headers for upload requests. Change its value according to your business needs.
    func getDefaultUploadHeaders(_ mimeType: String) -> Headers
}

public extension AKApiManagerDelegate {
    func getAddedHeaders() -> Headers? {
        nil
    }
    func getDefaultUploadHeaders(_ mimeType: String) -> Headers {
        Headers([
            "Content-Type": mimeType,
            "x-amz-acl": "public-read"
        ])
    }
    func willRetryFor(dataRequest: DataRequest, statusCode: Int) async -> Bool {
        false
    }
    func willRetryFor(uploadRequest: UploadRequest, statusCode: Int) async -> Bool {
        false
    }
}

/// Protocol used for unit testing purposes.
public protocol AKApiManagerProtocol {
    var isConnected: Bool { get }
    var baseUrl: String { get set }
    var delegate: AKApiManagerDelegate? { get set }
    var allowLogs: Bool { get set }
    @discardableResult func request(_ request: DataRequest) async -> (status: Int?, data: Data?)
    @discardableResult func upload(_ request: UploadRequest) async -> (status: Int?, data: Data?)
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
    @discardableResult public func upload(_ request: UploadRequest) async -> (status: Int?, data: Data?) {
        guard isConnected else { return (AKApiManager.notConnectedStatus, nil) }
        let uploadHeaders = delegate?.getDefaultUploadHeaders(request.mimeType) ?? Headers()
        let headers = delegate?.getAddedHeaders()?.added(uploadHeaders)
        let afReq = AF.upload(
            request.data,
            to: request.url,
            method: .put,
            headers: headers)
        .uploadProgress(closure: { [weak self] progress in
            request.progressHandler?(progress)
            self?.printInDebug("upload progress: \(progress)")
        })
        let response = await afReq.serializingData().response
        printInDebug("upload url: \(request.url)")
        let returnedValues = handleResponse(response: response)
        guard let statusCode = returnedValues.status,
              let isRetry = await delegate?.willRetryFor(uploadRequest: request, statusCode: statusCode),
              isRetry else { return returnedValues }
        return await upload(request)
    }
    
    /// Used for any restful api.
    /// - Parameters:
    ///   - request: Data request to be used.
    ///   - completionHandler: Callback to be triggered upon response.
    @discardableResult public func request(_ request: DataRequest) async -> (status: Int?, data: Data?) {
        guard isConnected else { return (AKApiManager.notConnectedStatus, nil) }
        let headers = delegate?.getAddedHeaders()?.added(request.headers ?? Headers())
        let reqUrl = baseUrl.appending(request.url)
        let time1 = Date()
        let afReq = AF.request(
            reqUrl,
            method: request.method,
            parameters: request.parameters,
            encoding: request.encoding,
            headers: headers)
        let response = await afReq.serializingData().response
        let time2 = Date()
        printInDebug("headers: \(String(describing: request.headers))")
        printInDebug("url: \(reqUrl)")
        printInDebug("type: \(request.method.rawValue)")
        printInDebug("parameters: \(request.parameters ?? [:])")
        printInDebug("encoding: \(request.encoding)")
        printInDebug("requestTime: \(time2.timeIntervalSince1970 - time1.timeIntervalSince1970)")
        let returnedValues = handleResponse(response: response)
        guard let statusCode = returnedValues.status,
              let isRetry = await delegate?.willRetryFor(dataRequest: request, statusCode: statusCode),
              isRetry else { return returnedValues }
        return await self.request(request)
    }

    private func handleResponse(response: AFDataResponse<Data>) -> (status: Int?, data: Data?) {
        printInDebug("status: \(String(describing: response.response?.statusCode))")
        switch response.result {
        case .success(let data):
//        if let data = response.data {
//            print("string data: \(String(describing: String(data: data, encoding: .utf8)))")
//        }
            printInDebug("json: \(String(describing: data))")
            return (response.response?.statusCode, data)
        case .failure(let error):
            printInDebug("error: \(String(describing: error.errorDescription))")
            if let data = response.data {
                printInDebug("string error: \(String(describing: String(data: data, encoding: .utf8)))")
            }
            printInDebug("json: \(String(describing: response.data))")
            return (response.response?.statusCode, response.data)
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
