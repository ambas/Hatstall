import ObjectMapper

/// HTTP method definitions.
///
/// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public protocol Connectable {

    func request(method: HTTPMethod,
                 path: String,
                 param: [String: Any],
                 isShowLoading: Bool,
                 headers: [String: String]?,
                 errorHandler: (Error) -> Void,
                 responseHandler: @escaping ([String : Any]) -> Void)

    func requestObjects<T: Requestable>(path: String,
                                        param: [String: Any],
                                        isShowLoading: Bool,
                                        require: [String]?,
                                        errorHandler: (Error) -> Void,
                                        responseHandler: @escaping (([T]) -> Void))

    func requestObject<T: Requestable>(path: String,
                                       param: [String: Any],
                                       isShowLoading: Bool,
                                       require: [String]?,
                                       errorHandler: (Error) -> Void,
                                       responseHandler: @escaping ((T) -> Void))

    func updateObject<T: Requestable>(path: String,
                                      param: [String: Any],
                                      isShowLoading: Bool,
                                      errorHandler: (Error) -> Void,
                                      resonseHandler: @escaping ((T) -> Void)) where T: Mappable

    func deleteObject<T: Requestable>(path: String,
                                      param: [String: Any],
                                      isShowLoading: Bool,
                                      errorHandler: (Error) -> Void,
                                      resonseHandler: @escaping ((T) -> Void)) where T: Mappable

    func basicAuthen<T: Requestable>(path: String, email: String, password: String, param: [String: Any], isShowLoading: Bool, errorHandler: (Error) -> Void, responseHandler: @escaping ((T) -> Void))

    func upload<T: Requestable>(path: String, param: [String: Any], isShowLoading: Bool, errorHandler: (Error) -> Void, responseHandler: @escaping ((T) -> Void))

    func hostPath() -> String
    func header() -> [String: String]

}

public extension Connectable {
    public func basicAuthen<T: Requestable>(path: String,
                                            email: String,
                                            password: String,
                                            param: [String: Any],
                                            isShowLoading: Bool = true,
                                            errorHandler: (Error) -> Void,
                                            responseHandler: @escaping ((T) -> Void)) {
        let mergedParam = T.param.merged(with: param)

        let path = T.path + path

        let credentialData = "\(email):\(password)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])

        let headers = ["Authorization": "Basic \(base64Credentials)"]

        request(method: .post, path: path, param: mergedParam, isShowLoading: isShowLoading, headers: headers, errorHandler: errorHandler) {
            response in
            guard let object = Mapper<T>().map(JSONObject: response) else {
                assert(false)
                return
            }
            responseHandler(object)
        }
    }

    public func requestObject<T: Requestable>(path: String,
                                              param: [String : Any],
                                              isShowLoading: Bool = true,
                                              require: [String]? = nil,
                                              errorHandler: (Error) -> Void,
                                              responseHandler: @escaping ((T) -> Void)) {
        let path = T.path + path
        let mergedParam = T.param.merged(with: param)

        request(method: .get, path: path, param: mergedParam, isShowLoading: isShowLoading, headers: nil, errorHandler: errorHandler) { response in
            guard let object = Mapper<T>().map(JSONObject: response) else {
                assert(false)
                return
            }
            responseHandler(object)
        }
    }

    public func deleteObject<T: Requestable>(path: String = "",
                                             param: [String: Any] = [:],
                                             isShowLoading: Bool = true,
                                             errorHandler: (Error) -> Void,
                                             resonseHandler: @escaping ((T) -> Void)) {
        let pathTemp = T.path + path
        let mergedParam = T.param.merged(with: param)

        request(method: .delete, path: pathTemp, param: mergedParam, isShowLoading: isShowLoading, headers: nil, errorHandler: errorHandler) { response in
            guard let object = Mapper<T>().map(JSONObject: response) else {
                assert(false)
                return
            }
            resonseHandler(object)
        }

    }

    public func updateObject<T: Requestable>(path: String = "",
                                             param: [String: Any] = [:],
                                             isShowLoading: Bool = true,
                                             errorHandler: (Error) -> Void,
                                             resonseHandler: @escaping ((T) -> Void)) {
        let pathTemp = T.path + path
        let mergedParam = T.param.merged(with: param)

        request(method: .post, path: pathTemp, param: mergedParam, isShowLoading: isShowLoading, headers: nil, errorHandler: errorHandler) { response in
            guard let object = Mapper<T>().map(JSONObject: response) else {
                assert(false)
                return
            }
            resonseHandler(object)
        }

    }

    public func requestObjects<T: Requestable>(path: String,
                                               param: [String : Any],
                                               isShowLoading: Bool = true,
                                               require: [String]? = nil,
                                               errorHandler: (Error) -> Void,
                                               responseHandler: @escaping (([T]) -> Void)) {

        let mergedParam = T.param.merged(with: param)
        let path = T.path + path

        request(method: .get, path: path, param: mergedParam, isShowLoading: isShowLoading, headers: nil, errorHandler: errorHandler) { response in
            guard let objects = Mapper<T>().mapArray(JSONObject: response["result"]) else {
                assert(false)
                return
            }
            responseHandler(objects)
        }
    }

    public func request(method: HTTPMethod,
                        path: String,
                        param: [String: Any],
                        isShowLoading: Bool = true,
                        headers: [String: String]? = nil,
                        errorHandler: (Error) -> Void,
                        responseHandler: @escaping ([String : Any]) -> Void) {
        let path = hostPath() + path
        if isShowLoading {
        }
        let pathURL = URL(string: path)!
        var request = URLRequest(url: pathURL)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        request.addValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        switch method {
        case .post:
            request.httpBody = try? JSONSerialization.data(withJSONObject: param, options: [])
        case .get:
            break

        default:
            break
        }

        let task = URLSession.shared.dataTask(with: request) { (data, _, _) in
            guard let data = data else {
                return
            }
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
                return
            }
            guard let jsonDict = json as? [String: Any] else {
                return
            }
            DispatchQueue.main.async {
                if isShowLoading {
                }

                responseHandler(jsonDict)
            }
        }
        task.resume()

    }

    func upload<T>(path: String, param: [String : Any], isShowLoading: Bool, errorHandler: (Error) -> Void, responseHandler: @escaping ((T) -> Void)) where T : Requestable {

    }
}

public protocol Requestable: Mappable, Groupable {
    static var path: String { get }
    static var param: [String: Any] { get }
}

public extension Requestable {
    static var param: [String : Any] {
        return ["app_name": "ios_application"]
    }

    static func grouped(objects: [Mappable]) -> [[Mappable]] {
        return [objects]
    }

    static func grupedBySectionKey(objects: [Mappable]) -> [[Mappable]] {
        guard let contacts = objects as? [Requestable] else {
            fatalError("Cant group")
        }

        var orderKey = [String]()
        var contactDict = [String: [Requestable]]()
        contacts.forEach { contact in
            let type = contact.sectionKey()
            if let currentContacts = contactDict[type] {
                let newContacts = currentContacts + [contact]
                contactDict[type] = newContacts
            } else {
                orderKey.append(type)
                contactDict[type] = [contact]
            }
        }

        return orderKey.map({ contactDict[$0] ?? [] })
    }

    static func titleForIndex(index: Int) -> String {
        return ""
    }

    static func objectForHeader(groupedObject: [[Mappable]], ungroupedObjects: [Mappable], index: Int) -> Any? {
        return nil
    }

    func sectionKey() -> String {
        return ""
    }

}

public protocol Groupable {

    static func grouped(objects: [Mappable]) -> [[Mappable]]
    static func grupedBySectionKey(objects: [Mappable]) -> [[Mappable]]
    static func titleForIndex(index: Int) -> String
    static func objectForHeader(groupedObject: [[Mappable]], ungroupedObjects: [Mappable], index: Int) -> Any?
    func sectionKey() -> String

}

public extension Connectable {
    func hostPath() -> String {
        assertionFailure("please implement host path")
        return ""
    }

    func header() -> [String: String] {
        return [:]
    }
}

func += <K, V> ( left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

protocol Mergable {
    func merged(with: Self) -> Self
}

extension Array: Mergable {
    func merged(with otherArray: Array<Element>) -> Array<Element> {
        var newDict = self
        newDict.append(contentsOf: otherArray)
        return newDict
    }
}

extension Dictionary: Mergable {
    func merged(with otherDict: Dictionary<Key, Value>) -> Dictionary<Key, Value> {
        var newDict = self
        for (key, value) in otherDict {
            if let value = value as? Array<Any>, let oldValue = newDict[key] as? Array<Any> {
                newDict[key] = oldValue.merged(with: value) as? Value
            } else if let value = value as? Dictionary<String, Any>, let oldValue =  newDict[key] as? Dictionary<String, Any> {
                newDict[key] = value.merged(with: oldValue) as? Value
            } else {
                newDict[key] = value
            }
        }
        return newDict
    }
}

