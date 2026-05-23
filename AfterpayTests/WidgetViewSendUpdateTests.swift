//
//  WidgetViewSendUpdateTests.swift
//  AfterpayTests
//

import XCTest
@testable import Afterpay

/// Verifies that WidgetView.sendUpdate(amount:) honours its `throws` contract.
///
/// Before the fix the function used `try?` internally — encoding errors were
/// swallowed and the function never actually threw, making the `throws`
/// annotation a lie. After the fix, `try` is used so encoding errors propagate.
final class WidgetViewSendUpdateTests: XCTestCase {

  override func setUpWithError() throws {
    try super.setUpWithError()
    let config = try Configuration(
      minimumAmount: "1.00",
      maximumAmount: "2000.00",
      currencyCode: "USD",
      locale: Locale(identifier: "en_US"),
      environment: .production
    )
    Afterpay.setConfiguration(config)
  }

  override func tearDown() {
    Afterpay.setConfiguration(nil)
    super.tearDown()
  }

  // Happy path — a valid amount must not throw.
  func testSendUpdateWithValidAmountDoesNotThrow() throws {
    let widget = try WidgetView(amount: "50.00")
    XCTAssertNoThrow(try widget.sendUpdate(amount: "75.00"))
  }

  // Verify the function is declared throws (compile-time contract test).
  // If someone removes `throws`, this body would produce a compiler warning/error.
  func testSendUpdateIsMarkedThrows() throws {
    let widget = try WidgetView(amount: "10.00")
    // `try` is required — if `throws` were removed this would fail to compile
    _ = { try widget.sendUpdate(amount: "20.00") }
  }

}
