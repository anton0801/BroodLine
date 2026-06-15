import SwiftUI
import Foundation

struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 0) {
                // Top bar — Skip always visible
                HStack {
                    Spacer()
                    Button(action: onFinish) {
                        Text("Skip").font(AppFont.medium(15)).foregroundColor(Palette.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: 44)

                TabView(selection: $page) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Dot indicators
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Palette.primary : Palette.border)
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                    }
                }
                .padding(.vertical, 14)

                // Navigation buttons
                HStack(spacing: 12) {
                    if page > 0 {
                        SecondaryButton(title: "Back", fullWidth: false) {
                            withAnimation { page -= 1 }
                        }
                    }
                    PrimaryButton(title: page == 2 ? "Get Started" : "Next",
                                  icon: page == 2 ? "checkmark" : "arrow.right") {
                        if page == 2 {
                            onFinish()
                        } else {
                            withAnimation { page += 1 }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Page 1 — tap to burst

struct OnboardingPage1: View {
    @State private var fireCount = 0

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Palette.copper.opacity(0.25), .clear],
                                         center: .center, startRadius: 5, endRadius: 150))
                    .frame(width: 280, height: 280)

                // Two unknown parents + a question
                HStack(spacing: 70) {
                    unknownParent
                    unknownParent
                }
                .offset(y: -70)

                if fireCount > 0 { TapBurst(fireCount: fireCount) }

                Button { fireCount += 1 } label: {
                    ZStack {
                        Circle().fill(Palette.card)
                            .frame(width: 110, height: 110)
                            .overlay(Circle().stroke(Palette.copper, lineWidth: 2))
                            .shadow(color: Palette.copperGlow, radius: 18)
                        Image(systemName: "questionmark")
                            .font(.system(size: 44, weight: .heavy))
                            .foregroundColor(Palette.copper)
                    }
                }
                .buttonStyle(ScaleButtonStyle(scale: 0.92))
                .offset(y: 40)
            }
            .frame(height: 300)

            VStack(spacing: 10) {
                Text("Understand the problem")
                    .font(AppFont.title(26)).foregroundColor(Palette.textPrimary)
                    .multilineTextAlignment(.center)
                Text("It's unclear which pair a brood came from. Tap the nest to scatter the guesswork.")
                    .font(AppFont.body(15)).foregroundColor(Palette.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
            }
            Spacer()
        }
        .onDisappear { fireCount = 0 }
    }

    private var unknownParent: some View {
        VStack(spacing: 6) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 30)).foregroundColor(Palette.textDisabled)
            Capsule().fill(Palette.border).frame(width: 30, height: 4)
        }
        .opacity(0.7)
    }
}

struct TapBurst: View {
    let fireCount: Int
    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in BurstParticle(index: i) }
        }
        .id(fireCount)
    }
}

struct BurstParticle: View {
    let index: Int
    @State private var out = false

    var body: some View {
        let angle = Double(index) / 12 * 2 * Double.pi
        Image(systemName: index % 2 == 0 ? "questionmark" : "circle.fill")
            .font(.system(size: index % 2 == 0 ? 15 : 7, weight: .bold))
            .foregroundColor(index % 3 == 0 ? Palette.copper : Palette.primary)
            .offset(x: out ? CGFloat(cos(angle)) * 110 : 0,
                    y: out ? CGFloat(sin(angle)) * 110 : 0)
            .opacity(out ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 0.7)) { out = true } }
    }
}

// MARK: - Page 2 — drag the ring onto the leg

struct OnboardingPage2: View {
    @State private var drag: CGSize = .zero
    @State private var placed = false

    private let target = CGSize(width: 80, height: 90)

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Palette.primary.opacity(0.22), .clear],
                                         center: .center, startRadius: 5, endRadius: 160))
                    .frame(width: 300, height: 300)

                // Target slot (bird leg)
                VStack(spacing: 4) {
                    Image(systemName: placed ? "checkmark.circle.fill" : "target")
                        .font(.system(size: 34))
                        .foregroundColor(placed ? Palette.statusReady : Palette.textDisabled)
                    Text(placed ? "Ringed!" : "Drop here")
                        .font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                }
                .offset(target)

                // Draggable ring
                ringChip
                    .offset(placed ? target : drag)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !placed { drag = value.translation }
                            }
                            .onEnded { value in
                                let dx = value.translation.width - target.width
                                let dy = value.translation.height - target.height
                                if (dx * dx + dy * dy) < 60 * 60 {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { placed = true }
                                } else {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { drag = .zero }
                                }
                            }
                    )
            }
            .frame(height: 300)

            VStack(spacing: 10) {
                Text("Track everything")
                    .font(AppFont.title(26)).foregroundColor(Palette.textPrimary)
                Text("Keep lineage and rings in one place. Drag the ring onto the leg to log it.")
                    .font(AppFont.body(15)).foregroundColor(Palette.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
            }
            Spacer()
        }
        .onDisappear { drag = .zero; placed = false }
    }

    private var ringChip: some View {
        HStack(spacing: 6) {
            Circle().stroke(Palette.onPrimary, lineWidth: 3).frame(width: 16, height: 16)
            Text("BR-052").font(AppFont.mono(14)).foregroundColor(Palette.onPrimary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Palette.primaryGradient)
        .clipShape(Capsule())
        .shadow(color: Palette.greenGlow, radius: 12)
    }
}

// MARK: - Page 3 — drag parallax of layered pedigree

struct OnboardingPage3: View {
    @State private var offset: CGSize = .zero

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Palette.structural.opacity(0.2), .clear],
                                         center: .center, startRadius: 5, endRadius: 170))
                    .frame(width: 300, height: 300)

                // Back layer — faint branches
                BranchShape()
                    .stroke(Palette.border, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 220, height: 200)
                    .offset(x: offset.width * 0.05, y: offset.height * 0.05)

                // Mid layer — report bars
                HStack(alignment: .bottom, spacing: 10) {
                    bar(70, Palette.chartStrong)
                    bar(48, Palette.chartMedium)
                    bar(90, Palette.primary)
                    bar(34, Palette.chartWeak)
                }
                .offset(x: offset.width * 0.13, y: offset.height * 0.13 - 20)

                // Front layer — focus card
                VStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill").font(.system(size: 26)).foregroundColor(Palette.primary)
                    Text("Reminder").font(AppFont.caption()).foregroundColor(Palette.textPrimary)
                }
                .padding(16)
                .background(Palette.card)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.border, lineWidth: 1))
                .shadow(color: Palette.shadow, radius: 12)
                .offset(x: offset.width * 0.24 + 70, y: offset.height * 0.24 + 60)
            }
            .frame(height: 300)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { offset = $0.translation }
                    .onEnded { _ in withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { offset = .zero } }
            )

            VStack(spacing: 10) {
                Text("Get better results")
                    .font(AppFont.title(26)).foregroundColor(Palette.textPrimary)
                Text("Use clear records, reports and reminders. Drag the scene to explore the layers.")
                    .font(AppFont.body(15)).foregroundColor(Palette.textSecondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 30)
            }
            Spacer()
        }
        .onDisappear { offset = .zero }
    }

    private func bar(_ height: CGFloat, _ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(color)
            .frame(width: 18, height: height)
    }
}
