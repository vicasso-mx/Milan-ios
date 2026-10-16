import SwiftUI

struct CatalogView: View {
    @Bindable var model: CatalogViewModel
    let add: (Product) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    BrandHeader().id("catalog-top")
                    filters
                    if model.filteredProducts.isEmpty {
                        ContentUnavailableView {
                            Label("No hay resultados que coincidan con tu búsqueda", systemImage: "line.3.horizontal.decrease.circle")
                        }
                        .accessibilityIdentifier("empty-catalog")
                    } else {
                        pagination(proxy: proxy)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 20)], spacing: 24) {
                            ForEach(model.productsOnPage) { product in
                                ProductCard(product: product) { add(product) }
                            }
                        }
                        .padding(.horizontal)
                        pagination(proxy: proxy, suffix: "bottom")
                    }
                    Text("Doceolab. Todos los derechos reservados")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var filters: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Marca").font(.subheadline.weight(.semibold))
                Picker("Marca", selection: $model.selectedBrandID) {
                    Text("Todas").tag(0)
                    ForEach(Catalog.brands) { Text($0.name).tag($0.id) }
                }
                .labelsHidden()
                .accessibilityIdentifier("brand-filter")
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tipo").font(.subheadline.weight(.semibold))
                Picker("Tipo", selection: $model.selectedTypeID) {
                    Text("Todos").tag(0)
                    ForEach(Catalog.types) { Text($0.name).tag($0.id) }
                }
                .labelsHidden()
                .accessibilityIdentifier("type-filter")
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button("Filtrar") {
                model.applyFilters()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityIdentifier("apply-filters")
        }
        .pickerStyle(.menu)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    private func pagination(proxy: ScrollViewProxy, suffix: String = "top") -> some View {
        VStack(spacing: 8) {
            Text(model.pageSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("page-summary-\(suffix)")
            HStack {
                Button("Anterior") {
                    model.previousPage()
                    proxy.scrollTo("catalog-top", anchor: .top)
                }
                .disabled(!model.canGoBack)
                .accessibilityIdentifier("previous-page-\(suffix)")
                Spacer()
                Button("Siguiente") {
                    model.nextPage()
                    proxy.scrollTo("catalog-top", anchor: .top)
                }
                .disabled(!model.canGoForward)
                .accessibilityIdentifier("next-page-\(suffix)")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal)
    }
}

private struct ProductCard: View {
    let product: Product
    let add: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(product.imageName)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibilityLabel(product.name)
            Text(product.name)
                .font(.headline)
            Text(Money.formatted(product.price))
                .font(.title2.bold())
                .foregroundStyle(Brand.primary)
            Button("Agregar al carrito", systemImage: "cart.badge.plus", action: add)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("add-\(product.id)")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("product-\(product.id)")
    }
}
