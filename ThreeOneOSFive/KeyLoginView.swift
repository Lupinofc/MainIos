import SwiftUI

struct KeyLoginView: View {
    @ObservedObject var auth: KeyAuthService
    @State private var key = ""
    @FocusState private var keyFocused: Bool

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 52)

                    AppLogo(size: 72)
                        .padding(.bottom, 24)

                    Text("URIEL XITER")
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)

                    Text("Digite sua Key para continuar")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 9) {
                        Text("KEY")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .foregroundStyle(AppTheme.accent)

                            TextField("Cole sua Key aqui", text: $key)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .textContentType(.password)
                                .focused($keyFocused)
                                .submitLabel(.go)
                                .onSubmit { submit() }
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 52)
                        .background(Color(uiColor: .secondarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color(uiColor: .separator).opacity(0.35)))
                    }

                    if let error = auth.errorMessage {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.callout)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                    }

                    Button(action: submit) {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Validar Key").fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            auth.isLoading || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? AnyShapeStyle(AppTheme.accent.opacity(0.4))
                                : AnyShapeStyle(AppTheme.accentGradient),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(auth.isLoading || key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.top, 24)

                    Text("A Key será vinculada a este dispositivo.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 18)

                    Spacer(minLength: 42)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            if key.isEmpty { key = auth.savedKey }
            keyFocused = auth.savedKey.isEmpty
        }
    }

    private func submit() {
        keyFocused = false
        Task { await auth.login(key: key) }
    }
}
