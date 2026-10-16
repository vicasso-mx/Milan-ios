import XCTest

@MainActor
final class MilanUITests: XCTestCase {
    private func app() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(es-MX)", "-AppleLocale", "es_MX"]
        app.launch()
        return app
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<12 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
    }

    func testCartUpdateRemovalAndNewLaunch() {
        let app = app()
        let add = app.buttons["add-1"]
        reveal(add, in: app)
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        let quantity = app.textFields["quantity-1"]
        XCTAssertTrue(quantity.waitForExistence(timeout: 5))
        quantity.tap()
        quantity.typeText(XCUIKeyboardKey.delete.rawValue + "2")
        app.buttons["Listo"].tap()
        let update = app.buttons["update-cart"]
        reveal(update, in: app)
        update.tap()
        XCTAssertTrue(app.staticTexts["cart-total"].label.contains("39.00"))
        reveal(app.buttons["continue-shopping"], in: app)
        app.buttons["continue-shopping"].tap()
        app.buttons["open-cart"].tap()
        XCTAssertEqual(app.textFields["quantity-1"].value as? String, "2")
        app.terminate()
        app.launch()
        app.buttons["open-cart"].tap()
        XCTAssertTrue(app.staticTexts["El carrito está vacío."].waitForExistence(timeout: 5))
    }

    func testRemoveLastProductWithZero() {
        let app = app()
        let add = app.buttons["add-1"]
        reveal(add, in: app)
        add.tap()
        let quantity = app.textFields["quantity-1"]
        XCTAssertTrue(quantity.waitForExistence(timeout: 5))
        quantity.tap()
        quantity.typeText(XCUIKeyboardKey.delete.rawValue + "0")
        app.buttons["Listo"].tap()
        let update = app.buttons["update-cart"]
        reveal(update, in: app)
        update.tap()
        XCTAssertTrue(app.staticTexts["El carrito está vacío."].waitForExistence(timeout: 5))
    }

    func testPaginationAndEmptyFilter() {
        let app = app()
        let next = app.buttons["next-page-top"]
        reveal(next, in: app)
        next.tap()
        XCTAssertTrue(app.staticTexts["page-summary-top"].label.contains("página 2 de 2"))
        XCTAssertFalse(app.buttons["next-page-top"].isEnabled)
        let previous = app.buttons["previous-page-top"]
        previous.tap()
        XCTAssertTrue(app.staticTexts["page-summary-top"].label.contains("página 1 de 2"))
        let type = app.buttons["type-filter"]
        type.tap()
        app.buttons["Industrial"].tap()
        app.buttons["apply-filters"].tap()
        XCTAssertTrue(app.staticTexts["No hay resultados que coincidan con tu búsqueda"].waitForExistence(timeout: 5))
    }
}

extension MilanUITests {
    private func recordScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func checkout(_ app: XCUIApplication) {
        let button = app.buttons["checkout"]
        reveal(button, in: app)
        XCTAssertTrue(button.isHittable)
        button.tap()
    }

    private func addFirst(_ app: XCUIApplication) {
        let button = app.buttons["add-1"]
        reveal(button, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(app.textFields["quantity-1"].waitForExistence(timeout: 5))
    }

    private func replaceQuantity(_ id: Int, with value: String, app: XCUIApplication) {
        let field = app.textFields["quantity-\(id)"]
        reveal(field, in: app)
        field.tap()
        let current = field.value as? String ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + value)
        app.buttons["Listo"].tap()
    }

    private func login(_ app: XCUIApplication, user: String = "cliente@doceolab.com") {
        let username = app.textFields["login-username"]
        XCTAssertTrue(username.waitForExistence(timeout: 5))
        username.tap()
        username.typeText(user)
        let password = app.secureTextFields["login-password"]
        password.tap()
        password.typeText("Pass@word1")
        app.buttons["login-submit"].tap()
    }

    private func menu(_ app: XCUIApplication, action: String) {
        let sessionMenu = app.navigationBars.buttons["session-menu"].firstMatch
        XCTAssertTrue(sessionMenu.waitForExistence(timeout: 5))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: sessionMenu)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        sessionMenu.tap()
        let button = app.buttons[action]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    private func pay(_ app: XCUIApplication) {
        let button = app.buttons["pay-now"]
        reveal(button, in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(app.buttons["view-order"].waitForExistence(timeout: 5))
    }

    func testCheckoutLoginCancellationResumptionAndOrderDetail() {
        let app = app()
        addFirst(app)
        XCTAssertFalse(app.textFields["login-username"].exists)
        replaceQuantity(1, with: "2", app: app)
        checkout(app) // No manual Actualizar.
        XCTAssertTrue(app.textFields["login-username"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["pay-now"].exists)
        app.buttons["login-cancel"].tap()
        XCTAssertTrue(app.textFields["quantity-1"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["quantity-1"].value as? String, "2")
        XCTAssertTrue(app.staticTexts["cart-total"].label.contains("39.00"))
        checkout(app)
        app.buttons["login-submit"].tap()
        XCTAssertTrue(app.staticTexts["login-error"].exists)
        login(app)
        XCTAssertTrue(app.staticTexts["review-total"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["review-total"].label.contains("39.00"))
        recordScreenshot("Revision-compra", app: app)
        pay(app)
        XCTAssertTrue(app.staticTexts["success-total"].label.contains("39.00"))
        app.buttons["view-order"].tap()
        let total = app.staticTexts["order-total"]
        reveal(total, in: app)
        XCTAssertTrue(total.label.contains("39.00"))
        recordScreenshot("Detalle-orden", app: app)
        app.navigationBars.buttons["Mis órdenes"].tap()
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "orders-list").firstMatch.cells.count, 1)
        menu(app, action: "sign-out")
        app.buttons["open-cart"].tap()
        XCTAssertTrue(app.staticTexts["El carrito está vacío."].waitForExistence(timeout: 5))
    }

    func testMultipleOrdersLogoutAndNewLoginHaveNoOldData() {
        let app = app()
        addFirst(app)
        checkout(app)
        login(app, user: "admin@doceolab.com")
        pay(app)
        app.buttons["continue-shopping"].tap()
        addFirst(app)
        replaceQuantity(1, with: "2", app: app)
        checkout(app)
        XCTAssertFalse(app.textFields["login-username"].exists)
        pay(app)
        menu(app, action: "orders-menu")
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "orders-list").firstMatch.cells.count, 2)
        recordScreenshot("Dos-ordenes", app: app)
        menu(app, action: "sign-out")
        menu(app, action: "orders-menu")
        XCTAssertTrue(app.textFields["login-username"].waitForExistence(timeout: 5))
        login(app, user: "admin@doceolab.com")
        XCTAssertTrue(app.staticTexts["Aún no tienes órdenes."].waitForExistence(timeout: 5))
    }

    func testProcessRelaunchClearsAuthenticationCartAndOrders() {
        let app = app()
        addFirst(app)
        checkout(app)
        login(app)
        pay(app)
        app.buttons["continue-shopping"].tap()
        addFirst(app) // Leave both an order and a nonempty cart before terminating.
        app.terminate()
        app.launch()
        app.buttons["open-cart"].tap()
        XCTAssertTrue(app.staticTexts["El carrito está vacío."].waitForExistence(timeout: 5))
        menu(app, action: "orders-menu")
        XCTAssertTrue(app.textFields["login-username"].waitForExistence(timeout: 5))
        login(app)
        XCTAssertTrue(app.staticTexts["Aún no tienes órdenes."].waitForExistence(timeout: 5))
    }

    func testCheckoutWithZeroQuantityDoesNotRequestAuthentication() {
        let app = app()
        addFirst(app)
        replaceQuantity(1, with: "0", app: app)
        checkout(app)
        XCTAssertTrue(app.staticTexts["El carrito está vacío."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["login-username"].exists)
        XCTAssertFalse(app.buttons["pay-now"].exists)
    }

    func testAddingAtMaximumShowsErrorWithoutChangingCart() {
        let app = app()
        addFirst(app)
        replaceQuantity(1, with: "2147483647", app: app)
        let update = app.buttons["update-cart"]
        reveal(update, in: app)
        update.tap()
        app.buttons["continue-shopping"].tap()
        let add = app.buttons["add-1"]
        reveal(add, in: app)
        add.tap()
        let alert = app.alerts["MILAN"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["Ingresa una cantidad entera entre 0 y 2,147,483,647."].exists)
        alert.buttons["Aceptar"].tap()
        app.buttons["open-cart"].tap()
        XCTAssertEqual(app.textFields["quantity-1"].value as? String, "2147483647")
    }

}
