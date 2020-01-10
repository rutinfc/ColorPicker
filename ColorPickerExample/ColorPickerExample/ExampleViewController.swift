//
//  ExampleViewController.swift
//  ColorPicker
//
//  Created by rutinfc on 2020/01/08.
//  Copyright © 2020 rutinfc. All rights reserved.
//

import UIKit
import ColorPicker

enum ColorType : Int {
    case primary, complementary, blackWhite, harmoney1, harmoney2, none
    
    func toTitle() -> String {
        switch self {
        case .primary:
            return "Primary"
        case .complementary:
            return "Complementary"
        case .blackWhite: 
            return "Black or White"
        case .harmoney1:
            return "Harmoney1"
        case .harmoney2:
            return "Harmoney2"
        default:
            return ""
        }
    }
}

class ExampleViewController: UIViewController {

    var colors = [UIColor]()
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var controlView: UIView!
    @IBOutlet weak var controlOptionView: UIView!
    @IBOutlet weak var harmonyTypeSeg: UISegmentedControl!
    @IBOutlet weak var controlViewBottomConstraints: NSLayoutConstraint!
    @IBOutlet weak var controlViewHeightContraints: NSLayoutConstraint!
    
    private var currentHarmonyType : ColorHarmonyType = .analogous
    private var currentType : ColorType = .none
    private var pickerView : ColorPickerView?
    private var resetColor : UIColor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.colors = (0..<5).map { _ in UIColor.white }
        
        self.tableView.reloadData()
        
        if let picker = ColorPickerView.createPicker() {
            
            self.controlView.addSubview(picker)
            self.pickerView = picker
            picker.translatesAutoresizingMaskIntoConstraints = false
            picker.topAnchor.constraint(equalTo: self.controlOptionView.bottomAnchor).isActive = true
            picker.bottomAnchor.constraint(equalTo: self.controlView.bottomAnchor).isActive = true
            picker.leadingAnchor.constraint(equalTo: self.controlView.leadingAnchor, constant: 10).isActive = true
            picker.trailingAnchor.constraint(equalTo: self.controlView.trailingAnchor, constant: -10).isActive = true
            
            picker.didChangeColors = { [weak self] (colors) in
                
                guard let type = self?.currentType else {
                    return
                }
                switch type {
                case .primary:
                    self?.colors = colors
                    self?.tableView.reloadData()
                case .blackWhite:
                    if let color = colors.first {
                        self?.colors[type.rawValue] = color.blackOrWhite
                    }
                    self?.tableView.reloadRows(at: [IndexPath(row:type.rawValue, section: 0)], with: .none)
                case .complementary, .harmoney1, .harmoney2:
                    if let color = colors.first {
                        self?.colors[type.rawValue] = color
                    }
                    self?.tableView.reloadRows(at: [IndexPath(row:type.rawValue, section: 0)], with: .none)
                default:
                    break
                }
            }
        }
        
        // Do any additional setup after loading the view.
        self.harmonyTypeSeg.removeAllSegments()
        self.harmonyTypeSeg.insertSegment(withTitle: "Analogous", at: 0, animated: false)
        self.harmonyTypeSeg.insertSegment(withTitle: "Triadic", at: 1, animated: false)
        self.harmonyTypeSeg.selectedSegmentIndex = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.closeColorPicker(animate: false)
    }
    
    @IBAction func resetColor(_ sender: Any) {
        if let resetColor = self.resetColor {
            self.pickerView?.color = resetColor
        }
    }
    
    @IBAction func colorDone(_ sender: Any) {
        self.closeColorPicker(animate: true)
    }
    
    @IBAction func didChangeHarmonyType(_ sender: Any) {
        
        switch self.harmonyTypeSeg.selectedSegmentIndex {
        case 0:
            self.pickerView?.harmony = .analogous
        case 1:
            self.pickerView?.harmony = .triadic
        default:
            break
        }
    }
    
    @IBAction func importImage(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = ["public.image"]
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
    }
}

extension ExampleViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage, let color = image.color {
            self.pickerView?.color = color
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ExampleViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.colors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ColorCell", for: indexPath)
        
        if let colorCell = cell as? ColorViewCell {
            
            if let type = ColorType(rawValue: indexPath.row) {
                colorCell.title.text = type.toTitle()
            }
            colorCell.color = self.colors[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let type = ColorType(rawValue: indexPath.row) ?? .none
        
        if self.currentType == type {
            return
        }
        
        self.currentType = type
        
        let color = self.colors[indexPath.row]
        
        switch indexPath.row {
        case 0:
            self.openPrimaryColorPicker()
        case 1:
            self.openSubColorPicker(color:color)
        case 2:
            self.openSubColorPicker(color:color)
        case 3:
            self.openSubColorPicker(color:color)
        case 4:
            self.openSubColorPicker(color:color)
        default:
            break
        }
    }
    
    func openColorPicker() {
        
        UIView.animate(withDuration: 0.2) {
            self.controlViewBottomConstraints.constant = 0
            self.view.layoutIfNeeded()
            self.controlView.alpha = 1
        }
    }
    
    func closeColorPicker(animate:Bool) {
        
        let block : ()->Void = {
            self.controlView.alpha = 0
            self.controlViewBottomConstraints.constant = self.controlViewHeightContraints.constant * -1
        }
        
        if animate {
            UIView.animate(withDuration: 0.2) {
                block()
                self.view.layoutIfNeeded()
            }
            return
        }
        
        block()
    }
    
    func openPrimaryColorPicker() {
        
        if self.controlView.alpha == 0 {
            self.openColorPicker()
        }
        
        let primaryColor = self.colors[0]
        self.pickerView?.harmony = self.currentHarmonyType
        self.pickerView?.color = primaryColor
        self.harmonyTypeSeg.isHidden = false
        self.resetColor = primaryColor
    }
    
    func openSubColorPicker(color:UIColor) {
        
        if self.controlView.alpha == 0 {
            self.openColorPicker()
        }
        
        self.pickerView?.harmony = .none
        self.pickerView?.color = color
        self.harmonyTypeSeg.isHidden = true
        self.resetColor = color
    }
}

