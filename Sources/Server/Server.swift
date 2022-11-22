import CommonLib
import Socket
import Foundation

@main
public struct Server {

    public static func main() {
        var lastReceivedID: Int = -1
        let argParser = ArgParser.receiverArgParser
        do {
            try argParser.parse()
        } catch(let error) {
            print(error)
            exit(-1)
        }

        let port: UInt16 = argParser.portNumber ?? 2222
        debugPrint("port number is \(port)")
        let socketManager = SocketManager(isForServer: true, serverIP: "", port: port)
        let fileManager = CommonLib.FileManager.shared
        //MARK: - create socket
        do {
            try socketManager.createSocket()
        } catch {
            print("Failed to create Socket")
            exit(-1)
        }
        print("socket created")

        //MARK: - Bind
        do {
            try socketManager.bind()
        } catch {
            print("Failed to bind")
            exit(-1)
        }

        print("bind successful")
        //MARK: - Listen
        do {
            try socketManager.listen()
        } catch {
            print("Failed to listen")
            exit(-1)
        }

        print("listen successful")
        //MARK: - Accept
        while(true) {
            do {
                try socketManager.accept()
            } catch {
                print("Failed to listen")
                exit(-1)
            }
           
            socketManager.getClientIpAddr()
            print("Accept client: \(socketManager.clientIPAddr!) successfully")
            while true {
                var receivedBuffer = Array<CChar>(repeating: 0, count: 1024)
                let bytes = read(socketManager.serverAcceptFD!, &receivedBuffer, 1024)
                if let json = (DataModel.convert(from: String(utf8String: receivedBuffer)!) as? DataModel) {
                    print(String(cString: receivedBuffer))
                    print(json)
                    if json.id == lastReceivedID + 1 {
                        lastReceivedID = json.id
                    }
                    let objectData = DataModel(seq: lastReceivedID, type: .ASK, data: nil)
                    let cStr = (objectData as JsonStringConvertible).convert()! as NSString
                    write(socketManager.serverAcceptFD!, cStr.cString(using: String.Encoding.ascii.rawValue), cStr.length)
                    if bytes == -1 {
                        break
                    }
                } else {
                    break
                }
            }
        }
                
    }
}
