//
//  ListViewController.swift
//  harita
//
//  Created by Berkay Avcılar on 11.09.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var isimDizisi = [String]()
    var idDizisi = [UUID]()
    var secilenYerIsmı = ""
    var secilenYerID : UUID?

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let jestAlgılayıcı = UIGestureRecognizer(target: self, action:#selector(klavyeKapa))
        view.addGestureRecognizer(jestAlgılayıcı)

        tableView.delegate = self
        tableView.dataSource = self
        
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(artiBtn))
        
        veriAl()
    }
    
    
    
    @objc func klavyeKapa(){
        view.endEditing(true)
    }
    
    @objc func artiBtn() {
        secilenYerIsmı = ""
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
                            
                                                                                          
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isimDizisi.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = isimDizisi[indexPath.row]
        return cell
    }
    
    
    @objc func veriAl(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
        request.returnsObjectsAsFaults = false
        
        do{
            
            let sonuclar = try context.fetch(request)
            
            if sonuclar.count > 0{
                isimDizisi.removeAll(keepingCapacity: false)
                idDizisi.removeAll(keepingCapacity: false)
                
                for sonuc in sonuclar as! [NSManagedObject]{
                    
                    if let isim = sonuc.value(forKey: "isim") as? String{//bize any olarak geliyor stringe çeviriyoz
                        isimDizisi.append(isim)
                    }
                    
                    if let id = sonuc.value(forKey: "id") as? UUID{
                        idDizisi.append(id)
                    }
                    
                }
                tableView.reloadData()//tableView'ı yeni dizi geldi diye yeniliyoruz
            }
            
        }catch{
            print("Hata")
        }
        
        
        
        
        
    }
    
    //    segue yapma (değer vc'dan veri çekme)
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {//tableView'daki row'a tıklandığında napacak
        secilenYerIsmı = isimDizisi[indexPath.row]
        secilenYerID = idDizisi[indexPath.row]
        performSegue(withIdentifier: "toMapsVC", sender: nil)
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {//öbür VC'deki bilgileri alır
        if segue.identifier == "toMapsVC"{
            let destinationVC = segue.destination as! mapViewController
            destinationVC.secilenIsim = secilenYerIsmı
            destinationVC.secilenID = secilenYerID
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(veriAl), name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {// sola kaydırınca silme işlemi
        if editingStyle == .delete{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
            let uuidString = idDizisi[indexPath.row].uuidString
            
            fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let sonuclar = try context.fetch(fetchRequest)
                if sonuclar.count > 0 {
                    for sonuc in sonuclar as! [NSManagedObject]{
                        
                        if let id = sonuc.value(forKey: "id") as? UUID{
                            if id == idDizisi[indexPath.row]{
                                context.delete(sonuc)
                                isimDizisi.remove(at: indexPath.row)
                                idDizisi.remove(at: indexPath.row)
                                
                                self.tableView.reloadData()
                                
                                do{
                                    try context.save()
                                }catch{
                                    print("Hata")
                                }
                                break
                            }
                        }
                    }
                }
            }catch{
                print("Hata")
            }
        }
    }
    
    
}
