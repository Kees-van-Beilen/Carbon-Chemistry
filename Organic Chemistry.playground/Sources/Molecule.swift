import Foundation
import UIKit

//A simple data rep. Of the current molocule beign displayed
public class Molecule{
    //All the Carbon atoms in the grid
    public var AtomGrid:[Atom];
    //A number that shows the highest used bus index
    public var moloculbusIndex = 0;
    //a init function because why not
    init(){
        //define one atom in the atom grid
        AtomGrid = [Atom(position: .zero)]
    } 
}

//A simple data rep. of a Carbon Atom  
public struct Atom {
    //identifies each atom 
    var uuid           = UUID();
    //the position in the grid * 100.0f
    var position:CGPoint;
    //the North, East, South &  West bonds [nobond, single, dubbel, hydrogen] 
    var bonds   :[Int] = [3,3,3,3]
    //may branch and bond [no, expand current bus, new branch, dubbelbond]
    var possible:[Int] = [1,1,1,1]
    //identify the branch of wich this Carbon atom is
    var bus     :Int   = 0;
}

public struct Branch {
    var atIndex: Int;
    var atPosition:Int;
    var forBus:Int;
}

public struct DubbelBond {
    var atIndex: Int;
    var atPosition:Int;
}


public struct offset {
    public static var BondWidth:CGFloat  = 6;
    public static var BondLength:CGFloat = 50;
    public static var Hydrogen:CGFloat = 65;
    
    public static var width:[CGFloat] = [
        BondWidth,
        BondLength,
        BondWidth,
        BondLength
    ]
    public static var height:[CGFloat] = [
        BondLength,
        BondWidth,
        BondLength,
        BondWidth,
    ]
    public static var dwidth:[CGFloat] = [
        BondWidth*2,
        BondLength,
        BondWidth*2,
        BondLength
    ]
    public static var dheight:[CGFloat] = [
        BondLength,
        BondWidth*2,
        BondLength,
        BondWidth*2,
    ]
    public static var x:[CGFloat] = [
        22,
        43,
        22,
        -43,
    ]
    public static var y:[CGFloat] = [
        -43,
        22,
        43,
        22,
    ]
    public static var gx:[CGFloat] = [
        0,
        1,
        0,
        -1,
    ]
    public static var gy:[CGFloat] = [
        -1,
        0,
        1,
        0,
    ]
    public static var hx:[CGFloat] = [
        0,
        Hydrogen,
        0,
        -Hydrogen,
    ]
    public static var hy:[CGFloat] = [
        -Hydrogen,
        0,
        Hydrogen,
        0,
    ]
    public static var reverseIndex:[Int] = [
        2,
        3,
        0,
        1
    ]
}

