import Foundation

struct Product: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
    let description: String
    let price: Decimal
    let brandID: Int
    let typeID: Int
    let imageName: String
}

struct CatalogOption: Identifiable, Equatable, Sendable {
    let id: Int
    let name: String
}

struct Catalog: Sendable {
    let products: [Product]
    static let brands = sorted([
        CatalogOption(id: 1, name: "VistaAérea"),
        CatalogOption(id: 2, name: "AeroMILA"),
        CatalogOption(id: 3, name: "TecnoVuelo"),
        CatalogOption(id: 4, name: "Centinela"),
        CatalogOption(id: 5, name: "AgroVuelo")
    ])
    static let types = sorted([
        CatalogOption(id: 1, name: "Recreativo"),
        CatalogOption(id: 2, name: "Profesional"),
        CatalogOption(id: 3, name: "Fotografía"),
        CatalogOption(id: 4, name: "Industrial")
    ])

    private static func sorted(_ options: [CatalogOption]) -> [CatalogOption] {
        options.sorted {
            $0.name.compare($1.name, locale: Locale(identifier: "es_MX")) == .orderedAscending
        }
    }

    enum LoadingError: Error, LocalizedError {
        case invalidCatalog
        var errorDescription: String? { "No se pudo cargar el catálogo local." }
    }

    static func load(bundle: Bundle = .main) throws -> Catalog {
        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw LoadingError.invalidCatalog
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> Catalog {
        // Prices are strings in the bundled data to avoid binary floating-point intermediates.
        struct Record: Decodable {
            let id: Int
            let name: String
            let description: String
            let price: String
            let brandID: Int
            let typeID: Int
            let imageName: String
        }
        let records = try JSONDecoder().decode([Record].self, from: data)
        let products = try records.map { record in
            guard let price = Decimal(string: record.price, locale: Locale(identifier: "en_US_POSIX")),
                  price > 0,
                  !record.name.isEmpty, !record.description.isEmpty,
                  brands.contains(where: { $0.id == record.brandID }),
                  types.contains(where: { $0.id == record.typeID }),
                  record.imageName == "product-\(record.id)" else {
                throw LoadingError.invalidCatalog
            }
            return Product(id: record.id, name: record.name, description: record.description,
                           price: price, brandID: record.brandID, typeID: record.typeID,
                           imageName: record.imageName)
        }
        guard products.count == 12, Set(products.map(\.id)) == Set(1...12) else {
            throw LoadingError.invalidCatalog
        }
        return Catalog(products: products.sorted { $0.id < $1.id })
    }
}
