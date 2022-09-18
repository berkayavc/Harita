//
//  ViewController.swift
//  harita
//
//  Created by Berkay Avcılar on 5.09.2022.
//

import UIKit
import MapKit//import etmezsen çalışmaz
import CoreLocation//kullanıcının konumunu alır
import CoreData

class mapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var isimtxt: UITextField!
    
    @IBOutlet weak var nottxt: UITextField!
    
    var locationManager = CLLocationManager()//konum ile ilgili olaylarda kullanılır(konum yöneticisi)
    var secilenLatitute = Double()
    var secilenLongatiute = Double()
    var secilenIsim = ""
    var secilenID : UUID?
    var annotationTitle = ""
    var anotationSubtitle = ""
    var anotationLatitude = Double()
    var anotationLongatiude = Double()
    var gitme : Bool = true
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        Done button
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(self.doneClicked))
        toolBar.setItems([flexibleSpace,doneButton], animated: false)
        isimtxt.inputAccessoryView = toolBar
        nottxt.inputAccessoryView = toolBar
        
        gitme = true
        
        print("ViewDidLoad")
        mapView.delegate = self
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest//kullanıcının nerde olduğunun kesinliğine kadar ölçer (1km ötesine kadarda ölçebilir)
        locationManager.requestWhenInUseAuthorization()//sadece uygulamayı kullanırken konumu alır ve izin ister konumunu bulmak için.
        locationManager.startUpdatingLocation()//konumu güncellemey başla
        //izin istemek için infoya gittik
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:)))//uzun süre b estığında ne yapacak
        gestureRecognizer.minimumPressDuration = 1//bir saniye basılı tutulduğunda algılar
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsim != ""{
            //coreDatadan verileri çek
            if let uuidString = secilenID?.uuidString{//id'yi doğruluyoruz geldimi diye
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)//id'si yazacağım argümana eşit olanları getir
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0{
                        
                        for sonuc in sonuclar as! [NSManagedObject]{
                            
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                            }
                            
                            if let not = sonuc.value(forKey: "not") as? String{
                                anotationSubtitle = not
                            }
                            
                            if let latitude = sonuc.value(forKey:"latitude") as? Double{
                                anotationLatitude = latitude
                            }
                            
                            if let longitude = sonuc.value(forKey: "longitude") as? Double{
                                anotationLongatiude = longitude
                            }
                            //önceden kaydetiği yeri gösterecek
                            let annotation = MKPointAnnotation()
                            annotation.title = annotationTitle//isim
                            annotation.subtitle = anotationSubtitle//not
                            let coordinate = CLLocationCoordinate2D(latitude: anotationLatitude, longitude: anotationLongatiude)
                            annotation.coordinate = coordinate
                            mapView.addAnnotation(annotation)
                            isimtxt.text = annotationTitle
                            nottxt.text = anotationSubtitle
                            
                            locationManager.stopUpdatingLocation()//seni kaydetiğin yere götürürken birden olduğun yere götürmesin diye
                            let span = MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                            let region = MKCoordinateRegion(center: coordinate, span: span)
                            mapView.setRegion(region, animated: true)
                        }
                        
                    }
                    
                }catch{
                    print("Hata")
                }
                
            }
        }else{
            //yeni veri eklemeye geldi
            
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        print("ViewWillAppear çalıştı")
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {//sana güncelledikçe konumları veriyor bunuda locations dizisinin içine atıyor sen bunu kullanıcaksın
//        print(locations[0].coordinate.latitude)//cordinataki enlem
//        print(locations[0].coordinate.longitude)//cordinataki boylam
        if secilenIsim == ""{//yeni bir yer eklediğinde çalışır sadece
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)//aldığımız enlem ve boylamdan lokasyon oluşturulabilir
            let span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)//bölgenin yükseklik ve genişliğine göre zoomlar yükseltirsek daha uzaktan görülür
            
            let region = MKCoordinateRegion(center: location, span: span)
            if gitme == true{
                mapView.setRegion(region, animated: true)//nerdeysen oraya götürür
                gitme = false
                print(gitme)
            }
            
        }
        
        
        
        
        
    }
    
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began{//state = durum demek jestin durumunu aldık ve eğer başlıyorsa bunu yap diyecez
            
            let dokunulanNokta = gestureRecognizer.location(in: mapView)
            let dokunulanKordinat = mapView.convert(dokunulanNokta, toCoordinateFrom: mapView)//dokununlan noktayı kordinata çevirir
            
            secilenLatitute = dokunulanKordinat.latitude
            secilenLongatiute = dokunulanKordinat.longitude
            
            let annotation = MKPointAnnotation()//dokunduğumuz yere iğne koyar
            annotation.coordinate = dokunulanKordinat//burda gösterilecek
            annotation.title = isimtxt.text//başlık
            annotation.subtitle = nottxt.text//altyazı
            mapView.addAnnotation(annotation)
            
        }
    }
    
    
    
    
    
    @IBAction func kaydetBtn(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(isimtxt.text, forKey: "isim")
        yeniYer.setValue(nottxt.text, forKey: "not")
        yeniYer.setValue(secilenLatitute, forKey: "latitude")
        yeniYer.setValue(secilenLongatiute, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        do{
            try context.save()
            print("Kayıt Edildi")
            NotificationCenter.default.post(name: NSNotification.Name("yeniYerOlusturuldu"), object: nil)//gözlemci oluşturduk
            navigationController?.popViewController(animated: true)//list VC'ye geri döndürür
        }catch{
            print("Hata")
            let alert = UIAlertController(title: "Kayıt Başarısız", message: "Seçtiğiniz Yer Kayıt Edilemedi", preferredStyle: UIAlertController.Style.alert)
            present(alert, animated: true, completion: nil)
            let action = UIAlertAction(title: " Tamam", style: UIAlertAction.Style.default){
                (action : UIAlertAction) in
            }
            alert.addAction(action)
        }
        
        
        
        
    }
    
    @objc func doneClicked() {
        view.endEditing(true)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {//iğnenin yanına buton ekleme ve özelleştirme
//https://www.btkakedemi.go.tr/portal/course/player/deliver(swift-ile-ios-proglamlama-12273
        if annotation is MKUserLocation{//eğer kullanıcının yeri ile ilgili bir şey yapacaksan
            return nil
        }
        
        let reusedID = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reusedID)
        
        if pinView == nil{
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reusedID)
            pinView?.canShowCallout = true
            pinView?.tintColor = .blue
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {//iğnenin yanındaki butona tıkladığın zaman ne olacak - apple haritaya atacak
        if secilenIsim != ""{//eğer kullanıcı kaydedilmiş  ir şeye bakacaksa
            
            let requestLocation = CLLocation(latitude: anotationLatitude, longitude: anotationLongatiude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarkDizisi, hata in
                
                if let placemarks = placemarkDizisi{
                    if placemarks.count > 0{
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]//arabaylamı gidecek bisikletlemi fln
                        
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
            
            
            
        }
    }
}

