import CommonLib
import Socket
import Foundation

@main
public struct Server {

    public static func main() {
        var lastReceivedID: Int = -1
        let argParser = ArgParser.receiverArgParser
        var dataSended = [DataModel]()
        var dataReceived = [DataModel]()
        var sendingCount = 0
        var receivingCount = 0
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
            var readBytes = 0
            repeat {
                var receivedBuffer = Array<CChar>(repeating: 0, count: 1024)
                readBytes = read(socketManager.serverAcceptFD!, &receivedBuffer, 1024)
                receivingCount += 1
                if let json = (DataModel.convert(from: String(utf8String: receivedBuffer)!) as? DataModel) {
                    //print(String(cString: receivedBuffer))
                    dataReceived.append(json)
                    print(json)
                    lastReceivedID = json.id
                    let objectData = DataModel(seq: lastReceivedID, type: .ASK, data: nil)
                    let cStr = (objectData as JsonStringConvertible).convert()! as NSString
                    let writeBytes = write(socketManager.serverAcceptFD!, cStr.cString(using: String.Encoding.ascii.rawValue), cStr.length)
                    dataSended.append(objectData)
                    if writeBytes != -1 {
                       print("send: \(objectData)\n successfull ")
                    } 
                    if writeBytes > 0 {
                         sendingCount += 1         
                    }
                    
                } else {
                    break
                }
                print("number of packets sended: \(sendingCount)")
                print("number of packets received: \(receivingCount)")
                print("Actual Drop \(abs(100 - Double(receivingCount) / Double(sendingCount) * 100))%")
            } while readBytes != -1 
            print("Received data ------------- data packate")
            Array(Set(dataReceived)).sorted{$0.id < $1.id}.forEach{ print($0) }
        }
                
    }
}
