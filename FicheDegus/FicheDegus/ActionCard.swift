import SwiftUI
import UIKit

struct ActionCard: View {
    let iconName: String
    let title: String
    let subtitle: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: iconName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(iconColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(titleColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(subtitleColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(CardPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double-tapez pour activer")
        .accessibilityAddTraits(.isButton)
    }

    private var cardBackground: AnyShapeStyle {
        if isPrimary {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(.thinMaterial)
    }

    private var iconColor: Color { isPrimary ? .white : .accentColor }
    private var titleColor: Color { isPrimary ? .white : .primary }
    private var subtitleColor: Color { isPrimary ? .white.opacity(0.9) : .secondary }
    private var borderColor: Color { isPrimary ? .white.opacity(0.14) : .white.opacity(0.20) }
}

private struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.white.opacity(configuration.isPressed ? 0.10 : 0.0))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.10 : 0.15), radius: 12, y: 8)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
