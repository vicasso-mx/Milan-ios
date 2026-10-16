import SwiftUI

struct SignInView: View {
    @Bindable var session: SessionViewModel
    let purpose: LoginPurpose
    @State private var username = ""
    @State private var password = ""
    @FocusState private var field: Field?
    private enum Field { case username, password }

    var body: some View {
        Form {
            Section {
                Text("Información sobre Autenticación:")
                    .font(.headline)
                Text("""
                Inicia sesión para finalizar la compra o consultar tus órdenes.

                Puedes usar cualquiera de estas cuentas:
                cliente@doceolab.com
                admin@doceolab.com

                La contraseña es la misma para ambas: Pass@word1
                """)
                .textSelection(.enabled)
            }
            Section {
                TextField("Usuario", text: $username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($field, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { field = .password }
                    .accessibilityIdentifier("login-username")
                SecureField("Contraseña", text: $password)
                    .focused($field, equals: .password)
                    .submitLabel(.go)
                    .onSubmit(signIn)
                    .accessibilityIdentifier("login-password")
            }
            if let error = session.loginError {
                Text(error).foregroundStyle(.red)
                    .accessibilityIdentifier("login-error")
            }
            Section {
                Button("Iniciar sesión", action: signIn)
                    .accessibilityIdentifier("login-submit")
                Button("Cancelar", role: .cancel) { session.cancelLogin() }
                    .accessibilityIdentifier("login-cancel")
            }
        }
        .navigationTitle("Iniciar sesión")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            password = ""
            username = ""
        }
    }

    private func signIn() {
        field = nil
        if session.signIn(username: username, password: password, purpose: purpose) {
            password = ""
        }
    }
}
