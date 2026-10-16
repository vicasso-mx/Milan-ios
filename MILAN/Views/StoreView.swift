import SwiftUI

enum Brand {
    static let primary = Color(red: 11 / 255, green: 101 / 255, blue: 201 / 255)
    static let secondary = Color(red: 2 / 255, green: 180 / 255, blue: 236 / 255)
}

struct StoreView: View {
    @State private var catalogModel: CatalogViewModel
    @State private var session: SessionViewModel

    init(catalog: Catalog) {
        _catalogModel = State(initialValue: CatalogViewModel(catalog: catalog))
        _session = State(initialValue: SessionViewModel(catalog: catalog))
    }

    var body: some View {
        NavigationStack(path: $session.path) {
            CatalogView(model: catalogModel) { product in
                if session.cartModel.add(product.id) {
                    session.openCart()
                } else {
                    session.errorMessage = session.cartModel.errorMessage
                }
            }
            .navigationTitle("Catálogo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { session.openCart() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "cart")
                            Text("\(session.cartModel.cart.itemCount)").monospacedDigit()
                        }
                    }
                    .accessibilityLabel("Carrito, \(session.cartModel.cart.itemCount) artículos")
                    .accessibilityIdentifier("open-cart")
                }
                ToolbarItem(id: "session", placement: .topBarTrailing) { sessionMenu }
            }
            .navigationDestination(for: StoreRoute.self) { route in
                destination(route)
                    .toolbar {
                        if route.showsSessionMenu {
                            ToolbarItem(id: "session", placement: .topBarTrailing) { sessionMenu }
                        }
                    }
            }
        }
        .onChange(of: session.path) { session.reconcileNavigation() }
        .alert("MILAN", isPresented: Binding(
            get: { session.errorMessage != nil },
            set: { if !$0 { session.errorMessage = nil } }
        )) {
            Button("Aceptar", role: .cancel) { session.errorMessage = nil }
        } message: {
            Text(session.errorMessage ?? "")
        }
    }

    private var sessionMenu: some View {
        Menu {
            if let username = session.username {
                Text(username)
            } else {
                Button("Iniciar sesión") { session.openLogin() }
                    .accessibilityIdentifier("sign-in-menu")
            }
            Button("Mis órdenes") { session.openOrders() }
                .accessibilityIdentifier("orders-menu")
            if session.isAuthenticated {
                Button("Cerrar sesión", role: .destructive) { session.signOut() }
                    .accessibilityIdentifier("sign-out")
            }
        } label: {
            Label("Sesión", systemImage: session.isAuthenticated ? "person.crop.circle.fill" : "person.crop.circle")
        }
        .labelStyle(.iconOnly)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier("session-menu")
    }

    @ViewBuilder private func destination(_ route: StoreRoute) -> some View {
        switch route {
        case .cart:
            CartView(model: session.cartModel) { session.beginCheckout() }
        case .login(let purpose):
            SignInView(session: session, purpose: purpose)
        case .review:
            CheckoutView(session: session)
        case .success(let id):
            PurchaseSuccessView(session: session, orderID: id)
        case .orders:
            OrdersView(session: session)
        case .order(let id):
            OrderDetailView(session: session, orderID: id)
        }
    }
}

struct BrandHeader: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("brand")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 298)
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(.white)
                .accessibilityLabel("MILAN. Mercado Interactivo en Línea de Artículos y Novedades")
            GeometryReader { geometry in
                Image("banner")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: 135)
                    .clipped()
            }
            .frame(height: 135)
            .accessibilityHidden(true)
        }
    }
}
