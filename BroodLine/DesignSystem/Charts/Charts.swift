//
//  Charts.swift
//  BroodLine
//
//  Custom charts drawn with Shape/GeometryReader (no Swift Charts on iOS 14).
//

import SwiftUI

// MARK: - Vertical bar chart

struct BarChartItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let color: Color
}

struct BarChartView: View {
    let data: [BarChartItem]
    var height: CGFloat = 150
    @State private var animate = false

    private func valueText(_ value: Double) -> String {
        value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
    }

    private func barHeight(_ value: Double, max maxValue: Double) -> CGFloat {
        animate ? CGFloat(value / maxValue) * height : 0
    }

    var body: some View {
        let maxValue = max(data.map { $0.value }.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(data) { item in
                VStack(spacing: 6) {
                    Text(valueText(item.value))
                        .font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [item.color, item.color.opacity(0.6)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: barHeight(item.value, max: maxValue))
                    Text(item.label)
                        .font(AppFont.caption(10)).foregroundColor(Palette.textSecondary)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: height + 42)
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { animate = true } }
        .onDisappear { animate = false }
    }
}

// MARK: - Horizontal progress bars

struct HBarItem: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let maxValue: Double
    let color: Color
    let trailing: String
}

struct HorizontalBarChartView: View {
    let data: [HBarItem]
    @State private var animate = false

    var body: some View {
        VStack(spacing: 14) {
            ForEach(data) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(item.label).font(AppFont.caption()).foregroundColor(Palette.textPrimary)
                        Spacer()
                        Text(item.trailing).font(AppFont.caption()).foregroundColor(item.color)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Palette.bgSoft)
                            Capsule().fill(item.color)
                                .frame(width: animate
                                       ? geo.size.width * CGFloat(min(item.value / max(item.maxValue, 0.0001), 1))
                                       : 0)
                        }
                    }
                    .frame(height: 10)
                }
            }
        }
        .onAppear { withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { animate = true } }
        .onDisappear { animate = false }
    }
}

// MARK: - Donut chart

struct DonutSegment: Identifiable {
    let id = UUID()
    let value: Double
    let color: Color
    let label: String
}

struct DonutChartView: View {
    let segments: [DonutSegment]
    var lineWidth: CGFloat = 26
    var centerTitle: String = ""
    var centerSubtitle: String = ""
    @State private var animate = false

    private var total: Double { max(segments.reduce(0) { $0 + $1.value }, 1) }

    private func ranges() -> [(start: CGFloat, end: CGFloat)] {
        var result: [(CGFloat, CGFloat)] = []
        var acc: Double = 0
        for s in segments {
            let start = acc / total
            acc += s.value
            let end = acc / total
            result.append((CGFloat(start), CGFloat(end)))
        }
        return result
    }

    var body: some View {
        ZStack {
            Circle().stroke(Palette.bgSoft, lineWidth: lineWidth)
            ForEach(Array(ranges().enumerated()), id: \.offset) { index, range in
                Circle()
                    .trim(from: range.start, to: animate ? range.end : range.start)
                    .stroke(segments[index].color,
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 2) {
                Text(centerTitle).font(AppFont.title(22)).foregroundColor(Palette.textPrimary)
                Text(centerSubtitle).font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
            }
        }
        .padding(lineWidth / 2)
        .onAppear { withAnimation(.spring(response: 0.7, dampingFraction: 0.85)) { animate = true } }
        .onDisappear { animate = false }
    }
}

// MARK: - Legend

struct ChartLegend: View {
    let items: [(label: String, color: Color)]
    var body: some View {
        HStack(spacing: 16) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(spacing: 6) {
                    Circle().fill(item.color).frame(width: 9, height: 9)
                    Text(item.label).font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
                }
            }
        }
    }
}
