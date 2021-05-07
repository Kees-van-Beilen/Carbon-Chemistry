import UIKit
import Foundation
extension CGPoint {
    func devide(by:CGFloat)->CGPoint {
        CGPoint(x: self.x/by, y: self.y/by);
    }
    
}

public class MoleculeView: UIView{
    
    public var camera:CGPoint = .zero;
    public var scene:Molecule? = nil;
    public var gridSpacing:CGFloat = 50;
    public var parentViewController:UIViewController? = nil
    public var viewingMode:Int = 0;//0:viewing,1:editing[adding C]
    private var startTouchPosition:CGPoint = .zero;
    
    init(molocule:Molecule,viewController:UIViewController){
        //the init frame size doesn't matter
        super.init(frame: .init(x: 0, y: 0, width: 200, height: 100))
        self.backgroundColor = #colorLiteral(red: 0.1353607475757599, green: 0.1353607475757599, blue: 0.1353607475757599, alpha: 1.0)
        setNeedsDisplay()
        //self.camera = bounds.origin.devide(by: 2);
        self.translatesAutoresizingMaskIntoConstraints=false
        self.scene = molocule;
        self.parentViewController = viewController;
    }
    
    @objc private func clearScene(){
        viewingMode = 0;
        scene = Molecule();
        setNeedsDisplay()
    }
    
    public override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(title: "Clear", image: nil, action: #selector(clearScene), input: "x", modifierFlags: [.command], propertyList: nil, alternates: [], discoverabilityTitle: "Clear the current scene", attributes: .destructive, state: .on)
        ]
    }
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let e = event?.allTouches?.first;
        let _ = startTouchPosition = e?.location(in: self) ?? .zero;
    }
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let e = event?.allTouches?.first;
        //hypot(dx,dy) < touchradius then it was an intended touch
        
        let a = e?.location(in: self) 
        let b = startTouchPosition
        //let dx = b!.x-a!.x
        let radius = hypot(b.x-a!.x,b.y-a!.y);
        //print(radius)
        if(radius>7){return}
        //check if the bottom button has been pressed
        let c = CGPoint(x: bounds.width-60, y: bounds.height-60)
        let buttonRad = hypot(c.x-a!.x,c.y-a!.y);
        let d = CGPoint(x: bounds.width-50, y: bounds.height-120)
        let destroyRad = hypot(d.x-a!.x,d.y-a!.y);
        if(viewingMode==1){
            let _ = buildNewAtoms(point: a!);
        }
        if(buttonRad<35){
            let _ = viewingMode = (viewingMode==0) ? 1:0;
        }
        if(destroyRad<18&&viewingMode==1){
            print("pressed")
            let alert = UIAlertController(title: "Warning", message: "Do you want to clear the scene?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "No", style: UIAlertAction.Style.cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive, handler: { [self] r in
                print("delete")
                viewingMode = 0;
                camera = .zero;
                scene = Molecule()
                let _ = setNeedsDisplay();
            }))
            parentViewController?.present(alert, animated: true, completion: {
                
            })
            //self.presentViewController(alert, animated: true, completion: nil)
            //let _ = viewingMode = (viewingMode==0) ? 1:0;
        }
        
        let _ = setNeedsDisplay();
        
    }
    
    private func postionOfBranchWithBus(n:Int,b:[Branch])->String{
        let origin = b.filter({a in a.forBus == n}).first;
        print(b)
        let bsize  = getBuslength(bus: origin!.forBus);
        var otherS = b.filter({a in getBuslength(bus:a.forBus) == bsize});
        //otherS.append(origin!);
        var rtn = "";
        for branch in otherS {
            rtn += ",\(branch.atPosition)"
        }
        
        rtn.remove(at: rtn.startIndex);
        return rtn
        
    }
    
    private func branchnames(b:[Branch],s:Bool)->String{
        let ubusses = getUniqueBranches(b: b);
        var output = "";
        for bus in ubusses{
            let length = getBuslength(bus: bus);
            let lengthname = OCname.getCNameFor(number: length);
            let amount = b.filter({a in getBuslength(bus:a.forBus) == length}).count;
            let multiname = OCname.getGNameFor(number: amount);
            let positions = postionOfBranchWithBus(n: bus, b: b);
            if(s){
                output+="\(multiname)\(lengthname)yl";
            }else{
                output+="-\(positions)-\(multiname)\(lengthname)yl";
            }
        }
        if(output.hasPrefix("-")){
            output.remove(at: output.startIndex);
        }
        return output;
    }
    
    private func getUniqueBranches(b:[Branch])->[Int]{
        var output:[Int] = [];
        for branch in b {
            let bus = branch.forBus;
            let length = getBuslength(bus: bus);
            var duplicate = false;
            for p in output {
                let plength = getBuslength(bus: p);
                if(plength == length){
                    duplicate = true;
                }
            }
            if(!duplicate){
                output.append(bus)
            }
        }
        return output;
    }
    
    private func getBuslength(bus:Int)->Int{
        scene!.AtomGrid.filter({a in a.bus == bus}).count
    }
    private func getPostFix(showNum:Bool)->String{
        if(scene?.AtomGrid.contains(where: {a in a.bonds.contains(2) == true}) == true){
            let dubblebonds = getDubbelBondOfMain();
            if(showNum){
                var arr:[String] = []
                for b in dubblebonds {
                    arr.append("\(b.atPosition)");
                }
                return "-\(arr.joined(separator: ","))-ene"
            }else{
                return "ene";
            }
            
        }else{
            return "ane"
        }
        
    }
    private func setName() {
        let mainbus = getBusCount(forBus: 0);
        let mainTitle = OCname.getCNameFor(number: mainbus);
        let sTitle = OCname.getCNameFor(number: getBusCount(forBus: 1 ));
        
        let showBranchPosition = mainbus > 3;
        
        let b = getBranchesOfMain();
        let postFix = getPostFix(showNum: showBranchPosition);
        if(sTitle=="zero"){
            parentViewController?.title = mainTitle.capitalizingFirstLetter() + postFix;
        }else{
            let prefixBranch = branchnames(b: b, s: !showBranchPosition);
            
            parentViewController?.title = "\(prefixBranch)\(mainTitle)\(postFix)";
            //alkanen aan: ane
            //alkenen een: ylene / ene
        }
        
    }
    
    private func getDubbelBondOfMain()->[DubbelBond]{
        //first decide all atoms that are part of main
        let main = scene!.AtomGrid.filter({a in a.bus == 0})
        //now get the index of the first starting atom
        let startIndex = main.firstIndex(where: {a in a.bonds.filter({b in b==1||b==2}).count == 1});
        
        //print("c->",main.count)
        var ignore = -1;
        var currentindex = startIndex!;
        var inTrain = 1;
        var branches:[DubbelBond] = [];
        //print("--start--")
        for i in (0...main.count-1) {
            let a:Atom = main[currentindex];
            //print("next-->",inTrain,a)
            let doesBranch = a.bonds.filter({b in b==1||b==2}).count > 2;
            //print(a.bonds)
            for index in (0...3){
                let b = a.bonds[index];
                //print(b,index);
                if((b==1||b==2)&&index != ignore){
                    //print("ad",index,offset.reverseIndex[index])
                    let p = grow(position: a.position, index: index)
                    let t = atomAt(position: p);
                    if(t?.bus != 0){continue}
                    ignore = offset.reverseIndex[index];
                    let lf = atomAt(position: p);
                    let li = main.firstIndex(where: {q in q.uuid == lf!.uuid});
                    currentindex = li!;
                    
                    if(b==2){
                        
                        branches.append(DubbelBond(atIndex: index, atPosition: inTrain))
                    }
                    inTrain+=1;
                    break;
                    //print("t->",inTrain)
                }
            }
        }
        return branches;
        
    }
    
    
    private func getBranchesOfMain()->[Branch]{
        //first decide all atoms that are part of main
        let main = scene!.AtomGrid.filter({a in a.bus == 0})
        //now get the index of the first starting atom
        let startIndex = main.firstIndex(where: {a in a.bonds.filter({b in b==1||b==2}).count == 1});
        
        //print("c->",main.count)
        var ignore = -1;
        var currentindex = startIndex!;
        var inTrain = 1;
        var branches:[Branch] = [];
        //print("--start--")
        for i in (0...main.count-1) {
            let a:Atom = main[currentindex];
            //print("next-->",inTrain,a)
            let doesBranch = a.bonds.filter({b in b==1||b==2}).count > 2;
            //print(a.bonds)
            if(!doesBranch){
                var btoi = 0;
                //print("ignore-->",ignore)
                for index in (0...3){
                    let b = a.bonds[index];
                    //print(b,index);
                    if((b==1||b==2)&&index != ignore){
                        //print("ad",index,offset.reverseIndex[index])
                        let lf = atomAt(position: grow(position: a.position, index: index));
                        let li = main.firstIndex(where: {q in q.uuid == lf!.uuid});
                        currentindex = li!;
                        ignore = offset.reverseIndex[index];
                        print(ignore)
                        inTrain+=1;
                        break;
                        //print("t->",inTrain)
                    }
                }
                //print(a.position)
                continue
                
            }
            //print(a.position)
            var trainForwarded = false;
            inTrain+=1;
            var b1 = -1;
            var b2 = -1;
            for index in (0...3) {
                let bond = a.bonds[index]
                let npos = grow(position: a.position, index: index);
                let na = atomAt(position: npos);
                if((na) != nil){
                    if(na?.bus != 0){
                        branches.append(Branch(atIndex: (scene?.AtomGrid.firstIndex(where: {ea in ea.uuid == na?.uuid}))!, atPosition: inTrain-1, forBus: na!.bus))
                        if(!trainForwarded){
                            //inTrain+=1;
                            trainForwarded=true;
                        }
                        if(b1 == -1){
                            b1 = index;
                        }else{
                            b2 = index;
                        }
                        
                    }else{
                        
                    }
                }
            }
            for index in (0...3) {
            if(index != ignore && index != b1 && index != b1 && a.bonds[index] == 1){
                //print("ad2",bindex,ignore,index,grow(position: a.position, index: bindex))
                let lf = atomAt(position: grow(position: a.position, index: index));
                if(lf==nil){continue}
                let li = main.firstIndex(where: {q in q.uuid == lf!.uuid});
                if(li==nil){continue}
                currentindex = li!;
                ignore = offset.reverseIndex[index];
                //print(ignore)
                //inTrain+=1;
                break;
                //print("t->",inTrain)
            }
                
            }
            //let branchindexS = a.bonds.firstIndex(of: <#T##Int#>)
        }
        print(branches)
        return branches;
        
    }
    
    private func getBusCount(forBus:Int)->Int{
        var i:Int = 0;
        for atom in scene!.AtomGrid {
            //print("",atom.bus)
            if(atom.bus==forBus){i+=1}
        }
        return i;
    }
    
    private func buildNewAtoms(point:CGPoint){
        let b = bounds.size;
        for atom in scene!.AtomGrid {
            for index in (0...3) {
//                  let h = CGRect(
//                      x:
//                          atom.position.x+camera.x+b.width/2-15+offset.hx[index],
//                      y: atom.position.y+camera.y+b.height/2-15+offset.hy[index],
//                      width: 30, 
//                      height: 30)
                let bond = atom.bonds[index];
                var newpos = atom.position;
                newpos.x += offset.gx[index]*100;
                newpos.y += offset.gy[index]*100;
                let x = atom.position.x+camera.x+b.width/2-15+offset.hx[index];
                let y = atom.position.y+camera.y+b.height/2-15+offset.hy[index];
                
                let bx = atom.position.x+camera.x+b.width/2-25+offset.x[index]
                let by = atom.position.y+camera.y+b.height/2-25+offset.y[index]
                
                if(point.x>bx&&point.y>by&&point.x<bx+30&&point.y<by+30&&atom.possible[index] == 3){
                    //dubbel bond
                    print("doing it")
                    let index2 = scene?.AtomGrid.firstIndex(where: { a in a.uuid == atom.uuid})
                    let p = grow(position: atom.position, index: index)
                    let index3 = scene?.AtomGrid.firstIndex(where: { a in a.position == p})
                    scene?.AtomGrid[index2!].bonds[index] = 2;
                    scene?.AtomGrid[index3!].bonds[offset.reverseIndex[index]] = 2;
                    scene?.AtomGrid[index2!].possible[index] = 0;
                    scene?.AtomGrid[index3!].possible[offset.reverseIndex[index]] = 0;
                    let fhi = scene?.AtomGrid[index2!].bonds.firstIndex(of: 3);
                    let shi = scene?.AtomGrid[index3!].bonds.firstIndex(of: 3);
                    if(fhi != nil){
                        scene?.AtomGrid[index2!].bonds[fhi!] = 0;
                        scene?.AtomGrid[index2!].possible[fhi!] = 0;
                    }
                    if(shi != nil){
                        scene?.AtomGrid[index3!].bonds[shi!] = 0;
                        scene?.AtomGrid[index3!].possible[shi!] = 0;
                    }
                    
                    
                    
                    //playground mistake
                    //let _ = replaceCovalent(id: atom.uuid, bonds: prevBonds)
                    //playground shit ahh
                    //let _ = definePosible()
                    //let _ = definePosible()
                    //let _ = setName()
                    //print(prevBonds)
                    let _ = setName()
                    continue;
                }
                
                if(point.x>x&&point.y>y&&point.x<x+30&&point.y<y+30&&atom.possible[index] != 0&&atom.possible[index] != 3){
                    
                    var a = Atom(position: newpos);
                    a.bonds[offset.reverseIndex[index]] = 1;
                    if(atom.bus==0&&atom.possible[index]==2){
                        scene?.moloculbusIndex+=1;
                        a.bus = scene!.moloculbusIndex;
                    }else{
                        a.bus=atom.bus;
                    }
                    scene!.AtomGrid.append(a)
                    var prevBonds = atom.bonds;
                    prevBonds[index] = 1;
                    //playground mistake
                    let _ = replaceCovalent(id: atom.uuid, bonds: prevBonds)
                    //playground shit ahh
                    let _ = definePosible()
                    //let _ = definePosible()
                    let _ = setName()
                    //print(prevBonds)
                }
            }
        }
        
        
    }
    
    public func definePosible(){
        let b = getBranchesOfMain();
        for atom in scene!.AtomGrid {
            for index in (0...3){
                let bond = atom.bonds[index];
                var postion = atom.position;
                postion.x += offset.gx[index]*100;
                postion.y += offset.gy[index]*100;
                //playground mistake ↓↓↓↓↓
                let _ = setPosible(id: atom.uuid, postion: postion,index:index,b:b)
            }
        }
    }
    
    public func replaceCovalent(id:UUID,bonds:[Int]){
        //for atom in scene!.AtomGrid where atom.uuid == id
        guard let index =  scene!.AtomGrid.firstIndex(where: {a in a.uuid == id}) else { return  };
        //print(index)
        scene!.AtomGrid[index].bonds = bonds;
    }
    
    public func checkNeighboorCountAt(position:CGPoint)->Int{
        let g  = scene!.AtomGrid;
        let p0 = grow(position: position, index: 0);
        let p1 = grow(position: position, index: 1);
        let p2 = grow(position: position, index: 2);
        let p3 = grow(position: position, index: 3);
        let c0 = g.contains(where: {a in a.position == p0})
        let c1 = g.contains(where: {a in a.position == p1})
        let c2 = g.contains(where: {a in a.position == p2})
        let c3 = g.contains(where: {a in a.position == p3})
        
        return (c0 ? 1 : 0)+(c1 ? 1 : 0)+(c2 ? 1 : 0)+(c3 ? 1 : 0)
    }
    
    public func atomAt(position:CGPoint)->Atom?{
        scene!.AtomGrid.first(where: {a in a.position == position});
    }
    
    public func grow(position:CGPoint,index:Int)->CGPoint{
        var p = position;
        p.x += offset.gx[index]*100;
        p.y += offset.gy[index]*100;
        return p;
    }
    
    
    public func setPosible(id:UUID,postion:CGPoint,index:Int,b:[Branch]){
        guard let aindex =  scene!.AtomGrid.firstIndex(where: {a in a.uuid == id}) else { return  };
        let p = scene!.AtomGrid[aindex].position;
        let atomAtPos = scene!.AtomGrid.contains(where: {a in
            return a.position == postion
            
        });
        //check if your branching out
        let branch = checkNeighboorCountAt(position: p);
        //the amount of C atoms that willneighbour this pos
        let n = checkNeighboorCountAt(position: postion);
        //you canot branch out further than youre relative branch position
        //aka yes:   no:
        //    o      o
        //  o-o-o    o
        //         o-o-o
//          if(!atomAtPos&&scene!.AtomGrid[aindex].bus != 0){
//              print("FUCK",n)
//              scene!.AtomGrid[aindex].possible[index] = 1;
//          }
        
        if(atomAtPos||n>1){
            scene!.AtomGrid[aindex].possible[index] = 0;
            if(scene!.AtomGrid[aindex].bus==0&&atomAtPos){
                //check if both of the atoms have spare hydrogen
                
                let ae:Atom = atomAt(position: postion)!;
                if(scene!.AtomGrid[aindex].bonds.contains(3) && ae.bonds.contains(3)&&ae.bus==0){
                    if(scene!.AtomGrid[aindex].bonds[index] != 2){
                        scene!.AtomGrid[aindex].possible[index] = 3;
                    }else{
                        scene!.AtomGrid[aindex].possible[index] = 0;
                    }
                    
                }
            }
        }else if(branch==2&&scene!.AtomGrid[aindex].bus==0){
            scene!.AtomGrid[aindex].possible[index] = 2;
        }
        if(branch==2&&scene!.AtomGrid[aindex].bus != 0){
            scene!.AtomGrid[aindex].possible[index] = 0;
        }
        if(scene!.AtomGrid[aindex].bus != 0){
            let branchB = b.first(where: {d in d.forBus == scene!.AtomGrid[aindex].bus});
            if(branchB==nil){
                //print("----->",scene!.AtomGrid[aindex]);
                //scene!.AtomGrid[aindex].bus = 0;
                //scene!.AtomGrid[aindex].possible[index] = 0;
                return;
                
            }
            let mainLength = getBuslength(bus: 0);
            var maxchain:Int = branchB!.atPosition - 1;
            if(branchB!.atPosition > mainLength/2){
                maxchain = mainLength - branchB!.atPosition
                
            }
            //print("maxChain--->",maxchain)
            if(getBusCount(forBus: branchB!.forBus) >= maxchain){
                scene!.AtomGrid[aindex].possible[index] = 0;
            }else if(!atomAtPos&&n==1){
                scene!.AtomGrid[aindex].possible[index] = 1;
                
            }
        }
        
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        do{
            let e = event?.allTouches!.first;
            let a = e?.location(in: self) 
            let b = e?.previousLocation(in: self);
            camera.x += a!.x-b!.x;
            camera.y += a!.y-b!.y;
            //do not log expensive progresses just redraw the view
            let _ = setNeedsDisplay()
        }catch{
            print("eerror")
        }
        //
        
        
        
    }
    
    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let b =  bounds.size
        //fix any height skewing
        
        //context.scaleBy(x: 0.5, y: 0.5)
        context.setFillColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
        // 3
        
        
        
        for atom in scene!.AtomGrid {
            let s:CGFloat = 50.0;
            context.setFillColor(#colorLiteral(red: 0.9992327094078064, green: 1.000091791152954, blue: 0.9992955327033997, alpha: 1.0))
            
            let t = CGRect(
                x: atom.position.x+camera.x+b.width/2-s/2,
                y: atom.position.y+camera.y+b.height/2-s/2,
                width: s, 
                height: s)
            if(atom.bus != 0){
                context.setStrokeColor(#colorLiteral(red: 0.26514732837677, green: 0.26514732837677, blue: 0.26514732837677, alpha: 1.0));
                context.setFillColor(#colorLiteral(red: 0.7540718913078308, green: 0.7540718913078308, blue: 0.7540718913078308, alpha: 1.0))
                context.strokeEllipse(in: t);
            }
            context.fillEllipse(in: t)
            
            
            NSString("C").draw(at: CGPoint(
                                x: atom.position.x+camera.x+b.width/2-s/2+14, 
                                y: atom.position.y+camera.y+b.height/2-s/2+2), withAttributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.1353607475757599, green: 0.1353607475757599, blue: 0.1353607475757599, alpha: 1.0), NSAttributedString.Key.font:UIFont(name: "KhmerSangamMN", size: 30)]);
            for index in (0...3) {
                //if(bond==0){continue}
                let bond = atom.bonds[index];
                let mayBranch = atom.possible[index];
                context.setFillColor(#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
                if(atom.bus != 0){
                    context.setFillColor(#colorLiteral(red: 0.7540718913078308, green: 0.7540718913078308, blue: 0.7540718913078308, alpha: 1.0))
                }else if(viewingMode == 1&&mayBranch==3){
                    context.setFillColor(#colorLiteral(red: 0.0, green: 0.3389558792, blue: 0.8385549188, alpha: 1.0))
                }
                if(bond==0){continue}
                if(!(bond==3&&viewingMode==1)){
                    let width = (bond == 2) ? offset.dwidth : offset.width;
                    let height = (bond == 2) ? offset.dheight : offset.height;
                    let xd:CGFloat = (bond == 2) ? 3 : 0; 
                    let yd:CGFloat = (bond == 2) ? 3 : 0; 
                    context.fill(CGRect(x: atom.position.x+camera.x+b.width/2-s/2+offset.x[index]-xd, y: atom.position.y+camera.y+b.height/2-s/2+offset.y[index]-yd,width: width[index], height: height[index]))
                    if(bond==2){
                        context.setFillColor(#colorLiteral(red: 0.1353607475757599, green: 0.1353607475757599, blue: 0.1353607475757599, alpha: 1.0))
                        context.fill(CGRect(x: atom.position.x+camera.x+b.width/2-s/2+offset.x[index], y: atom.position.y+camera.y+b.height/2-s/2+offset.y[index],width: offset.width[index], height: offset.height[index]))
                    }
                }
                if(bond != 3){continue}
                
                
                let h = CGRect(
                    x: atom.position.x+camera.x+b.width/2-30/2+offset.hx[index],
                    y: atom.position.y+camera.y+b.height/2-30/2+offset.hy[index],
                    width: 30, 
                    height: 30)
                context.setStrokeColor(#colorLiteral(red: 0.9214347004890442, green: 0.9214347004890442, blue: 0.9214347004890442, alpha: 1.0))
                context.setFillColor(#colorLiteral(red: 0.1353607475757599, green: 0.1353607475757599, blue: 0.1353607475757599, alpha: 1.0))
                var textHydrogen = "H";
                if(viewingMode==1){
                    context.setFillColor(#colorLiteral(red: 0.0, green: 0.3389558792, blue: 0.8385549188, alpha: 1.0))
                    textHydrogen = "+";
                    if(mayBranch==0){continue}
                    if(mayBranch==2&&atom.bus==0){
                        context.setFillColor(#colorLiteral(red: -0.2883068323135376, green: 0.8962136507034302, blue: 0.4389599561691284, alpha: 1.0))
                        textHydrogen = "B";
                    }
                }
                context.fillEllipse(in: h)
                context.setLineWidth(2)
                context.strokeEllipse(in: h)
                NSString(string: textHydrogen).draw(at: CGPoint(
                                    x: atom.position.x+camera.x+b.width/2-30/2+offset.hx[index]+10, 
                                    y: atom.position.y+camera.y+b.height/2-30/2+offset.hy[index]+4), withAttributes: [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.9214347004890442, green: 0.9214347004890442, blue: 0.9214347004890442, alpha: 1.0), NSAttributedString.Key.font:UIFont(name: "KhmerSangamMN", size: 15)]);
                
                
            }
        }
        
        //ui
        //context.setFillColor(#colorLiteral(red: 0.0, green: 0.3389558792, blue: 0.8385549188, alpha: 1.0))
        if viewingMode==1 {
            context.setStrokeColor(#colorLiteral(red: 0.0, green: 0.2595015466, blue: 0.6651419401, alpha: 1.0))
            context.setLineWidth(10)
            context.stroke(bounds)
        }
        
        
        context.setFillColor(#colorLiteral(red: 0.9214347004890442, green: 0.9214347004890442, blue: 0.9214347004890442, alpha: 1.0))
        //context.fill(bounds);
        //context.setFontSize(100)
        NSString(string: (viewingMode==0) ? "􀈌":"􀁡").draw(at: CGPoint(x: b.width-100, y: b.height-100), withAttributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font:UIFont(name: "KhmerSangamMN", size: 67)]);
        NSString(string: (viewingMode==0) ? "":"􀈓").draw(at: CGPoint(x: b.width-70, y: b.height-150), withAttributes: [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font:UIFont(name: "KhmerSangamMN", size: 37)]);
        
        
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

