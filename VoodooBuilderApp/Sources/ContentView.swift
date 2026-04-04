import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: BuildViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.ultraThinMaterial)

                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.28), lineWidth: 1)

                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .padding(12)
                    }
                    .frame(width: 76, height: 76)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.18 : 0.08), radius: 18, y: 10)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("VoodooHDA Builder")
                            .font(.system(size: 26, weight: .bold, design: .rounded))

                        Text("Compila kext, pref pane e gera o instalador sem alterar o fluxo original.")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Status")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)

                            Text(model.progressLine)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        Text(model.isRunning ? "EM EXECUCAO" : "PRONTO")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(statusBadgeForeground)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(statusBadgeBackground, in: Capsule())
                    }

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08))
                                .frame(height: 12)

                            Capsule()
                                .fill(progressGradient)
                                .frame(width: max(14, proxy.size.width * model.progressValue), height: 12)
                        }
                    }
                    .frame(height: 12)
                }
                .padding(18)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.22), lineWidth: 1)
                )

                Button(model.isRunning ? "Processando..." : "Criar VoodooHDA.pkg") {
                    model.runAll()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(nsColor: .controlAccentColor))
                .disabled(model.isRunning)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Text("O instalador abre automaticamente quando o pacote terminar de ser gerado.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(26)
        }
        .frame(width: 420, height: 320)
    }

    private var backgroundGradient: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.10, green: 0.12, blue: 0.16),
                Color(red: 0.14, green: 0.18, blue: 0.22),
                Color(red: 0.08, green: 0.10, blue: 0.13)
            ]
        }

        return [
            Color(red: 0.95, green: 0.97, blue: 0.99),
            Color(red: 0.90, green: 0.94, blue: 0.98),
            Color(red: 0.98, green: 0.96, blue: 0.92)
        ]
    }

    private var progressGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.55, blue: 0.95),
                Color(red: 0.09, green: 0.77, blue: 0.69)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var statusBadgeBackground: Color {
        model.isRunning
            ? Color(red: 0.98, green: 0.73, blue: 0.24)
            : Color(red: 0.19, green: 0.72, blue: 0.48)
    }

    private var statusBadgeForeground: Color {
        model.isRunning ? .black : .white
    }
}
