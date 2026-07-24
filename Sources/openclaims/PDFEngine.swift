import Foundation

enum PDFError: Error, CustomStringConvertible {
    case eofNotFound
    case startxrefNotFound
    case offsetNotParsed
    
    var description: String {
        switch self {
        case .eofNotFound: return "Could not find %%EOF marker. Is this a valid PDF?"
        case .startxrefNotFound: return "Could not find startxref keyword."
        case .offsetNotParsed: return "Could not parse previous xref offset integer."
        }
    }
}

struct PDFEngine {
    let inputPath: String
    let outputPath: String
    
    // Accept the generated JSON payload as an argument
    func process(payload: String) throws {
        let expandedPDFPath = NSString(string: inputPath).expandingTildeInPath
        let expandedOutputPath = NSString(string: outputPath).expandingTildeInPath
        
        let fileManager = FileManager.default
        let inputURL = URL(fileURLWithPath: expandedPDFPath)
        let outputURL = URL(fileURLWithPath: expandedOutputPath)
        
        // 1. File Duplication
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
        
        try fileManager.copyItem(at: inputURL, to: outputURL)
        
        // 2. Memory Ingestion
        let pdfData = try Data(contentsOf: outputURL)
        
        // 3. Reverse Scanning for PDF Markers
        let eofMarker = Data("%%EOF".utf8)
        let startxrefMarker = Data("startxref".utf8)
        
        guard let eofRange = pdfData.range(of: eofMarker, options: .backwards) else {
            throw PDFError.eofNotFound
        }
        
        guard let startxrefRange = pdfData.range(of: startxrefMarker, options: .backwards, in: 0..<eofRange.lowerBound) else {
            throw PDFError.startxrefNotFound
        }
        
        let offsetDataRange = startxrefRange.upperBound..<eofRange.lowerBound
        let offsetData = pdfData[offsetDataRange]
        
        guard let offsetString = String(data: offsetData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let previousXrefOffset = Int(offsetString) else {
            throw PDFError.offsetNotParsed
        }
        
        // 4. Payload Injection Setup
        // We use a high object ID (99999) to ensure we don't collide with existing objects in the PDF
        let newObjectId = 99999
        let injectionOffset = pdfData.count
        
        // PDFs require parentheses and backslashes inside literal strings to be escaped
        let escapedPayload = payload
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "(", with: "\\(")
            .replacingOccurrences(of: ")", with: "\\)")
        
        // Format the new PDF Dictionary Object 
        let newObjectString = """
        \n\(newObjectId) 0 obj
        << /Type /Metadata /Subtype /OpenClaims /Payload (\(escapedPayload)) >>
        endobj\n
        """
        
        // Calculate the exact byte offset where our new XREF table will begin
        let newXrefOffset = injectionOffset + newObjectString.utf8.count
        
        // Format the offset to strictly enforce the 10-digit PDF specification
        let formattedInjectionOffset = String(format: "%010d", injectionOffset)
        
        // Construct the new XREF table, Trailer, and final %%EOF marker
        let newXrefAndTrailer = """
        xref
        0 1
        0000000000 65535 f \r
        \(newObjectId) 1
        \(formattedInjectionOffset) 00000 n \r
        trailer
        << /Size \(newObjectId + 1) /Prev \(previousXrefOffset) >>
        startxref
        \(newXrefOffset)
        %%EOF
        """
        
        // 5. Append and Finalize
        var finalData = pdfData
        finalData.append(Data(newObjectString.utf8))
        finalData.append(Data(newXrefAndTrailer.utf8))
        
        // Overwrite the output file with the modified bytes
        try finalData.write(to: outputURL)
        print("✅ Successfully injected Open Claims payload into PDF.")
    }
}
