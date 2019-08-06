//
//  CodeDiyGroupModel.swift
//  CodeDemo
//
//  Created by 彭积利 on 2019/7/31.
//  Copyright © 2019 doubleflyer. All rights reserved.
//

import Foundation

public class CodeDiyGroupModel: Codable {
    var groupId = ""
    var groupCreateTime = ""
    var groupUserTime = ""
    var groupImg = ""
    var seriesGroup:[CodeDiyModel] = []
}

public class CodeDiyModel: Codable {
    var groupId = ""
    var diyId = ""
    var createTime = ""
    var useTime = ""
    var diyLock = ""
    var unlockWay = ""
    var imgIcon = ""
    var bigBorderIcon = ""
    var smallBorderIcon = ""
    var diyElement:[CodeDiyImageModel]  = []
}

public class CodeDiyImageModel: Codable {
    var imgWidth: String = ""
    var imgHeight: String = ""
    var imgUrl: String = ""
}
