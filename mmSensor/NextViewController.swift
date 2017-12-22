//
//  NextViewController.swift
//  mmSensor
//
//  Created by 宮西 昭次 on H29/12/19.
//  Copyright © 平成29年 宮西 昭次. All rights reserved.
//

import UIKit
import CoreBluetooth

class NextViewController: UIViewController{
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        let backButton = UIButton(frame: CGRect(x: 0,y: 0,width: 100,height:100))
        backButton.setTitleColor(UIColor.black ,for: .normal)
        backButton.setTitle("戻る", for: .normal)
        backButton.backgroundColor = UIColor.white
        backButton.addTarget(self, action: #selector(NextViewController.back(_:)), for: .touchUpInside)
        view.addSubview(backButton)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // selectorで呼び出す場合Swift4からは「@objc」をつける。
    @objc func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }    
}
