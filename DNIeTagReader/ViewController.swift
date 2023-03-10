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
        // Do any additional setup after loading the view.
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
