import Foundation

struct OrderItem: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let imageName: String
    let unitPrice: Decimal
    let quantity: Int
    let subtotal: Decimal

    init(line: CartLine) {
        id = line.id
        name = line.product.name
        imageName = line.product.imageName
        unitPrice = line.product.price
        quantity = line.quantity
        subtotal = line.subtotal
    }
}

struct Order: Identifiable, Equatable, Sendable {
    let id: String
    let date: Date
    let customer: String
    let items: [OrderItem]
    let total: Decimal
    let status = "Pago simulado completado"
}
