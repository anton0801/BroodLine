//
//  Components.swift
//  BroodLine
//
//  Reusable, themed building blocks used across every screen.
//

import SwiftUI

// MARK: - Button press animation

struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).font(AppFont.headline(16))
            }
            .foregroundColor(Palette.onPrimary)
            .padding(.vertical, 15)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 22)
            .background(Palette.primaryGradient)
            .cornerRadius(16)
            .shadow(color: Palette.greenGlow, radius: 14, x: 0, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).font(AppFont.headline(16))
            }
            .foregroundColor(Palette.secondaryText)
            .padding(.vertical, 15)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 22)
            .background(Palette.card)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct DangerButton: View {
    let title: String
    var icon: String? = nil
    var fullWidth: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).font(AppFont.headline(16))
            }
            .foregroundColor(Palette.onDanger)
            .padding(.vertical, 15)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 22)
            .background(Palette.statusRisk)
            .cornerRadius(16)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Card container

struct AppCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Palette.border, lineWidth: 1))
            .shadow(color: Palette.shadow.opacity(0.25), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Text field

struct AppTextField: View {
    let title: String
    var placeholder: String = ""
    @Binding var text: String
    var icon: String? = nil
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !title.isEmpty {
                Text(title).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
            }
            HStack(spacing: 10) {
                if let icon = icon { Image(systemName: icon).foregroundColor(Palette.textSecondary) }
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .foregroundColor(Palette.textPrimary)
            }
            .padding(14)
            .background(Palette.bgSoft)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.border, lineWidth: 1))
        }
    }
}

struct AppTextEditor: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(AppFont.caption()).foregroundColor(Palette.textSecondary)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Add notes…").foregroundColor(Palette.textDisabled)
                        .padding(.top, 8).padding(.leading, 5)
                }
                TextEditor(text: $text)
                    .frame(minHeight: 90)
                    .foregroundColor(Palette.textPrimary)
                    .opacity(text.isEmpty ? 0.95 : 1)
            }
            .padding(8)
            .background(Palette.bgSoft)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.border, lineWidth: 1))
        }
    }
}

// MARK: - Badges & chips

struct StatusBadge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(AppFont.caption(12))
            .foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(color.opacity(0.16))
            .clipShape(Capsule())
    }
}

struct ChipPicker<T: Hashable>: View {
    let items: [T]
    let label: (T) -> String
    @Binding var selection: T

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    let selected = item == selection
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = item }
                    } label: {
                        Text(label(item))
                            .font(AppFont.caption())
                            .foregroundColor(selected ? Palette.onPrimary : Palette.textSecondary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(selected ? Palette.primary : Palette.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Palette.border, lineWidth: selected ? 0 : 1))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

// MARK: - Search

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(Palette.textSecondary)
            TextField(placeholder, text: $text)
                .foregroundColor(Palette.textPrimary)
                .disableAutocorrection(true)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(Palette.textSecondary)
                }
            }
        }
        .padding(12)
        .background(Palette.card)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.border, lineWidth: 1))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title).font(AppFont.headline(17)).foregroundColor(Palette.textPrimary)
            Spacer()
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle).font(AppFont.caption()).foregroundColor(Palette.primary)
                }
            }
        }
    }
}

// MARK: - Stat tile

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle().fill(color.opacity(0.18)).frame(width: 38, height: 38)
                    Image(systemName: icon).foregroundColor(color)
                }
                Text(value).font(AppFont.title(24)).foregroundColor(Palette.textPrimary)
                Text(title).font(AppFont.caption()).foregroundColor(Palette.textSecondary).lineLimit(1)
            }
        }
    }
}

// MARK: - Icon badge

struct IconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3).fill(color.opacity(0.18))
            Image(systemName: icon).foregroundColor(color).font(.system(size: size * 0.42, weight: .semibold))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Palette.primary.opacity(0.12)).frame(width: 80, height: 80)
                Image(systemName: icon).font(.system(size: 32, weight: .semibold)).foregroundColor(Palette.primary)
            }
            Text(title).font(AppFont.headline(18)).foregroundColor(Palette.textPrimary)
            Text(message).font(AppFont.body(14)).foregroundColor(Palette.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 24)
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, icon: "plus", fullWidth: false, action: action)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Screen background

struct ScreenBackground: View {
    var body: some View {
        Palette.backgroundGradient.ignoresSafeArea()
    }
}

// MARK: - Glow modifier

extension View {
    func glow(_ color: Color, radius: CGFloat = 16) -> some View {
        self.shadow(color: color, radius: radius)
    }

    /// Slides + fades a view in on first appearance.
    func appearTransition(delay: Double = 0) -> some View {
        modifier(AppearTransition(delay: delay))
    }
}

struct AppearTransition: ViewModifier {
    let delay: Double
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                    shown = true
                }
            }
    }
}

// MARK: - Photo thumbnail (loads from ImageStorage)

struct PhotoThumb: View {
    let filename: String?
    var size: CGFloat = 56
    var corner: CGFloat = 12
    var fallbackIcon: String = "photo"

    var body: some View {
        Group {
            if let image = ImageStorage.load(filename) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    Palette.bgSoft
                    Image(systemName: fallbackIcon).foregroundColor(Palette.textDisabled)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: corner))
        .overlay(RoundedRectangle(cornerRadius: corner).stroke(Palette.border, lineWidth: 1))
    }
}
