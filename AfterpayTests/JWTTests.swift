//
//  JWTTests.swift
//  AfterpayTests
//

import XCTest
@testable import Afterpay

final class JWTTests: XCTestCase {

  // MARK: - Valid input

  func testDecodeValidJWT() {
    // header.payload.signature — standard 3-part JWT
    let payload = #"{"sub":"1234567890","name":"John Doe","iat":1516239022}"#
    let encoded = Data(payload.utf8).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
    let jwt = "eyJhbGciOiJIUzI1NiJ9.\(encoded).signature"

    let result = JWT.decode(jwtToken: jwt)

    XCTAssertEqual(result["sub"] as? String, "1234567890")
    XCTAssertEqual(result["name"] as? String, "John Doe")
  }

  // MARK: - Malformed input — these crash before the fix

  func testDecodeEmptyStringReturnsEmptyDict() {
    // segments[1] is out of bounds → crash without the guard
    let result = JWT.decode(jwtToken: "")
    XCTAssertTrue(result.isEmpty)
  }

  func testDecodeSingleSegmentReturnsEmptyDict() {
    let result = JWT.decode(jwtToken: "onlyone")
    XCTAssertTrue(result.isEmpty)
  }

  func testDecodeTwoSegmentsReturnsEmptyDictOnBadPayload() {
    // Only header + payload, no signature — payload is garbage
    let result = JWT.decode(jwtToken: "header.!!notbase64!!")
    XCTAssertTrue(result.isEmpty)
  }

  func testDecodePayloadWithInvalidJSONReturnsEmptyDict() {
    // Valid base64 but the decoded content is not JSON
    let notJSON = Data("this is not json".utf8).base64EncodedString()
    let jwt = "header.\(notJSON).sig"

    let result = JWT.decode(jwtToken: jwt)
    XCTAssertTrue(result.isEmpty)
  }

}
