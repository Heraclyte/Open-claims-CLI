import Foundation

enum PDFError: LocalizedError {
    case eofNotFound
    case startxrefNotFound
    case offsetNotParsed
    case sizeNotParsed
    case rootNotParsed
    case xrefStreamUnsupported
    
    var errorDescription: String? {
        switch self {
        case .eofNotFound: return "Could not find %%EOF marker. Is this a valid PDF?"
        case .startxrefNotFound: return "Could not find startxref keyword."
        case .offsetNotParsed: return "Could not parse previous xref offset integer."
        case .sizeNotParsed: return "Could not parse /Size from trailer."
        case .rootNotParsed: return "Could not parse /Root from trailer."
        case .xrefStreamUnsupported: return "PDF uses a compressed XRef stream (PDF 1.5+). This naive parser currently only supports classic plain-text XRef tables."
        }
    }
}

struct PDFEngine {
    let inputPath: String
    let outputPath: String
    
    func process(payload: String) throws {
        let expandedPDFPath = NSString(string: inputPath).expandingTildeInPath
        let expandedOutputPath = NSString(string: outputPath).expandingTildeInPath
        
        let fileManager = FileManager.default
        let inputURL = URL(fileURLWithPath: expandedPDFPath)
        let outputURL = URL(fileURLWithPath: expandedOutputPath)
        
        // 1. File Duplication & In-Place Support
        if inputURL.standardizedFileURL != outputURL.standardizedFileURL {
            if fileManager.fileExists(atPath: outputURL.path) {
                try fileManager.removeItem(at: outputURL)
            }
            try fileManager.copyItem(at: inputURL, to: outputURL)
            print("✅ Copied original PDF to target destination.")
        } else {
            print("✅ In-place modification detected. Reading directly from target.")
        }
        
        // 2. Memory Ingestion
        let pdfData = try Data(contentsOf: outputURL)
        
        // 3. Reverse Scanning for PDF Markers
        let eofMarker = Data("%%EOF".utf8)
        let startxrefMarker = Data("startxref".utf8)
        let trailerMarker = Data("trailer".utf8)
        
        guard let eofRange = pdfData.range(of: eofMarker, options: .backwards) else {
            throw PDFError.eofNotFound
        }
        
        guard let startxrefRange = pdfData.range(of: startxrefMarker, options: .backwards, in: 0..<eofRange.lowerBound) else {
            throw PDFError.startxrefNotFound
        }
        
        // Parse previous xref offset
        let offsetDataRange = startxrefRange.upperBound..<eofRange.lowerBound
        let offsetData = pdfData[offsetDataRange]
        guard let offsetString = String(data: offsetData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let previousXrefOffset = Int(offsetString) else {
            throw PDFError.offsetNotParsed
        }
        
        // 4. Extract Metadata from the Trailer
        // If "trailer" is missing before "startxref", this is a modern PDF using an XRef Stream
        guard let trailerRange = pdfData.range(of: trailerMarker, options: .backwards, in: 0..<startxrefRange.lowerBound) else {
            throw PDFError.xrefStreamUnsupported
        }
        
        let trailerDataRange = trailerRange.upperBound..<startxrefRange.lowerBound
        let trailerData = pdfData[trailerDataRange]
        guard let trailerString = String(data: trailerData, encoding: .utf8) else {
            throw PDFError.sizeNotParsed
        }
        
        let nsString = trailerString as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)
        
        // Extract /Size
        let sizeRegex = try NSRegularExpression(pattern: "/Size\\s+(\\d+)")
        guard let sizeMatch = sizeRegex.firstMatch(in: trailerString, range: fullRange),
              let sizeRange = Range(sizeMatch.range(at: 1), in: trailerString),
              let extractedSize = Int(trailerString[sizeRange]) else {
            throw PDFError.sizeNotParsed
        }
        
        // Extract /Root (e.g., matching "1 0 R" inside "/Root 1 0 R")
        let rootRegex = try NSRegularExpression(pattern: "/Root\\s+(\\d+\\s+\\d+\\s+R)")
        guard let rootMatch = rootRegex.firstMatch(in: trailerString, range: fullRange),
              let rootRange = Range(rootMatch.range(at: 1), in: trailerString) else {
            throw PDFError.rootNotParsed
        }
        let extractedRoot = String(trailerString[rootRange])
        
        let newObjectId = extractedSize
        print("✅ Dynamically assigned Object ID: \(newObjectId)")
        
        // 5. Payload Injection Setup
        let injectionOffset = pdfData.count
        
        let escapedPayload = payload
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
        
        let newObjectString = """
        \n\(newObjectId) 0 obj
        << /Type /Metadata /Subtype /OpenClaims /Payload (\(escapedPayload)) >>
        endobj\n
        """
        
        let newXrefOffset = injectionOffset + newObjectString.utf8.count
        let formattedInjectionOffset = String(format: "%010d", injectionOffset)
        
        // 6. Assemble Updated Trailer (now including /Root) and Append
        let newXrefAndTrailer = """
        xref
        0 1
        0000000000 65535 f \r
        \(newObjectId) 1
        \(formattedInjectionOffset) 00000 n \r
        trailer
        << /Size \(newObjectId + 1) /Prev \(previousXrefOffset) /Root \(extractedRoot) >>
        startxref
        \(newXrefOffset)
        %%EOF
        """
        
        var finalData = pdfData
        finalData.append(Data(newObjectString.utf8))
        finalData.append(Data(newXrefAndTrailer.utf8))
        
        try finalData.write(to: outputURL)
        print("✅ Successfully injected Open Claims payload into PDF.")
    }
}
