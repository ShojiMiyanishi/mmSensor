//
//  PeripheralViewController.swift
//  mmSensor
//
//  Created by 宮西 昭次 on H29/12/22.
//  Copyright © 平成29年 宮西 昭次. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

class PeripheralViewController:
    UIViewController,
    CBPeripheralManagerDelegate,
    CBCentralManagerDelegate
{
    weak var delegate:BleDelegate!
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!

    enum buttonTag:Int{
        case scanStart = 1
        case ledOn
        case ledOff
        case test
    }
    
    var myBleDevice:MyBleDevice!
   
    var lastPositionY:CGFloat=100
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        let backButton = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 100,height:100))
        backButton.setTitleColor(UIColor.black ,for: .normal)
        backButton.setTitle("戻る", for: .normal)
        backButton.sizeToFit()
        backButton.backgroundColor = UIColor.lightGray
        backButton.addTarget(self, action: #selector(PeripheralViewController.back(_:)), for: .touchUpInside)
        view.addSubview(backButton)
        lastPositionY += backButton.frame.height*2
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /*
     *  元のviewに戻る
     *  selectorで呼び出す場合Swift4からは「@objc」をつける。
     */
    @objc func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
     * labelの作成、削除
     */
     func addLabel(_ text:String){
        let label = UILabel()
        label.text = text
        label.sizeToFit()
        label.center.y = lastPositionY
        view.addSubview(label)
        lastPositionY += label.frame.height * 1.4
    }
    /*
     * ボタンの作成
     */
    func addButton(_ text:String ,tag:buttonTag!){
        let button = UIButton(frame: CGRect(x: 0,y: lastPositionY,width: 100,height:100))
        button.setTitle(text, for: .normal)
        button.sizeToFit()
        lastPositionY += ( button.frame.height * 0.5 )
        button.center.y = lastPositionY
        button.backgroundColor = UIColor.gray
        if nil != tag {
            button.tag=tag!.rawValue
        }
        button.addTarget(self, action: #selector(PeripheralViewController.buttonCallback(_:)), for: .touchUpInside)
        
        view.addSubview(button)
        lastPositionY += ( button.frame.height * 1.9 )
    }

    /*
     * 一時labelの作成、削除
     */
     var startPositionY:CGFloat!
     var lastPositionY2:CGFloat!
     func add2Label(_ text:String){
        let label = UILabel()
        label.text = text
        label.sizeToFit()
        if let y = lastPositionY2 {
            label.center.y = y
            view.addSubview(label)
            lastPositionY2 = y + label.frame.height * 1.4
        }
    }
    @objc func buttonCallback(_ sender: UIButton){
        print("[\(#function)]tag:\(sender.tag)")
        switch sender.tag{
        case buttonTag.scanStart.rawValue:
            startPositionY=lastPositionY
            lastPositionY2=startPositionY
            add2Label("start  wifi scan.")
            delegate?.action( action: BleAction.startScan , tag: myBleDevice.tag )
        case buttonTag.ledOn.rawValue:
            print("start connect fot LED on")
            startPositionY=lastPositionY
            lastPositionY2=startPositionY
            add2Label("start  led On.")
            myBleDevice.job=BleJob.ledOn
            centralManager.connect(myBleDevice.peripheral, options: nil)
        case buttonTag.ledOff.rawValue:
            print("start connect fot LED off")
            startPositionY=lastPositionY
            lastPositionY2=startPositionY
            add2Label("start  led Off.")
            myBleDevice.job=BleJob.ledOn
            centralManager.connect(myBleDevice.peripheral, options: nil)
            
        case buttonTag.test.rawValue:
            delegate?.test()
        default:
            print("tag:\(sender.tag)")
        }
    }
    func updateScan(){
        print("[\(#function)]")
        add2Label("updateScan")
    }
    func updateView(device:MyBleDevice){
        myBleDevice=device
        
        let peripheral=myBleDevice.peripheral
        var name = "デバイス名 : " + (peripheral.name ?? "no name")
        name += " ID : " + myBleDevice.id + "  "

        addLabel( name )
        
        if nil != myBleDevice.txPower_db{
            addLabel("BLE送信出力："+String(myBleDevice.txPower_db)+" dbm ")
        }
        if nil != myBleDevice.txInterval_ms{
            addLabel("BLE送信間隔："+String(myBleDevice.txInterval_ms/1000)+" 秒")
        }
        if nil != myBleDevice.gateway{
            addButton("LED オン", tag: buttonTag.ledOn)
            addButton("LED オフ", tag: buttonTag.ledOff)
            addButton("WiFi スキャン開始", tag: buttonTag.scanStart)
            addButton("test", tag: buttonTag.test)
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
        print("[\(#function)]",terminator:"")
        switch central.state{
        case .poweredOn:
            print(".poweredOn")
        case .poweredOff:
            print(".poweredOff")//インターフェースがオフになっている
        default:
            print("unkown state: \(central.state)")
        }
    }
    //  ペリフェラルのStatusが変化した時に呼ばれる
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("[\(#function)]",terminator:"")
        print("periState\(peripheral.state)")
    }
    //  接続成功時に呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[\(#function)]")
        if peripheral==myBleDevice.peripheral {
            if nil != myBleDevice.job{
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
        }else{
            print("connected wrong device")
            return
        }
    }

}
