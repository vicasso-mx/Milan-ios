import SwiftUI

@main
struct MilanApp: App {
    private let catalog: Catalog?

    init() {
        catalog = try? Catalog.load()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let catalog {
                    StoreView(catalog: catalog)
                } else {
                    ContentUnavailableView("No se pudo cargar el catálogo local.", systemImage: "exclamationmark.triangle")
                }
            }
            .environment(\.locale, Locale(identifier: "es_MX"))
            .tint(Brand.primary)
        }
    }
}
