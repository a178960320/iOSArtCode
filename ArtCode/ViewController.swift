//
//  ViewController.swift
//  ArtCode
//
//  Created by 彭积利 on 2019/8/6.
//  Copyright © 2019 zqbily. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var imageV: UIImageView!
    var codeModel:CodeDiyGroupModel = CodeDiyGroupModel()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getDiyData()
    }
    
    fileprivate func getDiyData(){
        guard let path = Bundle.main.path(forResource: "group_one", ofType: "json") else{return}
        let data = try! Data.init(contentsOf: URL.init(fileURLWithPath: path))
        
        codeModel = try! JSONDecoder().decode(CodeDiyGroupModel.self, from: data)
       
        if let image = ArtCodeTool.getArtCodeImage(content: "哈哈哈哈", style: codeModel.seriesGroup.first!){
            imageV.image = UIImage.init(cgImage: image)
        }
        
    }

}

