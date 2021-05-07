
public struct OCname {
    public static let compound = [
        "zero",
        "meth",
        "eth",
        "prop",
        "but",
        "pent",
        "hex",
        "hept",
        "oct",
        "non",
        "dec",
        "undec",
        "dodec",
        "tridec",
        "tetradec",
        "pentadec",
        "hexadec",
        "heptadec",
        "octadec",
        "nonadec",
        "eicosan",
    ]
    public static let compoundgroup = [
        "",
        "",//should be mono but who cares
        "di",
        "tri",
        "tetra",
        "penta",
        "hexa",
        "hepta",
        "octo",
        "ennea",
        "deca"
    ]
    public static func getGNameFor(number:Int)->String{
        if(number>10){
            return "multi"
        }else{
            return OCname.compoundgroup[number];
        }
    }
    public static func getCNameFor(number:Int)->String{
        if(number>19){
            return "multi"
        }else{
            return OCname.compound[number];
        }
    }
} 
