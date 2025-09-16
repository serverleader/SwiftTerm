//
//
//
// iOSTextInput.swift: code necessary to support UITextInput, almost everything
// is here, with the exception of `insertText` which is in iOSTerminalView.
//
// The system will invoke either methods in this file, or `insertText` and will
// modify the markedText property during input to reflect the state of the data
// that needs to be removed or wiped.
//
// 1. First, regular typing, that should work.
//
// Input systems:
// 1. With a keyboard input system that supports composed input (like Chinese,
//    Simplified Pinyin), try typing "d", and then it should show a bar of
//    completions, and once selected, it should insert the full result.
// 2. With the above, attempt entering "dddd" and select the first instance,
//    it should insert "点点滴滴"
// 3. Bonus points, try the other Chinese input methods (they differ in the
//    way the data is entered).
//
// Dictation:
// 1. Enable dictation in the app, and then say the word "Hello world", and
//    then tap the microphone again.
// 2. The above should show "Hello world", with no spaces before it (a common
//    bug I fought when inserText was not tracking the markedText region was
//    that it would insert 11 spaces instead - if you get this, this is a
//    sign that the logic for the marking is wrong).
// 3. Dictate "Hello world" once, and then "Hello world" again, it should work,
//    if not, it is possible that the internal state of the selection has gone
//    out of sync again with the dictation system.
//
// Bonus tests, but these should just be straight forward:
// 1. Inserting an emoji from the keyboard emoji should work
// 2. Inserting arabic characters, pick "م" and then "ا" should render "ما"

//
// Ideas:
//   setMarkedText could show an overlay of the text being composed, so that
//   there is a visual cue of what is going on for foreign language input users
//
//  Created by Miguel de Icaza on 1/28/21.
//

#if os(iOS) || os(visionOS)
import Foundation
import UIKit
import CoreText
import CoreGraphics

/// UITextInput Log capability
internal func uitiLog (_ message: String) {
    //print (message)
}

extension TerminalView: UITextInput {
    
    func trace (function: String = #function)  {
        uitiLog ("TRACE: \(function)")
    }

    public func text(in range: UITextRange) -> String? {
        guard let r = range as? TextRange else { 
            uitiLog ("text(in:) range is not TextRange, returning empty")
            return "" 
        }
        
        let startOffset = r.startPosition.offset
        let endOffset = r.endPosition.offset
        
        // Ensure both start and end are within bounds
        let storageCount = textInputStorage.count
        
        // Validate range bounds
        guard startOffset >= 0 && endOffset >= 0 && startOffset <= endOffset else {
            uitiLog ("text(in:) invalid range: start=\(startOffset) end=\(endOffset)")
            return ""
        }
        
        // Check if the range is within the storage bounds
        if startOffset <= storageCount && endOffset <= storageCount {
            // Safe range clamping to prevent out-of-bounds access
            let safeStart = max(0, min(startOffset, storageCount))
            let safeEnd = max(safeStart, min(endOffset, storageCount))
            
            if safeStart < safeEnd && safeEnd <= storageCount {
                let startIdx = textInputStorage.index(textInputStorage.startIndex, offsetBy: safeStart)
                let endIdx = textInputStorage.index(textInputStorage.startIndex, offsetBy: safeEnd)
                let res = String(textInputStorage[startIdx..<endIdx])
                uitiLog ("text(start=\(startOffset) end=\(endOffset)) => \"\(res)\"")
                return res
            } else if safeStart == safeEnd {
                // Empty range
                uitiLog ("text(start=\(startOffset) end=\(endOffset)) => \"\" (empty range)")
                return ""
            }
        }
        
        // Log the error but return empty string instead of crashing
        if #available(iOS 14.0, *) {
            log.critical("Attempt to access [\(startOffset)..<\(endOffset)] on storage with count: \(storageCount)")
        }
        uitiLog ("text(in:) out of bounds: range=[\(startOffset)..<\(endOffset)], count=\(storageCount)")
        return ""
    }
    
    func replace (_ buffer: String, start: Int, end: Int, withText text: String) -> String {
        // Ensure we have valid bounds
        guard !buffer.isEmpty else {
            return text
        }
        
        // Clamp start and end to valid ranges
        let safeStart = max(0, min(start, buffer.count))
        let safeEnd = max(safeStart, min(end, buffer.count))
        
        // Build the result safely
        let startIdx = buffer.index(buffer.startIndex, offsetBy: safeStart)
        let endIdx = buffer.index(buffer.startIndex, offsetBy: safeEnd)
        
        var result = buffer
        result.replaceSubrange(startIdx..<endIdx, with: text)
        return result
    }
    
    public func replace(_ range: UITextRange, withText text: String) {
        guard let r = range as? TextRange else { 
            uitiLog ("replace() range is not TextRange, ignoring")
            return 
        }
        let startOffset = r.startPosition.offset
        let endOffset = r.endPosition.offset
        uitiLog ("replace (\(startOffset)..\(endOffset) with: \"\(text)\") currentSize=\(textInputStorage.count)")
        textInputStorage = replace (textInputStorage, start: startOffset, end: endOffset, withText: text)
        
        // This is necessary, because I am getting an index that was created a long time before, not sure why
        // serial 21 vs 31
        let idx = min (textInputStorage.count, startOffset + text.count)
        _selectedTextRange = TextRange(from: TextPosition(offset: idx), to: TextPosition(offset: idx))
    }

    public var selectedTextRange: UITextRange? {
        get {
            uitiLog ("selectedTextRange -> [\(_selectedTextRange.startPosition.offset)..<\(_selectedTextRange.endPosition.offset)]")
            return _selectedTextRange
        }
        set(newValue) {
            guard let nv = newValue as? TextRange else { 
                uitiLog ("selectedTextRange setter: value is not TextRange, ignoring")
                return 
            }
            _selectedTextRange = nv
        }
    }
    
    public var markedTextRange: UITextRange? {
        get {
            return _markedTextRange
        }
        set {
            _markedTextRange = newValue as? TextRange
        }
    }
    
    public var markedTextStyle: [NSAttributedString.Key : Any]? {
        get {
            return nil
        }
        set(markedTextStyle) {
            //
        }
    }

    public func setMarkedText(_ string: String?, selectedRange: NSRange) {
        
        // setMarkedText operation takes effect on current focus point (marked or selected)
        uitiLog("setMarkedText: \(string as Any), selectedRange: \(selectedRange)")
      
        // after marked text is updated, old selection or markded range is replaced,
        // new marked range is always updated
        // and new selection is always changed to a new range with in
      
        uitiLog ("/ SET MARKED BEGIN ")
        uitiLog ("| _markedTextRange -> \(_markedTextRange?.debugDescription ?? "nil")")
        uitiLog ("| selectedRange -> \(selectedRange)")
        uitiLog ("| _selectedTextRange -> \(_selectedTextRange)")
        uitiLog ("\\-------------")
       
        let rangeToReplace = _markedTextRange ?? _selectedTextRange 
        let rangeStartPosition = rangeToReplace.startPosition.offset
        let rangeEndPosition = rangeToReplace.endPosition.offset
        if let newString = string {
            textInputStorage = replace(textInputStorage, start: rangeStartPosition, end: rangeEndPosition, withText: newString)
            _markedTextRange = TextRange(from: TextPosition(offset: rangeStartPosition), to: TextPosition(offset: rangeStartPosition+newString.count))
            
            let rangeStartIndex = rangeStartPosition
            let selectionStartIndex = rangeStartIndex + selectedRange.lowerBound
            _selectedTextRange = TextRange(from: TextPosition(offset: selectionStartIndex), to: TextPosition(offset: selectionStartIndex + selectedRange.length))
            _markedTextRange = TextRange(from: TextPosition(offset: rangeStartPosition), to: TextPosition(offset: rangeStartPosition + newString.count))
        } else {
            textInputStorage = replace(textInputStorage, start: rangeStartPosition, end: rangeEndPosition, withText: "")
            _markedTextRange = nil
            _selectedTextRange = TextRange(from: TextPosition(offset: rangeStartPosition), to: TextPosition(offset: rangeStartPosition))
        }
    }

    func resetInputBuffer (_ loc: String = #function)
    {
        inputDelegate?.selectionWillChange(self)
        textInputStorage = ""
        _selectedTextRange = TextRange(from: TextPosition(offset: 0), to: TextPosition(offset: 0))
        _markedTextRange = nil
        inputDelegate?.selectionDidChange(self)
    }
    
    public func unmarkText() {
        if let previouslyMarkedRange = _markedTextRange {
            let rangeEndPosition = previouslyMarkedRange.endPosition.offset
            _selectedTextRange = TextRange(from: TextPosition(offset: rangeEndPosition), to: TextPosition(offset: rangeEndPosition))
         
            // Not clear when I can then flush the contents of textInputStorage
            send (txt: textInputStorage)
            resetInputBuffer ()
        }
    }
    
    public var beginningOfDocument: UITextPosition {
        return TextPosition(offset: 0)
    }
    
    public var endOfDocument: UITextPosition {
        return TextPosition(offset: textInputStorage.count)
    }
    
    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let f = fromPosition as? TextPosition,
              let t = toPosition as? TextPosition else {
            uitiLog("[Geometry] textRange: positions are not TextPosition, returning nil")
            return nil
        }
        uitiLog("[Geometry] form range [\(f.offset) ..< \(t.offset)]")
        return TextRange(from: f, to: t)
    }
    
    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let pos = position as? TextPosition else {
            uitiLog("[Geometry] position: not TextPosition, returning nil")
            return nil
        }
        let p = pos.offset
        let newOffset = max(min(p + offset, textInputStorage.count), 0)
        uitiLog("[Geometry] position (from position: \(p), offset: \(offset)) -> \(newOffset)")
        return TextPosition(offset: newOffset)
    }
    
    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        trace()
        return nil
    }
    
    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        if let first = position as? TextPosition,
           let second = other as? TextPosition {
            if first.offset < second.offset {
                return .orderedAscending
            } else if first.offset == second.offset {
                return .orderedSame
            }
        }
        return .orderedDescending
    }
    
    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard let fromPos = from as? TextPosition,
              let toPos = toPosition as? TextPosition else {
            uitiLog("[Geometry] offset: positions are not TextPosition, returning 0")
            return 0
        }
        let f = fromPos.offset
        let t = toPos.offset

        let d = t - f
        uitiLog("[Geometry] form offset to=\(t) - from:\(f) = \(d)")
        return d
    }
    
    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        trace()
        return nil
    }
    
    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        trace()
        return nil
    }
    
    public func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        return .leftToRight
    }
    
    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        // do nothing
    }
    
    public func firstRect(for range: UITextRange) -> CGRect {
        //print ("Text, firstRect (range)")
        return bounds
    }
    
    public func caretRect(for position: UITextPosition) -> CGRect {
        // TODO
        //print ("Text, caretRect (range)")
        return bounds
    }
    
    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        // TODO
        //print ("Text, selectionRect (range)")
        return []
    }
    
    // These can be exercised by the hold-spacebar
    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        return TextPosition(offset: 0)
    }
    
    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        return TextPosition(offset: 0)
    }
    
    public func characterRange(at point: CGPoint) -> UITextRange? {
        return TextRange(from: TextPosition(offset: 0), to: TextPosition(offset: 0))
    }
    
    public func dictationRecordingDidEnd() {
        uitiLog("\(textInputStorage), dictation recording end")
    }
    
    public func dictationRecognitionFailed() {
        uitiLog("\(textInputStorage), dictation failed")
    }
    
    public func insertDictationResult(_ dictationResult: [UIDictationPhrase]) {
        uitiLog("\(textInputStorage), insertDictationResult: \(dictationResult)")
    }
    
    // This method is invoked from `insertText` with the provided text, and
    // it should compute based on that input text and the current marked/selection
    // what should be inserted
    func applyTextToInput (_ text: String) -> String {
        var sendData: String = ""
        
        if let rangeToReplace = _markedTextRange {
            let rangeStartIndex = rangeToReplace.startPosition.offset
            let rangeEndIndex = rangeToReplace.endPosition.offset
            let tmp = "insertText (\"\(text)\" into \"\(textInputStorage)\") rangeToReplace=[\(rangeStartIndex)..<\(rangeEndIndex)]"
            textInputStorage = replace (textInputStorage, start: rangeStartIndex, end: rangeEndIndex, withText: text)
            
            uitiLog ("\(tmp) -> \(textInputStorage)")
            _markedTextRange = nil
            let pos = rangeStartIndex + text.count
            
            _selectedTextRange = TextRange(from: TextPosition(offset: pos), to: TextPosition(offset: pos))
            sendData = ""
        } else if (_selectedTextRange.endPosition.offset - _selectedTextRange.startPosition.offset) > 0 {
            let rangeToReplace = _selectedTextRange
            let rangeStartIndex = rangeToReplace.startPosition.offset
            let rangeEndIndex = rangeToReplace.endPosition.offset
            let tmp = "insertText (\"\(text)\" into \"\(textInputStorage)\") rangeToReplace=[\(rangeStartIndex)..<\(rangeEndIndex)]"
            textInputStorage = replace (textInputStorage, start: rangeStartIndex, end: rangeEndIndex, withText: text)
            
            uitiLog ("\(tmp) -> \(textInputStorage)")
            _markedTextRange = nil
            let pos = rangeStartIndex + text.count
            
            _selectedTextRange = TextRange(from: TextPosition(offset: pos), to: TextPosition(offset: pos))
            sendData = ""
        } else {
            if textInputStorage.count != 0 {
                sendData = textInputStorage
            } else {
                sendData = text
            }
        }
        return sendData
    }
    
    public func beginFloatingCursor(at point: CGPoint)
    {
        lastFloatingCursorLocation = point
    }
    public func updateFloatingCursor(at point: CGPoint)
    {
        guard let lastPosition = lastFloatingCursorLocation else {
            return
        }
        lastFloatingCursorLocation = point
        let deltax = lastPosition.x - point.x
        
        
        if abs (deltax) > 2 {
            var data: [UInt8]
            if deltax > 0 {
                data = terminal.applicationCursor ? EscapeSequences.moveLeftApp : EscapeSequences.moveLeftNormal
            } else {
                data = terminal.applicationCursor ? EscapeSequences.moveRightApp : EscapeSequences.moveRightNormal
            }
            send (data)
        }
        if terminal.buffer.isAlternateBuffer {
            let deltay = lastPosition.y - point.y

            var data: [UInt8]
            if abs (deltay) > 2 {
                if deltay > 0 {
                    data = terminal.applicationCursor ? EscapeSequences.moveUpApp : EscapeSequences.moveUpNormal
                } else {
                    data = terminal.applicationCursor ? EscapeSequences.moveDownApp : EscapeSequences.moveDownNormal
                }
                send (data)
            }
        }
    }
    
    public func endFloatingCursor()
    {
        lastFloatingCursorLocation = nil
    }
}

// Note: xTextRange and xTextPosition classes have been removed
// as we're now using TextRange and TextPosition from iOSTextStorage.swift
#endif
