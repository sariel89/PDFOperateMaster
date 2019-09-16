//
//  ViewController.swift
//  PDFOperateMaster
//
//  Created by Tony on 2019/9/10.
//  Copyright © 2019 Tony. All rights reserved.
//

import Cocoa
import Quartz
import QuartzCore

class DraggingView: NSView {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        if let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], urls.count == 1 {
            self.operateURL(url: urls[0])
        } else {
            // 请拖入一个PDF文件
        }
    }
    
    func operateURL(url: URL) {
        if url.absoluteString.hasSuffix(".txt") {
            do {
                if let file = try? String(contentsOfFile: url.path), file.contains("※※※※※※※※※※") {
                    let array = file.components(separatedBy: "※※※※※※※※※※")
                    var count = 0
                    for value in array {
                        count += 1
                        if value.count < 100 {
                            continue
                        } else {
                            // 获取名称
                            if let begin = value.firstIndex(of: "["), let end = value.firstIndex(of: "/") {
                                let name = value[value.index(after: begin) ..< end].trimmingCharacters(in: CharacterSet.whitespaces)
                                let path = url.deletingLastPathComponent()
                                try value.write(to: path.appendingPathComponent(name + ".md"), atomically: true, encoding: .utf8)
                            }
                        }
                    }
                    print("一共 \(array.count), 执行了 \(count)")
                }
            } catch {
                
            }
        } else if url.absoluteString.hasSuffix(".pdf") {
            if let pdf = pdfDocument(url: url) {
                var pdfArray: [PDFPage] = []
                for i in stride(from: 0, to: pdf.count, by: 4) {
                    pdfArray.append(contentsOf: self.pdfPageOperate(pages: Array(pdf[i..<(i + 4 < pdf.count ? i + 4 : pdf.count)])))
                }
                
                // 组装一个新的PDF文件
                let pdfDocument = PDFDocument()
                for i in 0 ..< pdfArray.count {
                    pdfDocument.insert(pdfArray[i], at: i)
                }
                
                // 调用系统打印
                let printOperation = pdfDocument.printOperation(for: self.thePrintInfo(), scalingMode: .pageScaleNone, autoRotate: true)
                let printPanel = NSPrintPanel()
                printPanel.options = [
                    NSPrintPanel.Options.showsCopies,
                    NSPrintPanel.Options.showsPrintSelection,
                    NSPrintPanel.Options.showsPageSetupAccessory,
                    NSPrintPanel.Options.showsPreview,
                ]
                printOperation?.printPanel = printPanel
                printOperation?.run()
            }
        }
    }
    
    
    
    // Operate PDF
    //
    func pdfDocument(url:URL) -> [PDFPage]? {
        do {
            if let pdf = PDFDocument(data: try Data(contentsOf: url)) {
                var pages:[PDFPage] = []
                for i in 0 ..< pdf.pageCount {
                    pages.append(pdf.page(at: i) ?? PDFPage())
                }
                return pages
            } else {
                return nil
            }
        } catch {
            
        }
        return nil
    }
    
    func pdfPageOperate(pages:[PDFPage]) -> [PDFPage] {
        var result: [PDFPage] = [PDFPage(),PDFPage(),PDFPage(),PDFPage()]
        for i in 0 ..< pages.count {
            let page = pages[i]
            if i == 0 {
                result[0] = page
            } else if i == 1 {
                page.rotation = 180
                result[2] = page
            } else if i == 2 {
                result[1] = page
            } else if i == 3 {
                page.rotation = 180
                result[3] = page
            }
        }
        return result
    }
    
    func thePrintInfo() -> NSPrintInfo {
        let thePrintInfo = NSPrintInfo()
        thePrintInfo.horizontalPagination = .automatic // Tried fit
        thePrintInfo.verticalPagination = .automatic // Tried fit
        thePrintInfo.isHorizontallyCentered = true // Tried false
        thePrintInfo.isVerticallyCentered = true // Tried false
        thePrintInfo.leftMargin = 0.0
        thePrintInfo.rightMargin = 0.0
        thePrintInfo.topMargin = 0.0
        thePrintInfo.bottomMargin = 0.0
        thePrintInfo.jobDisposition = .spool
        return thePrintInfo
    }
}

class ViewController: NSViewController, NSDraggingDestination {
    
    @IBOutlet weak var draggingView: NSView!
    @IBOutlet weak var backgroundView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layer = CALayer()
        layer.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        self.backgroundView.layer?.addSublayer(layer)
        self.draggingView.alphaValue = 0.8
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

