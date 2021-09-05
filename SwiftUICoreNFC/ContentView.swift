//
//  ContentView.swift
//  SwiftUICoreNFC
//
//  Created by Boris Zinovyev on 05.09.2021.
//

import SwiftUI
import CoreNFC


struct ContentView: View {
//    Что делает?
    @State var urlT = ""
    @State var writer = NFCReader()
    var body: some View {
//    Как выглядит?
        VStack {
            TextField("Enter URL", text:$urlT).autocapitalization(.none)
            Button(action:{
                writer.scan(theactualdata: urlT)
            }) {
                Text("Write a Tag")
            }.padding()
        }.padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class NFCReader: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    
    var theactualData = ""
    var nfcSession: NFCNDEFReaderSession?
    
    func scan(theactualdata: String) {
        theactualData = theactualdata
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        nfcSession?.alertMessage = "Hold Your iPhone Near an NFC Card"
        nfcSession?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) { }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) { }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        let str: String = theactualData
        if tags.count > 1{
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than one Tag Detected, please try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                
            })
            return
        }
//        let tag = tags.first!
//        session.connect(to: tag) { (error: Error?) in
//            if nil != error {
//                session.alertMessage = "Unable To Connect to Tag"
//                session.invalidate()
//                return
//            }
//            tag.queryNDEFStatus(completionHandler: {(ndefstatus: NFC)})
//        })
//    }

    let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                guard error == nil else {
                    session.alertMessage = "Unable to query the NDEF status of tag."
                    session.invalidate()
                    return
                }

                switch ndefStatus {
                case .notSupported:
                    session.alertMessage = "Tag is not NDEF compliant."
                    session.invalidate()
                case .readOnly:
                    session.alertMessage = "Tag is read only."
                    session.invalidate()
                case .readWrite:
                    tag.writeNDEF(.init(records: [NFCNDEFPayload.wellKnownTypeURIPayload(string: "\(str)")!]), completionHandler: {(error: Error?) in
                        if nil != error {
                            session.alertMessage = "Write NDEF message fail: \(error!)"
                        } else {
                            session.alertMessage = "Write NDEF message successful."
                        }
                        session.invalidate()
                    })
                @unknown default:
                    session.alertMessage = "Unknown NDEF tag status."
                    session.invalidate()
                }
            })
        })
    }
}
