import SwiftUI

struct CartView: View {
    @Bindable var model: CartViewModel
    var checkout: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedProduct: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if model.cart.lines.isEmpty {
                    ContentUnavailableView("El carrito está vacío.", systemImage: "cart")
                        .accessibilityIdentifier("empty-cart")
                } else {
                    ForEach(model.cart.lines) { line in
                        cartRow(line)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total").font(.headline)
                        Text(Money.formatted(model.cart.total))
                            .font(.title.bold())
                            .foregroundStyle(Brand.primary)
                            .accessibilityIdentifier("cart-total")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let error = model.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("quantity-error")
                    }
                    Button("Actualizar") {
                        focusedProduct = nil
                        model.update()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("update-cart")
                    Button("Finalizar compra") {
                        focusedProduct = nil
                        checkout()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("checkout")
                }
                Button("Seguir comprando") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("continue-shopping")
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Carrito")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.beginEditing() }
        .onDisappear { model.beginEditing() }
        .safeAreaInset(edge: .bottom) {
            if focusedProduct != nil {
                HStack {
                    Spacer()
                    Button("Listo") { focusedProduct = nil }
                        .frame(minHeight: 44)
                }
                .padding(.horizontal)
                .background(.bar)
            }
        }
    }

    private func cartRow(_ line: CartLine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(line.product.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .accessibilityLabel(line.product.name)
            Text(line.product.name).font(.headline)
            LabeledContent("Precio", value: Money.formatted(line.product.price))
            VStack(alignment: .leading) {
                Text("Cantidad").font(.subheadline)
                TextField("Cantidad", text: Binding(
                    get: { model.drafts[line.id] ?? String(line.quantity) },
                    set: { model.drafts[line.id] = $0 }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(minHeight: 44)
                .focused($focusedProduct, equals: line.id)
                .accessibilityLabel("Cantidad de \(line.product.name)")
                .accessibilityIdentifier("quantity-\(line.id)")
            }
            LabeledContent("Importe", value: Money.formatted(line.subtotal))
                .fontWeight(.semibold)
                .accessibilityIdentifier("subtotal-\(line.id)")
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
}
