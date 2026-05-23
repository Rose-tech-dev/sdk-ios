//
//  AfterpaySDKError.swift
//  Afterpay
//

import Foundation

/// Errors produced by the Afterpay SDK itself (distinct from server-side API errors).
public enum AfterpaySDKError: LocalizedError {

  /// The SDK is not enabled because no valid configuration has been set.
  /// Call `Afterpay.setConfiguration` before invoking SDK functions.
  case notEnabled

  public var failureReason: String? {
    switch self {
    case .notEnabled:
      return "Afterpay SDK is not enabled. Call Afterpay.setConfiguration with a valid configuration first."
    }
  }

}
