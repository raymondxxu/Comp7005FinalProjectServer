import CommonLib
import Socket
import Foundation

@main
public struct Server {

    public static func main() {
        let argParser = ArgParser.serverShared
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
        if let dir = argParser.serverDir {
            try! fileManager.changeWorkingDir(with: dir)
        }
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



            var receivedBuffer = Array<CChar>(repeating: 0, count: 2048)
            receivedBuffer[0] = -1
            socketManager.getClientIpAddr()
            try! fileManager.crateWorkingDir(with: socketManager.clientIPAddr!)
            print("Accept client: \(socketManager.clientIPAddr!) successfully")
            while (receivedBuffer[0] != 0) {
                let _ = read(socketManager.serverAcceptFD!, &receivedBuffer, 1023)
                let file = String(cString: receivedBuffer)
                let fileName = file.split(separator: "_").first ?? ""
                let fileContent = file.split(separator: "_").last ?? ""
                if !fileName.isEmpty && !fileContent.isEmpty {
                    do {
                        debugPrint("receive file \(fileName)")
                        try fileManager.createFile(with: String(fileName), for: String(fileContent))
                    } catch {
                        print("Failed to create file")
                        exit(-1)
                    }
                }
            }
            fileManager.goBackToParentFolder()
        }
    }
}
