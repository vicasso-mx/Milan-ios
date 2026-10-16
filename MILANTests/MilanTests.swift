import XCTest
import UIKit
@testable import MILAN

final class CatalogTests: XCTestCase {
    func testTwelveProductsAndOriginalPrices() throws {
        let catalog = try Catalog.load()
        XCTAssertEqual(catalog.products.map(\.id), Array(1...12))
        let prices = ["19.50", "8.50", "12", "12", "8.50", "12", "12", "8.50", "12", "12", "8.50", "12"]
        let names = ["AeroMILA Halcón P2", "AeroMILA Brisa Mini", "AgroVuelo Prisma 4K", "AeroMILA Centinela S1", "AgroVuelo Órbita Foto", "AeroMILA Campo V3", "AgroVuelo Terrascan RTK", "AgroVuelo Vigía X", "AgroVuelo Giro Go", "AeroMILA Vista Aérea 6K", "AeroMILA Lente Nube", "AgroVuelo Inspección RTK"]
        for (index, product) in catalog.products.enumerated() {
            XCTAssertEqual(product.price, Decimal(string: prices[index]))
            XCTAssertEqual(product.name, names[index])
            XCTAssertFalse(product.description.isEmpty)
            XCTAssertNotNil(UIImage(named: product.imageName), product.imageName)
        }
        XCTAssertNotNil(UIImage(named: "brand"))
        XCTAssertNotNil(UIImage(named: "banner"))
    }

    func testRejectsIncompleteCatalog() {
        XCTAssertThrowsError(try Catalog.decode(Data("[]".utf8)))
    }

    @MainActor func testFilteringAndPagination() throws {
        let model = CatalogViewModel(catalog: try Catalog.load())
        XCTAssertEqual(model.productsOnPage.count, 10)
        XCTAssertFalse(model.canGoBack)
        model.previousPage()
        XCTAssertEqual(model.page, 0)
        model.nextPage()
        XCTAssertEqual(model.productsOnPage.map(\.id), [11, 12])
        model.nextPage()
        XCTAssertEqual(model.page, 1)
        model.selectedBrandID = 2
        model.selectedTypeID = 2
        model.applyFilters()
        XCTAssertEqual(model.page, 0)
        XCTAssertEqual(model.productsOnPage.map(\.id), [1, 4, 6])
        XCTAssertFalse(model.canGoForward)
        for (type, count) in [(1, 2), (2, 7), (3, 3), (4, 0)] {
            model.selectedBrandID = 0
            model.selectedTypeID = type
            model.applyFilters()
            XCTAssertEqual(model.filteredProducts.count, count)
        }
        for (brand, count) in [(1, 0), (2, 6), (3, 0), (4, 0), (5, 6)] {
            model.selectedBrandID = brand
            model.selectedTypeID = 0
            model.applyFilters()
            XCTAssertEqual(model.filteredProducts.count, count)
        }
        model.selectedBrandID = 0
        model.applyFilters()
        XCTAssertEqual(model.filteredProducts.count, 12)
    }
}

final class CartTests: XCTestCase {
    func testAddAccumulatesWithoutDuplicateLines() throws {
        let catalog = try Catalog.load()
        var cart = Cart()
        try cart.add(productID: 1, catalog: catalog)
        try cart.add(productID: 1, catalog: catalog)
        XCTAssertEqual(cart.lines.count, 1)
        XCTAssertEqual(cart.lines[0].quantity, 2)
        XCTAssertEqual(cart.itemCount, 2)
        XCTAssertEqual(cart.lines[0].subtotal, Decimal(39))
        XCTAssertThrowsError(try cart.add(productID: 999, catalog: catalog))
        XCTAssertEqual(cart.itemCount, 2)
    }

    func testUpdateRemoveSubtotalsAndTotal() throws {
        let catalog = try Catalog.load()
        var cart = Cart()
        try cart.add(productID: 1, catalog: catalog)
        try cart.add(productID: 2, catalog: catalog)
        try cart.update(quantities: [1: "2", 2: "3"])
        XCTAssertEqual(cart.lines.map(\.subtotal), [Decimal(39), Decimal(string: "25.50")!])
        XCTAssertEqual(cart.total, Decimal(string: "64.50"))
        XCTAssertEqual(cart.itemCount, 5)
        try cart.update(quantities: [1: "0"])
        XCTAssertEqual(cart.lines.map(\.id), [2])
        XCTAssertEqual(cart.total, Decimal(string: "25.50"))
        XCTAssertEqual(cart.itemCount, 3)
        try cart.update(quantities: [2: "0"])
        XCTAssertTrue(cart.lines.isEmpty)
        XCTAssertEqual(cart.total, .zero)
        XCTAssertEqual(cart.itemCount, 0)
    }

    func testInvalidQuantitiesRejectAtomically() throws {
        let catalog = try Catalog.load()
        var cart = Cart()
        try cart.add(productID: 1, catalog: catalog)
        try cart.add(productID: 2, catalog: catalog)
        let original = cart
        for text in ["-1", "1.5", "hola", "", "2147483648", "999999999999999999999", " 2", "+2"] {
            XCTAssertThrowsError(try cart.update(quantities: [1: "3", 2: text]), text)
            XCTAssertEqual(cart, original)
        }
        XCTAssertThrowsError(try cart.update(quantities: [999: "2"]))
        XCTAssertEqual(cart, original)
    }

    func testMaximumQuantityAndIncrementOverflow() throws {
        let catalog = try Catalog.load()
        var cart = Cart()
        try cart.add(productID: 1, catalog: catalog)
        try cart.update(quantities: [1: "2147483647"])
        XCTAssertEqual(cart.total, Decimal(string: "41875931116.50"))
        let original = cart
        XCTAssertThrowsError(try cart.add(productID: 1, catalog: catalog))
        XCTAssertEqual(cart, original)
    }

    func testDecimalArithmeticAndBankersRounding() {
        XCTAssertEqual(Money.rounded(Decimal(string: "1.005")!), Decimal(string: "1.00"))
        XCTAssertEqual(Money.rounded(Decimal(string: "1.015")!), Decimal(string: "1.02"))
        XCTAssertTrue(Money.formatted(Decimal(string: "64.50")!).contains("64.50"))
    }

    @MainActor func testViewModelKeepsConfirmedStateAndDiscardsDrafts() throws {
        let catalog = try Catalog.load()
        let model = CartViewModel(catalog: catalog)
        XCTAssertTrue(model.add(1))
        model.drafts[1] = "3"
        XCTAssertEqual(model.cart.itemCount, 1)
        model.beginEditing()
        XCTAssertEqual(model.drafts[1], "1")
        model.drafts[1] = "-1"
        model.update()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(model.cart.itemCount, 1)
        model.drafts[1] = "2"
        model.update()
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.cart.total, Decimal(39))
        XCTAssertTrue(CartViewModel(catalog: catalog).cart.lines.isEmpty)
    }
}
