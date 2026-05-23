//
//  StringJSEscapingTests.swift
//  AfterpayTests
//

import XCTest
@testable import Afterpay

final class StringJSEscapingTests: XCTestCase {

  // MARK: - No special characters — output unchanged

  func testPlainStringIsUnchanged() {
    XCTAssertEqual("hello world".escapedForJSSingleQuotedString(), "hello world")
  }

  func testDoubleQuotesAreUnchanged() {
    // Double quotes are safe inside JS single-quoted strings
    XCTAssertEqual(#"{"key":"value"}"#.escapedForJSSingleQuotedString(), #"{"key":"value"}"#)
  }

  // MARK: - Single quotes

  func testSingleQuoteIsEscaped() {
    // "O'Brien" injected into openCheckout('...') must not break the JS call
    XCTAssertEqual("O'Brien".escapedForJSSingleQuotedString(), #"O\'Brien"#)
  }

  func testMultipleSingleQuotesAreEscaped() {
    XCTAssertEqual("it's a dog's life".escapedForJSSingleQuotedString(), #"it\'s a dog\'s life"#)
  }

  // MARK: - Backslashes (already doubled in JSON output)

  func testBackslashIsDoubled() {
    // A single \ in JSON output (encoded as \\) must become \\\\ in JS
    // so the JS engine sees it as a literal backslash and JSON.parse still works.
    XCTAssertEqual("a\\b".escapedForJSSingleQuotedString(), "a\\\\b")
  }

  // MARK: - Combined

  func testSingleQuoteAfterBackslashIsHandledCorrectly() {
    // Backslash MUST be doubled before the single-quote replacement.
    // Wrong order would turn "foo\'" into "foo\\\'" which JS interprets as "foo\" + broken string.
    XCTAssertEqual("foo\\'bar".escapedForJSSingleQuotedString(), "foo\\\\\\'bar")
  }

  func testRealisticJSONPayloadWithSingleQuote() {
    let json = #"{"token":"abc","locale":"en_AU","name":"O'Brien"}"#
    let escaped = json.escapedForJSSingleQuotedString()
    // The escaping must not leave any unescaped single quotes
    let jsString = "openCheckout('\(escaped)');"
    let unescapedSingleQuotes = jsString
      .components(separatedBy: "\\'").joined()          // remove valid \' sequences
      .filter { $0 == "'" }
    // Only the outer delimiters should remain (first and last char)
    XCTAssertEqual(unescapedSingleQuotes.count, 2)
  }

}
