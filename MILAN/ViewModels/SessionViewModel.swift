import Foundation
import Observation

enum LoginPurpose: Hashable {
    case shopping, orders, checkout
}

enum StoreRoute: Hashable {
    case cart
    case login(LoginPurpose)
    case review
    case success(String)
    case orders
    case order(String)

    var showsSessionMenu: Bool {
        if case .login = self { return false }
        return true
    }
}

@MainActor @Observable
final class SessionViewModel {
    let cartModel: CartViewModel
    private(set) var username: String?
    private(set) var orders: [Order] = []
    var path: [StoreRoute] = []
    var loginError: String?
    var errorMessage: String?

    @ObservationIgnored private let credentials: [String: String]
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let makeID: () -> String
    @ObservationIgnored private var usedIDs: Set<String> = []
    private var generation = 1
    private var pendingCheckout: Review?
    private var review: Review?

    private struct Review {
        let cart: Cart
        let revision: Int
    }

    init(catalog: Catalog, credentials: [String: String] = [
        "cliente@doceolab.com": "Pass@word1", "admin@doceolab.com": "Pass@word1"
    ], now: @escaping () -> Date = { Date() },
         makeID: @escaping () -> String = { UUID().uuidString }) {
        cartModel = CartViewModel(catalog: catalog)
        self.credentials = credentials
        self.now = now
        self.makeID = makeID
    }

    var isAuthenticated: Bool { username != nil }
    var reviewCart: Cart? {
        guard isAuthenticated, let review,
              review.revision == cartModel.revision, review.cart == cartModel.cart,
              !review.cart.lines.isEmpty else { return nil }
        return review.cart
    }

    func openCart() {
        cartModel.beginEditing()
        path.append(.cart)
    }

    func openLogin() {
        guard !isAuthenticated else { return }
        loginError = nil
        path.append(.login(.shopping))
    }

    func openOrders() {
        if isAuthenticated {
            path.append(.orders)
        } else {
            loginError = nil
            path.append(.login(.orders))
        }
    }

    func beginCheckout() {
        // update validates the entire draft before committing any quantities.
        guard cartModel.update() else { return }
        guard !cartModel.cart.lines.isEmpty else {
            pendingCheckout = nil
            review = nil
            return
        }
        let snapshot = Review(cart: cartModel.cart, revision: cartModel.revision)
        if isAuthenticated {
            review = snapshot
            path.append(.review)
        } else {
            pendingCheckout = snapshot
            loginError = nil
            path.append(.login(.checkout))
        }
    }

    @discardableResult
    func signIn(username: String, password: String, purpose: LoginPurpose) -> Bool {
        guard !isAuthenticated else { return false }
        guard !username.isEmpty, !password.isEmpty else {
            loginError = "Ingresa tu usuario y contraseña."
            return false
        }
        guard credentials[username] == password else {
            loginError = "Usuario o contraseña incorrectos."
            return false
        }
        self.username = username
        loginError = nil
        if case .login = path.last { path.removeLast() }
        switch purpose {
        case .shopping:
            break
        case .orders:
            path.append(.orders)
        case .checkout:
            defer { pendingCheckout = nil }
            guard let pendingCheckout, !cartModel.cart.lines.isEmpty,
                  pendingCheckout.revision == cartModel.revision,
                  pendingCheckout.cart == cartModel.cart else {
                returnToCart()
                errorMessage = "El carrito cambió. Revisa los productos antes de finalizar la compra."
                return true
            }
            review = pendingCheckout
            path.append(.review)
        }
        return true
    }

    func cancelLogin() {
        let purpose: LoginPurpose?
        if case .login(let current) = path.last { purpose = current } else { purpose = nil }
        if purpose != nil { path.removeLast() }
        pendingCheckout = nil
        loginError = nil
        if purpose == .checkout { returnToCart() }
    }

    func returnToCart() {
        review = nil
        pendingCheckout = nil
        if let index = path.lastIndex(of: .cart) {
            path = Array(path.prefix(index + 1))
        } else {
            path = [.cart]
        }
        cartModel.beginEditing()
    }

    func continueShopping() {
        review = nil
        pendingCheckout = nil
        path = []
    }

    // Called after native back navigation as well as explicit buttons.
    func reconcileNavigation() {
        if !isAuthenticated, let destination = path.last {
            switch destination {
            case .orders, .order:
                path.removeLast()
                path.append(.login(.orders))
            case .review:
                path.removeLast()
                if path.last != .cart { path.append(.cart) }
                review = nil
                pendingCheckout = nil
                beginCheckout()
            default:
                break
            }
        }
        if path.last != .review { review = nil }
        if path.last != .login(.checkout) { pendingCheckout = nil }
        if case .login = path.last {} else { loginError = nil }
    }

    @discardableResult
    func pay() -> Order? {
        guard isAuthenticated, let username else {
            review = nil
            pendingCheckout = nil
            errorMessage = "Inicia sesión para finalizar la compra."
            if !cartModel.cart.lines.isEmpty, path.last != .login(.checkout) {
                pendingCheckout = Review(cart: cartModel.cart, revision: cartModel.revision)
                path.append(.login(.checkout))
            }
            return nil
        }
        guard review != nil else { return nil }
        guard let snapshot = reviewCart else {
            review = nil
            returnToCart()
            errorMessage = "El carrito cambió. Revisa los productos antes de finalizar la compra."
            return nil
        }
        // A synchronous MainActor operation consumes the review exactly once.
        review = nil
        let proposedID = "\(generation)-\(makeID())"
        var id = proposedID
        var suffix = 2
        while usedIDs.contains(id) {
            id = "\(proposedID)-\(suffix)"
            suffix += 1
        }
        usedIDs.insert(id)
        let order = Order(id: id, date: now(), customer: username,
                          items: snapshot.lines.map(OrderItem.init), total: snapshot.total)
        orders.insert(order, at: 0)
        // Newest date first; the insertion order breaks ties deterministically.
        orders = orders.enumerated().sorted {
            $0.element.date == $1.element.date ? $0.offset < $1.offset : $0.element.date > $1.element.date
        }.map(\.element)
        cartModel.clear()
        pendingCheckout = nil
        path = [.success(order.id)]
        return order
    }

    func order(id: String) -> Order? {
        guard let username else { return nil }
        return orders.first { $0.id == id && $0.customer == username }
    }

    var visibleOrders: [Order] {
        guard let username else { return [] }
        return orders.filter { $0.customer == username }
    }

    func showCompletedOrder(_ id: String) {
        guard order(id: id) != nil else { return }
        path = [.orders, .order(id)]
    }

    func signOut() {
        username = nil
        cartModel.clear()
        orders = []
        pendingCheckout = nil
        review = nil
        loginError = nil
        errorMessage = nil
        path = []
        usedIDs.removeAll()
        generation += 1 // Prevent identifier reuse without retaining previous orders or their IDs.
    }
}
