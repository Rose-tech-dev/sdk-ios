//
//  ApiV3Tests.swift
//  AfterpayTests
//

import XCTest
@testable import Afterpay

final class ApiV3Tests: XCTestCase {

  private let dummyRequest = URLRequest(url: URL(string: "https://example.com")!)

  // MARK: - Void overload

  func testVoidRequestCallsCompletionOn204() {
    let exp = expectation(description: "completion called")

    let handler = makeHandler(statusCode: 204, data: Data())
    ApiV3.request(handler, dummyRequest) { result in
      if case .success = result { exp.fulfill() }
    }.resume()

    waitForExpectations(timeout: 0.5)
  }

  func testVoidRequestCallsCompletionWithApiErrorBody() {
    let exp = expectation(description: "completion called with api error")
    let apiErrorJSON = #"{"errorCode":"E001","errorId":"id1","message":"bad","httpStatusCode":400}"#
    let handler = makeHandler(statusCode: 400, data: Data(apiErrorJSON.utf8))

    ApiV3.request(handler, dummyRequest) { result in
      if case .failure = result { exp.fulfill() }
    }.resume()

    waitForExpectations(timeout: 0.5)
  }

  // Before fix: completion was silently dropped when the server returned a
  // non-204 success with a body that didn't decode as ApiError.
  func testVoidRequestCallsCompletionWhenBodyIsNotApiError() {
    let exp = expectation(description: "completion called")

    let unexpectedBody = #"{"some":"unexpected","json":"body"}"#
    let handler = makeHandler(statusCode: 200, data: Data(unexpectedBody.utf8))

    ApiV3.request(handler, dummyRequest) { result in
      // Should be called with a failure (unexpected response), not silently dropped
      if case .failure = result { exp.fulfill() }
    }.resume()

    waitForExpectations(timeout: 0.5)
  }

  func testVoidRequestCallsCompletionOnNetworkError() {
    let exp = expectation(description: "completion called with network error")
    let handler: URLRequestHandler = { _, completion in
      let task = URLSessionDataTaskMock { completion(nil, nil, URLError(.notConnectedToInternet)) }
      return task
    }

    ApiV3.request(handler, dummyRequest) { result in
      if case .failure = result { exp.fulfill() }
    }.resume()

    waitForExpectations(timeout: 0.5)
  }

  // MARK: - Typed overload (sanity check)

  func testTypedRequestDecodesSuccessResponse() {
    struct Payload: Decodable { let value: Int }
    let exp = expectation(description: "decoded")
    let handler = makeHandler(statusCode: 200, data: Data(#"{"value":42}"#.utf8))

    ApiV3.request(handler, dummyRequest, type: Payload.self) { result in
      if case .success(let p) = result, p.value == 42 { exp.fulfill() }
    }.resume()

    waitForExpectations(timeout: 0.5)
  }

  // MARK: - Helpers

  private func makeHandler(statusCode: Int, data: Data) -> URLRequestHandler {
    return { request, completion in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
      )!
      return URLSessionDataTaskMock { completion(data, response, nil) }
    }
  }

}
