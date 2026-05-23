//
//  WidgetStatusTests.swift
//  AfterpayTests
//
//  Created by Huw Rowlands on 13/4/21.
//  Copyright © 2021 Afterpay. All rights reserved.
//

@testable import Afterpay
import XCTest

final class WidgetStatusTests: XCTestCase {

  func testDecodingValid() throws {
    let validStatus = """
    {
      "isValid": true,
      "amountDueToday": { "amount": "30.00", "currency": "USD" },
      "paymentScheduleChecksum": "magicNumberHere"
    }
    """.data(using: .utf8)!

    let status = try JSONDecoder().decode(WidgetStatus.self, from: validStatus)

    XCTAssertEqual(
      status,
      .valid(amountDueToday: Money(amount: "30.00", currency: "USD"), checksum: "magicNumberHere")
    )
  }

  func testDecodingInvalid() throws {
    let validStatus = """
    {
      "isValid": false,
      "error": { "errorCode": "SAD", "message": "I am sad" }
    }
    """.data(using: .utf8)!

    let status = try JSONDecoder().decode(WidgetStatus.self, from: validStatus)

    XCTAssertEqual(
      status,
      .invalid(errorCode: "SAD", message: "I am sad")
    )
  }

  // Before fix: `try?` swallowed the type-mismatch error and produced nil for
  // checksum, silently giving wrong data instead of surfacing the server bug.
  // After fix: the decode throws a DecodingError as expected.
  func testChecksumTypeMismatchThrowsDecodingError() {
    let wrongChecksumType = """
    {
      "isValid": true,
      "amountDueToday": { "amount": "30.00", "currency": "USD" },
      "paymentScheduleChecksum": 12345
    }
    """.data(using: .utf8)!

    XCTAssertThrowsError(
      try JSONDecoder().decode(WidgetStatus.self, from: wrongChecksumType),
      "Expected DecodingError when checksum is a number, not a string"
    )
  }

}
