import SwiftUI

struct CheckoutView: View {
    @Bindable var session: SessionViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let cart = session.reviewCart {
                    ForEach(cart.lines) { line in
                        OrderItemView(item: OrderItem(line: line))
                    }
                    Text("Total").font(.headline)
                    Text(Money.formatted(cart.total))
                        .font(.title.bold())
                        .accessibilityIdentifier("review-total")
                    Text("Pago simulado. No se realizará ningún cargo real.")
                        .font(.callout.weight(.semibold))
                    Button("Pagar ahora") { session.pay() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityIdentifier("pay-now")
                } else {
                    Text("El carrito cambió. Revisa los productos antes de finalizar la compra.")
                }
                Button("Volver al carrito") { session.returnToCart() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("back-to-cart")
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Revisar pedido")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PurchaseSuccessView: View {
    @Bindable var session: SessionViewModel
    let orderID: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let order = session.order(id: orderID) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Brand.primary)
                        .accessibilityHidden(true)
                    Text("¡Gracias por tu pedido!").font(.title.bold())
                    Text("Orden: \(order.id)").textSelection(.enabled)
                    Text(Money.formatted(order.total)).font(.title2.bold())
                        .accessibilityIdentifier("success-total")
                    Text(order.status)
                    Button("Ver orden") { session.showCompletedOrder(orderID) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accessibilityIdentifier("view-order")
                } else {
                    Text("No se encontró la orden.")
                }
                Button("Seguir comprando") { session.continueShopping() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("continue-shopping")
            }
            .padding()
        }
        .navigationTitle("Compra completada")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }
}
