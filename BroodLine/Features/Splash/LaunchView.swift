//
//  LaunchView.swift
//  BroodLine
//
//  Thematic splash: a growing pedigree "branch" motif with drifting feather
//  particles. Three simultaneously animated layers (background glow, midground
//  branches + particles, foreground logo) sequenced by a single coordinator
//  timer. All loops are reset on disappear so nothing leaks into the app.
//

import SwiftUI

struct LaunchView: View {
    var onFinish: () -> Void

    // Animation state (reset on disappear)
    @State private var isVisible = true
    @State private var glowPulse = false     // layer 1
    @State private var branchGrow = false    // layer 2
    @State private var particlesGo = false    // layer 2b
    @State private var logoIn = false         // layer 3
    @State private var exiting = false        // layer 4

    @State private var elapsed: Double = 0
    @State private var timer: Timer?

    private let particles: [Particle] = Particle.makeField(count: 14)

    var body: some View {
        ZStack {
            // ── Layer 1: shifting background glow ───────────────────────────
            Color(hex: "#0A0F0C").ignoresSafeArea()
            RadialGradient(colors: [Palette.primary.opacity(glowPulse ? 0.45 : 0.18),
                                    Color(hex: "#0A0F0C").opacity(0)],
                           center: .center,
                           startRadius: 10,
                           endRadius: glowPulse ? 420 : 280)
                .ignoresSafeArea()
                .scaleEffect(glowPulse ? 1.15 : 0.85)

            // ── Layer 2b: drifting feather particles ────────────────────────
            ForEach(particles) { p in
                Image(systemName: "leaf.fill")
                    .font(.system(size: p.size))
                    .foregroundColor(Palette.primaryGlowC.opacity(0.35))
                    .rotationEffect(.degrees(p.rotation))
                    .position(x: p.x, y: particlesGo ? p.yEnd : p.yStart)
                    .opacity(particlesGo ? p.opacity : 0)
            }

            // ── Layer 2: growing pedigree branches ──────────────────────────
            BranchShape()
                .trim(from: 0, to: branchGrow ? 1 : 0)
                .stroke(Palette.primaryGradient,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .frame(width: 230, height: 210)
                .opacity(0.9)
                .offset(y: -34)

            // ── Layer 3: foreground logo + wordmark ─────────────────────────
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Palette.card)
                        .frame(width: 96, height: 96)
                        .overlay(Circle().stroke(Palette.primary.opacity(0.5), lineWidth: 1.5))
                        .shadow(color: Palette.greenGlow, radius: 24)
                    BranchShape()
                        .stroke(Palette.primary,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .frame(width: 46, height: 44)
                }
                Text("Brood Line")
                    .font(AppFont.display(34))
                    .foregroundColor(Palette.textPrimary)
                Text("Smart poultry assistant")
                    .font(AppFont.medium(15))
                    .foregroundColor(Palette.textSecondary)
            }
            .scaleEffect(exiting ? 1.25 : (logoIn ? 1 : 0.6))
            .opacity(exiting ? 0 : (logoIn ? 1 : 0))
            .offset(y: 70)
        }
        .onAppear(perform: start)
        .onDisappear(perform: stop)
    }

    private func start() {
        isVisible = true
        // Layer 1 loop — background glow pulse (continuous)
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            glowPulse = true
        }

        // Single coordinator timer sequences the staged phases.
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { t in
            guard isVisible else { t.invalidate(); return }
            elapsed += 0.05

            // Phase 2 (0.6s): branches grow + particles drift
            if elapsed >= 0.6 && !branchGrow {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    branchGrow = true
                }
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: false)) {
                    particlesGo = true
                }
            }
            // Phase 3 (1.4s): logo spring entrance
            if elapsed >= 1.4 && !logoIn {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { logoIn = true }
            }
            // Phase 4 (2.3s): designed exit
            if elapsed >= 2.3 && !exiting {
                withAnimation(.easeIn(duration: 0.45)) { exiting = true }
            }
            // Finish (2.75s)
            if elapsed >= 2.75 {
                t.invalidate()
                onFinish()
            }
        }
    }

    private func stop() {
        isVisible = false
        timer?.invalidate()
        timer = nil
        // Reset all loop state so nothing animates in the background.
        glowPulse = false
        branchGrow = false
        particlesGo = false
        logoIn = false
        exiting = false
        elapsed = 0
    }
}

// MARK: - Branch (pedigree fork) shape

struct BranchShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let midX = rect.midX
        let bottom = rect.maxY
        let topY = rect.minY
        let trunkTop = rect.midY + rect.height * 0.12

        // Trunk
        p.move(to: CGPoint(x: midX, y: bottom))
        p.addLine(to: CGPoint(x: midX, y: trunkTop))

        // First fork
        let span1 = rect.width * 0.30
        let y1 = rect.midY - rect.height * 0.04
        p.move(to: CGPoint(x: midX, y: trunkTop))
        p.addLine(to: CGPoint(x: midX - span1, y: y1))
        p.move(to: CGPoint(x: midX, y: trunkTop))
        p.addLine(to: CGPoint(x: midX + span1, y: y1))

        // Second forks
        let span2 = rect.width * 0.17
        for sign in [-CGFloat(1), CGFloat(1)] {
            let bx = midX + sign * span1
            p.move(to: CGPoint(x: bx, y: y1))
            p.addLine(to: CGPoint(x: bx - span2, y: topY))
            p.move(to: CGPoint(x: bx, y: y1))
            p.addLine(to: CGPoint(x: bx + span2, y: topY))
        }
        return p
    }
}

// MARK: - Particle field

struct Particle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let yStart: CGFloat
    let yEnd: CGFloat
    let size: CGFloat
    let rotation: Double
    let opacity: Double

    static func makeField(count: Int) -> [Particle] {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        return (0..<count).map { i in
            let fx = CGFloat((i * 53) % 100) / 100
            let drift = CGFloat((i * 37) % 100) / 100
            return Particle(
                x: 20 + fx * (width - 40),
                yStart: height * 0.55 + drift * 120,
                yEnd: height * 0.15 - drift * 80,
                size: 10 + CGFloat(i % 4) * 4,
                rotation: Double((i * 47) % 360),
                opacity: 0.25 + Double(i % 5) * 0.1
            )
        }
    }
}
