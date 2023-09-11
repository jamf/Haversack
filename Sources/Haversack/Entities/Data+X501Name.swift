// SPDX-License-Identifier: MIT
// Copyright 2023, Jamf

import Foundation
import OrderedCollections

private indirect enum ASN1Element {
    case seq(elements: [ASN1Element])
    case set(elements: [ASN1Element])
    case integer(int: Int)
    case bytes(data: Data)
    case string(string: String)
    case objectIdentifier(oid: [UInt64])
    case constructed(tag: Int, elem: ASN1Element)
    case unknown
}

extension Data {
    /// Create a `Data` object by ASN.1 encoding the given dictionary as a Name structure
    ///
    /// See RFC 5280 for the Name structure definition.
    /// - Parameter oidToString: Dictionary of OID strings to simple string values
    /// - Returns: A `Data` object
    static func makeASN1EncodedName(from oidToString: OrderedDictionary<String, String>) -> Data {
        var namePairSets = [Data]()

        oidToString.forEach { (oidString: String, nameString: String) in
            // The OID and String are individually encoded, then wrapped in a sequence, then wrapped in a set.
            let oid = wrap(objectIdentifier: oidString)
            let name = wrap(printableString: nameString)
            let oidNamePair = wrap(sequence: oid, name)
            namePairSets.append(wrap(set: oidNamePair))
        }

        // The final result is a sequence of all of the wrapped oid/name sets.
        return wrap(sequence: namePairSets)
    }

    private static func wrap(objectIdentifier: String) -> Data {
        let parts = objectIdentifier.split(separator: ".").map {
            UInt64($0) ?? 0
        }

        func field(val: UInt64) -> Data {
            var val = val
            var result = Data(count: 9)
            var pos = 8
            result[pos] = UInt8(val & 0x7F)
            while val >= (UInt64(1) << 7) {
                val >>= 7
                pos -= 1
                result[pos] = UInt8((val & 0x7F) | 0x80)
            }
            return Data(result.dropFirst(pos))
        }

        var iter = parts.makeIterator()

        let first = iter.next()!
        let second = iter.next()!

        var bytes = field(val: first * 40 + second)

        while let val = iter.next() {
          bytes.append(field(val: val))
        }

        var result = Data()
        result.append(6) // OID identifier in ASN.1 language
        result.append(length: bytes.count)

        result.append(bytes)

        return result
    }

    private mutating func append(length value: Int) {

      switch value {
      case 0x0000 ..< 0x0080:
        self.append(UInt8(value & 0x007F))

      case 0x0080 ..< 0x0100:
        self.append(0x81)
        self.append(UInt8(value & 0x00FF))

      case 0x0100 ..< 0x8000:
        self.append(0x82)
        self.append(UInt8((value & 0xFF00) >> 8))
        self.append(UInt8(value & 0xFF))

      default:
        // We have too much data!
        fatalError("Unimplemented")
      }
    }

    private static func wrap(printableString: String) -> Data {
        var result = Data()

        if let stringData = printableString.data(using: .utf8) {
            result.append(19) // PrintableString identifier in ASN.1 language
            result.append(length: stringData.count)
            result.append(stringData)
        }

        return result
    }

    /// Convenience for wrapping a sequence with a given set of discrete data objects.
    /// - Parameter sequence: Should be one or more `Data` objects
    /// - Returns: The ASN.1 sequence data
    private static func wrap(sequence: Data...) -> Data {
        // Use the "constructed Sequence" tag in ASN.1 language
        return wrapSequenceOrSet(tag: 0x30, array: sequence)
    }

    private static func wrap(sequence: [Data]) -> Data {
        // Use the "constructed Sequence" tag in ASN.1 language
        return wrapSequenceOrSet(tag: 0x30, array: sequence)
    }

    private static func wrap(set: Data...) -> Data {
        // Use the "constructed Set" tag in ASN.1 language
        return wrapSequenceOrSet(tag: 0x31, array: set)
    }

    private static func wrapSequenceOrSet(tag: UInt8, array: [Data]) -> Data {
        let totalLength = array.reduce(0) { (lengthSoFar, item) in
            lengthSoFar + item.count
        }
        var result = Data()
        result.append(tag)
        result.append(length: totalLength)
        array.forEach { (item) in
            result.append(item)
        }
        return result
    }

    /// Attempts to parse the data as a ASN.1 Name structure from an X509 certificate
    /// - Returns: A dictionary of OID string keys to string values
    func decodeASN1Names() -> OrderedDictionary<String, String> {
        var result = OrderedDictionary<String, String>()
        let decodedASN1 = self.toASN1Element().0

        if case .seq(let elements) = decodedASN1 {
            // Outermost element is a Sequence....dig in and find the OIDs and text.
            elements.forEach { (element) in
                if case .set(let setElements) = element,
                   case .seq(let namePair) = setElements[0] {
                    // We have the array of OID + Name
                    var theOid: String?
                    var theString: String?
                    namePair.forEach { (piece) in
                        switch piece {
                        case .objectIdentifier(let myOid):
                            // We have the OID; convert it to a String
                            theOid = myOid.map { (oidPart) in
                                "\(oidPart)"
                            }.joined(separator: ".")
                        case .string(let myString):
                            theString = myString
                        default: break
                        }
                    }
                    // If we found the OID and the string, put it into the result dictionary
                    if let actualOid = theOid,
                       let actualString = theString {
                        result[actualOid] = actualString
                    }
                }
            }
        }
        return result
    }

    private func readLength() -> (result: Int, bytesUsed: Int) {
        if self[0] & 0x80 == 0x00 { // short form; 1 byte
            return (Int(self[0]), 1)
        } else {
            let lengthOfLength = Int(self[0] & 0x7F)
            var result: Int = 0
            for index in 1..<(1 + lengthOfLength) {
                result = 256 * result + Int(self[index])
            }
            return (result, 1 + lengthOfLength)
        }
    }

    private func toASN1Element() -> (ASN1Element, Int) {
        guard self.count >= 2 else {
            // format error
            return (.unknown, self.count)
        }

        switch self[0] {
        case 0x30, 0x31: // sequence and set are decoded pretty much the same way.
            let (length, lengthOfLength) = self.advanced(by: 1).readLength()
            var result: [ASN1Element] = []
            var subdata = self.advanced(by: 1 + lengthOfLength)
            var alreadyRead = 0

            while alreadyRead < length {
                let (element, elementLength) = subdata.toASN1Element()
                result.append(element)
                subdata = subdata.count > elementLength ? subdata.advanced(by: elementLength) : Data()
                alreadyRead += elementLength
            }
            if self[0] == 0x30 {
                return (.seq(elements: result), 1 + lengthOfLength + length)
            } else {
                return (.set(elements: result), 1 + lengthOfLength + length)
            }

        case 6: // OID
            let (length, lengthOfLength) = self.advanced(by: 1).readLength()
            let subData = self.subdata(in: (1 + lengthOfLength) ..< (1 + lengthOfLength + length))
            return (.objectIdentifier(oid: subData.parseOID()), 1 + lengthOfLength + length)

        case 12, 19, 20, 21, 22, 26, 27, 28, 29: // utf8String, printableString..
            let (length, lengthOfLength) = self.advanced(by: 1).readLength()
            let subData = self.subdata(in: (1 + lengthOfLength) ..< (1 + lengthOfLength + length))
            // Always using `.utf8` is not strictly correct; the general case should be improved
            let stringified = String(data: subData, encoding: .utf8)
            return (.string(string: stringified ?? "blargh"), 1 + lengthOfLength + length)

        default: // Some other thing we don't care about
            let (length, lengthOfLength) = self.advanced(by: 1).readLength()
            return (.bytes(data: self.subdata(in: (1 + lengthOfLength) ..< (1 + lengthOfLength + length))),
                    1 + lengthOfLength + length)
        }
    }

    private func parseOID() -> [UInt64] {
        var result = [UInt64]()
        var startIndex = self.startIndex

        while startIndex < self.endIndex {
            var (val, lastUsedIndex) = self.parseBase128(start: startIndex, end: self.endIndex)

            if result.isEmpty {
                if val < 40 {
                    result.append(0)
                } else if val < 80 {
                    result.append(1)
                    val -= 40
                } else {
                    result.append(2)
                    val -= 80
                }
            }
            result.append(val)

            startIndex = self.index(after: lastUsedIndex)
        }

        return result
    }

    private func parseBase128(start: Index, end: Index) -> (result: UInt64, lastUsedIndex: Index) {
        var result = UInt64(0)
        var lastUsedIndex = start

        for index in start..<end {
            let byte = self[index]
            lastUsedIndex = index
            result = result << 7
            result += UInt64(byte & 0x7F)
            if byte & 0x80 == 0 {
                break
            }
        }

        return (result, lastUsedIndex)
    }
}
