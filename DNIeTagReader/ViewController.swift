//
//  ViewController.swift
//  DNIeTagReader
//
//  Created by Ronald Ricardo Martinez Chunga on 10/03/23.
//

import UIKit
import CoreNFC
import CryptoKit

class ViewController: UIViewController, NFCTagReaderSessionDelegate {
    
    @IBOutlet weak var textOriginalMsg: UITextField!
    @IBOutlet weak var textPin: UITextField!
    @IBOutlet weak var textSignedEncodedMsg: UILabel!
    @IBOutlet weak var wrongPinMsg: UILabel!
    var inputString: String!
    var pin: String!
    var session: NFCTagReaderSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func beginScanning(_ sender: UIButton) {
        print("begin scanning !!!")
        
        textSignedEncodedMsg.lineBreakMode = .byWordWrapping
        textSignedEncodedMsg.numberOfLines = 0
        
        inputString = textOriginalMsg.text ?? "Dato a ser firmado"
        
        wrongPinMsg.text = ""
        
        pin = textPin.text ?? ""
        
        session = NFCTagReaderSession(pollingOption: .iso14443, delegate: self)
        session?.alertMessage = "Sostenga su DNIe cerca de la parte superior de su iPhone para iniciar la comunicación, mantenga la tarjeta hasta terminar."
        session?.begin()
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        var nfcIso7816Tag: NFCISO7816Tag? = nil
        var tag: NFCTag? = nil
        
        for nfcTag in tags {
            // In this example you are searching for a MIFARE Ultralight tag (NFC Forum T2T tag platform).
            if case let .iso7816(myIso7816Tag) = nfcTag {
                //if mifareTag.type == .iso7816Compatible {
                nfcIso7816Tag = myIso7816Tag
                tag = nfcTag
                //    break
                //}
            }
        }
        
        if nfcIso7816Tag == nil {
            session.invalidate(errorMessage: "Card not support")
            print("nfcIso7816Tag nil...")
            return
        }
        
        if tag == nil {
            session.invalidate(errorMessage: "No valid coupon found.")
            print("tag nil...")
            return
        }
        
        // 00A40400 0E E828BD080FD25047656E65726963
        //let selectApp : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0xA4, 0x04, 0x00, 0x08, 0x50, 0x41, 0x59, 0x2E, 0x54, 0x49, 0x43, 0x4C, 0x00]))!
        let apduSelect : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0xA4, 0x04, 0x00, 0x0E, 0xE8, 0x28, 0xBD, 0x08, 0x0F, 0xD2, 0x50, 0x47, 0x65, 0x6E, 0x65, 0x72, 0x69, 0x63, 0x00]))!
        // 00200081083131313131313131
        let verifyPinHeader:[UInt8] = [0x00, 0x20, 0x00, 0x81, UInt8(bitPattern: Int8(pin.count))]
        let inputPin = Data(pin.utf8)
        let verifyPin = verifyPinHeader + inputPin
        let verifyPinString = verifyPin.compactMap { String(format: "%02x", $0) }.joined()
        print("Hex string format: \(verifyPinString)")
        //let apduVerifyPin : NFCISO7816APDU = NFCISO7816APDU(data: Data.init([0x00, 0x20, 0x00, 0x81, 0x06, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36]))!
        let apduVerifyPin : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(verifyPin))!
        
        let mseSignHeader:[UInt8] = [0x00, 0x22, 0x41, 0xB6]
        let mseSignData:[UInt8] = [0x06, 0x80, 0x01, 0x8A, 0x84, 0x01, 0x81]
        let mseSign = mseSignHeader + mseSignData
        let apduSignMSE : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(mseSign))!
        
        // hash of data
        //let inputString = "Text message from iPhone App"
        
        let inputData = Data(inputString.utf8)
        print("Origin message: \(inputString.description)")
        let hashed = SHA256.hash(data: inputData)
        print(hashed.description)
        let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
        print("Hex string format: \(hashString)")
        let psoSignData = hashed
        
        let psoSignHeader:[UInt8] = [0x00, 0x2A, 0x9E, 0x9A, 0x31, 0x30, 0x2F, 0x30, 0x0B, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x04, 0x20]
        let psoSign = psoSignHeader + psoSignData
        let apduSignPSO : NFCISO7816APDU = NFCISO7816APDU(data: Data.init(psoSign))!
        
        session.connect(to: tag!) { (e: Error?) in
            
            nfcIso7816Tag?.sendCommand(apdu: apduSelect, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduSelect description: \(data.description)")
                print("sw1: \(String(sw1, radix:16)), sw2: \(String(sw2, radix:16))")
                
                guard (sw1 == 0x90 && sw2 == 0) else {
                    print("error:  \(error.debugDescription)")
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
            
            nfcIso7816Tag?.sendCommand(apdu: apduVerifyPin, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduVerifyPin description: \(data.description)")
                print("sw1: \(String(sw1, radix:16)), sw2: \(String(sw2, radix:16))")
                
                guard (sw1 == 0x90 && sw2 == 0) else {
                    print("error:  \(error.debugDescription)")
                    let wrongPinMsg = "PIN erróneo, le quedan \(sw2-192) intentos"
                    print(wrongPinMsg)
                    Task { @MainActor in
                        self.wrongPinMsg.text = wrongPinMsg
                    }
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
            
            nfcIso7816Tag?.sendCommand(apdu: apduSignMSE, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduSignMSE description: \(data.description)")
                print("sw1: \(String(sw1, radix:16)), sw2: \(String(sw2, radix:16))")
                
                guard ((sw1 == 0x90 && sw2 == 0)) else {
                    print("error:  \(error.debugDescription)")
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
            
            var signedData: Data!
            nfcIso7816Tag?.sendCommand(apdu: apduSignPSO, completionHandler: { (data: Data, sw1: UInt8, sw2: UInt8, error: Error?) in
                print("apduSignPSO description: \(data.description)")
                signedData = data
                let encoded: String = signedData.base64EncodedString()
                print("apduSignPSO base64 encoded: \(encoded)")
                //self.textSignedEncodedMsg.text = encoded
                Task { @MainActor in
                    self.textSignedEncodedMsg.text = encoded
                }
                print("apduSignPSO hexadecimal: \(signedData.compactMap { String(format: "%02x", $0) }.joined())")
                
                print("sw1: \(String(sw1, radix:16)), sw2: \(String(sw2, radix:16))")
                
                // This is the last interaction with the Tag, here we can close the session window with a customized message
                if (sw1 == 0x90 && sw2 == 0) {
                    session.alertMessage = "Lectura del DNIe exitosa"
                    session.invalidate()
                    return
                } else {
                    print("error:  \(error.debugDescription)")
                    session.invalidate(errorMessage: "Application failure")
                    return
                }
            })
        }
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {}
}
