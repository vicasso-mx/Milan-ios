import Foundation

struct CartLine: Identifiable, Equatable, Sendable {
    let product: Product
    var quantity: Int
    var id: Int { product.id }
    var subtotal: Decimal { Money.rounded(product.price * Decimal(quantity)) }
}

struct Cart: Equatable, Sendable {
    static let maximumQuantity = 2_147_483_647
    private(set) var lines: [CartLine] = []
    var itemCount: Int { lines.reduce(0) { $0 + $1.quantity } }
    var total: Decimal {
        Money.rounded(lines.reduce(Decimal.zero) { $0 + $1.product.price * Decimal($1.quantity) })
    }

    enum ValidationError: Error, Equatable, LocalizedError {
        case invalidQuantity
        case unknownProduct
        var errorDescription: String? {
            switch self {
            case .invalidQuantity:
                "Ingresa una cantidad entera entre 0 y 2,147,483,647."
            case .unknownProduct:
                "No se encontró el producto en el catálogo local."
            }
        }
    }

    static func quantity(from text: String) throws -> Int {
        guard !text.isEmpty,
              text.utf8.allSatisfy({ (48...57).contains($0) }),
              let value = Int(text), (0...maximumQuantity).contains(value) else {
            throw ValidationError.invalidQuantity
        }
        return value
    }

    mutating func add(productID: Int, catalog: Catalog) throws {
        guard let product = catalog.products.first(where: { $0.id == productID }) else {
            throw ValidationError.unknownProduct
        }
        if let index = lines.firstIndex(where: { $0.id == productID }) {
            guard lines[index].quantity < Self.maximumQuantity else {
                throw ValidationError.invalidQuantity
            }
            lines[index].quantity += 1
        } else {
            lines.append(CartLine(product: product, quantity: 1))
        }
    }

    mutating func update(quantities: [Int: String]) throws {
        // Validate the entire draft before committing any mutation.
        guard Set(quantities.keys).isSubset(of: Set(lines.map(\.id))) else {
            throw ValidationError.unknownProduct
        }
        let parsed = try quantities.mapValues { try Self.quantity(from: $0) }
        var updated = lines
        for index in updated.indices {
            if let quantity = parsed[updated[index].id] {
                updated[index].quantity = quantity
            }
        }
        lines = updated.filter { $0.quantity > 0 }
    }
}
