
import UIKit

public class ApplicationViewController:UIViewController{
    
    public var scene:Molecule? = nil;
    
    override public func viewDidLoad() {
        title = "Methaan";
        
        self.scene = Molecule()
        view = MoleculeView(molocule: scene!,viewController: self)
    }
    override public func viewWillLayoutSubviews() {
        view.setNeedsDisplay()
    }
    @objc public func clearScene(){
        self.scene = Molecule();
        view.setNeedsDisplay()
    }
    
    
    
    
}
