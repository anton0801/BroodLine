//
//  ImageStorage.swift
//  BroodLine
//
//  Saves/loads photo files in Documents/Photos and references them by filename.
//

import UIKit

enum ImageStorage {
    static var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Photos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Persists a JPEG and returns the generated filename.
    @discardableResult
    static func save(_ image: UIImage, filename: String = UUID().uuidString + ".jpg") -> String? {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        let url = directory.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    static func load(_ filename: String?) -> UIImage? {
        guard let filename = filename else { return nil }
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ filename: String?) {
        guard let filename = filename else { return }
        let url = directory.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    /// Generates and stores a simple gradient placeholder (used for seed data).
    @discardableResult
    static func makePlaceholder(symbol: String, colors: [UIColor]) -> String? {
        let size = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            let gradientColors = colors.map { $0.cgColor } as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: gradientColors,
                                         locations: [0, 1]) {
                cg.drawLinearGradient(gradient,
                                      start: .zero,
                                      end: CGPoint(x: size.width, y: size.height),
                                      options: [])
            }
            let config = UIImage.SymbolConfiguration(pointSize: 220, weight: .bold)
            if let glyph = UIImage(systemName: symbol, withConfiguration: config)?
                .withTintColor(.white.withAlphaComponent(0.85), renderingMode: .alwaysOriginal) {
                let rect = CGRect(x: (size.width - glyph.size.width) / 2,
                                  y: (size.height - glyph.size.height) / 2,
                                  width: glyph.size.width,
                                  height: glyph.size.height)
                glyph.draw(in: rect)
            }
        }
        return save(image)
    }
}
