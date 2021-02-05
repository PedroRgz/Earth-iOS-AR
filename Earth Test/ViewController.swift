//
//  ViewController.swift
//  Earth Test
//
//  Created by Pedro Rodríguez on 01/02/21.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    /*
     -Se utiliza ARSessionDelegate para modificar la escena de AR
     en funcion de la ambientación del usuario
    */

    @IBOutlet var sceneView: ARSCNView! //está unido al storyboard main
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Aquí se asoscia la escena creada y definida en Earth
        //a partir de aquí, se cargará lo que se encuentre en dicha escena
        let scene = SCNScene()
        
        
        // Set the scene to the view
        sceneView.scene = scene
        
        drawEarth()
    }
    
    
    func drawEarth(){
        //Se procede a cargar los elementos
        //...se empiezará por las imágenes
        guard let diffuse = UIImage(named: "art.scnassets/earth_diffuse_4k.jpg"),
              let specular = UIImage(named: "art.scnassets/earth_specular_1k.jpg"),
              let lights = UIImage(named: "art.scnassets/earth_lights_4k.jpg"),
              let normal = UIImage(named: "art.scnassets/earth_normal_4k.jpg"),
              let nubes = UIImage(named: "art.scnassets/clouds_transparent_2K.jpg") else {
            return
        }
        
        //ahora se crea una esferá que será la tierra
        let earth = SCNSphere(radius: 0.3) //30cm de radio
        /*
         la esfera por si sola no es nada, no se representa ni se ve
         tiene que ser asociada a un nodo para que se ancle a la escena y pueda visualizarse
         */
        let earthNode = SCNNode(geometry: earth)
        earthNode.name = "earth"
        
        
        //agregamos los materiales de nuestro modelo de esfera
        let earthMaterial = SCNMaterial()
        earthMaterial.diffuse.contents = diffuse
        earthMaterial.specular.contents = specular
        earthMaterial.normal.contents = normal
        earthMaterial.emission.contents = lights
        earthMaterial.multiply.contents = UIColor(white: 0.7, alpha: 1.0)
        earthMaterial.shininess = 0.5
        earth.firstMaterial = earthMaterial
        
        //Creamos las nubes
        //será ligeramente más grande para que esta envuelva la tierra
        let clouds = SCNSphere(radius: 0.3075)
        clouds.segmentCount = 144 //predeterminados son 48
        let cloudMaterial = SCNMaterial()
        cloudMaterial.diffuse.contents = UIColor.white
        cloudMaterial.locksAmbientWithDiffuse = true
        cloudMaterial.transparent.contents = nubes
        cloudMaterial.transparencyMode = .rgbZero
        //se disminuyen cargas de profundidad porque no serán necesarias
        cloudMaterial.writesToDepthBuffer = false
        
        //Cargamos el shader de las nubes
        if let shaderURL = Bundle.main.url(forResource: "AtmosphereHalo", withExtension: "glsl"),
           let contents = try? Data(contentsOf: shaderURL), let string = String(data: contents, encoding: .utf8){
            /*
             En esta parte del código, se establece la ruta del shacer, se abre de manera segura
             y se extrae el código en la variable string... Posteriormente se pasará el shader como material
             de las nubes...
             */
            cloudMaterial.shaderModifiers = [.fragment: string]
        }
        
        //asignamos las propiedades de los materiales a las nubes
        clouds.firstMaterial = cloudMaterial
        //Lo asignamos a un nodo
        let cloudNode = SCNNode(geometry: clouds)
        cloudNode.name = "nubes"
        
        //la agregamos a la tierra
        earthNode.addChildNode(cloudNode)
        
        /*
         Para darle un poco más de realismo, podemos inclinar a la tierra sobre su eje
         y se necesita establecer un eje sobre el cual se ancla la tierra para rotarla
         */
        let axisNode = SCNNode()
        /*
         Ahora, este nodo debe asociarse a la pantalla en donde se quiere establecer,
         por lo que se toma la sceneView y se asigna al nodo raíz
         */
        sceneView.scene.rootNode.addChildNode(axisNode) //porque este contiene la tierra
        axisNode.addChildNode(earthNode)
        axisNode.rotation = SCNVector4(1, 0, 0, Double.pi/6)
        
        
        
        /*
         Podemos colocar la tierra en una posición determinada, con la especificación
         de un vector x, y, z
         Alejamos el objeto 1m de nosotros (-1) y la bajamos porque el axis la eleva
         */
        earthNode.position = SCNVector3(0, -0.5, -1)
        
        //***************************************
        //para verificar si rota la tierra:
        earthNode.rotation = SCNVector4(0,1,0,0)
        //***************************************
        
        //***************************************
        //para verificar si rota las nubes:
        cloudNode.rotation = SCNVector4(0,1,0,0)
        //***************************************
        
        
        
        
        //Creamos una fuente de luz que represente el sol y brinde efectos de iluminación a la tierra
        let sun = SCNLight()
        sun.type = .spot //brindará una fuente de luz en forma cónica
        sun.castsShadow = true
        sun.shadowRadius = 0.3
        sun.shadowColor = UIColor(white: 0.0, alpha: 0.75)
        sun.zFar = 4.0 //la distancia visible de iluminación cercana
        sun.zNear = 1.0 //la distancia visible de iluminación cercana
        //anclamos esta figura a un nodo
        let sunNode = SCNNode()
        sunNode.light = sun
        sunNode.name = "sun"
        sunNode.position = SCNVector3(-15,0,12)
        //ahora especificamos que la fuente de luz apunte hacia un objetivo determinado
        sunNode.constraints = [SCNLookAtConstraint(target: earthNode)]
        //ahora agregamos el nodo del sol a la escena principal
        sceneView.scene.rootNode.addChildNode(sunNode)
        
        
        //Creamos la animación de rotación de la tierra -> las cuales se hacen a través de CoreAnimation
        let earthRotate = CABasicAnimation(keyPath: "rotation.w") //verificar si funciona sin la w
        earthRotate.byValue = CGFloat.pi * 2.0
        earthRotate.duration = 50 //durará 50 segs
        earthRotate.timingFunction = CAMediaTimingFunction(name: .linear) //linear
        earthRotate.repeatCount = .infinity //se repide de forma indefinida
        earthNode.addAnimation(earthRotate, forKey: "Rotación Tierra")
        
        //Creamos la animación de rotación de las nubes --> las cuales se hacen a través de core animation
        let cloudRotate = CABasicAnimation(keyPath: "rotation.w") //verificar si funciona sin la w
        cloudRotate.byValue = -CGFloat.pi * 2.0
        cloudRotate.duration = 150 //durará 150 segs
        cloudRotate.timingFunction = CAMediaTimingFunction(name: .linear) //linear
        cloudRotate.repeatCount = .infinity //se repide de forma indefinida
        cloudNode.addAnimation(cloudRotate, forKey: "Rotación nubes")
    }
    
    
    //Ahora se diseña la función que obtendrá la información del ambiente para actualizar la información
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //Vamos a recuperar la luz del ambiente y compararla con la que produce nuestro sol
        
        guard let sol = sceneView.scene.rootNode.childNode(withName: "sun", recursively: false),
              let ambientLight = session.currentFrame?.lightEstimate?.ambientIntensity,
              let tempAmbient = session.currentFrame?.lightEstimate?.ambientColorTemperature,
              let luzSolar = sol.light else {
            return
        }
        
        if luzSolar.intensity != ambientLight {
            sol.light?.intensity = ambientLight
            sol.light?.temperature = tempAmbient
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
