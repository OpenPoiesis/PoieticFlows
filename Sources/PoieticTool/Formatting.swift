//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2023.
//


extension String {
    /// Returns a right-aligned string padded with `padding` to the desired
    /// width `width`.
    ///
    public func alignRight(_ width: Int, padding: String = " ") -> String {
        // TODO: Allow lenght of padding to be more than one character
        let repeats = width - self.count
        return String(repeating: padding, count: repeats) + self
    }
}

func formatLabelledList(_ items: [(String?, String?)],
                        separator: String = ": ",
                        labelWidth: Int? = nil) -> [String] {
    let actualWidth = labelWidth
                        ?? items.map { $0.0?.count ?? 0 }.max() ?? 0
    
    var result: [String] = []
    
    for (label, value) in items {
        let item: String

        if let label {
            let alignedLabel = label.alignRight(actualWidth)
            if let value {
                item = "\(alignedLabel)\(separator)\(value)"
            }
            else {
                item = "\(alignedLabel)"
            }
        }
        else {
            if let value {
                let padding = "".alignRight(actualWidth + separator.count)
                item = "\(padding)\(value)"
            }
            else {
                item = ""
            }
        }
        
        result.append(item)
    }
    
    return result
}

