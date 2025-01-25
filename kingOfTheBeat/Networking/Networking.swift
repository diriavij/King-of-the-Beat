//
//  Networking.swift
//  seminar_05.11
//
//  Created by Кирилл Исаев on 05.11.2024.
//

import UIKit
protocol NetworkingLogic {
    typealias Response = ((_ response: Result<Networking.ServerResponse, Error>) -> Void)
    
    func execute(with request: Request, completion: @escaping Response)
}

enum Networking {
    struct ServerResponse {
        let data: Data?
        let response: URLResponse?
    }
}


final class BaseUrlWorker: NetworkingLogic {
    
    enum BaseUrlError: Error {
        case invalidRequest
    }
    
    var baseURL: String
    
    init(baseURL: String) {
        self.baseURL = baseURL
    }
    
    func execute(
        with request: Request,
        completion: @escaping Response
    ) {
        guard let urlRequest = convert(request) else {
            completion(.failure(BaseUrlError.invalidRequest))
            return
        }
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }
            
            completion(.success(Networking.ServerResponse(data: data, response: response)))
        }
        
        task.resume()
    }

    func convert(_ request: Request) -> URLRequest? {
        guard let url = generateDestinationURL(for: request) else {
            return nil
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.allHTTPHeaderFields = request.endpoint.headers
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeInterval
        
        return urlRequest
    }
    
    private func generateDestinationURL(for request: Request) -> URL? {
        guard
            let url = URL(string: baseURL),
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }
        
        let queryItems = request.parameters?.map { key, value in
            URLQueryItem(name: key, value: value)
        }
        components.path += request.endpoint.compositePath
        components.queryItems = queryItems
        
        print("Generated URL: \(components.url?.absoluteString ?? "Invalid URL")")
        return components.url
    }
}


