//
//  CashAppPayCheckoutTests.swift
//  AfterpayTests
//

import XCTest
@testable import Afterpay

final class CashAppPayCheckoutTests: XCTestCase {

  // MARK: - Bug 3: createRequest force-unwrap URL
  // Passing an invalid URL string previously crashed inside createRequest.
  // After the fix, signCashAppOrderToken must call completion with a failure.

  func testSignTokenWithInvalidURLCallsCompletionWithFailure() {
    let exp = expectation(description: "completion called")

    CashAppPayCheckout.signCashAppOrderToken(
      "some-token",
      cashAppSigningURL: "",   // empty → URL(string:) returns nil
      urlSession: .shared
    ) { result in
      if case .failed = result { exp.fulfill() }
    }

    waitForExpectations(timeout: 0.5)
  }

  // MARK: - Bug 5: signPayment force-cast `response as! HTTPURLResponse`
  // A non-HTTP URLResponse (e.g., plain URLResponse from a mock) previously crashed.
  // After the fix it must call completion with a failure.

  func testSignTokenWithNonHTTPResponseCallsCompletionWithFailure() {
    let exp = expectation(description: "completion called with failure")

    let nonHTTPResponse = URLResponse(
      url: URL(string: "https://example.com")!,
      mimeType: nil,
      expectedContentLength: 0,
      textEncodingName: nil
    )
    let mockSession = URLSessionMock(requestDataTaskHandler: { _ in
      (nil, nonHTTPResponse, nil)
    })

    CashAppPayCheckout.signCashAppOrderToken(
      "some-token",
      cashAppSigningURL: "https://api-plus.us.afterpay.com/v2/payments/sign-payment",
      urlSession: mockSession
    ) { result in
      if case .failed = result { exp.fulfill() }
    }

    waitForExpectations(timeout: 0.5)
  }

  // MARK: - Bug 4: validateOrder force-cast `response as! HTTPURLResponse`
  // A non-HTTP URLResponse previously crashed. After fix it must call completion with failure.

  func testValidateOrderWithNonHTTPResponseCallsCompletionWithFailure() throws {
    let exp = expectation(description: "completion called with failure")

    let config = try Configuration(
      minimumAmount: "1.00",
      maximumAmount: "2000.00",
      currencyCode: "USD",
      locale: Locale(identifier: "en_US"),
      environment: .production
    )
    let nonHTTPResponse = URLResponse(
      url: URL(string: "https://example.com")!,
      mimeType: nil,
      expectedContentLength: 0,
      textEncodingName: nil
    )
    let mockSession = URLSessionMock(requestDataTaskHandler: { _ in
      (nil, nonHTTPResponse, nil)
    })

    CashAppPayCheckout.validateOrder(
      configuration: config,
      jwt: "jwt",
      customerId: "cust",
      grantId: "grant",
      urlSession: mockSession
    ) { result in
      if case .failed = result { exp.fulfill() }
    }

    waitForExpectations(timeout: 0.5)
  }

  // MARK: - Bug 4: validateOrder force-cast `message as! String`
  // A 4xx response body with no "message" key previously crashed.
  // After fix it must call completion with a failure (using a fallback message).

  func testValidateOrderWithMissingMessageKeyCallsCompletionWithFailure() throws {
    let exp = expectation(description: "completion called with failure")

    let config = try Configuration(
      minimumAmount: "1.00",
      maximumAmount: "2000.00",
      currencyCode: "USD",
      locale: Locale(identifier: "en_US"),
      environment: .production
    )
    let bodyWithoutMessage = #"{"code":"ERROR"}"#.data(using: .utf8)!
    let mockSession = URLSessionMock(requestDataTaskHandler: { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 400,
        httpVersion: nil,
        headerFields: nil
      )!
      return (bodyWithoutMessage, response, nil)
    })

    CashAppPayCheckout.validateOrder(
      configuration: config,
      jwt: "jwt",
      customerId: "cust",
      grantId: "grant",
      urlSession: mockSession
    ) { result in
      if case .failed(let reason) = result,
         case .httpError(let code, _) = reason,
         code == 400 {
        exp.fulfill()
      }
    }

    waitForExpectations(timeout: 0.5)
  }

}
