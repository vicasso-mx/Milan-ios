import SwiftUI

struct OrdersView: View {
    @Bindable var session: SessionViewModel

    var body: some View {
        Group {
            if !session.isAuthenticated {
                ContentUnavailableView("Inicia sesión para consultar tus órdenes.", systemImage: "person.crop.circle")
            } else if session.visibleOrders.isEmpty {
                ContentUnavailableView("Aún no tienes órdenes.", systemImage: "list.bullet.rectangle")
                    .accessibilityIdentifier("empty-orders")
            } else {
                List {
                    ForEach(session.visibleOrders) { order in
                        NavigationLink(value: StoreRoute.order(order.id)) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Orden: \(order.id)").font(.headline)
                                Text(OrderPresentation.date(order.date)).font(.subheadline)
                                Text(Money.formatted(order.total)).fontWeight(.semibold)
                                Text(order.status).font(.caption)
                            }
                            .padding(.vertical, 8)
                        }
                        .accessibilityIdentifier("order-\(order.id)")
                    }
                }
                .accessibilityIdentifier("orders-list")
            }
        }
        .navigationTitle("Mis órdenes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderDetailView: View {
    @Bindable var session: SessionViewModel
    let orderID: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let order = session.order(id: orderID) {
                    Text("Orden: \(order.id)").font(.headline)
                    Text("Fecha: \(OrderPresentation.date(order.date))")
                    Text("Usuario: \(order.customer)")
                    Text("Estado: \(order.status)")
                    ForEach(order.items) { OrderItemView(item: $0) }
                    Text("Total").font(.headline)
                    Text(Money.formatted(order.total))
                        .font(.title.bold())
                        .accessibilityIdentifier("order-total")
                } else {
                    Text(session.isAuthenticated ? "No se encontró la orden." : "Inicia sesión para consultar tus órdenes.")
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalle de orden")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OrderItemView: View {
    let item: OrderItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(item.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 130)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel(item.name)
            Text(item.name).font(.headline)
            LabeledContent("Precio", value: Money.formatted(item.unitPrice))
            LabeledContent("Cantidad", value: String(item.quantity))
            LabeledContent("Importe", value: Money.formatted(item.subtotal))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

private enum OrderPresentation {
    static func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.timeZone = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
