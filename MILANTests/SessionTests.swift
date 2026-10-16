import XCTest
@testable import MILAN

@MainActor
final class SessionTests: XCTestCase {
    private func session() throws -> SessionViewModel {
        SessionViewModel(catalog: try Catalog.load(), now: { Date(timeIntervalSince1970: 1_700_000_000) }, makeID: { "prueba" })
    }

    private func signIn(_ model: SessionViewModel, user: String = "cliente@doceolab.com") {
        XCTAssertTrue(model.signIn(username: user, password: "Pass@word1", purpose: .shopping))
    }

    private func fill(_ model: SessionViewModel) {
        XCTAssertTrue(model.cartModel.add(1))
        XCTAssertTrue(model.cartModel.add(2))
        model.cartModel.drafts = [1: "2", 2: "3"]
    }

    func testBothDemoAccountsAndInvalidCredentials() throws {
        for user in ["cliente@doceolab.com", "admin@doceolab.com"] {
            let model = try session()
            XCTAssertTrue(model.cartModel.add(1))
            for pair in [("", ""), (user, "incorrecta"), ("otro@doceolab.com", "Pass@word1")] {
                XCTAssertFalse(model.signIn(username: pair.0, password: pair.1, purpose: .shopping))
                XCTAssertFalse(model.isAuthenticated)
                XCTAssertNotNil(model.loginError)
                XCTAssertEqual(model.cartModel.cart.itemCount, 1)
            }
            signIn(model, user: user)
            XCTAssertEqual(model.username, user)
            XCTAssertEqual(model.cartModel.cart.itemCount, 1)
            XCTAssertNil(model.loginError)
        }
    }

    func testPublicCartAndProtectedCheckoutAndOrders() throws {
        let model = try session()
        fill(model)
        XCTAssertFalse(model.isAuthenticated)
        XCTAssertNil(model.pay())
        XCTAssertTrue(model.orders.isEmpty)
        model.continueShopping()
        model.openOrders()
        XCTAssertEqual(model.path.last, .login(.orders))
        XCTAssertTrue(model.visibleOrders.isEmpty)
        XCTAssertNil(model.order(id: "inexistente"))
        model.cancelLogin()
        model.beginCheckout()
        XCTAssertEqual(model.path.last, .login(.checkout))
        XCTAssertEqual(model.cartModel.cart.total, Decimal(string: "64.50"))
        XCTAssertNil(model.reviewCart)
        XCTAssertTrue(model.orders.isEmpty)
    }

    func testSignInResumesPendingPurchaseWithoutLosingCart() throws {
        let model = try session()
        fill(model)
        model.path = [.cart]
        model.beginCheckout()
        let confirmed = model.cartModel.cart
        XCTAssertTrue(model.signIn(username: "cliente@doceolab.com", password: "Pass@word1", purpose: .checkout))
        XCTAssertEqual(model.path, [.cart, .review])
        XCTAssertEqual(model.cartModel.cart, confirmed)
        XCTAssertEqual(model.reviewCart, confirmed)
        XCTAssertTrue(model.orders.isEmpty)
    }

    func testCancelLoginReturnsToUpdatedAnonymousCart() throws {
        let model = try session()
        fill(model)
        model.path = [.cart]
        model.beginCheckout()
        model.cancelLogin()
        XCTAssertEqual(model.path, [.cart])
        XCTAssertFalse(model.isAuthenticated)
        XCTAssertEqual(model.cartModel.cart.itemCount, 5)
        XCTAssertEqual(model.cartModel.cart.total, Decimal(string: "64.50"))
        XCTAssertTrue(model.orders.isEmpty)
        model.beginCheckout()
        XCTAssertEqual(model.path.last, .login(.checkout))
    }

    func testCheckoutValidationIsAtomicAndKeepsDrafts() throws {
        let model = try session()
        fill(model)
        let original = model.cartModel.cart
        model.path = [.cart]
        for invalid in ["-1", "1.5", "", "texto", "2147483648"] {
            model.cartModel.drafts = [1: "4", 2: invalid]
            model.beginCheckout()
            XCTAssertEqual(model.cartModel.cart, original)
            XCTAssertEqual(model.cartModel.drafts[1], "4")
            XCTAssertEqual(model.cartModel.drafts[2], invalid)
            XCTAssertEqual(model.path, [.cart])
            XCTAssertNotNil(model.cartModel.errorMessage)
            XCTAssertTrue(model.orders.isEmpty)
        }
    }

    func testZeroQuantitiesBlockEmptyPurchaseAndRemovePartialLines() throws {
        let model = try session()
        fill(model)
        model.path = [.cart]
        model.cartModel.drafts = [1: "0", 2: "3"]
        model.beginCheckout()
        XCTAssertEqual(model.cartModel.cart.lines.map(\.id), [2])
        XCTAssertEqual(model.cartModel.cart.total, Decimal(string: "25.50"))
        model.cancelLogin()
        model.cartModel.drafts = [2: "0"]
        model.beginCheckout()
        XCTAssertTrue(model.cartModel.cart.lines.isEmpty)
        XCTAssertEqual(model.path, [.cart])
        XCTAssertFalse(model.isAuthenticated)
        XCTAssertTrue(model.orders.isEmpty)
        XCTAssertNil(model.pay())
        XCTAssertTrue(model.orders.isEmpty)
    }

    func testPurchaseSnapshotIsCorrectAndDoublePaymentIsIgnored() throws {
        let model = try session()
        fill(model)
        signIn(model)
        model.beginCheckout()
        let order = try XCTUnwrap(model.pay())
        XCTAssertEqual(order.date, Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(order.customer, "cliente@doceolab.com")
        XCTAssertEqual(order.items.map(\.id), [1, 2])
        XCTAssertEqual(order.items.map(\.quantity), [2, 3])
        XCTAssertEqual(order.items.map(\.unitPrice), [Decimal(string: "19.50")!, Decimal(string: "8.50")!])
        XCTAssertEqual(order.items.map(\.subtotal), [Decimal(39), Decimal(string: "25.50")!])
        XCTAssertEqual(order.items[0].name, "AeroMILA Halcón P2")
        XCTAssertEqual(order.items[0].imageName, "product-1")
        XCTAssertEqual(order.total, Decimal(string: "64.50"))
        XCTAssertEqual(order.status, "Pago simulado completado")
        XCTAssertTrue(model.cartModel.cart.lines.isEmpty)
        XCTAssertTrue(model.cartModel.drafts.isEmpty)
        XCTAssertTrue(model.isAuthenticated)
        XCTAssertNil(model.pay())
        XCTAssertEqual(model.orders, [order])
        XCTAssertEqual(model.path, [.success(order.id)])
    }

    func testMultipleOrdersHaveUniqueIDsAndImmutableDetails() throws {
        let model = try session()
        fill(model)
        signIn(model)
        model.beginCheckout()
        let first = try XCTUnwrap(model.pay())
        XCTAssertTrue(model.cartModel.add(3))
        model.beginCheckout()
        let second = try XCTUnwrap(model.pay())
        XCTAssertNotEqual(first.id, second.id) // Even when both factories return fixed values.
        XCTAssertEqual(model.visibleOrders.map(\.id), [second.id, first.id])
        XCTAssertEqual(model.order(id: first.id), first)
        XCTAssertEqual(second.total, Decimal(12))
        XCTAssertNil(model.order(id: "inexistente"))
    }

    func testChangedCartInvalidatesReviewEvenIfQuantitiesAreRestored() throws {
        let model = try session()
        fill(model)
        signIn(model)
        model.beginCheckout()
        XCTAssertTrue(model.cartModel.add(1))
        model.cartModel.drafts[1] = "2"
        model.cartModel.update()
        XCTAssertNil(model.reviewCart)
        XCTAssertNil(model.pay())
        XCTAssertTrue(model.orders.isEmpty)
        XCTAssertEqual(model.cartModel.cart.itemCount, 5)
        XCTAssertEqual(model.path.last, .cart)
    }

    func testCancelReviewAndNativeBackDoNotPurchase() throws {
        let model = try session()
        fill(model)
        signIn(model)
        model.path = [.cart]
        model.beginCheckout()
        model.path.removeLast()
        model.reconcileNavigation()
        XCTAssertNil(model.pay())
        XCTAssertTrue(model.orders.isEmpty)
        XCTAssertEqual(model.cartModel.cart.itemCount, 5)
        model.beginCheckout()
        model.returnToCart()
        XCTAssertEqual(model.path, [.cart])
        XCTAssertEqual(model.cartModel.cart.itemCount, 5)
    }

    func testSignOutClearsEverythingAndRejectsStalePayment() throws {
        for route in [StoreRoute.review, .orders, .order("anterior"), .success("anterior")] {
            let model = try session()
            fill(model)
            signIn(model)
            model.beginCheckout()
            let first = try XCTUnwrap(model.pay())
            XCTAssertTrue(model.cartModel.add(1))
            model.beginCheckout()
            model.cartModel.drafts[1] = "99"
            model.path = [route]
            model.signOut()
            XCTAssertNil(model.username)
            XCTAssertTrue(model.cartModel.cart.lines.isEmpty)
            XCTAssertTrue(model.cartModel.drafts.isEmpty)
            XCTAssertTrue(model.orders.isEmpty)
            XCTAssertNil(model.order(id: first.id))
            XCTAssertNil(model.reviewCart)
            XCTAssertTrue(model.path.isEmpty)
            XCTAssertNil(model.loginError)
            XCTAssertNil(model.errorMessage)
            XCTAssertNil(model.pay())
            signIn(model, user: "admin@doceolab.com")
            XCTAssertTrue(model.visibleOrders.isEmpty)
            XCTAssertTrue(model.cartModel.cart.lines.isEmpty)
        }
    }

    func testFreshProcessStateAndLoginOrdersDestination() throws {
        let old = try session()
        fill(old)
        signIn(old)
        old.beginCheckout()
        XCTAssertNotNil(old.pay())
        let fresh = try session()
        XCTAssertFalse(fresh.isAuthenticated)
        XCTAssertTrue(fresh.cartModel.cart.lines.isEmpty)
        XCTAssertTrue(fresh.orders.isEmpty)
        XCTAssertTrue(fresh.path.isEmpty)
        fresh.openOrders()
        XCTAssertTrue(fresh.signIn(username: "admin@doceolab.com", password: "Pass@word1", purpose: .orders))
        XCTAssertEqual(fresh.path, [.orders])
        XCTAssertTrue(fresh.visibleOrders.isEmpty)
    }

    func testUnauthenticatedProtectedNavigationRequestsLogin() throws {
        for route in [StoreRoute.orders, .order("inexistente")] {
            let model = try session()
            model.path = [route]
            model.reconcileNavigation()
            XCTAssertEqual(model.path, [.login(.orders)])
            XCTAssertTrue(model.visibleOrders.isEmpty)
        }
        let model = try session()
        fill(model)
        model.path = [.review]
        model.reconcileNavigation()
        XCTAssertEqual(model.path.last, .login(.checkout))
        XCTAssertEqual(model.cartModel.cart.itemCount, 5)
        XCTAssertTrue(model.orders.isEmpty)
    }

}
