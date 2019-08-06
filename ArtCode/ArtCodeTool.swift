//
//  ArtCodeTool.swift
//  ArtCode
//
//  Created by 彭积利 on 2019/8/6.
//  Copyright © 2019 zqbily. All rights reserved.
//

import UIKit

public enum InputCorrectionLevel: Int {
    case l = 0     // L 7%
    case m = 1     // M 15%
    case q = 2     // Q 25%
    case h = 3     // H 30%
}

class ArtCodeTool {
    static public func getArtCodeImage(content:String,style:CodeDiyModel) -> CGImage?{
        guard let codes = getPixels(content: content, inputCorrectionLevel: .m) else{
            print("getPixels error")
            return nil
        }
        
        let codeSize = codes.count
        let imageSize = CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.width * 2)
        
        let scaleX = imageSize.width / CGFloat(codeSize)
        let scaleY = imageSize.height / CGFloat(codeSize)
        if scaleX < 1.0 || scaleY < 1.0 {
            print("Warning: Size too small.")
        }
        
        var result: CGImage?
        let context = CGContext(
            data: nil, width: Int(imageSize.width), height: Int(imageSize.height),
            bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        
        if let context = context {
    
            // Image
            // 单位点
            var icons = [CodeDiyImageModel]()
            // 定位点
            var positions = [CodeDiyImageModel]()
            // 其他素材
            var others = [CodeDiyImageModel]()
            
            for item in style.diyElement{
                if item.imgWidth == "7" && item.imgHeight == "7"{
                    positions.append(item)
                }else if item.imgWidth == "1" && item.imgHeight == "1"{
                    icons.append(item)
                }else{
                    others.append(item)
                }
            }
            
            //计算矩阵中2 * 2的数量
            let rows = others
                .map{(Int($0.imgWidth)!,Int($0.imgHeight)!)}
                .sorted{$0.0 * $0.1 > $1.0 * $0.1}
            let matrixs = MatrixExt.findAllMatrix(array: codes,rows:rows)
            for indexY in 0 ..< codeSize {
                for indexX in 0 ..< codeSize where codes[indexX][indexY] {
                    // CTM-90
                    let indexXCTM = indexY
                    let indexYCTM = codeSize - indexX - 1
                    
                    //剔除 矩阵、定位点 等点的绘制
                    if (indexX <= 7 && indexY <= 7) || (indexX >= codeSize - 8 && indexY <= 7) || (indexX <= 7 && indexY >= codeSize - 8) || matrixs.contains{$0.contains{$0.2.x == indexY && $0.2.y == indexX}}{
                        continue
                    }
                    
                    let randomOne = Int(arc4random_uniform(UInt32(icons.count - 1)))
                    let image = UIImage(named: icons[randomOne].imgUrl)
                    
                    context.draw(image!.cgImage!, in: CGRect(
                        x: CGFloat(indexXCTM) * scaleX ,
                        y: CGFloat(indexYCTM) * scaleY ,
                        width: scaleX,
                        height: scaleY
                    ))
                }
            }
            
            //对应大小图片替换对应矩阵
            for item in matrixs{
                let rect = CGRect.init(x: CGFloat(item[0].2.x) * scaleX, y: CGFloat(codeSize - item[0].2.y - item[0].1) * scaleY, width: scaleX * CGFloat(item[0].0), height: scaleY * CGFloat(item[0].1))
                
                let canUseArray = others.filter{Int($0.imgWidth) == item[0].0 && (Int($0.imgHeight) == item[0].1)}
                let randomOne = arc4random_uniform(UInt32(canUseArray.count - 1))
                let image = UIImage.init(named:canUseArray[Int(randomOne)].imgUrl)!.cgImage!
                
                context.draw(image, in: rect)
            }
            
            for i in 0..<3{
                let rect = CGRect(x:i == 0 ? scaleX : i == 1 ? scaleX : CGFloat(codes.count - 8) * scaleX,
                                  y: i == 0 ? scaleY : CGFloat(codes.count - 8) * scaleY,
                                  width: 7 * scaleX,
                                  height: 7 * scaleY)
                var image:UIImage!
                if i < positions.count{
                    image = UIImage.init(named: positions[i].imgUrl)
                }else{
                    image = UIImage.init(named: positions.last!.imgUrl)
                }
                
                context.draw(image.cgImage!, in: rect)
            }
            
            result = context.makeImage()
        }
        return result
    }
    
    //MARK: - 生成二维数组
    private static func getPixels(content:String,inputCorrectionLevel:InputCorrectionLevel) -> [[Bool]]? {
        
        guard let ciImage = createQRCode(string: content, inputCorrectionLevel: inputCorrectionLevel),let tryQRImage = CIContext().createCGImage(ciImage, from: ciImage.extent) else {
                print("Warning: Content too large.")
                return nil
        }
        let width = tryQRImage.width
        let height = tryQRImage.height
        let dataSize = width * height * 4
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 4 * width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                return nil
        }
        context.draw(tryQRImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let pixels: [[Bool]] = ( 0 ..< height ).map { y in
            ( 0 ..< width ).map { x in
                let offset = 4 * (x + y * width)
                let red = pixelData[offset + 0]
                let green = pixelData[offset + 1]
                let blue = pixelData[offset + 2]
                return red == 0 && green == 0 && blue == 0
            }
        }
        
        return pixels
    }
    
    /// Create QR CIImage
    private static func createQRCode(string: String, inputCorrectionLevel: InputCorrectionLevel = .m) -> CIImage? {
        let stringData = string.data(using: .utf8)
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        qrFilter.setValue(stringData, forKey: "inputMessage")
        qrFilter.setValue(["L", "M", "Q", "H"][inputCorrectionLevel.rawValue], forKey: "inputCorrectionLevel")
        return qrFilter.outputImage
    }
}


//MARK: - Matrix
class MatrixExt {
    /// 寻找所有值为True 所有子矩阵
    ///
    /// - Parameters:
    ///   - array: 数据
    ///   - rows: 子矩阵数组
    /// - Returns: 所有符合图片填充子矩阵
    static func findAllMatrix(array:[[Bool]],rows:[(Int,Int)]) ->[[(Int,Int,One)]] {
        var allOneArray:[One] = []
        var returnOneArray:[[(Int,Int,One)]] = []
        for (y,item) in array.enumerated(){
            for (x,obj) in item.enumerated(){
                if obj{
                    if (x <= 7 && y <= 7) || (x >= item.count - 8 && y <= 7) || (x <= 7 && y >= item.count - 8){
                        continue
                    }
                    let one = One(x: x, y: y)
                    allOneArray.append(one)
                }
            }
        }
        
        for one in allOneArray{
            for row in rows{
                var isContain = true
                var oneArray:[(Int,Int,One)] = []
                for i in 0..<row.0{
                    for j in 0..<row.1{
                        let contain = allOneArray.contains{$0.x == one.x + i && $0.y == one.y + j}
                        isContain  = isContain && contain
                        if contain{
                            oneArray.append((row.0,row.1,One.init(x: one.x + i, y: one.y + j )))
                        }
                    }
                }
                //如果包含row * col矩阵
                if isContain{
                    allOneArray.removeAll { (one) -> Bool in
                        return oneArray.contains{$0.2.x == one.x && $0.2.y == one.y}
                    }
                    returnOneArray.append(oneArray)
                }
            }
        }
        
        return returnOneArray
    }
}

struct One {
    var x:Int
    var y:Int
    
    init(x:Int,y:Int) {
        self.x = x
        self.y = y
    }
}
