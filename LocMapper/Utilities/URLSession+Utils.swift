/*
 * URLSession+Synchronous.swift
 * LocMapper
 *
 * Created by François Lamboley on 2017-02-06.
 * Copyright © 2017 happn. All rights reserved.
 */

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif



extension URLSession {
	
	func synchronousDataTask(with request: URLRequest) throws -> (data: Data?, response: URLResponse?) {
		let semaphore = DispatchSemaphore(value: 0)
		
		/* No, it’s not actually Sendable, but the way we use it it’s ok. */
		final class ResponseHolder : @unchecked Sendable {
			
			var data: Data?
			var urlResponse: URLResponse?
			var error: Error?
			
		}
		
		let responseHolder = ResponseHolder()
		dataTask(with: request) { data, response, error in
			responseHolder.data = data
			responseHolder.urlResponse = response
			responseHolder.error = error
			
			semaphore.signal()
		}.resume()
		
		_ = semaphore.wait(timeout: .distantFuture)
		
		if let error = responseHolder.error {
			throw error
		}
		
//		print("request: \(request.httpBody?.base64EncodedString())")
//		print("data: \(responseHolder.data?.base64EncodedString())")
		
		return (data: responseHolder.data, response: responseHolder.urlResponse)
	}
	
	func fetchData(request: URLRequest) -> Data? {
		guard
			let (data, response) = try? URLSession.shared.synchronousDataTask(with: request),
			let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode
		else {return nil}
		
		return data
	}
	
	func fetchJSON(request: URLRequest) -> [String: Any?]? {
		guard
			let data = fetchData(request: request),
			let parsedJson = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any?]
		else {return nil}
		
		return parsedJson
	}
	
	func fetchJSONAndCheckResponse(request: URLRequest) -> [String: Any?]? {
		guard
			let json = fetchJSON(request: request),
			let response = json["response"] as? [String: Any?],
			response["status"] as? String == "success",
			response["code"] as? String == "200"
		else {return nil}
		
		return json
	}
	
}
