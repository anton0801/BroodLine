//
//  ReportsView.swift
//  BroodLine
//

import SwiftUI

struct ShareURLItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ReportsView: View {
    @EnvironmentObject var store: DataStore
    @State private var share: ShareURLItem?
    @State private var exportError = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    broodsByPairCard
                    lineQualityCard
                    sexRatioCard
                    exportButtons
                    TabBarSpacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
            }
        }
        .navigationBarTitle("Reports", displayMode: .large)
        .sheet(item: $share) { item in ShareSheet(items: [item.url]) }
        .alert(isPresented: $exportError) {
            Alert(title: Text("Export failed"), message: Text("Could not create the file."), dismissButton: .default(Text("OK")))
        }
    }

    private var broodsByPairCard: some View {
        let data = store.broodsByPair().prefix(5).map {
            BarChartItem(label: shortLabel($0.label), value: Double($0.count), color: Palette.primary)
        }
        return AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Broods by pair").font(AppFont.headline(17)).foregroundColor(Palette.textPrimary)
                if data.isEmpty {
                    Text("No broods recorded yet.").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                } else {
                    BarChartView(data: Array(data))
                }
            }
        }
    }

    private var lineQualityCard: some View {
        let scores = store.lineScores().filter { $0.broodCount > 0 || !$0.line.isEmpty }
        let data = scores.map {
            HBarItem(label: $0.line, value: $0.score, maxValue: 100, color: $0.bucket.color, trailing: "\(Int($0.score))/100")
        }
        return AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Line quality").font(AppFont.headline(17)).foregroundColor(Palette.textPrimary)
                if data.isEmpty {
                    Text("No lines recorded yet.").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                } else {
                    HorizontalBarChartView(data: data)
                    ChartLegend(items: [("Strong", Palette.chartStrong), ("Average", Palette.chartMedium), ("Weak", Palette.chartWeak)])
                }
            }
        }
    }

    private var sexRatioCard: some View {
        let ratio = store.sexRatio()
        let total = ratio.males + ratio.females
        let segments = [
            DonutSegment(value: Double(ratio.males), color: Palette.structural, label: "Males"),
            DonutSegment(value: Double(ratio.females), color: Palette.copper, label: "Females")
        ]
        return AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sex ratio by brood").font(AppFont.headline(17)).foregroundColor(Palette.textPrimary)
                if total == 0 {
                    Text("No chicks sexed yet.").font(AppFont.caption()).foregroundColor(Palette.textSecondary)
                } else {
                    HStack(spacing: 20) {
                        DonutChartView(segments: segments,
                                       centerTitle: "\(total)",
                                       centerSubtitle: "chicks")
                            .frame(width: 150, height: 150)
                        VStack(alignment: .leading, spacing: 12) {
                            legendRow("Males ♂", ratio.males, total, Palette.structural)
                            legendRow("Females ♀", ratio.females, total, Palette.copper)
                        }
                    }
                }
            }
        }
    }

    private func legendRow(_ label: String, _ count: Int, _ total: Int, _ color: Color) -> some View {
        let pct = total > 0 ? Int(Double(count) / Double(total) * 100) : 0
        return HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(AppFont.caption()).foregroundColor(Palette.textPrimary)
                Text("\(count) · \(pct)%").font(AppFont.caption(11)).foregroundColor(Palette.textSecondary)
            }
        }
    }

    private var exportButtons: some View {
        VStack(spacing: 10) {
            PrimaryButton(title: "Export PDF", icon: "doc.richtext") {
                if let url = PDFExporter.makeReport(store: store, lineScores: store.lineScores()) {
                    share = ShareURLItem(url: url)
                } else { exportError = true }
            }
            SecondaryButton(title: "Share data (CSV)", icon: "square.and.arrow.up") {
                if let url = store.exportCSVURL() { share = ShareURLItem(url: url) } else { exportError = true }
            }
        }
    }

    private func shortLabel(_ full: String) -> String {
        if let first = full.split(separator: "×").first {
            return String(first).trimmingCharacters(in: .whitespaces)
        }
        return full
    }
}
