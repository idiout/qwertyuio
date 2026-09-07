import Foundation
import Network

enum PacketSendResult {
    case success
    case failure(String)
}

enum NetworkSender {

    static func send(ip: String, port: String, packet: String, completion: @escaping (PacketSendResult) -> Void) {
        let trimmedIP = ip.trimmingCharacters(in: .whitespaces)
        guard !trimmedIP.isEmpty else {
            completion(.failure("Missing IP"))
            return
        }
        guard let portValue = UInt16(port.trimmingCharacters(in: .whitespaces)),
              let nwPort = NWEndpoint.Port(rawValue: portValue) else {
            completion(.failure("Invalid port"))
            return
        }

        let data = encodePayload(packet)
        let connection = NWConnection(host: NWEndpoint.Host(trimmedIP), port: nwPort, using: .udp)

        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                connection.send(content: data, completion: .contentProcessed { error in
                    if let error {
                        completion(.failure(error.localizedDescription))
                    } else {
                        completion(.success)
                    }
                    connection.cancel()
                })
            case .failed(let error):
                completion(.failure(error.localizedDescription))
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .global(qos: .userInitiated))
    }

    /// Plain text is sent as UTF-8. Space/comma-separated hex byte pairs
    /// (e.g. "AA BB 01" or "0xAA,0xBB") are sent as raw bytes instead.
    private static func encodePayload(_ raw: String) -> Data {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let hexData = parseHex(trimmed) {
            return hexData
        }
        return Data(trimmed.utf8)
    }

    private static func parseHex(_ string: String) -> Data? {
        guard !string.isEmpty else { return nil }
        let cleaned = string
            .replacingOccurrences(of: "0x", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ",", with: " ")
        let tokens = cleaned.split(separator: " ").filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }

        var bytes: [UInt8] = []
        for token in tokens {
            guard token.count <= 2, let byte = UInt8(token, radix: 16) else { return nil }
            bytes.append(byte)
        }
        return Data(bytes)
    }
}
