//
//  String+JSEscaping.swift
//  Afterpay
//

import Foundation

extension String {
  /// Returns a copy safe for embedding inside a JavaScript single-quoted string literal.
  ///
  /// JSON output can legitimately contain `\` (encoded as `\\`) and `'` (unescaped, since
  /// JSON uses double-quote delimiters). Both must be re-escaped before the string is
  /// spliced into `someJSFunction('...')` to avoid breaking the JS syntax or enabling
  /// unintended script execution.
  ///
  /// - Backslashes are doubled first so subsequent `'` replacement doesn't corrupt them.
  /// - Single quotes are then escaped with a backslash.
  func escapedForJSSingleQuotedString() -> String {
    return self
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "'", with: "\\'")
  }
}
