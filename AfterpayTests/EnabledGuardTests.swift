//
//  EnabledGuardTests.swift
//  AfterpayTests
//

import XCTest
@testable import Afterpay

// Tests that functions with an `enabled` guard call their completion handlers
// rather than silently returning when the SDK has no configuration set.
final class EnabledGuardTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Ensure no configuration is set so `Afterpay.enabled == false`
    Afterpay.setConfiguration(nil)
    Afterpay.setV3Configuration(nil)
  }

  // MARK: - signCashAppOrderToken

  func testSignCashAppOrderTokenCallsCompletionWhenNotEnabled() {
    let exp = expectation(description: "completion called")

    Afterpay.signCashAppOrderToken("token") { result in
      if case .failed = result { exp.fulfill() }
    }

    waitForExpectations(timeout: 0.5)
  }

  // MARK: - validateCashAppOrder

  func testValidateCashAppOrderCallsCompletionWhenNotEnabled() {
    let exp = expectation(description: "completion called")

    Afterpay.validateCashAppOrder(jwt: "jwt", customerId: "c", grantId: "g") { result in
      if case .failed = result { exp.fulfill() }
    }

    waitForExpectations(timeout: 0.5)
  }

}
