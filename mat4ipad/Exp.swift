//
//  Exp.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation

protocol item {
    
}
enum Err:Error {
    case stackisempty
    case unknownArith
}

protocol Exp: item {
    func latex() -> String;
}
protocol BinaryOp:Exp {
    var a: Exp { get }
    var b: Exp { get }
}
struct Mul:BinaryOp {
    var a: Exp
    
    var b: Exp
    
    func latex() -> String {
        return "{\(a.latex())} * {\(b.latex())}"
    }
}
struct Mat:Exp {
    func latex() -> String {
        let inner = elements.map({ $0.map({"{\($0.latex())}"}).joined(separator: " & ") }).joined(separator: "\\\\\n")
        return "\\begin{pmatrix}\n" + inner + "\n\\end{pmatrix}"
    }
    
    var elements:[[Exp]];
}
struct Unassigned:Exp {
    func latex() -> String {
        return letter
    }
    
    var letter:String
    
}
