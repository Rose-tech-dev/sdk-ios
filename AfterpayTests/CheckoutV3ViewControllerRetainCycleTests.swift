//
//  CheckoutV3ViewControllerRetainCycleTests.swift
//  AfterpayTests
//

import XCTest
@testable import Afterpay

/// Verifies that CheckoutV3ViewController does not form a retain cycle with its
/// in-flight URLSessionDataTask. The cycle is:
///
///   VC.currentTask → task → callback closure → VC   (strong, without [weak self])
///
/// A real URLSession retains its task's callback until the task completes. The
/// RetainingMockTask below replicates that behaviour so the cycle is observable
/// without a live network.
final class CheckoutV3ViewControllerRetainCycleTests: XCTestCase {

  // A URLSessionDataTask that holds the callback strongly, like URLSession does.
  private final class RetainingMockTask: URLSessionDataTask {
    let storedCallback: (Data?, URLResponse?, Error?) -> Void
    init(storedCallback: @escaping (Data?, URLResponse?, Error?) -> Void) {
      self.storedCallback = storedCallback
    }
    override func resume() { /* intentionally never fires callback */ }
  }

  private struct StubConsumer: CheckoutV3Consumer {
    let email = "test@example.com"
    let givenNames: String? = nil
    let surname: String? = nil
    let phoneNumber: String? = nil
    let shippingInformation: CheckoutV3Contact? = nil
    let billingInformation: CheckoutV3Contact? = nil
  }

  func testViewControllerIsDeallocatedWhenRequestIsInFlight() {
    let config = CheckoutV3Configuration(
      shopDirectoryMerchantId: "merchant_id",
      region: .US,
      environment: .production
    )

    var retainingTask: RetainingMockTask?
    let retainingHandler: URLRequestHandler = { _, callback in
      let task = RetainingMockTask(storedCallback: callback)
      retainingTask = task
      return task
    }

    weak var weakVC: CheckoutV3ViewController?

    autoreleasepool {
      let checkout = CheckoutV3.Request(
        consumer: StubConsumer(),
        orderTotal: OrderTotal(total: 10, shipping: 0, tax: 0),
        configuration: config
      )
      let vc = CheckoutV3ViewController(
        checkout: checkout,
        buyNow: false,
        configuration: config,
        requestHandler: retainingHandler,
        completion: { _ in }
      )
      weakVC = vc

      // Trigger performCheckoutRequest (called by viewDidAppear via the host-validation guard)
      vc.loadViewIfNeeded()
      vc.beginAppearanceTransition(true, animated: false)
      vc.endAppearanceTransition()
    }

    // retainingTask is still alive, holding the callback chain:
    //   task.storedCallback → completeOnMainThread → completion closure → VC
    // Without [weak self] in the completion closure, VC cannot be deallocated.
    // After the [weak self] fix, the closure only holds a weak reference to VC,
    // so VC is released when the autoreleasepool is drained.
    XCTAssertNil(
      weakVC,
      "CheckoutV3ViewController leaked — strong self capture in network closure creates a retain cycle"
    )

    _ = retainingTask // keep alive until assertion is done
  }

}
