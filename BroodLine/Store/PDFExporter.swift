//
//  PDFExporter.swift
//  BroodLine
//
//  Renders a simple report PDF with UIGraphicsPDFRenderer for share/export.
//

import UIKit

enum PDFExporter {

    static func makeReport(store: DataStore, lineScores: [LineScore]) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter @72dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BroodLine-Report.pdf")

        let margin: CGFloat = 48
        let width = pageRect.width - margin * 2

        do {
            try renderer.writePDF(to: url) { ctx in
                ctx.beginPage()
                var y: CGFloat = margin

                func draw(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 6) {
                    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                    let attr = NSAttributedString(string: text, attributes: attrs)
                    let bounds = attr.boundingRect(
                        with: CGSize(width: width, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                    if y + bounds.height > pageRect.height - margin {
                        ctx.beginPage(); y = margin
                    }
                    attr.draw(in: CGRect(x: margin, y: y, width: width, height: bounds.height))
                    y += bounds.height + spacingAfter
                }

                func rule() {
                    let path = UIBezierPath()
                    path.move(to: CGPoint(x: margin, y: y))
                    path.addLine(to: CGPoint(x: margin + width, y: y))
                    UIColor(hex: "#10B981").setStroke()
                    path.lineWidth = 1.5
                    path.stroke()
                    y += 14
                }

                let df = DateFormatter(); df.dateStyle = .long

                draw("Brood Line — Flock Report", font: .systemFont(ofSize: 26, weight: .heavy),
                     color: UIColor(hex: "#059669"))
                draw("Generated \(df.string(from: Date()))", font: .systemFont(ofSize: 12, weight: .regular),
                     color: .darkGray, spacingAfter: 16)
                rule()

                draw("Summary", font: .systemFont(ofSize: 18, weight: .bold))
                draw("Birds: \(store.birds.count)", font: .systemFont(ofSize: 13))
                draw("Active pairs: \(store.activePairs.count)", font: .systemFont(ofSize: 13))
                draw("Broods registered: \(store.broods.count)", font: .systemFont(ofSize: 13))
                draw("Open broods: \(store.openBroods.count)", font: .systemFont(ofSize: 13))
                draw("Inbreeding warnings: \(store.inbreedingWarnings.count)",
                     font: .systemFont(ofSize: 13), spacingAfter: 16)
                rule()

                draw("Line quality", font: .systemFont(ofSize: 18, weight: .bold))
                if lineScores.isEmpty {
                    draw("No lines recorded yet.", font: .systemFont(ofSize: 13), color: .darkGray)
                } else {
                    for s in lineScores {
                        let color: UIColor
                        switch s.bucket {
                        case .strong: color = UIColor(hex: "#22C55E")
                        case .medium: color = UIColor(hex: "#FBBF24")
                        case .weak: color = UIColor(hex: "#EF4444")
                        }
                        draw("\(s.line) — \(Int(s.score))/100 (\(s.bucket.label)) · \(s.broodCount) broods · \(Int(s.hatchRatio * 100))% hatch · \(s.awards) awards",
                             font: .systemFont(ofSize: 13), color: color)
                    }
                }
                y += 10
                rule()

                draw("Broods by pair", font: .systemFont(ofSize: 18, weight: .bold))
                let counts = store.broodsByPair()
                if counts.isEmpty {
                    draw("No broods registered yet.", font: .systemFont(ofSize: 13), color: .darkGray)
                } else {
                    for item in counts {
                        draw("\(item.label): \(item.count) broods", font: .systemFont(ofSize: 13))
                    }
                }
            }
            return url
        } catch {
            return nil
        }
    }
}
