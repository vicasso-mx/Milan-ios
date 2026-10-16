import Foundation
import Observation

@MainActor @Observable
final class CatalogViewModel {
    let catalog: Catalog
    var selectedBrandID = 0
    var selectedTypeID = 0
    private(set) var appliedBrandID = 0
    private(set) var appliedTypeID = 0
    private(set) var page = 0
    let pageSize = 10

    init(catalog: Catalog) { self.catalog = catalog }

    var filteredProducts: [Product] {
        catalog.products.filter {
            (appliedBrandID == 0 || $0.brandID == appliedBrandID)
                && (appliedTypeID == 0 || $0.typeID == appliedTypeID)
        }
    }
    var totalPages: Int { (filteredProducts.count + pageSize - 1) / pageSize }
    var productsOnPage: [Product] { Array(filteredProducts.dropFirst(page * pageSize).prefix(pageSize)) }
    var canGoBack: Bool { page > 0 }
    var canGoForward: Bool { page + 1 < totalPages }
    var pageSummary: String {
        "Mostrando \(productsOnPage.count) de \(filteredProducts.count) productos — página \(page + 1) de \(totalPages)"
    }

    func applyFilters() {
        appliedBrandID = selectedBrandID
        appliedTypeID = selectedTypeID
        page = 0
    }
    func previousPage() { if canGoBack { page -= 1 } }
    func nextPage() { if canGoForward { page += 1 } }
}
