import Foundation
import Observation

@MainActor @Observable
final class CartViewModel {
    private(set) var cart = Cart()
    private(set) var revision = 0
    var drafts: [Int: String] = [:]
    var errorMessage: String?
    private let catalog: Catalog

    init(catalog: Catalog) { self.catalog = catalog }

    @discardableResult
    func add(_ productID: Int) -> Bool {
        do {
            try cart.add(productID: productID, catalog: catalog)
            revision += 1
            beginEditing()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func beginEditing() {
        drafts = Dictionary(uniqueKeysWithValues: cart.lines.map { ($0.id, String($0.quantity)) })
        errorMessage = nil
    }

    @discardableResult
    func update() -> Bool {
        do {
            let previous = cart
            try cart.update(quantities: drafts)
            if cart != previous { revision += 1 }
            beginEditing()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func clear() {
        cart = Cart()
        revision += 1
        beginEditing()
    }
}
