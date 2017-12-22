//
//  BleCentral.swift
//  mmSensor
//
//  Created by 宮西 昭次 on H29/12/22.
//  Copyright © 平成29年 宮西 昭次. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation

class GateWay
{
    var ssid:String=""
}
class MmSensor
{
    var outputInterval_s:Int=60
}
class MyBleDevice:
    CBPeripheral
{
    var peripheral: CBPeripheral
    var connected:Bool=false
    /*
     * optionalな変数はサービスとキャラクタリスティックの読み出し後に設定される
     */
    var tag:Int!
    var id:String!
    var txInterval_ms:Int!
    var txPower_db:Int!
    var mmSensor:[MmSensor]!
    var gateway:GateWay!
    var led:Bool!
    init(device:CBPeripheral){
        peripheral=device
    }
    func id(str:String){
        id=str
    }
    func add(device:MmSensor){
        mmSensor.append(device)
    }
    func add(device:GateWay){
        gateway=device
    }
}
class BleCentral:
    UIViewController,
    CBCentralManagerDelegate,
    CBPeripheralManagerDelegate,
    CBPeripheralDelegate
{
    let LedUUID         = CBUUID.init(string: "A001")                                       //LEDキャラクタリスティック
    let TxPowerUUID     = CBUUID.init(string: "2A07")
    let TxIntervalUUID  = CBUUID.init(string: "65025681-0FD8-5FB5-5148-3027069B3FD9") 
    let TxUUID          = CBUUID.init(string: "65020001-0FD8-5FB5-5148-3027069B3FD1")  //キャラクタリスティック
    let RxUUID          = CBUUID.init(string: "65020002-0FD8-5FB5-5148-3027069B3FD1")  //キャラクタリスティック
    let GwIdUUID        = CBUUID.init(string: "65020003-0FD8-5FB5-5148-3027069B3FD1")  //idキャラクタリスティック
    let IntervalUUID    = CBUUID.init(string: "65020004-0FD8-5FB5-5148-3027069B3FD1")  //キャラクタリスティック
    let IdUUID          = CBUUID.init(string: "65025682-0FD8-5FB5-5148-3027069B3FD9")  //idキャラクタリスティック
    let LedServiceUUID  = CBUUID.init(string: "A000")//var UUID1:CBUUID
    let GwIdServiceUUID = CBUUID.init(string: "65020001-0FD8-5FB5-5148-3027069B3FD1")//Gateway Id Service
    let IdServiceUUID   = CBUUID.init(string: "65025680-0FD8-5FB5-5148-3027069B3FD9")//id Service
    let BatteryServiceUUID = CBUUID.init(string:"180F")
    let TxPowerServiceUUID = CBUUID.init(string:"1804")
    let EnvironmentalServiceUUID = CBUUID.init(string:"181A")

    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var peripherals: [MyBleDevice]=[]
    var peripheralManager: CBPeripheralManager!

    override func viewDidLoad() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func getService() {
        print("[\(#function)]")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func startArvertisement(){
        let advertisementData = [CBAdvertisementDataLocalNameKey: "Test Device"]
        let serviceUUID = CBUUID(string: "0000")
        let service = CBMutableService(type: serviceUUID, primary: true)
        let charactericUUID = CBUUID(string: "0001")
        let characteristic = CBMutableCharacteristic(type: charactericUUID, properties: CBCharacteristicProperties.read, value: nil, permissions: CBAttributePermissions.readable)
        service.characteristics = [characteristic]
        peripheralManager.add(service)
        peripheralManager.startAdvertising(advertisementData)
    }
    func stopArvertisement(){
        print("[\(#function)]")
        peripheralManager.stopAdvertising()
    }
    
    /*
     *  接続状況が変わるたびに呼ばれる BLEセントラルマネージャーがコールバック
     *      .poweredOn:セントラルマネージャーがアップしたとき
     *      .poweredOff:セントラルマネージャーが停止した時
     *
     */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("[\(#function)]state: \(central.state)",terminator:"")
        switch central.state{
        case .poweredOn:
            //view.viewWithTag(Tag.bleMessage.rawValue)?.removeFromSuperview()//?によって、nilだったら実行しない
            print(".poweredOn")
            startScan()
        //case .poweredOff:
            //let label = UILabel()
            //print(".poweredOff")//インターフェースがオフになっている
            //label.text = "Bluetoothが機能していません。"
            //label.sizeToFit()
            //label.center = view.center
            //label.tag=Tag.bleMessage.rawValue
            //view.addSubview(label)
        default:
            print()
        }
    }

    func startScan() {
        print("[\(#function)]")
        let ServiceUUIDs = [
            //LedServiceUUID,//var UUID1:CBUUID
            GwIdServiceUUID,//mmsensor Service
            IdServiceUUID//id Service
        ]
        centralManager.scanForPeripherals(withServices:ServiceUUIDs, options: nil)
    }
    
    func stopScan(){
        centralManager.stopScan()
    }
    //  スキャン結果を取得
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        for device in peripherals{
            if device.peripheral==peripheral{
                return
            }
        }
        peripherals.insert( MyBleDevice(device:peripheral) ,at: 0 )
        // ペリフェラルと接続
        self.centralManager.connect((peripherals[0].peripheral), options: nil)
        
        /*
        */
        print("[\(#function) peripheral]ペリフェラル発見!RSSI:\(RSSI),name:\(peripheral.name ?? "none")")
        /*
        var i:Int=0
        print("[\(#function) peripheral]advertisementData.count:\(advertisementData.count)")
        for dic in advertisementData{
            if dic.key == "kCBAdvDataIsConnectable" {
                print("[\(#function) peripheral]advertisementData[\(i)]:IsConnectable:\(dic.value)")
            }else
            if dic.key == "kCBAdvDataHashedServiceUUIDs" {
                print("[\(#function) peripheral]advertisementData[\(i)]:HashedServiceUUIDs:")
                print("\(dic.value)")
            }else
            if dic.key == "kCBAdvDataLocalName"    {
                print("[\(#function) peripheral]advertisementData[\(i)]:LocalName:\(dic.value)")
            }else{
                print("[\(#function) peripheral]\(dic.key):\(dic.value)")
            }
            i += 1
        }
        print()
        */
    }

    //  接続成功時に呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        var myBleDevice:MyBleDevice!
        var index=0
        for device in peripherals{
            if device.peripheral==peripheral{
                myBleDevice=device
                break;
            }
            index+=1
        }
        print("[\(#function) peripheral]index[\(index)]name:\(peripheral.name ?? "none")")
        //myBleDevice.peripheral.delegate = self
        //myBleDevice.peripheral.discoverServices(nil)
        myBleDevice.connected=true
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    //  接続失敗時に呼ばれる
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let name:String=peripheral.name{
            print("[\(#function) peripheral]failed!,name:\(name)")
        }else{
            print("[\(#function) peripheral]failed!,\(peripheral)")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
         print("[\(#function)]")
         return true
    }
    
    //  ペリフェラルのStatusが変化した時に呼ばれる
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("[\(#function)]state:\(peripheral.state)")
    }
    //  サービス追加結果の取得
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("[\(#function)]service:",terminator:"")
        if error != nil {
            print("Failed")
            return
        }
        print("Sucsess!")
    }
    
    //  アドバタイズ開始処理の結果を取得
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("[\(#function)]",terminator:"")
        if let error = error {
            print("Advertising ERROR:\(error)")
            return
        }
        print("Advertising success")
    }
    
    /*
     * サービススキャンでサービスを発見した時のコールバック
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("[\(#function)]",terminator:"")
        guard let services = peripheral.services else{
            print("error")
            return
        }

        print("name:\(peripheral.name ?? "none"),\(services.count)個のサービスを発見。")
        
        var i=0
        var index=0
        var myBleDevice:MyBleDevice!
        for device in peripherals{
            if device.peripheral==peripheral{
                myBleDevice=device
                break;
            }
            index+=1
        }
        for service in services {
            if service.uuid.uuidString==LedServiceUUID.uuidString{
                //print("add[\(index)][\(i)]LedService")
            }else
            if service.uuid.uuidString==TxPowerServiceUUID.uuidString{
                print("add[\(index)][\(i)]TxPowerService")
            }else
            if service.uuid.uuidString==BatteryServiceUUID.uuidString{
                //print("add[\(index)][\(i)]BatteryService")
            }else
            if service.uuid.uuidString==EnvironmentalServiceUUID.uuidString{
                //print("add[\(index)][\(i)]EnvironmentalService")
            }else
            if service.uuid.uuidString==GwIdServiceUUID.uuidString{
                print("add[\(index)][\(i)]gatewayService")
                myBleDevice.add( device:GateWay() )
            }else
            if service.uuid.uuidString==IdServiceUUID.uuidString{
                print("add[\(index)][\(i)]pingerService")
                //myBleDevice.add( device:Pinger() )//サービスUUIDがGATでひっくり返るbugによりここで判断できない。
            }
            i+=1
        }
        i = 0
        for service in services {
            print("device[\(index)]services[\(i)]",service.uuid.uuidString)
            i+=1
            //  サービスを見つけたらすぐにキャラクタリスティックを取得
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //  キャラクタリスティック検索結果取得
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var index=0
        //var myBleDevice:MyBleDevice!
        for device in peripherals{
            if device.peripheral==peripheral{
                //myBleDevice=device
                break;
            }
            index+=1
        }
        //print("[\(#function)]",terminator:"")
        if let characteristics = service.characteristics {
            print("device[\(index)]sevice:\(service.uuid.uuidString),\(characteristics.count)個のキャラクタリスティックを発見。")
 
            var i=0
            
            for characteritic in characteristics{
                //print( CBCharacteristicProperties.read )
                //print( (UInt8(CBCharacteristicProperties.read.rawValue) & UInt8(characteritic.properties.rawValue)) )
                /*
                 * read属性のキャラクタリスティックの読み出しを実行する。
                 */
                let readFlag =  (UInt8(CBCharacteristicProperties.read.rawValue) & UInt8(characteritic.properties.rawValue))
                if readFlag == CBCharacteristicProperties.read.rawValue {
                    peripheral.readValue(for: characteritic)
                    print("device[\(index)][\(i)],uuid:\(characteritic.uuid.uuidString),properties:\( characteritic.properties.rawValue ),startRead")
                }else{
                    print("device[\(index)][\(i)],uuid:\(characteritic.uuid.uuidString),properties:\( characteritic.properties.rawValue )")
                }
                i+=1
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("[\(#function)]")
        var myBleDevice:MyBleDevice!
        var index=0
        for device in peripherals{
            if device.peripheral==peripheral{
                myBleDevice=device
                break;
            }
            index+=1
        }
        if let count = characteristic.value?.count{
            var values0 = [UInt8](repeating:0, count: count)
            var values = [UInt8](repeating:0, count: count)
        
            characteristic.value?.copyBytes(to: &values0,count:values.count)
            var index:Int=1
            for i in values0{
                values[count-index]=i
                index += 1
            }
            if characteristic.uuid.uuidString==IntervalUUID.uuidString{
                //print("[\(#function)]MmSensorInterval:\(values)")
            }else
            if characteristic.uuid==TxIntervalUUID{
                let hexStr = values.map{
                    String(format: "%.2hhx",$0)
                }.joined()
                print("[\(index)][\(#function)]txInterval:\(hexStr)")
                myBleDevice.txInterval_ms=Int(hexStr,radix:16)!
            }else
            if characteristic.uuid==TxPowerUUID{
                let hexStr = values.map{
                    String(format: "%.2hhx",$0)
                }.joined()
                print("[\(index)][\(#function)]txPower:\(hexStr)")
                myBleDevice.txPower_db=Int(hexStr,radix:16)!
            }else
            if characteristic.uuid==LedUUID{
                if values[0]==0 {
                    myBleDevice.led=false
                }else{
                    myBleDevice.led=true
                }
            }else
            if characteristic.uuid==IdUUID{
                let hexStr = values.map{
                    String(format: "%.2hhx",$0)
                }.joined()
                print("[\(index)][\(#function)]ID:\(hexStr)")
                myBleDevice.id=hexStr
            }else
            if characteristic.uuid==GwIdUUID{
                let hexStr = values.map{
                    String(format: "%.2hhx",$0)
                }.joined()
                print("[\(index)][\(#function)]ID:\(hexStr)")
                myBleDevice.id=hexStr
            }else{
                //print("[\(#function)]service.UUID:\(characteristic.service.uuid)")
                //print("[\(#function)]characteristic.UUID:\(characteristic.uuid)")
                //print("[\(#function)]characteristic:\(characteristic)")
            }
        }
        /*
         * 切断判定
         */
        if nil != myBleDevice.id && nil != myBleDevice.led {
            myBleDevice.connected=false
            if nil != myBleDevice.gateway{
                print("device[\(index)]=gateway,Id:\(myBleDevice.id),LED:\(myBleDevice.led)")
                centralManager.cancelPeripheralConnection(peripheral)
            }else{
                print("device[\(index)]=Pinger,Id:\(myBleDevice.id),LED:\(myBleDevice.led),txPower:\(myBleDevice.txPower_db),txInterval:\(myBleDevice.txInterval_ms)")
                if myBleDevice.txInterval_ms != nil && myBleDevice.txPower_db != nil{
                    centralManager.cancelPeripheralConnection(peripheral)
                }
            }
            var i=0
            for device in peripherals{
                if nil != device.gateway{
                    print("device[\(i)]gateway connected:\(device.connected),id:\(device.id ?? "none"),name:\(device.peripheral.name ?? "none"),LED:\(device.led)")
                }else
                if nil != device.txInterval_ms{
                    print("device[\(i)]pinger connected:\(device.connected),id:\(device.id ?? "none"),name:\(device.peripheral.name ?? "none"),LED:\(device.led),txPower:\(device.txPower_db),txInterval:\(device.txInterval_ms)")
                }else{
                    print("device[\(i)]unknown connected:\(device.connected)")
                }
                i += 1
            }
        }
    }

}
