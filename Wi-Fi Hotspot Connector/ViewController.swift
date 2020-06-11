//
//  ViewController.swift
//  Wi-Fi Hotspot Connector
//
//  Created by Artyom Nesterenko on 11/6/20.
//  Copyright © 2020 artnest. All rights reserved.
//

import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import UIKit

class ViewController: UIViewController {
    @IBOutlet private var ssidTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var connectButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private var wifiInfoLabel: UILabel!
    
    @IBAction private func connectButtonTapped(_ sender: UIButton) {
        guard
            let ssid = ssidTextField.text,
            let password = passwordTextField.text
        else { return }
        
        connectToHotspot(ssid: ssid, password: password)
    }
    
    private func connectToHotspot(ssid: String, password: String) {
        activityIndicator.startAnimating()
        
        let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: password, isWEP: false)
        configuration.joinOnce = true

        NEHotspotConfigurationManager.shared.apply(configuration) { [weak self] error in
            print("error is \(String(describing: error))")
            
            self?.activityIndicator.stopAnimating()
            
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == NEHotspotConfigurationErrorDomain {
                    if let configError = NEHotspotConfigurationError(rawValue: nsError.code) {
                        switch configError {
                        case .invalidWPAPassphrase:
                            print("password error: \(error.localizedDescription)")
                        case .invalid,
                             .invalidSSID,
                             .invalidSSIDPrefix,
                             .invalidWEPPassphrase,
                             .invalidEAPSettings,
                             .invalidHS20Settings,
                             .invalidHS20DomainName,
                             .userDenied,
                             .pending,
                             .systemConfiguration,
                             .unknown,
                             .joinOnceNotSupported,
                             .alreadyAssociated,
                             .applicationIsNotInForeground,
                             .internal:
                            print("other error: \(error.localizedDescription)")
                        @unknown default:
                            print("later added error: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("some other error: \(error.localizedDescription)")
                }
            } else {
                print("perhaps connected")

                self?.printWifiInfo()
            }
        }
    }
    
    private func printWifiInfo() {
        print("printWifiInfo:")
        
        if let wifi = getConnectedWifiInfo() {
            if let connectedSSID = wifi["SSID"] {
                print("we are currently connected with \(connectedSSID)")
            }
            print("further info:")
            for (k, v) in wifi {
                print(".  \(k) \(v)")
            }
            
            let ssid = wifi["SSID"] as! String
            let bssid = wifi["BSSID"] as! String
            wifiInfoLabel.text = "SSID \(ssid)\nBSSID \(bssid)"
        }
        
        print()
    }

    private func getConnectedWifiInfo() -> [AnyHashable: Any]? {
        if
            let ifs = CFBridgingRetain(CNCopySupportedInterfaces()) as? [String],
            let ifName = ifs.first as CFString?,
            let info = CFBridgingRetain(CNCopyCurrentNetworkInfo(ifName)) as? [AnyHashable: Any]
        {
            return info
        }
        return nil
    }
}
