//
//  ViewController.swift
//  CentralManager
//
//  Created by Uy Nguyen Long on 1/5/18.
//  Copyright © 2018 Uy Nguyen Long. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, UITableViewDelegate, UITableViewDataSource, CBPeripheralDelegate {
    
    @IBOutlet weak var lblAlert: UILabel!
    @IBOutlet weak var lblReadValue: UILabel!
    @IBOutlet weak var txtWritedValue: UITextField!
    @IBOutlet weak var tbvScannedDevices: UITableView!
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    
    let kServiceUUID = "94515FA0-D9DD-41D4-9D2C-CA3CFFF6C83D"
    let kCharacteristicUUID = "94515FA1-D9DD-41D4-9D2C-CA3CFFF6C83D"
    
    var discovererChars : [String: CBCharacteristic] = [:]
    
    var scannedDevices = [(device: CBPeripheral, rssi: NSNumber)]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "YourUniqueIdentifierKey"])
        
        tbvScannedDevices.delegate = self
        tbvScannedDevices.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("peripheralManagerDidUpdateState \(central.state.rawValue)")

        if central.state == .poweredOn {
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    func checkIfExisted(_ name: String) -> Bool {
        for item in self.scannedDevices {
            if (item.device.name == name) {
                return true
            }
        }
        return false
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            if (!checkIfExisted(name)) {
                print("didDiscoverPeripheral \(String(describing: peripheral.name))")
                let tupleDeviceInfo = (device: peripheral, rssi: RSSI)
                self.scannedDevices.append(tupleDeviceInfo)
            }
            
            
            DispatchQueue.main.async {
                self.tbvScannedDevices.reloadData()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.centralManager.stopScan()
        self.lblAlert.text = "Did connect to \(peripheral.name ?? "")"
        peripheral.delegate = self
        self.peripheral = peripheral
        self.peripheral?.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        LocalNotification.shared.notify(title: "Manager will restore state", text: "")
            
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            peripherals.forEach { (awakedPeripheral) in
                print("\(Date.init()). - Awaked peripheral \(String(describing: awakedPeripheral.name))")
                guard let localName = awakedPeripheral.name,
                localName == "HAHAHA" else {
                    return
                }
                
                self.peripheral = awakedPeripheral
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.lblAlert.text = "Did fail connect to \(peripheral.name ?? "")"
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.lblAlert.text = "Did disconnect to \(peripheral.name ?? "")"
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            return
        }
        
        for service in (peripheral.services)! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("didDiscoverCharacteristicsFor Error \(error.localizedDescription)")
            return
        }
        print("Chars:")
        for char in service.characteristics! {
            print("\(char)")
            if char.properties.contains(.notify) {
                print("Set notify")
                peripheral.setNotifyValue(true, for: char)
            }
            
            discovererChars[char.uuid.uuidString] = char
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let value = String.init(data: characteristic.value!, encoding: .utf8)!
        self.lblReadValue.text = "\(value)"
        LocalNotification.shared.notify(title: "did update value for characteristic", text: String(data: characteristic.value!, encoding: .utf8)!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("Did write value with error \(err.localizedDescription)")
        }
    }
    
    @IBAction func btnReadTouchDown(_ sender: Any) {
        self.peripheral?.readValue(for: discovererChars[kCharacteristicUUID]!)
    }
    
    @IBAction func btnWriteTouchDown(_ sender: Any) {
        let data = self.txtWritedValue.text!.data(using: .utf8)!
        self.peripheral?.writeValue(data, for: discovererChars[kCharacteristicUUID]!, type: .withResponse)
    }
}


extension ViewController {
    
    // MARK: Tableview delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return self.scannedDevices.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Scanned devices"
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tbvScannedDevices.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")!
        
        let per = self.scannedDevices[indexPath.row]
        cell.textLabel?.text = "\(per.device.name!) - RSSI \(per.rssi)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let per = self.scannedDevices[indexPath.row]
        self.centralManager.connect(per.device, options: nil)
    }

}

