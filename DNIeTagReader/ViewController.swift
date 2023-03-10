//
//  ViewController.swift
//  DNIeTagReader
//
//  Created by Ronald Ricardo Martinez Chunga on 10/03/23.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var TextView: UITextView!
    
    @IBOutlet weak var TextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Looks for single or multiple taps.
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @IBAction func setText(_ sender: UIButton) {
        print("set text !!!")
        let mText = TextField.text
        TextView.text = mText
    }
    
    @IBAction func appendText(_ sender: UIButton) {
        print("append text !!!")
        let mText = TextField.text
        TextView.text += mText ?? ""
    }
}
