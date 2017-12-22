//
//  ViewController.swift
//  mmSensor
//
//  Created by 宮西 昭次 on H29/12/19.
//  Copyright © 平成29年 宮西 昭次. All rights reserved.
//

import UIKit
import CoreBluetooth
import Foundation
enum BleAction:Int{
    case startScan=1
    case ledOn
    case ledOff
    case test
}
protocol BleDelegate: class
{
    func action(action:BleAction,tag:Int)
    func test()
}
class GateWay
{
    var ssid:String=""
}
class MmSensor
{
    var outputInterval_s:Int=60
}
enum BleJob:Int{
    case scanServie
    case scanCharacteristic
    case ledOn
    case ledOff
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
    var job:BleJob!
    var ledCharacteristic:CBCharacteristic!
    
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
class ViewController:
    UIViewController,
    CBCentralManagerDelegate,
    CBPeripheralManagerDelegate,
    CBPeripheralDelegate,
    BleDelegate
{
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var peripheralManager: CBPeripheralManager!
    var peripherals: [MyBleDevice]=[]
    var lastPositionY:CGFloat=100
    let offsetY:CGFloat=20
    var peripheralViewController:PeripheralViewController!
    
    var tagCount=0
    
    let LedUUID = CBUUID.init(string: "A001")                                       //LEDキャラクタリスティック
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

    enum Tag:Int{
        case bleMessage=10
        case scanStartButton=11
        case scanStopButton=12
        case nextButton
        case testLabel
        case testLabelRemoveButton
        case deviceButton=100
    }
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        addStartScanButton()
        addStopScanButton()
        //addNextButtonButton()
        //addTestLabel()
        //addTestLabelRemoveButton()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
    }

    /*
     * スキャン停止ボタン
     */
    func addStopScanButton(){
        //let button = UIButton(frame: CGRect(x: 0,y: PosY.scanStartButton.rawValue,width: 200,height:100))
        let button = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 200,height:100))
        button.setTitle("スキャン停止", for: .normal)
        button.sizeToFit()
        button.center.x = view.center.x
        button.backgroundColor = UIColor.gray
        button.tag = Tag.scanStopButton.rawValue
        button.addTarget(self, action: #selector(ViewController.stopScan(_:)), for: .touchUpInside)
        
        view.addSubview(button)
        
        lastPositionY += (button.frame.height + offsetY)
    }
    //  スキャン停止ボタンのコールバック
    @IBAction func stopScan(_ sender: UIButton) {
        print("[\(#function)]")
        centralManager.stopScan()
    }


    /*
     * スキャン開始ボタン
     */
    func addStartScanButton(){
        let button = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 200,height:100))

        button.setTitle("スキャン開始", for: .normal)
        button.sizeToFit()
        button.center.x = view.center.x
        button.backgroundColor = UIColor.gray
        button.tag = Tag.scanStartButton.rawValue
        button.addTarget(self, action: #selector(ViewController.startScan(_:)), for: .touchUpInside)
        
        view.addSubview(button)

        lastPositionY += button.frame.height + offsetY
    }
    @objc func startScan(_ sender: UIButton) {
        print("[\(#function)]")
        _startScan()
    }

    func addSendMessageButton(){
        let button = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 200,height:100))
        button.setTitle("送信", for: .normal)
        button.sizeToFit()
        button.center.x = view.center.x
        button.backgroundColor = UIColor.gray
        button.tag = Tag.scanStopButton.rawValue
        button.addTarget(self, action: #selector(ViewController.stopScan(_:)), for: .touchUpInside)
        
        view.addSubview(button)

        lastPositionY += button.frame.height + offsetY
    }
    @IBAction func sendMessage(_ sender: UIButton) {
        print("[\(#function)]")
    }
    /*
     * NextViewに遷移するボタン
     */
    func addNextButtonButton(){
        let button = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 200,height:100))

        button.setTitle("Go!", for: .normal)
        button.sizeToFit()
        button.center.x = view.center.x
        button.backgroundColor = UIColor.gray
        button.tag = Tag.nextButton.rawValue
        button.addTarget(self, action: #selector(ViewController.goNext(_:)), for: .touchUpInside)
        
        view.addSubview(button)

        lastPositionY += button.frame.height + offsetY
    }
    /*
     * NextViewControllerオブジェクトに制御を渡す
     * selectorで呼び出す場合Swift4からは「@objc」をつける。
     */
    @objc func goNext(_ sender: UIButton){
        let nextvc = NextViewController()
        nextvc.view.backgroundColor = UIColor.darkGray
        self.present(nextvc, animated: true, completion: nil)
    }
    /*
     * labelの作成、削除
     */
     func addTestLabel(){
        let label = UILabel()
        label.text = "test"
        label.sizeToFit()
        label.center.y = lastPositionY
        label.center.x = view.center.x
        //label.center = view.center
        label.tag = Tag.testLabel.rawValue
        view.addSubview(label)
        lastPositionY += label.frame.height + offsetY
    }
    @objc func removeTestLabel(_ sender: UIButton){
        let label = view.viewWithTag(Tag.testLabel.rawValue)
        label?.removeFromSuperview()//?によって、labelがnilだったら実行しない
    }
    func addTestLabelRemoveButton(){
        let button = UIButton(frame: CGRect(x: 0,y: lastPositionY ,width: 100,height:100))
        button.setTitle("removeLabel by tag!", for: .normal)
        button.sizeToFit()
        button.center.x = view.center.x
        button.backgroundColor = UIColor.gray
        button.tag = Tag.testLabelRemoveButton.rawValue
        button.addTarget(self, action: #selector(ViewController.removeTestLabel(_:)), for: .touchUpInside)
        
        view.addSubview(button)
        
        lastPositionY += ( button.frame.height * 1.4 )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
     * PeripheralViewControllerに遷移するボタン
     */
    func addOpenButtonButton(_ peripheral: CBPeripheral ){
        var myBleDevice:MyBleDevice!
        var index=0
        for device in peripherals{
            if device.peripheral==peripheral{
                myBleDevice=device
                break;
            }
            index+=1
        }
        let button = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 200,height:100))
        var name = String(myBleDevice.tag) + ":" + (peripheral.name ?? "no name")
        name += " [ " + myBleDevice.id + " ] "
        button.setTitle( name , for: .normal)
        button.sizeToFit()
        button.center.x = view.center.x
        button.backgroundColor = UIColor.gray
        button.tag = myBleDevice.tag
        button.addTarget(self, action: #selector(ViewController.goDeviceView(_:)), for: .touchUpInside)
        
        view.addSubview(button)
        
        let button2 = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 200,height:100))
        button2.setTitle( "LED On" , for: .normal)
        button2.sizeToFit()
        button2.center.x = button.center.x + button.frame.width+10
        button2.backgroundColor = UIColor.gray
        button2.tag = myBleDevice.tag
        button2.addTarget(self, action: #selector(ViewController.ledOn(_:)), for: .touchUpInside)
        view.addSubview(button2)

        let button3 = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 200,height:100))
        button3.setTitle( "LED Off" , for: .normal)
        button3.sizeToFit()
        button3.center.x = button2.center.x + button2.frame.width+10
        button3.backgroundColor = UIColor.gray
        button3.tag = myBleDevice.tag
        button3.addTarget(self, action: #selector(ViewController.ledOff(_:)), for: .touchUpInside)
        view.addSubview(button3)

        lastPositionY += ( button.frame.height * 1.4 )
    }
    /*
     * PeripheralViewControllerオブジェクトに制御を渡す
     * selectorで呼び出す場合Swift4からは「@objc」をつける。
     */
    @objc func goDeviceView(_ sender: UIButton){
        var myBleDevice:MyBleDevice!
        for device in peripherals{
            if let tag=device.tag{
                if tag == sender.tag{
                    myBleDevice=device
                    // AppDelegateのmessageに押されたボタンのtagを代入
                    let peripheralViewController = PeripheralViewController()
                    peripheralViewController.delegate = self
                    peripheralViewController.view.backgroundColor = UIColor.white
                    self.present(peripheralViewController, animated: true, completion: nil)
                    print("[\(#function)]button clicked")
                    peripheralViewController.updateView(device: myBleDevice)
                    print("[\(#function)]\(peripheralViewController)")
                    break;
                }
            }
        }
    }
    @objc func ledOn(_ sender: UIButton){
        for device in peripherals{
            if let tag=device.tag{
                if tag == sender.tag{
                    device.job=BleJob.ledOn
                    centralManager.connect(device.peripheral, options:nil)
                    break;
                }
            }
        }
    }
    @objc func ledOff(_ sender: UIButton){
        for device in peripherals{
            if let tag=device.tag{
                if tag == sender.tag{
                    device.job=BleJob.ledOff
                    centralManager.connect(device.peripheral, options:nil)
                    break;
                }
            }
        }
    }
    /*===========================================================================================*******************************************************************/
    //
    //          BLE関連
    //
    /*===========================================================================================*******************************************************************/
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
            view.viewWithTag(Tag.bleMessage.rawValue)?.removeFromSuperview()//?によって、nilだったら実行しない
            print(".poweredOn")
            _startScan()
        case .poweredOff:
            let label = UILabel()
            print(".poweredOff")//インターフェースがオフになっている
            label.text = "Bluetoothが機能していません。"
            label.sizeToFit()
            label.center = view.center
            label.tag=Tag.bleMessage.rawValue
            view.addSubview(label)
        default:
            print()
        }
    }

    func _startScan() {
        print("[\(#function)]")
        let ServiceUUIDs = [
            //LedServiceUUID,//var UUID1:CBUUID
            GwIdServiceUUID,//mmsensor Service
            //IdServiceUUID//id Service
        ]
        centralManager.scanForPeripherals(withServices:ServiceUUIDs, options: nil)
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
        print("[\(#function)]",terminator:"")
        var myBleDevice:MyBleDevice!
        var index=0
        for device in peripherals{
            if device.peripheral==peripheral{
                myBleDevice=device
                break;
            }
            index+=1
        }
        if nil == myBleDevice.job{
            print("[\(#function) peripheral]index[\(index)]name:\(peripheral.name ?? "none"),job:discoverServices")
            //myBleDevice.peripheral.delegate = self
            //myBleDevice.peripheral.discoverServices(nil)
            myBleDevice.connected=true
            peripheral.delegate = self
            peripheral.discoverServices(nil)
        }else{
            switch myBleDevice.job.rawValue{
            case BleJob.ledOn.rawValue:
                print("[\(#function) peripheral]index[\(index)]name:\(peripheral.name ?? "none"),job:LED on")
                var valure: CUnsignedChar = 0x01
                let data: NSData = NSData(bytes: &valure, length: 1)
                myBleDevice.peripheral.writeValue(data as Data, for: myBleDevice.ledCharacteristic,type:.withResponse)
            case BleJob.ledOff.rawValue:
                print("[\(#function) peripheral]index[\(index)]name:\(peripheral.name ?? "none"),job:LED off")
                var valure: CUnsignedChar = 0x00
                let data: NSData = NSData(bytes: &valure, length: 1)
                myBleDevice.peripheral.writeValue(data as Data, for: myBleDevice.ledCharacteristic,type:.withResponse)
            default:
                print("[\(#function) peripheral]index[\(index)]name:\(peripheral.name ?? "none"),job:unkown=\(myBleDevice.job)")
            }
        }
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
    @IBAction func startAdvertite(_ sender: UIButton) {
        let advertisementData = [CBAdvertisementDataLocalNameKey: "Test Device"]
        let serviceUUID = CBUUID(string: "0000")
        let service = CBMutableService(type: serviceUUID, primary: true)
        let charactericUUID = CBUUID(string: "0001")
        let characteristic = CBMutableCharacteristic(type: charactericUUID, properties: CBCharacteristicProperties.read, value: nil, permissions: CBAttributePermissions.readable)
        service.characteristics = [characteristic]
        self.peripheralManager.add(service)
        peripheralManager.startAdvertising(advertisementData)
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
    
    //  アドバタイズ終了
    @IBAction func stopArvertisement(_ sender: UIButton) {
        print("[\(#function)]")
        peripheralManager.stopAdvertising()
    }
    
    //  service検索開始
    @IBAction func getService(_ sender: UIButton) {
        print("[\(#function)]")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
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
            if service.uuid==LedServiceUUID{
                //print("add[\(index)][\(i)]LedService")
            }else
            if service.uuid==TxPowerServiceUUID{
                print("add[\(index)][\(i)]TxPowerService")
            }else
            if service.uuid==BatteryServiceUUID{
                //print("add[\(index)][\(i)]BatteryService")
            }else
            if service.uuid.uuidString==EnvironmentalServiceUUID.uuidString{
                //print("add[\(index)][\(i)]EnvironmentalService")
            }else
            if service.uuid==GwIdServiceUUID{
                print("add[\(index)][\(i)]gatewayService")
                myBleDevice.add( device:GateWay() )
                if nil == myBleDevice.tag{
                    tagCount += 1
                    myBleDevice.tag = tagCount
                }
            }else
            if service.uuid==IdServiceUUID{
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
        var myBleDevice:MyBleDevice!
        for device in peripherals{
            if device.peripheral==peripheral{
                myBleDevice=device
                break;
            }
            index+=1
        }
        //print("[\(#function)]",terminator:"")
        if let characteristics = service.characteristics {
            print("device[\(index)]sevice:\(service.uuid.uuidString),\(characteristics.count)個のキャラクタリスティックを発見。")
 
            var i=0
            
            for characteritic in characteristics{
                if characteritic.uuid == LedUUID{
                    myBleDevice.ledCharacteristic=characteritic
                }
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
                addOpenButtonButton(peripheral)
            }else{
                print("device[\(index)]=Pinger,Id:\(myBleDevice.id),LED:\(myBleDevice.led),txPower:\(myBleDevice.txPower_db),txInterval:\(myBleDevice.txInterval_ms)")
                if myBleDevice.txInterval_ms != nil && myBleDevice.txPower_db != nil{
                    centralManager.cancelPeripheralConnection(peripheral)
                }
                if nil == myBleDevice.tag {
                    tagCount += 1
                    myBleDevice.tag = tagCount
                }
                addOpenButtonButton(peripheral)
                
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
    
    func action(action:BleAction,tag:Int){
        print("[\(#function)]",terminator:"")
        if nil != peripheralViewController{
            for device in peripherals{
                if device.tag == tag {
                    switch action.rawValue{
                    case BleAction.ledOn.rawValue:
                        device.job=BleJob.ledOn
                        centralManager.connect(device.peripheral, options:nil)
                    case BleAction.ledOff.rawValue:
                        device.job=BleJob.ledOff
                        centralManager.connect(device.peripheral, options:nil)
                    default:
                        print("unknownAction:\(action)")
                    }
                }
            }
        }else{
            print("error peripheralViewController:\(peripheralViewController)")
        }
    }
    func test(){
        print("[\(#function)]")
    }
}

